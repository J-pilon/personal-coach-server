# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TestMailer, type: :mailer do
  describe '#ping' do
    let(:recipient) { 'qa@example.com' }
    let(:mail) { described_class.ping(recipient) }

    it 'addresses the supplied recipient' do
      expect(mail.to).to eq([recipient])
    end

    it 'uses the configured default From address' do
      expect(mail.from).to eq([Rails.application.config.action_mailer.default_options.fetch(:from)])
    end

    it 'uses the configured default Reply-To address' do
      expect(mail.reply_to).to eq([Rails.application.config.action_mailer.default_options.fetch(:reply_to)])
    end

    it 'includes the environment in the subject' do
      expect(mail.subject).to include(Rails.env)
    end

    it 'renders both text and html parts' do
      expect(mail.body.parts.map(&:content_type)).to include(
        a_string_starting_with('text/plain'),
        a_string_starting_with('text/html')
      )
    end
  end
end
