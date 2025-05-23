# frozen_string_literal: true

require 'ostruct'
require_relative 'query'

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
        def self.build(hash, serializer_name, resource:, references:) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
          klass = Class.new(SimpleDelegator) do
            def self.with_lazy_references(hash, struct_class:, resource:, references:) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
              define_method('valid?') { resource.valid? }
              define_method('errors') { resource.errors }
              define_method('to_hash') { hash }
              define_method('class_name') { resource.class.name }
              define_method('model_name') { resource.model_name }
              define_method('to_key') { resource.to_key }
              define_method('_resource') { resource }
              references.each do |args|
                if args.type.instance_of?(LedgerSync::Serialization::Type::SerializerReferencesOneType) # rubocop:disable Layout/LineLength
                  define_method("#{args.hash_attribute}_id") do
                    resource.send("#{args.hash_attribute}_id")
                  end
                end
                define_method(args.hash_attribute) do
                  Query.const_get(
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

            def to_model
              self
            end

            def to_json(*args)
              JSON.generate(to_hash, *args)
            end
          end

          name = serializer_name.split('::')
          class_name = name.pop.gsub(/[^0-9a-z ]/i, '').gsub(/.*\KSerializer/, '')
          struct_name = "#{class_name}Struct"
          module_name = name.empty? ? Object : Object.const_get(name.join('::'))
          begin
            v, $VERBOSE = $VERBOSE, v
            # module_name.remove_const(struct_name) if module_name.const_defined?(struct_name)
            module_name.const_set(struct_name, Class.new(OpenStruct))
          ensure
            $VERBOSE = v
          end
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
