# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Legion::Extensions::Reward::Helpers::RewardSignal do
  subject(:signal) { described_class.new }

  let(:positive_sources) do
    {
      prediction_accuracy: 0.8,
      curiosity_resolved:  0.5,
      goal_achieved:       0.6,
      social_approval:     0.3,
      flow_state:          0.4,
      error_avoidance:     0.7,
      novelty_encounter:   0.3,
      homeostatic_balance: 0.2
    }
  end

  let(:negative_sources) do
    {
      prediction_accuracy: -0.5,
      curiosity_resolved:  -0.3,
      goal_achieved:       -0.8,
      social_approval:     -0.4,
      flow_state:          -0.2,
      error_avoidance:     -0.6,
      novelty_encounter:   -0.1,
      homeostatic_balance: -0.3
    }
  end

  let(:neutral_sources) do
    {
      prediction_accuracy: 0.0,
      curiosity_resolved:  0.0,
      goal_achieved:       0.0,
      social_approval:     0.0,
      flow_state:          0.0,
      error_avoidance:     0.0,
      novelty_encounter:   0.0,
      homeostatic_balance: 0.0
    }
  end

  describe '#initialize' do
    it 'starts with zero running average' do
      expect(signal.running_average).to eq(0.0)
    end

    it 'starts with zero predicted reward' do
      expect(signal.predicted_reward).to eq(0.0)
    end

    it 'starts with zero RPE' do
      expect(signal.last_rpe).to eq(0.0)
    end

    it 'starts with empty history' do
      expect(signal.history).to be_empty
    end

    it 'starts with zero tick count' do
      expect(signal.tick_count).to eq(0)
    end
  end

  describe '#compute' do
    it 'returns reward result hash' do
      result = signal.compute(positive_sources)
      expect(result).to include(:reward, :rpe, :rpe_class, :running_average,
                                :predicted_reward, :sources, :learning_signal)
    end

    it 'computes positive reward from positive sources' do
      result = signal.compute(positive_sources)
      expect(result[:reward]).to be > 0.0
    end

    it 'computes negative reward from negative sources' do
      result = signal.compute(negative_sources)
      expect(result[:reward]).to be < 0.0
    end

    it 'computes zero reward from neutral sources' do
      result = signal.compute(neutral_sources)
      expect(result[:reward]).to eq(0.0)
    end

    it 'clamps reward to [-1.0, 1.0]' do
      extreme = positive_sources.transform_values { 10.0 }
      result = signal.compute(extreme)
      expect(result[:reward]).to be <= 1.0
    end

    it 'increments tick count' do
      signal.compute(positive_sources)
      expect(signal.tick_count).to eq(1)
    end

    it 'records in history' do
      signal.compute(positive_sources)
      expect(signal.history.size).to eq(1)
    end

    it 'computes RPE as actual minus predicted' do
      signal.compute(neutral_sources)
      result = signal.compute(positive_sources)
      expect(result[:rpe]).to be > 0.0
    end

    it 'updates running average via EMA' do
      signal.compute(positive_sources)
      expect(signal.running_average).to be > 0.0
    end

    it 'updates predicted reward via EMA' do
      signal.compute(positive_sources)
      expect(signal.predicted_reward).to be > 0.0
    end
  end

  describe 'RPE classification' do
    it 'classifies large positive RPE' do
      # First tick with neutral, then large positive
      signal.compute(neutral_sources)
      result = signal.compute(positive_sources)
      expect(result[:rpe_class]).to be_a(Symbol)
    end

    it 'classifies neutral RPE for stable rewards' do
      20.times { signal.compute(neutral_sources) }
      result = signal.compute(neutral_sources)
      expect(result[:rpe_class]).to eq(:neutral)
    end
  end

  describe '#record_domain_reward' do
    it 'stores domain-specific rewards' do
      signal.record_domain_reward(:networking, 0.5)
      expect(signal.domain_history[:networking].size).to eq(1)
    end

    it 'caps domain history at MAX_DOMAIN_HISTORY' do
      max = Legion::Extensions::Reward::Helpers::Constants::MAX_DOMAIN_HISTORY
      (max + 5).times { signal.record_domain_reward(:test, 0.1) }
      expect(signal.domain_history[:test].size).to eq(max)
    end
  end

  describe '#domain_average' do
    it 'returns 0.0 for unknown domain' do
      expect(signal.domain_average(:unknown)).to eq(0.0)
    end

    it 'computes average of domain rewards' do
      signal.record_domain_reward(:test, 0.4)
      signal.record_domain_reward(:test, 0.6)
      expect(signal.domain_average(:test)).to eq(0.5)
    end
  end

  describe '#domain_trend' do
    it 'returns :no_data for unknown domain' do
      expect(signal.domain_trend(:unknown)).to eq(:no_data)
    end

    it 'returns :no_data with insufficient entries' do
      3.times { signal.record_domain_reward(:test, 0.5) }
      expect(signal.domain_trend(:test)).to eq(:no_data)
    end

    it 'detects improving trend' do
      5.times { signal.record_domain_reward(:test, 0.1) }
      5.times { signal.record_domain_reward(:test, 0.9) }
      expect(signal.domain_trend(:test)).to eq(:improving)
    end

    it 'detects declining trend' do
      5.times { signal.record_domain_reward(:test, 0.9) }
      5.times { signal.record_domain_reward(:test, 0.1) }
      expect(signal.domain_trend(:test)).to eq(:declining)
    end

    it 'detects stable trend' do
      10.times { signal.record_domain_reward(:test, 0.5) }
      expect(signal.domain_trend(:test)).to eq(:stable)
    end
  end

  describe '#anhedonic?' do
    it 'returns false initially' do
      expect(signal.anhedonic?).to be false
    end

    it 'returns true with persistent negative rewards' do
      50.times { signal.compute(negative_sources) }
      expect(signal.anhedonic?).to be true
    end
  end

  describe '#euphoric?' do
    it 'returns false initially' do
      expect(signal.euphoric?).to be false
    end

    it 'returns true with persistent high rewards' do
      extreme_positive = positive_sources.transform_values { 1.0 }
      50.times { signal.compute(extreme_positive) }
      expect(signal.euphoric?).to be true
    end
  end

  describe '#learning_signal?' do
    it 'returns false when RPE is below threshold' do
      20.times { signal.compute(neutral_sources) }
      expect(signal.learning_signal?).to be false
    end

    it 'returns true when RPE exceeds threshold' do
      signal.compute(neutral_sources)
      signal.compute(positive_sources)
      expect(signal.learning_signal?).to be true
    end
  end

  describe '#recent_rewards' do
    it 'returns empty for no history' do
      expect(signal.recent_rewards).to be_empty
    end

    it 'returns requested number of entries' do
      10.times { signal.compute(positive_sources) }
      expect(signal.recent_rewards(5).size).to eq(5)
    end
  end

  describe '#discounted_return' do
    it 'returns 0.0 for empty history' do
      expect(signal.discounted_return).to eq(0.0)
    end

    it 'computes discounted sum of rewards' do
      5.times { signal.compute(positive_sources) }
      expect(signal.discounted_return).to be > 0.0
    end

    it 'recent rewards count more than older ones' do
      full = signal.discounted_return(10)
      expect(full).to eq(0.0)

      5.times { signal.compute(positive_sources) }
      windowed = signal.discounted_return(3)
      full_return = signal.discounted_return
      expect(full_return).to be >= windowed
    end
  end

  describe '#reward_volatility' do
    it 'returns 0.0 with insufficient data' do
      expect(signal.reward_volatility).to eq(0.0)
    end

    it 'is low for consistent rewards' do
      20.times { signal.compute(neutral_sources) }
      expect(signal.reward_volatility).to be < 0.1
    end

    it 'is higher for alternating rewards' do
      10.times do
        signal.compute(positive_sources)
        signal.compute(negative_sources)
      end
      expect(signal.reward_volatility).to be > 0.0
    end
  end

  describe '#to_h' do
    it 'returns complete state hash' do
      signal.compute(positive_sources)
      h = signal.to_h
      expect(h).to include(:running_average, :predicted_reward, :last_rpe, :rpe_class,
                           :tick_count, :learning_signal, :anhedonic, :euphoric,
                           :volatility, :domains_tracked, :history_size)
    end
  end

  describe 'history cap' do
    it 'caps at MAX_REWARD_HISTORY' do
      max = Legion::Extensions::Reward::Helpers::Constants::MAX_REWARD_HISTORY
      (max + 10).times { signal.compute(positive_sources) }
      expect(signal.history.size).to eq(max)
    end
  end
end
