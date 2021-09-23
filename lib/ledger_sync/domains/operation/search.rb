# frozen_string_literal: true

require_relative '../operation'

module LedgerSync
  module Domains
    class Operation
      class Search
        include LedgerSync::Domains::Operation::Mixin

        # make kaminari work with serialized results
        class PaginatedResult < SimpleDelegator
          attr_accessor :next_page, :last_page, :current_page, :total_pages,
                        :limit_value, :total_count

          def self.from_result(result, items:)
            search = new(items)
            search.next_page = result.next_page
            search.last_page = result.last_page?
            search.current_page = result.current_page
            search.total_pages = result.total_pages
            search.total_count = result.total_count
            search.limit_value = result.limit_value
            search
          end

          def last_page?
            last_page == true
          end
        end

        class Contract < LedgerSync::Ledgers::Contract
          params do
            required(:query).value(:hash)
            required(:limit).value(:hash)
            required(:includes).value(:array)
            required(:order).value(:string)
            required(:page).value(:integer)
            required(:per).value(:integer)
          end
        end

        private

        def operate
          if resources
            success
          else
            failure('Not found')
          end
        end

        def resources # rubocop:disable Metrics/AbcSize
          @resources ||= resource_class.where(params[:limit])
                                       .where(params[:query])
                                       .includes(params[:includes])
                                       .order(params[:order])
                                       .page(params[:page])
                                       .per(params[:per])
        end

        def success
          super(
            PaginatedResult.from_result(
              resources,
              items: resources.map { |resource| serialize(resource: resource) }
            )
          )
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
