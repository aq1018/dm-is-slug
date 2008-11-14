# Needed to import datamapper and other gems
require 'rubygems'
require 'pathname'

# Add all external dependencies for the plugin here
gem 'dm-core', '=0.9.6'
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

# Include DataMapper::Model#get and DataMapper::Collection#get override
# So we do user.posts.get("my-shinny-new-post")

module DataMapper
  module Model
    include DataMapper::Is::Slug::AliasMethods
  end
  
  class Collection
    include DataMapper::Is::Slug::AliasMethods
  end
  
end

