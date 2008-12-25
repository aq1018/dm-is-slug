module DataMapper
  module Is
    module Slug
      
      # OPTIMIZE Kinda slow compared to a constant
      def self.default_slug_size
        50
      end
      
      # TODO Add Iconv escaping
      def self.escape(str)
        s = str.gsub(/\W+/, ' ')
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

      def is_slug(options)
        extend  DataMapper::Is::Slug::ClassMethods
        include DataMapper::Is::Slug::InstanceMethods
        
        # merge in default options
        options = { :permanent_slug => true }.merge(options)
        
        # must at least specify a source property to generate the slug
        raise 'You must specify a :source to generate slug' unless options.include?(:source)
        
        # make sure the source property exsists
        source_property = properties.detect{|p| p.name == options[:source].to_sym && p.type == String}
        # find the string length so that slug can adapt size dynamically depending on the source property
        options[:size] ||= source_property.size if source_property
        
        # if the source is not a property and no size is given, we use default
        options[:size] ||= DataMapper::Is::Slug.default_slug_size
        
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
          properties.detect{|p| p.name == slug_source && p.type == String}        
        end
        
        def slug_property
          properties.detect{|p| p.name == :slug && p.type == String}
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
                              
          # TODO Remove superfluous brackets
          return if (permanent_slug? && self.slug) || source.nil?
          
          # we turn the source into a slug here
          self.slug = DataMapper::Is::Slug.escape(source)
          
          # The rest of the code here is to ensure uniqueness of the slug. The 
          # methodology used sucks.

          # TODO clean up uniqueness code
          self.slug = "#{self.slug}-2" if self.class.first(:slug => self.slug)

          while(self.class.first(:slug => self.slug)!=nil)
            i = self.slug[-1..-1].to_i + 1
            self.slug = self.slug[0..-2]+i.to_s
          end
        end
      end # InstanceMethods
      
      module AliasMethods
        # override the old get method so that it looks for slugs first
        # and call the old get if slug is not found
        def get_with_slug(*key)
          if respond_to?(:slug_options) && slug_options && key[0].to_s.to_i.to_s != key[0].to_s
              return first(:slug => key[0])
          end
          get_without_slug(*key)
        end
        
        ##
        # fired when your plugin gets included into Resource
        #
        #--
        # TODO This stuff looks fishy and eerily similar to AMC
        def self.included(base)
          base.send :alias_method, :get_without_slug, :get
          base.send :alias_method, :get, :get_with_slug
        end
      end
      
    end # Slug
  end # Is
end # DataMapper
