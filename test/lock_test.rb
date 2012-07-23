require 'test/unit'
require 'resque'
require 'resque/plugins/workers/lock'

$counter = 0

class LockTest < Test::Unit::TestCase
  class Job
    extend Resque::Plugins::Workers::Lock
    @queue = :lock_test

    def self.perform
      raise "This should not have not happened"
    end
  end

  def setup
    Resque.redis.del('queue:lock_test')
    Resque.redis.del(Job.lock)
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

  def test_lock
    3.times { Resque.enqueue(Job) }

    assert_equal 3, Resque.redis.llen('queue:lock_test')
  end
end