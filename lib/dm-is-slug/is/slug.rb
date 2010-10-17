require 'unidecode'
require 'dm-core'
require 'dm-core/support/chainable'

module DataMapper
  module Is
    module Slug
      def self.included(base)
        base.extend ClassMethods
      end

      class InvalidSlugSourceError < StandardError; end

      # @param [String] str A string to escape for use as a slug
      # @return [String] an URL-safe string
      def self.escape(str)
        s = str.to_ascii
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

      # Defines a +slug+ property on your model with the same length as your
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
      # +length+::
      #   The length of the +slug+ property
      #
      # @param [Hash] provide options in a Hash. See *Parameters* for details
      def is_slug(options)
        if options.key?(:size)
          warn "Slug with :size option is deprecated, use :length instead"
          options[:length] = options.delete(:size)
        end

        extend  DataMapper::Is::Slug::ClassMethods
        include DataMapper::Is::Slug::InstanceMethods
        extend Chainable

        @slug_options = {}

        @slug_options[:permanent_slug] = options.delete(:permanent_slug)
        @slug_options[:permanent_slug] = true if @slug_options[:permanent_slug].nil?

        @slug_options[:source] = options.delete(:source)
        raise InvalidSlugSourceError, 'You must specify a :source to generate slug.' unless slug_source


        options[:length] ||= get_slug_length
        property(:slug, String, options.merge(:unique => true)) unless slug_property

        before respond_to?(:valid?) ? :valid? : :save, :generate_slug
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
          p = properties[name]
          !p.nil? && DataMapper::Property::String >= p.class ? p : nil
        end

        def get_slug_length
          slug_property.nil? ? (slug_source_property.nil? ? DataMapper::Property::String::DEFAULT_LENGTH : slug_source_property.length) : slug_property.length
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

        def generate_slug
          #puts "\nGenerating slug for #{self.class.name}: #{self.key.inspect}\n"
          return unless self.class.respond_to?(:slug_options) && self.class.slug_options
          raise InvalidSlugSourceError, 'Invalid slug source.' unless slug_source_property || self.respond_to?(slug_source)
          return unless stale_slug?
          attribute_set :slug, unique_slug
        end

        def unique_slug
          old_slug = self.slug
          max_length = self.class.send(:get_slug_length)
          base_slug = ::DataMapper::Is::Slug.escape(slug_source_value)[0, max_length]
          i = 1
          new_slug = base_slug

          if old_slug != new_slug
            not_self_conditions = {}
            unless new?
              self.model.key.each do |property|
                not_self_conditions.merge!(property.name.not => self.send(property.name))
              end
              #puts "Not self: #{not_self_conditions.inspect}"
            end

            lambda do
              #puts "Lambda new slug: #{new_slug}"
              dupe = self.class.first(not_self_conditions.merge(:slug => new_slug))
              if dupe
                #puts "Got dupe: #{dupe.inspect}"
                i = i + 1
                slug_length = max_length - i.to_s.length - 1
                new_slug = "#{base_slug[0, slug_length]}-#{i}"
                #puts "New slug: #{new_slug}"
                redo
              end
            end.call
            puts "Found new slug '#{new_slug}' in #{i} attempts"
            new_slug
          else
            old_slug
          end
        end
      end # InstanceMethods

      Model.send(:include, self)
    end # Slug
  end # Is
end # DataMapper
