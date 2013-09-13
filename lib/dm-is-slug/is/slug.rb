require 'unidecoder'
require 'dm-core'
require 'dm-core/support/chainable'
require 'dm-validations'

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

        if options.has_key? :scope
          @slug_options[:scope] = [options.delete(:scope)].flatten
        end

        @slug_options[:unique] = options.delete(:unique) || false

        @slug_options[:source] = options.delete(:source)
        raise InvalidSlugSourceError, 'You must specify a :source to generate slug.' unless slug_source


        options[:length] ||= get_slug_length
        if slug_property && slug_property.class >= DataMapper::Property::String
            options.merge! slug_property.options
        end
        property :slug, String, options

        if @slug_options[:unique]
          scope_options = @slug_options[:scope] && @slug_options[:scope].any? ?
            {:scope => @slug_options[:scope]} : {}

          validates_uniqueness_of :slug, scope_options
        end

        before :valid?, :generate_slug
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
        # 3. scope is not changed
        def stale_slug?
          !(
            (permanent_slug? && !slug.blank?) ||
            slug_source_value.blank?
          ) ||
          !(!new? && (dirty_attributes.keys.map(&:name) &
                      (self.class.slug_options[:scope] || [])).compact.blank?
          )
        end

        private

        def generate_slug
          return unless self.class.respond_to?(:slug_options) && self.class.slug_options
          raise InvalidSlugSourceError, 'Invalid slug source.' unless slug_source_property || self.respond_to?(slug_source)
          return unless stale_slug?
          attribute_set :slug, unique_slug
        end

        def unique_slug
          max_length = self.class.send(:get_slug_length)
          base_slug = ::DataMapper::Is::Slug.escape(slug_source_value)[0, max_length]
          # Assuming that 5 digits is more than enought
          index_length = 5
          new_slug = base_slug

          variations = max_length - base_slug.length - 1

          slugs = if variations > index_length + 1
            [base_slug]
          else
            ((variations - 1)..index_length).map do |n|
              base_slug[0, max_length - n - 1]
            end.uniq
          end

          not_self_conditions = {}
          unless new?
            self.model.key.each do |property|
              not_self_conditions.merge!(property.name.not => self.send(property.name))
            end
          end

          scope_conditions = {}
          if self.class.slug_options[:scope]
            self.class.slug_options[:scope].each do |subject|
              scope_conditions[subject] = self.__send__(subject)
            end
          end

          max_index = slugs.map do |s|
            self.class.all(not_self_conditions.merge(scope_conditions).merge :slug.like => "#{s}-%")
          end.flatten.map do |r|
            index = r.slug.gsub /^(#{slugs.join '|'})-/, ''
            index =~ /\d+/ ? index.to_i : nil
          end.compact.max

          new_index = if max_index.nil?
            self.class.first(not_self_conditions.merge(scope_conditions).merge :slug => base_slug).blank? ? 1 : 2
          else
            max_index + 1
          end

          if new_index > 1
            slug_length = max_length - new_index.to_s.length - 1
            new_slug = "#{base_slug[0, slug_length]}-#{new_index}"
          end

          new_slug
        end
      end # InstanceMethods

      Model.send(:include, self)
    end # Slug
  end # Is
end # DataMapper
