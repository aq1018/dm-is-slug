require 'pathname'
require 'iconv'
require 'dm-core'

require Pathname(__FILE__).dirname.expand_path / 'dm-is-slug' / 'is' / 'version.rb'

# Require plugin-files
require Pathname(__FILE__).dirname.expand_path / 'dm-is-slug' / 'is' / 'slug.rb'

# Include the plugin in Resource
module DataMapper
  module Resource
    module ClassMethods
      include DataMapper::Is::Slug
    end # module ClassMethods
  end # module Resource
end # module DataMapper
