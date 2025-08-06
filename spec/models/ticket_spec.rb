require 'rails_helper'

RSpec.describe Ticket, type: :model do
  let(:profile) { create(:profile) }

  describe 'validations' do
    it 'is valid with valid attributes' do
      ticket = build(:ticket, profile: profile)
      expect(ticket).to be_valid
    end

    it 'is invalid without a title' do
      ticket = build(:ticket, profile: profile, title: nil)
      expect(ticket).not_to be_valid
      expect(ticket.errors[:title]).to include("can't be blank")
    end

    it 'is invalid without a description' do
      ticket = build(:ticket, profile: profile, description: nil)
      expect(ticket).not_to be_valid
      expect(ticket.errors[:description]).to include("can't be blank")
    end

    it 'is invalid with a title longer than 255 characters' do
      ticket = build(:ticket, profile: profile, title: 'a' * 256)
      expect(ticket).not_to be_valid
      expect(ticket.errors[:title]).to include('is too long (maximum is 255 characters)')
    end

    it 'is invalid with a description shorter than 10 characters' do
      ticket = build(:ticket, profile: profile, description: 'short')
      expect(ticket).not_to be_valid
      expect(ticket.errors[:description]).to include('is too short (minimum is 10 characters)')
    end

    it 'is invalid without a kind' do
      ticket = build(:ticket, profile: profile, kind: nil)
      expect(ticket).not_to be_valid
      expect(ticket.errors[:kind]).to include("can't be blank")
    end

    it 'is invalid with an invalid kind' do
      ticket = build(:ticket, profile: profile, kind: 'invalid')
      expect(ticket).not_to be_valid
      expect(ticket.errors[:kind]).to include('is not included in the list')
    end

    it 'is valid with bug kind' do
      ticket = build(:ticket, profile: profile, kind: 'bug')
      expect(ticket).to be_valid
    end

    it 'is valid with feedback kind' do
      ticket = build(:ticket, profile: profile, kind: 'feedback')
      expect(ticket).to be_valid
    end

    it 'is invalid without a source' do
      ticket = build(:ticket, profile: profile, source: nil)
      expect(ticket).not_to be_valid
      expect(ticket.errors[:source]).to include("can't be blank")
    end

    it 'is invalid with an invalid source' do
      ticket = build(:ticket, profile: profile, source: 'invalid')
      expect(ticket).not_to be_valid
      expect(ticket.errors[:source]).to include('is not included in the list')
    end

    it 'is valid with app source' do
      ticket = build(:ticket, profile: profile, source: 'app')
      expect(ticket).to be_valid
    end

    it 'is valid with web source' do
      ticket = build(:ticket, profile: profile, source: 'web')
      expect(ticket).to be_valid
    end

    it 'is valid with api source' do
      ticket = build(:ticket, profile: profile, source: 'api')
      expect(ticket).to be_valid
    end
  end

  describe 'associations' do
    it 'belongs to a profile' do
      ticket = build(:ticket, profile: profile)
      expect(ticket.profile).to eq(profile)
    end
  end

  describe 'scopes' do
    let!(:oldest_ticket) { create(:ticket, profile: profile, created_at: 3.days.ago) }
    let!(:middle_ticket) { create(:ticket, profile: profile, created_at: 2.days.ago) }
    let!(:newest_ticket) { create(:ticket, profile: profile, created_at: 1.day.ago) }

    it 'orders by created_at desc for recent scope' do
      expect(described_class.recent).to eq([newest_ticket, middle_ticket, oldest_ticket])
    end

    it 'filters by kind for by_kind scope' do
      expect(described_class.by_kind('bug')).to include(oldest_ticket, middle_ticket, newest_ticket)
    end
  end

  describe '.create_with_diagnostics' do
    let(:diagnostics) do
      {
        app_version: '1.0.0',
        device_model: 'iPhone 14',
        os_version: '17.0',
        locale: 'en',
        timezone: 'America/New_York',
        network_state: 'online',
        user_id: '123'
      }
    end

    let(:ticket_attributes) do
      {
        profile: profile,
        kind: 'bug',
        title: 'Test Bug',
        description: 'Test Description',
        source: 'app'
      }
    end

    it 'creates a ticket with diagnostics metadata' do
      ticket = described_class.create_with_diagnostics(ticket_attributes, diagnostics)

      expect(ticket).to be_persisted
      expect(ticket.metadata['app_version']).to eq('1.0.0')
      expect(ticket.metadata['device_model']).to eq('iPhone 14')
      expect(ticket.metadata['os_version']).to eq('17.0')
      expect(ticket.metadata['locale']).to eq('en')
      expect(ticket.metadata['timezone']).to eq('America/New_York')
      expect(ticket.metadata['network_state']).to eq('online')
      expect(ticket.metadata['user_id']).to eq('123')
      expect(ticket.metadata['timestamp']).to be_present
    end
  end
end
