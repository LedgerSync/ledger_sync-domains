# frozen_string_literal: true

require_relative '../operation'
require_relative 'resource'

module LedgerSync
  module Domains
    class Operation
      class Find < Resource
        class Contract < LedgerSync::Ledgers::Contract
          params do
            required(:id).filled(:integer)
            required(:limit).value(:hash)
          end
        end

        private

        def operate
          if resource
            success
          else
            failure('Not found')
          end
        end

        def resource
          @resource ||= resource_class.where(params[:limit]).find_by(id: params[:id])
        end

        def success
          super(resource)
        end

        def failure(message)
          super(
            LedgerSync::Error::OperationError.new(
              operation: self,
              message: message
            )
          )
        end
      end
    end
  end
end
