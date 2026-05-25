# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SmartGoals::Create do
  include ActiveSupport::Testing::TimeHelpers

  let(:profile) { create(:profile, timezone: 'America/Los_Angeles') }

  let(:valid_params) do
    {
      title: 'Learn React Native',
      description: 'Master React Native development',
      timeframe: '3_months',
      specific: 'Ship 3 RN apps',
      measurable: 'Three deployed apps',
      achievable: '2h/day',
      relevant: 'Career growth',
      time_bound: 'Three months',
      completed: false
    }
  end

  describe '.call' do
    context 'with valid params and timeframe 1_month' do
      let(:params) { valid_params.merge(timeframe: '1_month') }

      it 'persists the smart goal and returns a successful result' do
        travel_to Time.zone.local(2026, 5, 25, 14, 30, 0) do
          result = described_class.call(profile: profile, params: params)

          expect(result).to be_success
          expect(result.smart_goal).to be_persisted
          expect(result.errors).to be_empty
        end
      end

      it 'derives target_date as start-of-day in profile TZ + 1 month' do
        travel_to Time.zone.local(2026, 5, 25, 14, 30, 0) do
          result = described_class.call(profile: profile, params: params)

          expected = Time.current.in_time_zone('America/Los_Angeles').beginning_of_day + 1.month
          expect(result.smart_goal.target_date).to eq(expected)
        end
      end
    end

    context 'with timeframe 3_months' do
      it 'derives target_date 3 months ahead' do
        travel_to Time.zone.local(2026, 5, 25, 14, 30, 0) do
          result = described_class.call(profile: profile, params: valid_params)

          expected = Time.current.in_time_zone('America/Los_Angeles').beginning_of_day + 3.months
          expect(result.smart_goal.target_date).to eq(expected)
        end
      end
    end

    context 'with timeframe 6_months' do
      let(:params) { valid_params.merge(timeframe: '6_months') }

      it 'derives target_date 6 months ahead' do
        travel_to Time.zone.local(2026, 5, 25, 14, 30, 0) do
          result = described_class.call(profile: profile, params: params)

          expected = Time.current.in_time_zone('America/Los_Angeles').beginning_of_day + 6.months
          expect(result.smart_goal.target_date).to eq(expected)
        end
      end
    end

    context 'when the profile timezone is not UTC' do
      let(:profile) { create(:profile, timezone: 'Asia/Tokyo') }

      it 'anchors target_date to start-of-day in the profile timezone' do
        travel_to Time.zone.local(2026, 5, 25, 14, 30, 0) do
          result = described_class.call(profile: profile, params: valid_params)

          expected = Time.current.in_time_zone('Asia/Tokyo').beginning_of_day + 3.months
          expect(result.smart_goal.target_date).to eq(expected)
        end
      end
    end

    context 'when target_date is supplied by the caller' do
      let(:params) { valid_params.merge(target_date: 10.years.from_now) }

      it 'ignores the caller-supplied target_date and derives its own' do
        travel_to Time.zone.local(2026, 5, 25, 14, 30, 0) do
          result = described_class.call(profile: profile, params: params)

          expected = Time.current.in_time_zone('America/Los_Angeles').beginning_of_day + 3.months
          expect(result.smart_goal.target_date).to eq(expected)
        end
      end
    end

    context 'with an unknown timeframe' do
      let(:params) { valid_params.merge(timeframe: 'invalid_timeframe') }

      it 'returns an unsuccessful result with timeframe and target_date errors' do
        result = described_class.call(profile: profile, params: params)

        expect(result).not_to be_success
        expect(result.smart_goal).not_to be_persisted
        expect(result.errors).to include('Timeframe is not included in the list')
        expect(result.errors).to include("Target date can't be blank")
      end
    end

    context 'when a required field is missing' do
      let(:params) { valid_params.except(:specific) }

      it 'returns an unsuccessful result with the model error' do
        result = described_class.call(profile: profile, params: params)

        expect(result).not_to be_success
        expect(result.smart_goal).not_to be_persisted
        expect(result.errors).to include("Specific can't be blank")
      end
    end

    it 'associates the goal with the given profile' do
      result = described_class.call(profile: profile, params: valid_params)

      expect(result.smart_goal.profile).to eq(profile)
    end
  end
end
