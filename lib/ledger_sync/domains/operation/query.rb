# frozen_string_literal: true

require_relative '../operation'
require_relative 'resource'

module LedgerSync
  module Domains
    class Operation
      class Query < Resource
        class Contract < LedgerSync::Ledgers::Contract
          params do
            required(:query).value(:hash)
            required(:limit).value(:hash)
            required(:includes).value(:array)
            required(:order).value(:string)
          end
        end

        private

        def operate
          success(query)
        end

        def resources
          @resources ||= resource_class.where(params[:limit])
                                       .where(params[:query])
                                       .includes(params[:includes])
                                       .order(params[:order])
        end

        def query
          LedgerSync::Domains::Serializer::Query.new(
            serializer: params[:serializer] || serializer_for(resource: resource_class.new),
            query: resources
          )
        end
      end
    end
  end
end
