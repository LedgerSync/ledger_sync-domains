# frozen_string_literal: true

# reopen AR module for non-rails apps
module ActiveRecord
  module Base; end
end

module LedgerSync
  module Domains
    class Operation
      class OperationResult
        module ResultTypeBase
          attr_reader :meta

          def self.included(base)
            base.class_eval do
              simply_serialize only: %i[meta]
            end
          end

          def initialize(*args, meta: nil)
            @meta = meta
            super(*args)
          end
        end

        include LedgerSync::ResultBase
      end

      module Mixin # rubocop:disable Metrics/ModuleLength
        def self.included(base)
          base.include SimplySerializable::Mixin
          base.include Fingerprintable::Mixin
          base.include LedgerSync::Error::HelpersMixin

          base.class_eval do
            simply_serialize only: %i[
              params
              result
            ]
          end
        end

        attr_reader :params, :result

        def initialize(domain:, **params)
          @domain = domain
          @params = params
          @result = nil
        end

        def perform # rubocop:disable Metrics/MethodLength
          if performed?
            return failure(
              LedgerSync::Error::OperationError::PerformedOperationError.new(
                operation: self
              )
            )
          end

          unless valid?
            failure(errors)
            return
          end

          @result = begin
            operate
          rescue LedgerSync::Error => e
            failure(e)
          rescue StandardError => e
            failure(e)
          ensure
            @performed = true
          end
        end

        def performed?
          @performed == true
        end

        def serialize(resource:)
          serializer_for(resource: resource).serialize(resource: resource)
        end

        def serializer_for(resource:)
          serializer_class_for(resource: resource).new
        end

        def serializer_class_for(resource:)
          Object.const_get(
            "#{resource.class.to_s.pluralize}::#{@domain.to_s.capitalize}Serializer"
          )
        end

        # Results

        def failure(error)
          @result = OperationResult.Failure(error)
        end

        def failure?
          result.failure?
        end

        def success(value, meta: nil)
          @result = OperationResult.Success(deep_serialize(value), meta: meta)
        end

        def deep_serialize(value)
          case value
          when ActiveRecord::Base, LedgerSync::Resource
            serialize(resource: value)
          when Hash
            value.transform_values { deep_serialize(_1) }
          when Array
            value.map { deep_serialize(_1) }
          else
            value
          end
        end

        def success?
          result.success?
        end

        def valid?
          validate.success?
        end

        def validate
          LedgerSync::Util::Validator.new(
            contract: validation_contract_class,
            data: params
          ).validate
        end

        def validation_contract_class
          @validation_contract_class ||= inferred_validation_contract_class
        end

        def inferred_validation_contract_class
          self.class.const_get('Contract')
        end

        def errors
          validate.validator.errors
        end

        # Comparison

        def ==(other)
          return false unless self.class == other.class
          return false unless params == other.params

          true
        end

        private

        def operate
          raise NotImplementedError, self.class.name
        end
      end
    end
  end
end
