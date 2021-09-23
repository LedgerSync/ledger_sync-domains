# frozen_string_literal: true

require "ledger_sync/domains"
require 'ledger_sync/test/support'

support :resource_helpers
support :factory_bot

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
