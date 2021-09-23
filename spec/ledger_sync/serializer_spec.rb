# frozen_string_literal: true

require 'spec_helper'

RSpec.describe LedgerSync::Domains::Serializer do
  let(:custom_resource_class) do
    new_resource_class(
      attributes: %i[
        foo
        type
        name
        phone_number
        email
      ]
    )
  end

  let(:test_serializer_class) do
    Class.new(LedgerSync::Domains::Serializer) do
      attribute :name
      attribute :phone_number
      attribute :email, if: :email_present?

      def email_present?(args = {})
        resource = args.fetch(:resource)

        resource.email.present?
      end
    end
  end

  describe 'serialize' do
    context 'resource' do
      let(:resource) { custom_resource_class.new(name: 'Test', phone_number: '+1234567890', email: 'test@ledger_sync.dev') }

      it 'into OpenStruct' do
        serialized = test_serializer_class.new.serialize(resource: resource)

        expect(serialized.name).to eq('Test')
      end
    end

  end
end