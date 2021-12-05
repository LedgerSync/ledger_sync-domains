# frozen_string_literal: true

module LedgerSync
  module Domains
    class ConfigurationStore
      attr_reader :configs

      def initialize
        @configs = {}
      end

      def register_domain(config:)
        @configs[config.root_key] = config
      end

      def module_for(domain:)
        @configs[domain]&.base_module
      end

      def domain_for(base_module:)
        config = @configs.values.find { |c| c.base_module == base_module }
        config ||= @configs[:main]

        config.root_key
      end
    end

    class Configuration
      attr_accessor :name
      attr_reader :root_key, :base_module

      def initialize(root_key, base_module:)
        @root_key = root_key.to_sym
        @name = root_key.to_s.capitalize
        @base_module = base_module
      end
    end
  end
end
