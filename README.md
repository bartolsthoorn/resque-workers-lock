# Resque Workers Lock
This is a [resque](https://github.com/defunkt/resque) plugin inspired by [resque-lock](https://github.com/defunkt/resque-lock) and requires Resque 1.7.0.

## What does it do?
If resque jobs have the same lock applied this means that those jobs cannot be processed simultaneously by two or more workers.

## What is the default lock?
By default the lock is the instance name + arguments (just like the classic resque-lock). Override this lock to lock on specific arguments.

## How does it differ from resque-lock?
Resque-lock will not let you queue jobs when you locked them. Resque-workers-lock locks on a workers-level and will requeue the locked jobs. Resque workers lock will not prevent you to queue jobs. If a worker takes on a job that is already being processed by another worker it will put the job back up in the queue!

## Example
This example shows how you can use the workers-lock to prevent two jobs with the same domain to be processed simultaneously.
``` ruby
require 'resque/plugins/workers/lock'

class Scraper
  extend Resque::Plugins::Workers::Lock

	def self.lock(domain)
		return domain
	end

  def self.perform(domain)
    # do the work
  end
end
```

## Requeue loop
When a job is requeue'ed there is a small delay (1 second by default) before the worker places the job actually back in the queue. Let's say you have two jobs left, and one job is taking 15 seconds on the first worker and the other similar job is being blocked by the second worker. The second worker will continuously try to put the job back in the queue and it will try to process it again (racing for 15 seconds untill the other job has finished). This only happens when there are no other (not locked) jobs in the queue.

To overwrite this delay in your class:
``` ruby
def self.requeue_perform_delay
	5.0
end
```

Please note that setting this value to 5 seconds will keep the worker idle for 5 seconds when the job is locked.

## Possibilities to prevent the loop 
Do a delayed resque (re)queue. However, this will have approximately the same results and will require a large extra chunk of code and rake configurations.
