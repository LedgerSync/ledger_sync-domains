# frozen_string_literal: true

module LedgerSync
  module Domains
    class Serializer < LedgerSync::Serializer
      def create_record_from(hash, resource:, references:) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
        # This is the most ruby hackery I ever did
        # Defining Record class that inherits from SimpleDelegator is not
        # enough. Adding methods through define_method was adding these methods
        # to all objects created through this main class. Specifically address
        # record has an attribute called address, which returned serialized
        # address. This is a same approach, but with dynamic class definition
        # to avoid defining methods in unrelated classes. We are using
        # SimpleDelegator to delegate these methods into OpenStruct passed in.
        # Pure hackery.
        klass = Class.new(SimpleDelegator) do
          def self.with_lazy_references(hash, struct_class:, resource:, references:) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
            define_method('valid?') { resource.valid? }
            define_method('errors') { resource.errors }
            define_method('to_hash') { hash }
            references.each do |args|
              define_method(args.hash_attribute) do
                if args.references_many?
                  resource.try(args.resource_attribute).each do |item|
                    args.type.serializer.new.serialize(resource: item)
                  end
                else
                  item = resource.try(args.resource_attribute)
                  next if item.nil?

                  args.type.serializer.new.serialize(resource: item)
                end
              end
            end

            new(struct_class.new(hash))
          end

          def to_param
            id.to_s
          end

          def persisted?
            id.present?
          end

          def to_json(*args)
            JSON.generate(to_hash, *args)
          end
        end

        name = self.class.to_s.split('::')
        class_name = name.pop.gsub(/[^0-9a-z ]/i, '').gsub(/.*\KSerializer/, '')
        struct_name = "#{class_name}Struct"
        module_name = name.empty? ? Object : Object.const_get(name.join('::'))
        module_name.const_set(struct_name, Class.new(OpenStruct))

        klass.with_lazy_references(
          hash,
          struct_class: module_name.const_get(struct_name),
          resource: resource, references: references
        )
      end

      def self.references
        @references ||= []
      end

      def self.split_attributes
        regular = []
        references = []

        attributes.each_value do |attr|
          if attr.references_many? || attr.references_one?
            references.push(attr)
          else
            regular.push(attr)
          end
        end
        [regular, references]
      end

      def serialize(args = {}) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
        only_changes = args.fetch(:only_changes, false)
        resource     = args.fetch(:resource)

        ret = {}

        regular, references = self.class.split_attributes
        regular.each do |serializer_attribute|
          if (only_changes && !resource.attribute_changed?(serializer_attribute.resource_attribute)) || # rubocop:disable Layout/LineLength
             (serializer_attribute.if_method.present? && !send(serializer_attribute.if_method, resource: resource)) # rubocop:disable Layout/LineLength
            next
          end

          ret = LedgerSync::Util::HashHelpers.deep_merge(
            hash_to_merge_into: ret,
            other_hash: serializer_attribute.hash_attribute_hash_for(resource: resource)
          )
        end
        create_record_from(ret, resource: resource, references: references)
      end
    end
  end
end
