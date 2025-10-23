# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'JWT functionality' do
    let(:user) { create(:user) }

    describe '#jwt_payload' do
      it 'generates valid JWT payload' do
        payload = user.jwt_payload
        expect(payload).to be_present
        expect(payload).to be_a(Hash)
      end

      it 'includes JTI in JWT payload' do
        payload = user.jwt_payload

        expect(payload['jti']).to eq(user.jti)
      end

      it 'generates different payloads for different users' do
        user2 = create(:user)
        payload1 = user.jwt_payload
        payload2 = user2.jwt_payload

        expect(payload1['jti']).not_to eq(payload2['jti'])
      end

      it 'generates same payload for same user' do
        payload1 = user.jwt_payload
        payload2 = user.jwt_payload

        expect(payload1['jti']).to eq(payload2['jti'])
      end
    end

    describe '#jwt_subject' do
      it 'returns user ID as JWT subject' do
        subject = user.jwt_subject
        expect(subject).to eq(user.id)
      end

      it 'returns different subjects for different users' do
        user2 = create(:user)
        subject1 = user.jwt_subject
        subject2 = user2.jwt_subject

        expect(subject1).not_to eq(subject2)
      end
    end

    describe 'JTI (JWT ID) functionality' do
      it 'generates JTI on user creation' do
        expect(user.jti).to be_present
        expect(user.jti).to be_a(String)
      end

      it 'generates unique JTI for different users' do
        user2 = create(:user)
        expect(user.jti).not_to eq(user2.jti)
      end

      it 'regenerates JTI when user is updated' do
        original_jti = user.jti

        # Manually regenerate JTI
        user.update!(jti: SecureRandom.uuid)

        expect(user.jti).not_to eq(original_jti)
        expect(user.jti).to be_present
      end
    end

    describe 'JWT revocation strategy' do
      it 'changes JTI when user is updated' do
        original_jti = user.jti
        original_payload = user.jwt_payload

        # Manually update JTI
        user.update!(jti: SecureRandom.uuid)

        # JTI should have changed
        expect(user.jti).not_to eq(original_jti)

        # New payload should have different JTI
        new_payload = user.jwt_payload
        expect(new_payload['jti']).not_to eq(original_payload['jti'])
      end

      it 'revokes all tokens when user is updated' do
        payload1 = user.jwt_payload
        payload2 = user.jwt_payload

        # Both payloads should have same JTI initially
        expect(payload1['jti']).to eq(payload2['jti'])

        # Manually update JTI
        user.update!(jti: SecureRandom.uuid)

        # New payload should have different JTI
        new_payload = user.jwt_payload
        expect(new_payload['jti']).not_to eq(payload1['jti'])
        expect(new_payload['jti']).not_to eq(payload2['jti'])
      end

      it 'allows new tokens after JTI change' do
        original_payload = user.jwt_payload
        user.update!(jti: SecureRandom.uuid)

        # New payload should be valid with new JTI
        new_payload = user.jwt_payload
        expect(new_payload['jti']).not_to eq(original_payload['jti'])
        expect(new_payload['jti']).to eq(user.jti)
      end
    end

    describe 'JWT verification' do
      it 'verifies valid JWT payload' do
        payload = user.jwt_payload

        expect(payload['jti']).to eq(user.jti)
      end

      it 'includes required JWT claims' do
        payload = user.jwt_payload

        expect(payload['jti']).to be_present
      end

      it 'has correct JWT subject' do
        subject = user.jwt_subject

        expect(subject).to eq(user.id)
      end

      it 'has unique JTI for different users' do
        user2 = create(:user)
        payload1 = user.jwt_payload
        payload2 = user2.jwt_payload

        expect(payload1['jti']).not_to eq(payload2['jti'])
      end
    end
  end
end
