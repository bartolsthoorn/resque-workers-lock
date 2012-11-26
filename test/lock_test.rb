require 'test/unit'
require 'resque/plugins/workers/lock'
require 'tempfile'

class LockTest < Test::Unit::TestCase
  class UniqueJob
    extend Resque::Plugins::Workers::Lock
    @queue = :lock_test

    def self.lock_workers(*)
      self.name
    end

    def self.perform params
      File.open(params['output_file'], 'a') do |output_file|
        output_file.puts params['job']
        output_file.flush
        sleep 1
        output_file.puts params['job']
      end
    end
  end

  def test_lint
    assert_nothing_raised do
      Resque::Plugin.lint(Resque::Plugins::Workers::Lock)
    end
  end

  def test_workers_dont_work_simultaneously
    assert_locking_works_with jobs: 2, workers: 2
  end

  private

  def assert_locking_works_with options
    jobs = (1..options[:jobs]).map{|job| "Job #{job}" }
    output_file = Tempfile.new 'output_file'

    jobs.each do |job|
      Resque.enqueue UniqueJob, job: job, output_file: output_file.path
    end

    process_jobs workers: options[:workers], timeout: 10

    lines = File.readlines(output_file).map(&:chomp)
    lines.each_slice(2) do |a,b|
      assert_equal a,b, "#{a} was interrupted by #{b}"
    end
  ensure
    output_file.close
  end

  def process_jobs options
    with_workers options[:workers] do
      wait_until(options[:timeout]) do
         no_busy_workers && no_queued_jobs
      end
    end
  end

  def with_workers n
    pids = []
    n.times do
      if pid = fork
        pids << pid
      else
        pids = [] # Don't kill from child's ensure
        worker = Resque::Worker.new('*')
        worker.reconnect
        worker.work(0.5)
        exit!
      end
    end

    yield

  ensure
    pids.each do |pid|
      Process.kill("QUIT", pid)
    end

    pids.each do |pid|
      Process.waitpid(pid)
    end
  end

  def no_busy_workers
    Resque::Worker.working.size == 0
  end

  def no_queued_jobs
    Resque.redis.llen("queue:lock_test") == 0
  end

  def wait_until(timeout)
    timeout.times do
      return if yield
      sleep 1
    end

    raise "Timout occured"
  end
end
