# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Habit, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:profile) }
    it { is_expected.to belong_to(:smart_goal) }
    it { is_expected.to have_many(:habit_completions).dependent(:destroy) }
  end

  describe 'validations' do
    subject { build(:habit) }

    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_presence_of(:cue) }
    it { is_expected.to validate_presence_of(:minimum_version) }
    it { is_expected.to validate_presence_of(:normal_version) }
    it { is_expected.to validate_inclusion_of(:position).in_range(1..3) }

    it 'rejects unknown frequency values' do
      habit = build(:habit, frequency: 'bogus')
      expect(habit).not_to be_valid
      expect(habit.errors[:frequency]).to be_present
    end
  end

  describe '.active' do
    it 'excludes archived habits' do
      active = create(:habit, position: 1)
      create(:habit, :archived, position: 2, smart_goal: active.smart_goal)

      expect(described_class.active).to contain_exactly(active)
    end
  end

  describe 'partial unique index on (smart_goal_id, position)' do
    it 'allows the same position when the earlier row is archived' do
      goal = create(:smart_goal)
      create(:habit, :archived, smart_goal: goal, profile: goal.profile, position: 1)

      expect {
        create(:habit, smart_goal: goal, profile: goal.profile, position: 1)
      }.not_to raise_error
    end

    it 'rejects two active habits sharing a position within a goal' do
      goal = create(:smart_goal)
      create(:habit, smart_goal: goal, profile: goal.profile, position: 1)

      expect {
        create(:habit, smart_goal: goal, profile: goal.profile, position: 1)
      }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end
end
