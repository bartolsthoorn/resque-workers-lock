require 'test/unit'
require 'resque/plugins/workers/lock'

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

    def self.lock_enqueue(id)
      return id.to_s+"e"
    end

    def self.lock_workers(id)
      return id.to_s+"w"
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

  def test_enqueue
    3.times { Resque.enqueue(SimilarJob) }

    assert_equal "LockTest::SimilarJob-[]", SimilarJob.lock_workers
    assert_equal "LockTest::SimilarJob-[]", SimilarJob.lock_enqueue
    assert_equal 1, Resque.redis.llen('queue:lock_test')

    3.times do |i|
      Resque.enqueue(UniqueJob, i+100)
      assert_equal i.to_s+"e", UniqueJob.lock_enqueue(i)
      assert_equal i.to_s+"w", UniqueJob.lock_workers(i)
    end

    assert_equal 4, Resque.redis.llen('queue:lock_test')

    # Test for complete queue wipe
    Resque.remove_queue(:lock_test)

    Resque.enqueue(SimilarJob)
    assert_equal 1, Resque.redis.llen('queue:lock_test')
  end

  def test_zcleanup
    Resque.remove_queue(:lock_test)

    Resque.redis.keys('enqueuelock:*').collect { |x| Resque.redis.del(x) }
    Resque.redis.keys('workerslock:*').collect { |x| Resque.redis.del(x) }

    assert_equal 0, Resque.redis.llen('queue:lock_test')
  end

  # Sleep job, for testing that two workers are not processing two jobs with
  # the same lock.
  class SimilarSleepJob
    extend Resque::Plugins::Workers::Lock
    @queue = :lock_test_workers

    def self.lock_enqueue(id)
      false
    end

    def self.lock_workers(id)
      return id.to_s
    end

    def self.perform(id)
      File.open('test/test.txt', 'a') {|f| f.write('1') }
      sleep(5)
    end
  end

  # To test this, make sure to run `TERM_CHILD=1 COUNT=2 VVERBOSE=1 QUEUES=* rake resque:work`
  def test_lock
    2.times { Resque.enqueue(SimilarSleepJob, 'writing_and_sleeping') }
    SimilarSleepJob.perform('abc')
    
    # After 3 seconds only 1 job had the change of running
    sleep(3)
    file = File.open('test/test.txt', 'rb')
    contents = file.read
    file.close
    assert_equal '1', contents
    
    # After 12 seconds the 2 jobs should have been processed (not at the same time because of the lock)
    sleep(12)
    file = File.open('test/test.txt', 'rb')
    contents = file.read
    file.close
    assert_equal '11', contents
  end
end
