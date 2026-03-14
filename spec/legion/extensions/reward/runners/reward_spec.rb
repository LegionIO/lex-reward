# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Legion::Extensions::Reward::Runners::Reward do
  let(:client) { Legion::Extensions::Reward::Client.new }

  let(:positive_tick) do
    {
      prediction_engine: { rolling_accuracy: 0.8, error_rate: 0.1 },
      curiosity:         { resolved_count: 2, intensity: 0.6 },
      volition:          { completed_count: 1, failed_count: 0, current_domain: :test },
      trust:             { composite_delta: 0.1 },
      flow:              { in_flow: true, score: 0.7 },
      attention:         { novelty_score: 0.4, spotlight_count: 2 },
      homeostasis:       { worst_deviation: 0.1, allostatic_load: 0.1 }
    }
  end

  describe '#compute_reward' do
    it 'returns reward hash' do
      result = client.compute_reward(tick_results: positive_tick)
      expect(result).to include(:reward, :rpe, :rpe_class, :running_average,
                                :predicted_reward, :sources, :learning_signal)
    end

    it 'returns positive reward for positive tick' do
      result = client.compute_reward(tick_results: positive_tick)
      expect(result[:reward]).to be > 0.0
    end

    it 'returns reward in valid range' do
      result = client.compute_reward(tick_results: positive_tick)
      expect(result[:reward]).to be_between(-1.0, 1.0)
    end

    it 'handles empty tick results' do
      result = client.compute_reward(tick_results: {})
      expect(result[:reward]).to be_a(Float)
    end
  end

  describe '#reward_status' do
    it 'returns status with health assessment' do
      client.compute_reward(tick_results: positive_tick)
      status = client.reward_status
      expect(status).to include(:running_average, :predicted_reward, :last_rpe,
                                :tick_count, :health)
      expect(status[:health]).to include(:status, :severity)
    end
  end

  describe '#reward_for' do
    it 'returns domain report' do
      client.compute_reward(tick_results: positive_tick)
      report = client.reward_for(domain: :test)
      expect(report).to include(:domain, :average, :trend, :history)
    end

    it 'returns empty for unknown domain' do
      report = client.reward_for(domain: :unknown)
      expect(report[:average]).to eq(0.0)
    end
  end

  describe '#reward_history' do
    it 'returns empty initially' do
      result = client.reward_history
      expect(result[:history]).to be_empty
      expect(result[:total]).to eq(0)
    end

    it 'returns history after compute calls' do
      5.times { client.compute_reward(tick_results: positive_tick) }
      result = client.reward_history
      expect(result[:history].size).to eq(5)
      expect(result[:total]).to eq(5)
    end

    it 'respects limit' do
      10.times { client.compute_reward(tick_results: positive_tick) }
      result = client.reward_history(limit: 3)
      expect(result[:history].size).to eq(3)
    end

    it 'includes discounted return' do
      5.times { client.compute_reward(tick_results: positive_tick) }
      result = client.reward_history
      expect(result[:discounted_return]).to be_a(Float)
    end
  end

  describe '#domain_rewards' do
    it 'returns empty initially' do
      result = client.domain_rewards
      expect(result[:domains]).to be_empty
      expect(result[:domain_count]).to eq(0)
    end

    it 'tracks domains from tick results' do
      client.compute_reward(tick_results: positive_tick)
      result = client.domain_rewards
      expect(result[:domain_count]).to be >= 1
    end

    it 'identifies best and worst domains' do
      5.times { client.compute_reward(tick_results: positive_tick) }
      result = client.domain_rewards
      expect(result[:best_domain]).not_to be_nil if result[:domain_count] > 0
    end
  end

  describe '#reward_stats' do
    it 'returns comprehensive stats' do
      client.compute_reward(tick_results: positive_tick)
      stats = client.reward_stats
      expect(stats).to include(:running_average, :predicted_reward, :volatility,
                               :tick_count, :health, :domains_tracked,
                               :history_size, :discounted_return,
                               :anhedonic, :euphoric)
    end
  end

  describe 'reward prediction error learning' do
    it 'generates large RPE for unexpected positive after neutral' do
      10.times { client.compute_reward(tick_results: {}) }
      result = client.compute_reward(tick_results: positive_tick)
      expect(result[:rpe]).to be > 0.0
      expect(result[:learning_signal]).to be true
    end

    it 'generates negative RPE for unexpected negative after positive' do
      10.times { client.compute_reward(tick_results: positive_tick) }
      negative_tick = {
        prediction_engine: { rolling_accuracy: 0.2, error_rate: 0.8 },
        volition:          { completed_count: 0, failed_count: 2 },
        flow:              { in_flow: false, score: 0.1 }
      }
      result = client.compute_reward(tick_results: negative_tick)
      expect(result[:rpe]).to be < 0.0
    end

    it 'converges RPE to zero for stable rewards' do
      30.times { client.compute_reward(tick_results: positive_tick) }
      result = client.compute_reward(tick_results: positive_tick)
      expect(result[:rpe].abs).to be < 0.1
    end
  end
end
