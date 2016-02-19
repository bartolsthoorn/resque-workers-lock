Gem::Specification.new do |s|
  s.name              = "resque-workers-lock"
  s.version           = "2.0.1"
  s.date              = Time.now.strftime('%Y-%m-%d')
  s.summary           = "Resque plugin, prevent specific jobs to be processed simultaneously by multiple workers."
  s.homepage          = "http://github.com/bartolsthoorn/resque-workers-lock"
  s.email             = "bartolsthoorn@gmail.com"
  s.authors           = ["Bart Olsthoorn", "Mike Nicholaides", "Jason Garber", "Tijs Planckaert", "Anton Bogdanovich"]
  s.licenses          = ["MIT"]
  s.has_rdoc          = false

  s.files             = %w( README.md Rakefile LICENSE )
  s.files            += Dir.glob("lib/**/*")
  s.files            += Dir.glob("test/**/*")

  s.add_dependency "resque"
  s.add_development_dependency "rake"

  s.description       = <<desc
A Resque plugin. Two or more jobs with the same lock cannot be processed simultaneously by multiple workers.
When this situation occurs the second job gets pushed back to the queue.
desc
end
