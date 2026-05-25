# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SmartGoal, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:profile) }
    it { is_expected.to have_many(:tasks).dependent(:nullify) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_presence_of(:specific) }
    it { is_expected.to validate_presence_of(:measurable) }
    it { is_expected.to validate_presence_of(:achievable) }
    it { is_expected.to validate_presence_of(:relevant) }
    it { is_expected.to validate_presence_of(:time_bound) }
    it { is_expected.to validate_presence_of(:target_date) }
    it { is_expected.to validate_inclusion_of(:timeframe).in_array(%w[1_month 3_months 6_months]) }
  end
end
