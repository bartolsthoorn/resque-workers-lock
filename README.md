# Resque Workers Lock
This is a [resque](https://github.com/defunkt/resque) plugin inspired by [resque-lock](https://github.com/defunkt/resque-lock).

``` ruby
gem 'resque-workers-lock'
```

**Important notice** - As of this gem version 1.7, Resque Workers Lock no longer includes an enqueue lock but focusses solely on a workers lock. If you're also looking for enqueue lock functionality, just add [resque-lock](https://github.com/defunkt/resque-lock) or another plugin in the mix.

## What does it do?
If resque jobs have the same lock(s) applied this means that those jobs cannot be processed simultaneously by two or more workers. When this situation occurs the second job gets pushed back to the queue.

## What is the default lock?
By default the lock is the instance name + arguments (just like the classic resque-lock). Override this lock to lock on specific arguments.
You can specify only one lock or an array of locks.

## How does it differ from resque-lock?
Resque-lock will not let you enqueue jobs when you locked them. Resque-workers-lock locks on a workers-level and will requeue the locked jobs. If a worker takes on a job that is already being processed by another worker it will put the job back up in the queue!

## Example
This example shows how you can use the workers-lock to prevent two jobs with the same domain to be processed simultaneously.

``` ruby
require 'resque/plugins/workers/lock'

class Parser
  extend Resque::Plugins::Workers::Lock

  # Lock method has the same arguments as the self.perform
  def self.lock_workers(domain, arg2, arg3)
    return domain
  end

  # This is the time in seconds that the worker lock should be considered valid.
  # The default is one hour (3600 seconds).
  def self.worker_lock_timeout(domain, arg2, arg3)
    3600
  end

  # Perform method with some arguments
  def self.perform(domain, arg2, arg3)
    # do the work
  end
end
```

In this example `domain` is used to specify certain types of jobs that are not allowed to run at the same time. For example: if you create three jobs with the domain argument google.com, google.com and yahoo.com, the two google.com jobs will never run at the same time.

## One queue
Best results with one big queue instead of multiple queues.

## Requeue loop
When a job is requeued there is a small delay (1 second by default) before the worker places the job back in the queue. Let's say you have two jobs left, and one job is taking 15 seconds on the first worker and the other similar job is being blocked by the second worker. The second worker will continuously try to put the job back in the queue and it will try to process it again (racing for 15 seconds untill the other job has finished). This only happens when there are no other (not locked) jobs in the queue.

To overwrite this delay in your class:
``` ruby
def self.requeue_perform_delay
  5.0
end
```

Please note that setting this value to 5 seconds will keep the worker idle for 5 seconds when the job is locked.

## Possibilities to prevent the loop
Do a delayed resque (re)queue. However, this will have approximately the same results and will require a large extra chunk of code and rake configurations.

## Authors/Contributors
[nicholaides](https://github.com/nicholaides)
[jgarber](https://github.com/jgarber)
