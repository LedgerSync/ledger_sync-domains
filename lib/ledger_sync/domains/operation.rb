# frozen_string_literal: true

unless Object.const_defined?('ActiveRecord')
  # reopen AR module for non-rails apps
  module ActiveRecord
    module Base; end
  end
end

module LedgerSync
  module Domains
    class InternalOperationError < LedgerSync::Error::OperationError; end

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
        module ClassMethods
          @internal = false

          def internal
            @internal = true
          end

          def internal?
            !!@internal
          end
        end

        def self.included(base)
          base.include SimplySerializable::Mixin
          base.include Fingerprintable::Mixin
          base.include LedgerSync::Error::HelpersMixin
          base.extend ClassMethods

          base.class_eval do
            simply_serialize only: %i[
              params
              result
            ]
          end
        end

        attr_reader :params, :result

        def initialize(domain: nil, serializer: nil, **params)
          @domain = domain
          @serializer = serializer
          @params = params
          @result = nil
        end

        def perform # rubocop:disable Metrics/MethodLength
          unless allowed?
            return failure(
              LedgerSync::Domains::InternalOperationError.new(
                operation: self,
                message: 'Cross-domain operation execution is not allowed'
              )
            )
          end

          if performed?
            return failure(
              LedgerSync::Error::OperationError::PerformedOperationError.new(
                operation: self
              )
            )
          end

          return failure(errors) unless valid?

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

        def allowed?
          return true unless self.class.internal?

          local_domain == @domain
        end

        def performed?
          @performed == true
        end

        def serialize(resource:)
          serializer = serializer_for(resource: resource)
          return resource unless serializer

          serializer_for(resource: resource).new.serialize(resource: resource)
        end

        def serializer_for(resource:)
          @serializer || serializer_class_for(resource: resource)
        end

        def serializer_class_for(resource:)
          name = [
            serializer_module_for(resource: resource),
            "#{domain}Serializer"
          ].join('::')

          return unless Object.const_defined?(name)

          Object.const_get(name)
        end

        def serializer_module_for(resource:)
          (
            resource.class.try(:serializer_module) || resource.class.name.pluralize
          )
        end

        def domain
          LedgerSync::Domains.domains.module_for(domain: @domain)
        end

        def local_domain
          LedgerSync::Domains.domains.domain_for(
            base_module: self.class.to_s.split('::').first.constantize
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
          when ActiveRecord::Base # , LedgerSync::Resource
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
