# frozen_string_literal: true

require_relative 'serializer/struct'

module LedgerSync
  module Domains
    class Serializer < LedgerSync::Serializer
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
        Serializer::Struct.build(
          ret, self.class.to_s,
          resource: resource, references: references
        )
      end
    end
  end
end
