# frozen_string_literal: true

require_relative 'serializer/struct'

module LedgerSync
  module Domains
    class Serializer < LedgerSync::Serializer
      def attributes_for(*)
        self.class.attributes.values.select do |attr|
          !attr.references_many? && !attr.references_one?
        end
      end

      def references_for(*)
        self.class.attributes.values.select do |attr|
          attr.references_many? || attr.references_one?
        end
      end

      def serialize(args = {}) # rubocop:disable Metrics/MethodLength
        resource = args.fetch(:resource)
        ret = {}

        attributes_for(resource: resource).each do |serializer_attribute|
          ret = LedgerSync::Util::HashHelpers.deep_merge(
            hash_to_merge_into: ret,
            other_hash: serializer_attribute.hash_attribute_hash_for(resource: resource)
          )
        end
        Serializer::Struct.build(
          ret, self.class.to_s,
          resource: resource,
          references: references_for(resource: resource)
        )
      end
    end
  end
end
