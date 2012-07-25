module Resque
  module Plugins
    module Workers
      module Lock
        
        # Override in your job to control the queue lock key
        def enqueue_lock(*args)
          "enqueuelock:#{name}-#{args.to_s}"
        end
        
        # Override in your job to control the workers lock key.
        def workers_lock(*args)
          "workerslock:#{name}-#{args.to_s}"
        end
        
        # Override in your job to change the perform requeue delay
        def requeue_perform_delay
          1.0
        end
        
        def before_enqueue_lock(*args)
          if enqueue_lock(*args)
            return Resque.redis.setnx(enqueue_lock(*args), true)
          else
            return true
          end
        end
        
        def before_perform_lock(*args)
          if workers_lock(*args)
            nx = Resque.redis.setnx(workers_lock(*args), true)
            if nx == false
              sleep(requeue_perform_delay)
              Resque.redis.del(enqueue_lock(*args))
              Resque.enqueue(self, *args)
              raise Resque::Job::DontPerform
            end
          end
        end
      
        def around_perform_lock(*args)
          begin
            yield
          ensure
            # Clear the lock. (even with errors)
            Resque.redis.del(workers_lock(*args))
            Resque.redis.del(enqueue_lock(*args))
          end
        end
        
        def on_failure_lock(exception, *args)
          # Clear the lock on DirtyExit
          Resque.redis.del(workers_lock(*args))
          Resque.redis.del(enqueue_lock(*args))
        end
        
      end
    end
  end
end