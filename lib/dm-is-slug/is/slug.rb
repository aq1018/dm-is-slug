module DataMapper
  module Is
    module Slug
      DEFAULT_SLUG_SIZE = 50
      
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
      #   The property on the model to use as the source of the generated slug
      # +size+::
      #   The length of the +slug+ property
      #
      # @param [Hash] provide options in a Hash. See *Parameters* for details
      def is_slug(options)
        extend  DataMapper::Is::Slug::ClassMethods
        include DataMapper::Is::Slug::InstanceMethods
        
        # merge in default options
        options = { :permanent_slug => true }.merge(options)
        
        # must at least specify a source property to generate the slug
#        raise 'You must specify a :source to generate slug' unless options.include?(:source)
        raise 'You must specify a :source to generate slug' unless options[:source]
        
        # make sure the source property exsists
        source_property = properties.detect do |p|
          p.name == options[:source].to_sym && p.type == String
        end

        # Find the string length so that slug can adapt size dynamically 
        # depending on the source property, or use the default slug size.
        options[:size] ||= source_property &&
                             source_property.size ||
                             DataMapper::Is::Slug::DEFAULT_SLUG_SIZE
        
        # save as class variable for later...
        @slug_options = options
        
        unless slug_property
          property :slug, String, :size => options[:size], :unique => true
        end
         
        before :save, :generate_slug
      end

      module ClassMethods
        attr_reader :slug_options
        
        def permanent_slug?
          slug_options[:permanent_slug]
        end
        
        def slug_source
          slug_options[:source].to_sym
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
        
        def generate_slug
          source = self.send(slug_source)
          
          raise ':source is invalid!' unless slug_source_property || self.respond_to?(slug_source)
                              
          return if permanent_slug? && self.slug || source.nil?
          
          # we turn the source into a slug here
          self.slug = DataMapper::Is::Slug.escape(source)
          
          # The rest of the code here is to ensure uniqueness of the slug. The 
          # methodology used sucks.

          self.slug = "#{self.slug}-2" if self.class.first(:slug => self.slug)

          while self.class.first(:slug => self.slug) != nil
            i = self.slug[-1..-1].to_i + 1
            self.slug = self.slug[0..-2] + i.to_s
          end
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
