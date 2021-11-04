# frozen_string_literal: true

module LedgerSync
  module Domains
    class Serializer < LedgerSync::Serializer
      class Relation
        def initialize(serializer:, resource:, attribute:)
          @query = resource.try(attribute)
          @serializer = serializer
        end

        QUERY_METHODS = %w(
          distinct distinct! eager_load eager_load! extending extending!
          from from! group group! having having! includes includes!
          joins joins! left_outer_joins left_outer_joins!
          limit limit! offset offset! order order! preload preload!
          references references! unscope unscope! where where!
          load reload reset
        ) # lock lock!
        READER_METHODS = %w(
          fifth fifth! find find_by find_by! first first! forty_two forty_two!
          fourth fourth! last last! second second! second_to_last
          second_to_last! third third! third_to_last third_to_last!
        )
        READERS_METHODS = %w(find_each each map to_ary) # find_in_batches in_batches
        INSPECT_METHODS = %w(
          any? blank? empty? explain many? none? one? size to_sql exists? count
          ids maximum minimum sum none none! loaded?
        )

        def inspect(*args)
          entries = to_ary.take(11).map!(&:inspect)
    
          entries[10] = "..." if entries.size == 11
    
          "#<#{self.class.name} [#{entries.join(', ')}]>"
        end

        def as_json(*args)
          to_ary.map!(&:as_json)
        end

        QUERY_METHODS.each do |name|
          define_method(name) do |*args|
            @query = @query.send(name, *args)

            self
          end
        end

        READER_METHODS.each do |name|
          define_method(name) do |*args, **params, &block|
            item = @query.send(name, *args, **params, &block)

            @serializer.serialize(resource: item)
          end
        end

        READERS_METHODS.each do |name|
          define_method(name) do |*args, **params, &block|
            result = @query.send(name, *args, **params, &block)

            result.map do |item|
              @serializer.serialize(resource: item)
            end
          end
        end

        INSPECT_METHODS.each do |name|
          define_method(name) do |*args|
            @query.send(name, *args)
          end
        end

        class SerializerReferencesOneType
          def proxy(serializer:, resource:, attribute:)
            item = resource.try(attribute)

            serializer.serialize(resource: item)
            # Relation.new(
            #   serializer: serializer,
            #   resource: resource,
            #   attribute: attribute
            # )
          end
        end

        class SerializerReferencesManyType
          def proxy(serializer:, resource:, attribute:)
            Relation.new(
              serializer: serializer,
              resource: resource,
              attribute: attribute
            )
          end
        end
      end
    end
  end
end
