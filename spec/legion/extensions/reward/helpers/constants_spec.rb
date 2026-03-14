# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Legion::Extensions::Reward::Helpers::Constants do
  describe 'REWARD_SOURCES' do
    it 'defines 8 sources' do
      expect(described_class::REWARD_SOURCES.size).to eq(8)
    end

    it 'has weights summing to 1.0' do
      total = described_class::REWARD_SOURCES.values.sum { |v| v[:weight] }
      expect(total).to be_within(0.001).of(1.0)
    end

    it 'includes prediction accuracy' do
      expect(described_class::REWARD_SOURCES).to have_key(:prediction_accuracy)
    end

    it 'includes curiosity resolved' do
      expect(described_class::REWARD_SOURCES).to have_key(:curiosity_resolved)
    end

    it 'includes goal achieved' do
      expect(described_class::REWARD_SOURCES).to have_key(:goal_achieved)
    end

    it 'is frozen' do
      expect(described_class::REWARD_SOURCES).to be_frozen
    end
  end

  describe 'REWARD_ALPHA' do
    it 'is 0.15' do
      expect(described_class::REWARD_ALPHA).to eq(0.15)
    end
  end

  describe 'PREDICTION_ALPHA' do
    it 'is 0.1' do
      expect(described_class::PREDICTION_ALPHA).to eq(0.1)
    end
  end

  describe 'RPE_THRESHOLD' do
    it 'is 0.05' do
      expect(described_class::RPE_THRESHOLD).to eq(0.05)
    end
  end

  describe 'REWARD_RANGE' do
    it 'spans -1.0 to 1.0' do
      expect(described_class::REWARD_RANGE[:min]).to eq(-1.0)
      expect(described_class::REWARD_RANGE[:max]).to eq(1.0)
    end
  end

  describe 'RPE_LEVELS' do
    it 'defines 5 levels' do
      expect(described_class::RPE_LEVELS.size).to eq(5)
    end

    it 'has large_positive > positive > neutral thresholds' do
      levels = described_class::RPE_LEVELS
      expect(levels[:large_positive]).to be > levels[:positive]
      expect(levels[:positive]).to be > levels[:neutral]
    end
  end

  describe 'TEMPORAL_DISCOUNT' do
    it 'is 0.95' do
      expect(described_class::TEMPORAL_DISCOUNT).to eq(0.95)
    end
  end

  describe 'thresholds' do
    it 'defines anhedonia threshold' do
      expect(described_class::ANHEDONIA_THRESHOLD).to eq(-0.3)
    end

    it 'defines euphoria threshold' do
      expect(described_class::EUPHORIA_THRESHOLD).to eq(0.7)
    end
  end

  describe 'MAX_REWARD_HISTORY' do
    it 'caps at 200' do
      expect(described_class::MAX_REWARD_HISTORY).to eq(200)
    end
  end
end
