Gem::Specification.new do |s|
  s.name = "dm-is-slug"
  s.version = "0.9.9"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Aaron Qian, Nik Radford"]
  s.date = "2009-01-12"
  s.description = "DataMapper plugin that generates unique permalinks / slugs"
  s.email = ["aaron [a] ekohe [d] com; nik [a] terminaldischarge [d] net"]
  s.extra_rdoc_files = ["History.txt", "Manifest.txt", "README.txt"]
  s.files = [
    "History.txt", 
    "LICENSE", 
    "Manifest.txt", 
    "README.txt", 
    "Rakefile", 
    "TODO", 
    "lib/dm-is-slug.rb", 
    "lib/dm-is-slug/is/slug.rb", 
    "lib/dm-is-slug/is/version.rb", 
    "spec/integration/slug_spec.rb", 
    "spec/spec.opts", 
    "spec/spec_helper.rb"
  ]
  
  s.homepage = "http://github.com/aq1018/dm-is-slug"
  s.rdoc_options = ["--main", "README.txt"]
  s.require_paths = ["lib"]
  s.rubyforge_project = "dm-is-slug"
  s.rubygems_version = "1.3.1"
  s.summary = "DataMapper plugin that generates unique permalinks / slugs"

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<dm-core>, ["~> 0.9"])
      s.add_development_dependency(%q<hoe>, [">= 1.8.2"])
    else
      s.add_dependency(%q<dm-core>, ["~> 0.9"])
      s.add_dependency(%q<hoe>, [">= 1.8.2"])
    end
  else
    s.add_dependency(%q<dm-core>, ["~> 0.9"])
    s.add_dependency(%q<hoe>, [">= 1.8.2"])
  end
end
