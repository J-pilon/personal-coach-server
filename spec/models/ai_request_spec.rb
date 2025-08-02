# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AiRequest, type: :model do
  let(:user) { create(:user) }
  let(:profile) { user.profile }
  let(:prompt) { 'Create a SMART goal to exercise more' }
  let(:job_type) { 'smart_goal' }

  describe 'associations' do
    it { is_expected.to belong_to(:profile) }
  end

  describe 'validations' do
    subject { build(:ai_request) }

    it { is_expected.to validate_presence_of(:prompt) }
    it { is_expected.to validate_presence_of(:job_type) }

    it 'validates job_type inclusion' do
      valid_types = %w[smart_goal prioritization]
      valid_types.each do |type|
        ai_request = build(:ai_request, job_type: type)
        expect(ai_request).to be_valid
      end

      ai_request = build(:ai_request, job_type: 'invalid_type')
      expect(ai_request).not_to be_valid
      expect(ai_request.errors[:job_type]).to include('is not included in the list')
    end
  end

  describe 'callbacks' do
    it 'generates hash_value before validation on create' do
      ai_request = build(:ai_request, prompt: prompt, hash_value: nil)
      ai_request.valid?

      expected_hash = Digest::SHA256.hexdigest(prompt)
      expect(ai_request.hash_value).to eq(expected_hash)
    end

    it 'does not regenerate hash_value on update' do
      ai_request = create(:ai_request, prompt: prompt)
      original_hash = ai_request.hash_value

      ai_request.update(prompt: 'Updated prompt')
      expect(ai_request.hash_value).to eq(original_hash)
    end
  end

  describe '.find_by_prompt_hash' do
    let!(:ai_request) { create(:ai_request, prompt: prompt) }

    it 'finds request by prompt hash' do
      hash_value = Digest::SHA256.hexdigest(prompt)
      found_request = described_class.find_by_prompt_hash(hash_value)

      expect(found_request).to eq(ai_request)
    end

    it 'returns nil when hash not found' do
      found_request = described_class.find_by_prompt_hash('nonexistent_hash')
      expect(found_request).to be_nil
    end
  end

  describe '.exists_with_prompt?' do
    let!(:ai_request) { create(:ai_request, prompt: prompt) }

    it 'returns true when prompt exists' do
      expect(described_class.exists_with_prompt?(prompt)).to be true
    end

    it 'returns false when prompt does not exist' do
      expect(described_class.exists_with_prompt?('Different prompt')).to be false
    end

    it 'returns false for blank prompt' do
      expect(described_class.exists_with_prompt?('')).to be false
      expect(described_class.exists_with_prompt?(nil)).to be false
    end
  end

  describe '.create_with_prompt' do
    it 'creates a new AI request with automatic hash generation' do
      expect do
        described_class.create_with_prompt(
          profile_id: profile.id,
          prompt: prompt,
          job_type: job_type
        )
      end.to change(described_class, :count).by(1)

      ai_request = described_class.last
      expect(ai_request.profile).to eq(profile)
      expect(ai_request.prompt).to eq(prompt)
      expect(ai_request.job_type).to eq(job_type)
      expect(ai_request.status).to eq('pending')
      expect(ai_request.hash_value).to eq(Digest::SHA256.hexdigest(prompt))
    end

    it 'creates a new AI request with custom status' do
      expect do
        described_class.create_with_prompt(
          profile_id: profile.id,
          prompt: prompt,
          job_type: job_type,
          status: 'completed'
        )
      end.to change(described_class, :count).by(1)

      ai_request = described_class.last
      expect(ai_request.status).to eq('completed')
    end

    it 'raises validation error for invalid job_type' do
      expect do
        described_class.create_with_prompt(
          profile_id: profile.id,
          prompt: prompt,
          job_type: 'invalid_type'
        )
      end.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  describe 'hash generation' do
    it 'generates consistent hash for same prompt' do
      hash1 = Digest::SHA256.hexdigest(prompt)
      hash2 = Digest::SHA256.hexdigest(prompt)
      expect(hash1).to eq(hash2)
    end

    it 'generates different hashes for different prompts' do
      prompt1 = 'Create a SMART goal to exercise'
      prompt2 = 'Create a SMART goal to exercise more'

      hash1 = Digest::SHA256.hexdigest(prompt1)
      hash2 = Digest::SHA256.hexdigest(prompt2)

      expect(hash1).not_to eq(hash2)
    end

    it 'handles special characters in prompt' do
      special_prompt = 'Create a goal with "quotes" & symbols!'
      ai_request = build(:ai_request, prompt: special_prompt)
      ai_request.valid?

      expected_hash = Digest::SHA256.hexdigest(special_prompt)
      expect(ai_request.hash_value).to eq(expected_hash)
    end
  end
end
