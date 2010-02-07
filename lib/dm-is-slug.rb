require 'pathname'
require 'dm-core'

# Require plugin-files
require Pathname(__FILE__).dirname.expand_path / 'dm-is-slug' / 'is' / 'slug.rb'

DataMapper::Model.append_extensions DataMapper::Is::Slug
