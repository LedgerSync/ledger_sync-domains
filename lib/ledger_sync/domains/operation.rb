# frozen_string_literal: true

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

      module Mixin
        module ClassMethods
          def inferred_resource_class
            name = to_s.split('::')
            name.pop # remove serializer/operation class from name
            resource = name.pop.singularize # pluralized resource module name

            const_get((name + [resource]).join('::'))
          end

          def inferred_serializer_class
            const_get("#{inferred_resource_class}Serializer")
          end

          def inferred_deserializer_class
            const_get("#{inferred_resource_class}Deserializer")
          end

          def inferred_validation_contract_class
            const_get('Contract')
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

        def initialize(serializer: nil, deserializer: nil, **params)
          @serializer = serializer
          @deserializer = deserializer
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
          serializer.serialize(resource: resource)
        end

        def deserializer
          @deserializer ||= deserializer_class.new
        end

        def deserializer_class
          @deserializer_class ||= self.class.inferred_deserializer_class
        end

        def serializer
          @serializer ||= serializer_class.new
        end

        def serializer_class
          @serializer_class ||= self.class.inferred_serializer_class
        end

        def resource_class
          @resource_class ||= self.class.inferred_resource_class
        end

        # Results

        def failure(error)
          @result = OperationResult.Failure(error)
        end

        def failure?
          result.failure?
        end

        def success(value, meta: nil)
          @result = OperationResult.Success(value, meta: meta)
        end

        def success?
          result.success?
        end

        def valid?
          validate.success?
        end

        def validate
          LedgerSync::Util::Validator.new(
            contract: validation_contract,
            data: params
          ).validate
        end

        def validation_contract
          @validation_contract ||= self.class.inferred_validation_contract_class
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
