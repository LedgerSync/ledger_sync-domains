# frozen_string_literal: true

require 'ledger_sync'
require_relative 'domains/version'
require_relative 'domains/serializer'
require_relative 'domains/operation'
require_relative 'domains/operation/add'
require_relative 'domains/operation/find'
require_relative 'domains/operation/remove'
require_relative 'domains/operation/search'
require_relative 'domains/operation/transition'
require_relative 'domains/operation/update'

module LedgerSync
  module Domains; end
end
