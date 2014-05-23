require File.expand_path('../../lib/resque/plugins/workers/lock', __FILE__)

class UniqueJobMKey
  extend Resque::Plugins::Workers::Lock
  @queue = :mlock_test

  def self.worker_lock_timeout(*)
    5
  end

  def self.lock_workers(*)
    [self.name + '1', self.name + '2']
  end

  def self.append_output filename, string
    File.open(filename, 'a') do |output_file|
      output_file.puts string
    end
  end

  def self.perform params
    append_output params['output_file'], "starting #{params['job']}"
    sleep(params['sleep'] || 1)
    append_output params['output_file'], "finished #{params['job']}"
  end
end
