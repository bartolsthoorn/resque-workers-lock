module Resque
  module Plugins
    module Workers
      module Lock
        # Override in your job to control the lock key.
        def lock(*args)
          "lock:#{name}-#{args.to_s}"
        end
        
        def before_perform_with_lock(*args)
          nx = Resque.redis.setnx(lock(*args), true)
          raise Resque::Failure, "worker locked" unless nx
        end
        
        def on_failure_retry(e, *args)
          Logger.info "Performing #{self} caused an exception (#{e}). Retrying..."
          Resque.enqueue self, *args
        end
      
        def around_perform_lock(*args)
          begin
            yield
          ensure
            # Always clear the lock when we're done, even if there is an
            # error.
            Resque.redis.del(lock(*args))
          end
        end
      end
    end
  end
end