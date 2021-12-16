# frozen_string_literal: true

require_relative '../operation'
require_relative 'resource'

module LedgerSync
  module Domains
    class Operation
      class Remove < Resource
        private

        def operate
          return failure('Resource not found') unless resource

          if resource.destroy
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
            true
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
