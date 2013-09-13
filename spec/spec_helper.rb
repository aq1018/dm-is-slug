require 'rubygems'

require 'coveralls'
Coveralls.wear!

require 'dm-core/spec/setup'
require 'dm-core/spec/lib/adapter_helpers'

require 'dm-is-slug'
require 'dm-migrations'

# dm-core 1.0.2 does not allow configuration of spec db settings.
# This monkey patch is ripped from dm-core master branch.
# https://github.com/datamapper/dm-core/blob/master/lib/dm-core/spec/setup.rb#L134
class DataMapper::Spec::Adapters::Adapter
  def username
    ENV.fetch('DM_DB_USER', 'datamapper')
  end

  def password
    ENV.fetch('DM_DB_PASSWORD', 'datamapper')
  end

  def host
    ENV.fetch('DM_DB_HOST', 'localhost')
  end
end

DataMapper::Spec.setup!

Spec::Runner.configure do |config|
  config.extend(DataMapper::Spec::Adapters::Helpers)
end
