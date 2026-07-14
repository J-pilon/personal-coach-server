# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HabitCompletion, type: :model do
  include ActiveSupport::Testing::TimeHelpers

  describe 'associations' do
    it { is_expected.to belong_to(:habit) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:completed_on) }

    it 'rejects unknown state values' do
      completion = build(:habit_completion, state: 'bogus')
      expect(completion).not_to be_valid
      expect(completion.errors[:state]).to be_present
    end
  end

  describe 'uniqueness of (habit_id, completed_on)' do
    it 'rejects a duplicate on the same date' do
      completion = create(:habit_completion)

      expect do
        create(:habit_completion, habit: completion.habit, completed_on: completion.completed_on)
      end.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  describe '#transition_to!' do
    let(:completion) { create(:habit_completion) }

    it 'moves committed -> completed_minimum and stamps completed_at' do
      freeze_time do
        completion.transition_to!('completed_minimum')
        expect(completion.reload).to be_state_completed_minimum
        expect(completion.completed_at).to eq(Time.current)
      end
    end

    it 'moves committed -> completed_normal and stamps completed_at' do
      freeze_time do
        completion.transition_to!('completed_normal')
        expect(completion.reload).to be_state_completed_normal
        expect(completion.completed_at).to eq(Time.current)
      end
    end

    it 'moves committed -> skipped without stamping completed_at' do
      completion.transition_to!('skipped')
      expect(completion.reload).to be_state_skipped
      expect(completion.completed_at).to be_nil
    end

    it 'rejects a transition back to committed' do
      completion.transition_to!('completed_minimum')
      expect { completion.transition_to!('committed') }
        .to raise_error(HabitCompletion::InvalidTransitionError)
    end

    it 'rejects a transition from a terminal state' do
      completion.transition_to!('skipped')
      expect { completion.transition_to!('completed_normal') }
        .to raise_error(HabitCompletion::InvalidTransitionError)
    end

    it 'rejects unknown target states' do
      expect { completion.transition_to!('nowhere') }
        .to raise_error(HabitCompletion::InvalidTransitionError)
    end
  end
end
