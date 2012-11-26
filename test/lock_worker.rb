require 'resque'
require 'resque/plugins/workers/lock'

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