# frozen_string_literal: true

require 'ledger_sync'
require_relative 'domains/version'
require_relative 'domains/store'
require_relative 'domains/serializer'
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
