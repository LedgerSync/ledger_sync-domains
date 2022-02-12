# frozen_string_literal: true

require_relative '../operation'
require_relative 'resource'

module LedgerSync
  module Domains
    class Operation
      class Update < Resource
        class Contract < LedgerSync::Ledgers::Contract
          params do
            required(:id).filled(:integer)
            required(:limit).value(:hash)
          end
        end

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
          @resource ||= resource_class.where(params[:limit]).find_by(id: params[:id])
        end

        def success
          super(resource)
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
