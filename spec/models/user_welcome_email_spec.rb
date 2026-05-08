# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'welcome email on signup' do
    let(:attrs) do
      {
        email: Faker::Internet.unique.email,
        password: 'password123',
        password_confirmation: 'password123'
      }
    end

    around do |example|
      original = Rails.configuration.x.welcome_email.enabled
      example.run
    ensure
      Rails.configuration.x.welcome_email.enabled = original
    end

    context 'when welcome email is enabled' do
      before { Rails.configuration.x.welcome_email.enabled = true }

      it 'enqueues UserMailer.welcome after commit on create' do
        expect { described_class.create!(attrs) }
          .to have_enqueued_mail(UserMailer, :welcome)
      end

      it 'does not enqueue on update' do
        user = described_class.create!(attrs)
        expect { user.update!(email: Faker::Internet.unique.email) }
          .not_to have_enqueued_mail(UserMailer, :welcome)
      end

      it 'does not enqueue when validation fails' do
        expect { described_class.create(attrs.merge(email: nil)) }
          .not_to have_enqueued_mail(UserMailer, :welcome)
      end
    end

    context 'when welcome email is disabled' do
      before { Rails.configuration.x.welcome_email.enabled = false }

      it 'does not enqueue any mail' do
        expect { described_class.create!(attrs) }
          .not_to have_enqueued_mail(UserMailer, :welcome)
      end
    end
  end
end
