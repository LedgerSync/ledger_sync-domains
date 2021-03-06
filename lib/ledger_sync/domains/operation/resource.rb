# frozen_string_literal: true

module LedgerSync
  module Domains
    class Operation
      class Resource
        include LedgerSync::Domains::Operation::Mixin

        def resource_class
          @resource_class ||= inferred_resource_class
        end

        def validation_error_message
          errors.messages.map do |e|
            "#{e.path.first.to_s.gsub('_', ' ').capitalize} #{e.text}"
          end.to_sentence
        end

        private

        def inferred_resource_class
          name = self.class.to_s.split('::')
          name.pop # remove serializer/operation class from name
          resource = name.pop.singularize # pluralized resource module name

          self.class.const_get((name + [resource]).join('::'))
        end
      end
    end
  end
end
