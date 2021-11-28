# frozen_string_literal: true

require 'spec_helper'

class TestResource < LedgerSync::Resource
  attribute :name, type: LedgerSync::Type::String
  attribute :phone_number, type: LedgerSync::Type::String
  attribute :email, type: LedgerSync::Type::String
end

class TestOperation < LedgerSync::Domains::Operation::Find
  def resource
    return nil if params[:id].negative?

    @resource ||= TestResource.new(ledger_id: params[:id], name: 'Test')
  end
end

module TestResources
  class TestSerializer < LedgerSync::Domains::Serializer
    attribute :name
    attribute :phone_number
    attribute :email, if: :email_present?

    def email_present?(args = {})
      resource = args.fetch(:resource)

      resource.email.present?
    end
  end
end

RSpec.describe LedgerSync::Domains::Operation do
  describe 'operate' do
    context 'with nice ID' do
      let(:operation) { TestOperation.new(id: 1, limit: {}, domain: 'Test') }

      before {
        operation.perform
      }

      it 'succeeds' do
        expect(operation.success?).to eq(true)
        expect(operation.result.value.name).to eq('Test')
      end
    end

    context 'with bad ID' do
      let(:operation) { TestOperation.new(id: -1, limit: {}, domain: 'Test') }

      before {
        operation.perform
      }

      it 'fails' do
        expect(operation.success?).to eq(false)
      end
    end
  end
end
