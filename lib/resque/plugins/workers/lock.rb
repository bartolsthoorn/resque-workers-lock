require 'resque'

module Resque
  alias_method :orig_remove_queue, :remove_queue

  def remove_queue(queue)
    Resque.redis.keys('workerslock:*').each{ |x| Resque.redis.del(x) }
    orig_remove_queue(queue)
  end

  module Plugins
    module Workers
      module Lock

        # Override in your job to control the worker lock experiation time. This
        # is the time in seconds that the lock should be considered valid. The
        # default is one hour (3600 seconds).
        def worker_lock_timeout(*)
          3600
        end

        # Override in your job to control the workers lock key(s).
        def lock_workers(*args)
          "#{name}-#{args.to_s}"
        end

        def get_lock_workers(*args)
          lock_result = lock_workers(*args)

          if lock_result.kind_of?(Array)
            lock_result.map do |lock|
              "workerslock:#{lock}"
            end
          else
            ["workerslock:#{lock_result}"]
          end
        end

        # Override in your job to change the perform requeue delay
        def requeue_perform_delay
          1.0
        end

        # Override in your job to change the way how job is reenqueued
        def reenqueue
          if defined? Resque::Scheduler
            # schedule a job in requeue_perform_delay seconds
            Resque.enqueue_in(requeue_perform_delay, self, *args)
          else
            sleep(requeue_perform_delay)
            Resque.enqueue(self, *args)
          end
          raise Resque::Job::DontPerform
        end

        # Called with the job args before perform.
        # If it raises Resque::Job::DontPerform, the job is aborted.
        def before_perform_workers_lock(*args)
          if lock_workers(*args)
            lock_result = get_lock_workers(*args)

            if Resque.redis.msetnx lock_result.zip([true]*lock_result.size).flatten
              lock_result.each do |lock|
                Resque.redis.expire(lock, worker_lock_timeout(*args))
              end
            else
              reenqueue
            end
          end
        end

        def clear_workers_lock(*args)
          lock_result = get_lock_workers(*args)

          lock_result.each do |lock|
            Resque.redis.del(lock)
          end
        end

        def around_perform_workers_lock(*args)
          yield
        ensure
          # Clear the lock. (even with errors)
          clear_workers_lock(*args)
        end

        def on_failure_workers_lock(exception, *args)
          # Clear the lock on DirtyExit
          clear_workers_lock(*args)
        end

      end
    end
  end
end
