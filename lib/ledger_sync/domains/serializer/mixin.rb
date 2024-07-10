# frozen_string_literal: true

module LedgerSync
  module Domains
    class Serializer < LedgerSync::Serializer
      module Mixin
        module ClassMethods
          def serializer_module
            self
          end

          def domain_serializable(resource_attributes: nil, resource_references: [], resource_methods: []) # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity, Metrics/MethodLength, Layout/LineLength
            LedgerSync::Domains.domains.configs.each_value do |domain| # rubocop:disable Metrics/BlockLength
              parent_name = name.split('::')[..-1]
              module_name = parent_name.empty? ? Object : Object.const_get(parent_name.join('::'))
              next if module_name.const_defined?("#{domain.name}Serializer")

              default_attributes = new.attributes.map { |k, _| k.to_sym }

              klass = Class.new(LedgerSync::Domains::Serializer) do
                (resource_attributes || default_attributes).each { attribute _1 }
                resource_methods.each { attribute _1 }

                define_method :resource_references do
                  resource_references
                end

                def references_for(resource:) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
                  return [] unless resource.class.respond_to?(:reflect_on_all_associations)

                  resource_name = self.class.name.split('::')
                  domain_name = resource_name.pop.gsub(/[^0-9a-z ]/i, '').gsub(/.*\KSerializer/, '')

                  resource.class.reflect_on_all_associations.map do |association|
                    next unless resource_references.include?(association.name)
                    unless Object.const_defined?("#{association.klass.name}::#{domain_name}Serializer") # rubocop:disable Layout/LineLength
                      next
                    end

                    serializer = Object.const_get("#{association.klass.name}::#{domain_name}Serializer") # rubocop:disable Layout/LineLength

                    if association.belongs_to? || association.has_one?
                      LedgerSync::Serialization::SerializerAttribute.new(
                        hash_attribute: association.name,
                        resource_attribute: association.name,
                        type: Serialization::Type::SerializerReferencesOneType.new(
                          serializer: serializer
                        )
                      )
                    else
                      LedgerSync::Serialization::SerializerAttribute.new(
                        hash_attribute: association.name,
                        resource_attribute: association.name,
                        type: Serialization::Type::SerializerReferencesManyType.new(
                          serializer: serializer
                        )
                      )
                    end
                  end.compact
                end
              end

              module_name.const_set("#{domain.name}Serializer", klass)
            end
          end
        end

        def self.included(base)
          base.extend ClassMethods
        end
      end
    end
  end
end
