Gem::Specification.new do |s|
  s.name              = "resque-workers-lock"
  s.version           = "1.0.0"
  s.date              = Time.now.strftime('%Y-%m-%d')
  s.summary           = "Resque plugin, prevent specific jobs to be processed simultaneously by multiple workers."
  s.homepage          = "http://github.com/defunkt/resque-lock"
  s.email             = "bartolsthoorn@gmail.com"
  s.authors           = [ "Bart Olsthoorn" ]
  s.has_rdoc          = false

  s.files             = %w( README.md Rakefile LICENSE )
  s.files            += Dir.glob("lib/**/*")
  s.files            += Dir.glob("test/**/*")

  s.description       = <<desc
A Resque plugin. If you want to prevent specific jobs to be processed simultaneously, 
extend it with this module. It locks on the first argument in the perform method.

For example:

    class UpdateNetworkGraph
      extend Resque::Workers::Lock

      def self.perform(domain)
        # Do HTTP request to domain
      end
    end
desc
end