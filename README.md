# Resque Workers Lock
This is a [resque](https://github.com/defunkt/resque) plugin inspired by [resque-lock](https://github.com/defunkt/resque-lock) and requires Resque 1.7.0.

## What does it do?
If resque jobs have the same lock applied this means that those jobs cannot be processed simultaneously by two or more workers.

## The Lock
By default the lock is the instance name + arguments. Override this lock to lock on specific arguments.

## How does it differ from resque-lock
Resque-lock will not let you queue jobs when you locked them. Resque-workers-lock locks on a workers-level and will requeue the locked jobs.

## Example
``` ruby
require 'resque/plugins/workers/lock'

class UpdateNetworkGraph
  extend Resque::Plugins::Workers::Lock

	def self.lock(domain)
		return domain
	end

  def self.perform(domain)
    # do the work
  end
end
```