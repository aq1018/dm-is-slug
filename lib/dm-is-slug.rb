require 'pathname'
require 'iconv'
require 'dm-core'

require Pathname(__FILE__).dirname.expand_path / 'dm-is-slug' / 'is' / 'version.rb'

# Require plugin-files
require Pathname(__FILE__).dirname.expand_path / 'dm-is-slug' / 'is' / 'slug.rb'

DataMapper::Model.append_extensions DataMapper::Is::Slug
