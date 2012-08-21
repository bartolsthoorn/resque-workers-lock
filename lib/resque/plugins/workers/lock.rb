module Resque
  alias_method :orig_remove_queue, :remove_queue
  
  def remove_queue(queue)
    Resque.redis.keys('enqueuelock:*').collect { |x| Resque.redis.del(x) }.count
    Resque.redis.keys('workerslock:*').collect { |x| Resque.redis.del(x) }.count
    
    orig_remove_queue(queue)
  end
  
  module Plugins
    module Workers
      module Lock
        
        # Override in your job to control the queue lock key
        def lock_enqueue(*args)
          "#{name}-#{args.to_s}"
        end
        
        def get_lock_enqueue(*args)
          "enqueuelock:"+lock_enqueue(*args).to_s
        end
        
        # Override in your job to control the workers lock key.
        def lock_workers(*args)
          "#{name}-#{args.to_s}"
        end
        
        def get_lock_workers(*args)
          "workerslock:"+lock_workers(*args).to_s
        end
        
        # Override in your job to change the perform requeue delay
        def requeue_perform_delay
          1.0
        end
        
        
        # Called with the job args before a job is placed on the queue. 
        # If the hook returns false, the job will not be placed on the queue.
        def before_enqueue_lock(*args)
          if lock_enqueue(*args) == false
            return true
          else
            return Resque.redis.setnx(get_lock_enqueue(*args), true)
          end
        end
        
        # Called with the job args before perform. 
        # If it raises Resque::Job::DontPerform, the job is aborted.
        def before_perform_lock(*args)
          if lock_workers(*args)
            nx = Resque.redis.setnx(get_lock_workers(*args), true)
            if nx == false
              sleep(requeue_perform_delay)
              Resque.redis.del(get_lock_enqueue(*args))
              Resque.enqueue(self, *args)
              raise Resque::Job::DontPerform
            end
          end
        end
        
        def after_dequeue_lock(*args)
          # Clear the lock when dequeueed
          Resque.redis.del(get_lock_enqueue(*args))
        end
      
        def around_perform_lock(*args)
          begin
            yield
          ensure
            # Clear the lock. (even with errors)
            Resque.redis.del(get_lock_workers(*args))
            Resque.redis.del(get_lock_enqueue(*args))
          end
        end
        
        def on_failure_lock(exception, *args)
          # Clear the lock on DirtyExit
          Resque.redis.del(get_lock_workers(*args))
          Resque.redis.del(get_lock_enqueue(*args))
        end
        
      end
    end
  end
end