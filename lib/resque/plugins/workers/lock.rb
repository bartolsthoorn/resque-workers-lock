module Resque
  module Plugins
    module Workers
      module Lock
        # Override in your job to control the lock key.
        def lock(*args)
          "lock:#{name}-#{args.to_s}"
        end
        
        def requeue_perform_delay
          1.0
        end
        
        def before_perform_lock(*args)
          nx = Resque.redis.setnx(lock(*args), true)
          if nx == false
            sleep(requeue_perform_delay)
            Resque.enqueue(self, *args)
            raise Resque::Job::DontPerform
          end
        end
      
        def around_perform_lock(*args)
          begin
            yield
          ensure
            # Clear the lock. (even with errors)
            Resque.redis.del(lock(*args))
          end
        end
      end
    end
  end
end