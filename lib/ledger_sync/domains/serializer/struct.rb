# frozen_string_literal: true

require_relative 'relation'

module LedgerSync
  module Domains
    class Serializer < LedgerSync::Serializer
      class Struct
        # This is the most ruby hackery I ever did
        # Defining Record class that inherits from SimpleDelegator is not
        # enough. Adding methods through define_method was adding these methods
        # to all objects created through this main class. Specifically address
        # record has an attribute called address, which returned serialized
        # address. This is a same approach, but with dynamic class definition
        # to avoid defining methods in unrelated classes. We are using
        # SimpleDelegator to delegate these methods into OpenStruct passed in.
        # Pure hackery.
        def self.build(hash, serializer_name, resource:, references:)
          klass = Class.new(SimpleDelegator) do
            def self.with_lazy_references(hash, struct_class:, resource:, references:) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
              define_method('valid?') { resource.valid? }
              define_method('errors') { resource.errors }
              define_method('to_hash') { hash }
              references.each do |args|
                define_method(args.hash_attribute) do
                  Relation.const_get(
                    args.type.class.to_s.split('::').last
                  ).new.proxy(
                    serializer: args.type.serializer.new,
                    resource: resource,
                    attribute: args.resource_attribute
                  )
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

          name = serializer_name.split('::')
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
      end
    end
  end
end
