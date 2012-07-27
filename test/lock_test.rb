require 'test/unit'
require 'resque'
require 'resque/plugins/workers/lock'

$counter = 0

class LockTest < Test::Unit::TestCase
  class SimilarJob
    extend Resque::Plugins::Workers::Lock
    @queue = :lock_test

    def self.perform
      raise "Woah woah! How did this happen?"
    end
  end
  
  class UniqueJob
    extend Resque::Plugins::Workers::Lock
    @queue = :lock_test
    
    #def self.lock_enqueue(id)
    #  return id.to_s
    #end
    
    def self.lock_workers(id)
      return id.to_s
    end
    
    def self.perform(id)
      raise "Woah woah! How did this happen?"
    end
  end

  def setup
    Resque.redis.del('queue:lock_test')
    Resque.redis.del(SimilarJob.lock_workers)
    Resque.redis.del(SimilarJob.lock_enqueue)
  end

  def test_lint
    assert_nothing_raised do
      Resque::Plugin.lint(Resque::Plugins::Workers::Lock)
    end
  end

  def test_version
    major, minor, patch = Resque::Version.split('.')
    assert_equal 1, major.to_i
    assert minor.to_i >= 17
    assert Resque::Plugin.respond_to?(:before_enqueue_hooks)
  end

  def test_enqueue
    3.times { Resque.enqueue(SimilarJob) }

    assert_equal "workerslock:LockTest::SimilarJob-[]", SimilarJob.lock_workers
    assert_equal "enqueuelock:LockTest::SimilarJob-[]", SimilarJob.lock_enqueue
    assert_equal 1, Resque.redis.llen('queue:lock_test')
    
    3.times do |i|
      Resque.enqueue(UniqueJob, (i+100).to_s)
      #assert_equal i.to_s, UniqueJob.lock_enqueue(i.to_s)
      assert_equal i.to_s, UniqueJob.lock_workers(i.to_s)
    end
    
    assert_equal 4, Resque.redis.llen('queue:lock_test')
    
    # Test for complete queue wipe
    Resque.remove_queue(:lock_test)
    
    Resque.enqueue(SimilarJob)
    assert_equal 1, Resque.redis.llen('queue:lock_test')
  end
  
  def test_zcleanup
    Resque.redis.del(SimilarJob.lock_workers)
    Resque.redis.del(SimilarJob.lock_enqueue)
    
    3.times do |i|
      Resque.redis.del(UniqueJob.lock_enqueue((i+100).to_s))
    end
    Resque.redis.del('queue:lock_test')
    assert_equal 0, Resque.redis.llen('queue:lock_test')
  end
  
  def test_lock
    # TODO: test that two workers are not processing two jobs with same locks
    # This is pretty hard to do, contributors are welcome!
  end
end