# -*- ruby -*-

require 'rubygems'
require 'hoe'
require 'spec/rake/spectask'
require 'pathname'

ROOT = Pathname(__FILE__).dirname.expand_path
require ROOT + 'lib/dm-is-slug/is/version'

AUTHOR = "Aaron Qian"
EMAIL  = "aaron [a] ekohe [d] com"
GEM_NAME = "dm-is-slug"
GEM_VERSION = DataMapper::Is::Slug::VERSION
GEM_DEPENDENCIES = [["dm-core", GEM_VERSION]]
GEM_CLEAN = ["log", "pkg"]
GEM_EXTRAS = { :has_rdoc => false }
 
PROJECT_NAME = "datamapper"
PROJECT_URL  = "http://github.com/aq1018/dm-is-slug"
PROJECT_DESCRIPTION = PROJECT_SUMMARY = "DataMapper plugin that generates unique slugs"

Hoe.new('dm-is-slug', DataMapper::Is::Slug::VERSION) do |p|
  p.rubyforge_name = 'dm-is-slug' # if different than lowercase project name
  p.developer('Aaron Qian', 'aaron [a] ekohe [d] com')
end

task :default => [ :spec ]
 
WIN32 = (RUBY_PLATFORM =~ /win32|mingw|cygwin/) rescue nil
SUDO  = WIN32 ? '' : ('sudo' unless ENV['SUDOLESS'])
 
desc "Install #{GEM_NAME} #{GEM_VERSION}"
task :install => [ :package ] do
  sh "#{SUDO} gem install --local pkg/#{GEM_NAME}-#{GEM_VERSION} --no-update-sources", :verbose => false
end
 
desc "Uninstall #{GEM_NAME} #{GEM_VERSION} (default ruby)"
task :uninstall => [ :clobber ] do
  sh "#{SUDO} gem uninstall #{GEM_NAME} -v#{GEM_VERSION} -I -x", :verbose => false
end
 
desc 'Run specifications'
Spec::Rake::SpecTask.new(:spec) do |t|
  t.spec_opts << '--options' << 'spec/spec.opts' if File.exists?('spec/spec.opts')
  t.spec_files = Pathname.glob(Pathname.new(__FILE__).dirname + 'spec/**/*_spec.rb')
 
  begin
    t.rcov = ENV.has_key?('NO_RCOV') ? ENV['NO_RCOV'] != 'true' : true
    t.rcov_opts << '--exclude' << 'spec'
    t.rcov_opts << '--text-summary'
    t.rcov_opts << '--sort' << 'coverage' << '--sort-reverse'
  rescue Exception
    # rcov not installed
  end
end
