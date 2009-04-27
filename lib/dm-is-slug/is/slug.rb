module DataMapper
  module Is
    module Slug
      class InvalidSlugSource < Exception
      end
      
      DEFAULT_SLUG_SIZE = 50
      
      DEFAULT_SLUG_OPTIONS = {
        :permanent_slug => true
      }
      
      # @param [String] str A string to escape for use as a slug
      # @return [String] an URL-safe string
      def self.escape(str)
        s = Iconv.conv('ascii//translit//IGNORE', 'utf-8', str)
        s.gsub!(/\W+/, ' ')
        s.strip!
        s.downcase!
        s.gsub!(/\ +/, '-')
        s
      end
      
      ##
      # Methods that should be included in DataMapper::Model.
      # Normally this should just be your generator, so that the namespace
      # does not get cluttered. ClassMethods and InstanceMethods gets added
      # in the specific resources when you fire is :slug
      ##

      # Defines a +slug+ property on your model with the same size as your 
      # source property. This property is Unicode escaped, and treated so as 
      # to be fit for use in URLs.
      #
      # ==== Example
      # Suppose your source attribute was the following string: "Hot deals on 
      # Boxing Day". This string would be escaped to "hot-deals-on-boxing-day".
      #
      # Non-ASCII characters are attempted to be converted to their nearest 
      # approximate.
      #
      # ==== Parameters
      # +permanent_slug+::
      #   Permanent slugs are not changed even if the source property has
      # +source+::
      #   The property on the model to use as the source of the generated slug,
      #   or an instance method defined in the model, the method must return
      #   a string or nil.
      # +size+::
      #   The length of the +slug+ property
      #
      # @param [Hash] provide options in a Hash. See *Parameters* for details
      def is_slug(options)
        extend  DataMapper::Is::Slug::ClassMethods
        include DataMapper::Is::Slug::InstanceMethods
        
        @slug_options = DEFAULT_SLUG_OPTIONS.merge(options)
        raise InvalidSlugSource('You must specify a :source to generate slug.') unless slug_source

        slug_options[:size] ||= get_slug_size
        property(:slug, String, :size => slug_options[:size], :unique => true) unless slug_property
        before :save, :generate_slug
      end

      module ClassMethods
        attr_reader :slug_options
        
        def permanent_slug?
          slug_options[:permanent_slug]
        end
        
        def slug_source
          slug_options[:source] ? slug_options[:source].to_sym : nil
        end
        
        def slug_source_property
          detect_slug_property_by_name(slug_source)
        end
        
        def slug_property
          detect_slug_property_by_name(:slug)
        end

        private

        def detect_slug_property_by_name(name)
          properties.detect do |p|
            p.name == name && p.type == String
          end
        end
        
        def get_slug_size
          slug_source_property && slug_source_property.size || DataMapper::Is::Slug::DEFAULT_SLUG_SIZE
        end
      end # ClassMethods

      module InstanceMethods
        def to_param
          [slug]
        end
        
        def permanent_slug?
          self.class.permanent_slug?
        end
        
        def slug_source
          self.class.slug_source
        end
        
        def slug_source_property
          self.class.slug_source_property
        end
        
        def slug_property
          self.class.slug_property
        end
        
        def slug_source_value
          self.send(slug_source)
        end
        
        # The slug is not stale if 
        # 1. the slug is permanent, and slug column has something valid in it
        # 2. the slug source value is nil or empty
        def stale_slug?
          !((permanent_slug? && slug && !slug.empty?) || (slug_source_value.nil? || slug_source_value.empty?))
        end
        
        private
                
        def make_unique_slug!
          base_slug = DataMapper::Is::Slug.escape(slug_source_value)
          i = 1
          unique_slug = base_slug

          while (self.class.first(:slug => unique_slug))
            i = i + 1
            unique_slug = "#{base_slug}-#{i}"
          end
          unique_slug
        end
        
        def generate_slug
          raise InvalidSlugSource('Invalid slug source.') unless slug_source_property || self.respond_to?(slug_source)
          return unless stale_slug?
          self.slug = make_unique_slug!
        end
      end # InstanceMethods
      
      module AliasMethods
        # override the old get method so that it looks for slugs first
        # and call the old get if slug is not found
        def get_with_slug(*key)
          if respond_to?(:slug_options) && slug_options && key[0].to_s.to_i.to_s != key[0].to_s
            first(:slug => key[0])
          else
            get_without_slug(*key)
          end
        end
        
        ##
        # fired when your plugin gets included into Resource
        def self.included(base)
          base.send :alias_method, :get_without_slug, :get
          base.send :alias_method, :get, :get_with_slug
        end
      end
    end # Slug
  end # Is
end # DataMapper
