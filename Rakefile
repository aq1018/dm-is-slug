require 'rubygems'
require 'rake'

begin
  gem 'jeweler', '~> 1.4'
  require 'jeweler'

  Jeweler::Tasks.new do |gem|
    gem.name = "dm-is-slug"
    gem.summary = "DataMapper plugin that generates unique slugs"
    gem.description = gem.summary
    gem.email = [
      'aq1018@gmail.com',
      'james.herdman@gmail.com',
      'nik [a] terminaldischarge [d] net',
      'maverick.stoklosa@gmail.com',
      'frawl021@gmail.com',
      'cheba+github@pointlessone.org'
    ]
    gem.homepage = "http://github.com/aq1018/dm-is-slug"
    gem.authors = ['Aaron Qian', 'James Herdman', 'Nik Radford', 'Paul', 'Mike Frawley', 'Alexander Mankuta']

    gem.add_dependency "dm-core", "~> 1.0.2"
    gem.add_dependency "dm-validations", "~> 1.0.2"
    gem.add_dependency "unidecode", "~> 1.0.0"

    gem.add_development_dependency 'rspec', '~> 1.3'
  end

  Jeweler::GemcutterTasks.new

  FileList['tasks/**/*.rake'].each { |task| import task }
rescue LoadError
  puts 'Jeweler (or a dependency) not available. Install it with: gem install jeweler'
end
