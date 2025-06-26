# frozen_string_literal: true

require_relative '../operation'
require_relative 'resource'

module LedgerSync
  module Domains
    class Operation
      class Transition < Resource
        class Contract < LedgerSync::Ledgers::Contract
          params do
            required(:model_name).filled(:string)
            required(:id).filled(:integer)
            required(:event).value(:string)
            required(:attrs).maybe(%i[hash array])
            required(:limit).value(:hash)
          end
        end

        private

        def operate
          if resource.present?
            if run_guard && run_event
              success
            else
              failure('Unable to transition')
            end
          else
            failure('Not found')
          end
        end

        def run_guard
          resource.send(guard_method, params[:attrs])
        end

        def guard_method
          "may_#{params[:event]}?"
        end

        def run_event
          resource.send(event_method, params[:attrs])
        end

        def event_method
          "#{params[:event]}!"
        end

        def resource
          @resource ||= resource_class.where(params[:limit]).find_by(id: params[:id])
        end

        def resource_class
          @resource_class ||= Object.const_get(params[:model_name])
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
