# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Ai::IntentRouter do
  describe '#route' do
    context 'when input contains goal keywords' do
      it 'routes to smart_goal intent' do
        router = described_class.new('I want to create a goal to lose weight')
        expect(router.route).to eq(:smart_goal)
      end

      it 'routes to smart_goal intent with objective keyword' do
        router = described_class.new('My objective is to learn Spanish')
        expect(router.route).to eq(:smart_goal)
      end

      it 'routes to smart_goal intent with target keyword' do
        router = described_class.new('I want to achieve my target of running a marathon')
        expect(router.route).to eq(:smart_goal)
      end
    end

    context 'when input contains prioritization keywords' do
      it 'routes to prioritization intent' do
        router = described_class.new('Please prioritize my tasks: buy groceries, call mom, finish report')
        expect(router.route).to eq(:prioritization)
      end

      it 'routes to prioritization intent with priority keyword' do
        router = described_class.new('Help me organize my todo list by priority')
        expect(router.route).to eq(:prioritization)
      end

      it 'routes to prioritization intent with rank keyword' do
        router = described_class.new('Rank these actions: exercise, work, sleep')
        expect(router.route).to eq(:prioritization)
      end
    end

    context 'when input is unclear' do
      it 'raises an exception for unclear input' do
        router = described_class.new('I need help with something')
        expect do
          router.route
        end.to raise_error(RuntimeError,
                           "IntentRouter: 'i need help with something' input does not match accepted choices.")
      end

      it 'raises an exception for empty input' do
        router = described_class.new('')
        expect { router.route }.to raise_error(RuntimeError, "IntentRouter: '' input does not match accepted choices.")
      end
    end

    context 'when input contains mixed keywords' do
      it 'prioritizes goal intent over task intent' do
        router = described_class.new('I want to set a goal for my tasks')
        expect(router.route).to eq(:smart_goal)
      end
    end

    context 'case sensitivity' do
      it 'handles uppercase input' do
        router = described_class.new('CREATE A GOAL TO EXERCISE')
        expect(router.route).to eq(:smart_goal)
      end

      it 'handles mixed case input' do
        router = described_class.new('Prioritize My Tasks')
        expect(router.route).to eq(:prioritization)
      end
    end
  end
end
