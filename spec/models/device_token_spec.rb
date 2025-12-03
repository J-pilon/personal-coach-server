# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DeviceToken, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:profile) }
  end

  describe 'validations' do
    subject { create(:device_token) }

    it { is_expected.to validate_presence_of(:token) }
    it { is_expected.to validate_uniqueness_of(:token).scoped_to(:profile_id) }
    it { is_expected.to validate_presence_of(:platform) }
    it { is_expected.to validate_inclusion_of(:platform).in_array(DeviceToken::PLATFORMS) }
  end

  describe 'scopes' do
    let(:profile) { create(:profile) }
    let!(:active_ios) { create(:device_token, profile: profile, platform: 'ios', active: true) }
    let!(:active_android) { create(:device_token, profile: profile, platform: 'android', active: true) }
    let!(:inactive_android) { create(:device_token, :inactive, profile: profile, platform: 'android') }
    let!(:web_token) { create(:device_token, :web, profile: profile) }

    describe '.active' do
      it 'returns only active tokens' do
        expect(described_class.active).to contain_exactly(active_ios, active_android, web_token)
      end
    end

    describe '.for_platform' do
      it 'returns tokens for specified platform' do
        expect(described_class.for_platform('ios')).to contain_exactly(active_ios)
      end
    end

    describe '.push_capable' do
      it 'returns only ios and android tokens' do
        expect(described_class.push_capable).to contain_exactly(active_ios, active_android, inactive_android)
      end
    end
  end

  describe '#expo_token?' do
    it 'returns true for Expo push tokens' do
      token = build(:device_token, token: 'ExponentPushToken[abc123]')
      expect(token.expo_token?).to be true
    end

    it 'returns false for non-Expo tokens' do
      token = build(:device_token, token: 'fcm_token_123')
      expect(token.expo_token?).to be false
    end
  end

  describe '#web_push?' do
    it 'returns true for web platform with endpoint' do
      token = build(:device_token, :web)
      expect(token.web_push?).to be true
    end

    it 'returns false for non-web platform' do
      token = build(:device_token, platform: 'ios')
      expect(token.web_push?).to be false
    end
  end

  describe '#deactivate!' do
    it 'sets active to false' do
      token = create(:device_token, active: true)
      token.deactivate!
      expect(token.reload.active).to be false
    end
  end
end
