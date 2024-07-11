# frozen_string_literal: true

require 'ledger_sync'
require_relative 'domains/version'
require_relative 'domains/store'
require_relative 'domains/serializer'
require_relative 'domains/serializer/mixin'
require_relative 'domains/operation'
require_relative 'domains/operation/resource'
require_relative 'domains/operation/add'
require_relative 'domains/operation/find'
require_relative 'domains/operation/query'
require_relative 'domains/operation/remove'
require_relative 'domains/operation/search'
require_relative 'domains/operation/transition'
require_relative 'domains/operation/update'

module LedgerSync
  module Domains
    class InternalOperationError < LedgerSync::Error::OperationError; end

    class UnspecifiedError < LedgerSync::Error::OperationError
      attr_reader :error

      def initialize(operation:, error:)
        @error = error
        message = 'Operation failed with unraisable error. Please check your error.'
        super(message: message, operation: operation)
      end

      def inspect
        "#<#{self.class}: #{message} (errors: #{error.inspect})>"
      end
    end

    class ValidationError < LedgerSync::Error::OperationError
      attr_reader :errors

      def initialize(operation:, errors:)
        @errors = errors
        message = 'Operation arguments are invalid. Please check your errors.'
        super(message: message, operation: operation)
      end

      def inspect
        "#<#{self.class}: #{message} (errors: #{errors.inspect})>"
      end
    end

    class PerformedOperationError < LedgerSync::Error::OperationError
      def initialize(operation:)
        message = 'Operation has already been performed. Please check the result.'
        super(message: message, operation: operation)
      end
    end

    def self.domains
      @domains ||= LedgerSync::Domains::ConfigurationStore.new
    end

    def self.register_domain(*args, **params)
      config = LedgerSync::Domains::Configuration.new(*args, **params)
      yield(config) if block_given?

      domains.register_domain(config: config)
    end

    def self.register_main_domain
      config = LedgerSync::Domains::Configuration.new(:main, base_module: nil)
      config.name = 'Main'

      domains.register_domain(config: config)
    end
  end
end
