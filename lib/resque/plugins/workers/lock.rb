module Resque
  module Plugins
    module Workers
      module Lock
        # Override in your job to control the lock key.
        def lock(*args)
          "lock:#{name}-#{args.to_s}"
        end
        
        def before_perform_lock(*args)
          if Resque.redis.setnx(lock(*args), true)
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