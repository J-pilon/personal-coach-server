# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UserMailer, type: :mailer do
  describe '#welcome' do
    let(:user) { create(:user, email: 'new-user@example.com') }
    let(:mail) { described_class.welcome(user) }

    it 'addresses the new user' do
      expect(mail.to).to eq([user.email])
    end

    it 'uses the configured default From address' do
      expect(mail.from).to eq([Rails.application.config.action_mailer.default_options.fetch(:from)])
    end

    it 'uses the configured default Reply-To address' do
      expect(mail.reply_to).to eq([Rails.application.config.action_mailer.default_options.fetch(:reply_to)])
    end

    it 'has a welcome subject' do
      expect(mail.subject).to eq('Welcome to Personal Coach')
    end

    it 'renders both text and html parts' do
      expect(mail.body.parts.map(&:content_type)).to include(
        a_string_starting_with('text/plain'),
        a_string_starting_with('text/html')
      )
    end

    it 'mentions the user email in both parts' do
      bodies = mail.body.parts.map { |p| p.body.to_s }
      expect(bodies).to all(include(user.email))
    end

    it 'mentions the next-step onboarding cue' do
      html = mail.body.parts.find { |p| p.content_type.start_with?('text/html') }.body.to_s
      expect(html).to match(/onboarding/i)
    end
  end
end
