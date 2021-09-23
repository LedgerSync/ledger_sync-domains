# frozen_string_literal: true

require_relative '../operation'

module LedgerSync
  module Domains
    class Operation
      class Update
        include LedgerSync::Domains::Operation::Mixin

        private

        def operate
          return failure('Resource not found') unless resource

          if resource.update(params.except(:id))
            success
          else
            failure(
              'Please review the problems below:',
              data: serialize(resource: resource)
            )
          end
        end

        def resource
          @resource ||= resource_class.find_by(id: params[:id])
        end

        def success
          super(
            serialize(resource: resource)
          )
        end

        def failure(message, data: nil)
          super(
              LedgerSync::Error::OperationError.new(
                operation: self,
                message: message,
                response: data
              )
          )
        end
      end
    end
  end
end
