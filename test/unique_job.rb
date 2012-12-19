require File.expand_path('../../lib/resque/plugins/workers/lock', __FILE__)

class UniqueJob
  extend Resque::Plugins::Workers::Lock
  @queue = :lock_test

  def self.worker_lock_timeout(*)
    5
  end

  def self.lock_workers(*)
    self.name
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