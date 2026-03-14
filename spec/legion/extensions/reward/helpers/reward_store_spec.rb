# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Legion::Extensions::Reward::Helpers::RewardStore do
  subject(:store) { described_class.new }

  let(:positive_tick) do
    {
      prediction_engine: { rolling_accuracy: 0.8, error_rate: 0.1 },
      curiosity:         { resolved_count: 2, intensity: 0.6 },
      volition:          { completed_count: 1, failed_count: 0, current_domain: :networking },
      trust:             { composite_delta: 0.1 },
      flow:              { in_flow: true, score: 0.8 },
      attention:         { novelty_score: 0.5, spotlight_count: 3 },
      homeostasis:       { worst_deviation: 0.1, allostatic_load: 0.1 }
    }
  end

  let(:negative_tick) do
    {
      prediction_engine: { rolling_accuracy: 0.2, error_rate: 0.8 },
      curiosity:         { resolved_count: 0, intensity: 0.1 },
      volition:          { completed_count: 0, failed_count: 2, current_domain: :debugging },
      trust:             { composite_delta: -0.2 },
      flow:              { in_flow: false, score: 0.1 },
      attention:         { novelty_score: 0.0, spotlight_count: 0 },
      homeostasis:       { worst_deviation: 0.8, allostatic_load: 0.7 }
    }
  end

  let(:empty_tick) { {} }

  describe '#process_tick' do
    it 'returns reward result hash' do
      result = store.process_tick(positive_tick)
      expect(result).to include(:reward, :rpe, :rpe_class, :running_average,
                                :predicted_reward, :sources, :learning_signal)
    end

    it 'computes positive reward for positive tick' do
      result = store.process_tick(positive_tick)
      expect(result[:reward]).to be > 0.0
    end

    it 'computes negative reward for negative tick' do
      result = store.process_tick(negative_tick)
      expect(result[:reward]).to be < 0.0
    end

    it 'handles empty tick results' do
      result = store.process_tick(empty_tick)
      expect(result[:reward]).to be_a(Float)
    end

    it 'records domain reward when domain available' do
      store.process_tick(positive_tick)
      expect(store.signal.domain_history[:networking]).not_to be_nil
    end
  end

  describe '#domain_report' do
    it 'returns report for known domain' do
      store.process_tick(positive_tick)
      report = store.domain_report(:networking)
      expect(report).to include(:domain, :average, :trend, :history)
      expect(report[:domain]).to eq(:networking)
    end

    it 'returns empty report for unknown domain' do
      report = store.domain_report(:unknown)
      expect(report[:average]).to eq(0.0)
      expect(report[:trend]).to eq(:no_data)
    end
  end

  describe '#all_domain_averages' do
    it 'returns empty hash initially' do
      expect(store.all_domain_averages).to be_empty
    end

    it 'tracks multiple domains' do
      store.process_tick(positive_tick)
      store.process_tick(negative_tick)
      averages = store.all_domain_averages
      expect(averages.keys).to include(:networking, :debugging)
    end
  end

  describe '#health_assessment' do
    it 'returns healthy initially' do
      assessment = store.health_assessment
      expect(assessment[:status]).to eq(:neutral).or eq(:healthy)
    end

    it 'detects anhedonia with persistent negative' do
      50.times { store.process_tick(negative_tick) }
      assessment = store.health_assessment
      expect(assessment[:status]).to eq(:anhedonic)
    end

    it 'detects euphoria with persistent positive' do
      extreme = positive_tick.dup
      extreme[:prediction_engine] = { rolling_accuracy: 1.0, error_rate: 0.0 }
      extreme[:curiosity] = { resolved_count: 5, intensity: 1.0 }
      extreme[:volition] = { completed_count: 3, failed_count: 0, current_domain: :test }
      extreme[:flow] = { in_flow: true, score: 1.0 }
      extreme[:attention] = { novelty_score: 1.0, spotlight_count: 5 }
      extreme[:homeostasis] = { worst_deviation: 0.0, allostatic_load: 0.0 }
      50.times { store.process_tick(extreme) }
      assessment = store.health_assessment
      expect(assessment[:status]).to eq(:euphoric)
    end

    it 'includes severity' do
      assessment = store.health_assessment
      expect(assessment).to have_key(:severity)
    end
  end

  describe 'signal extraction' do
    it 'extracts prediction reward from accuracy' do
      result = store.process_tick(positive_tick)
      expect(result[:sources][:prediction_accuracy]).to be > 0.0
    end

    it 'extracts curiosity reward from resolved count' do
      result = store.process_tick(positive_tick)
      expect(result[:sources][:curiosity_resolved]).to be > 0.0
    end

    it 'extracts goal reward from completed count' do
      result = store.process_tick(positive_tick)
      expect(result[:sources][:goal_achieved]).to be > 0.0
    end

    it 'extracts social reward from trust delta' do
      result = store.process_tick(positive_tick)
      expect(result[:sources][:social_approval]).to be > 0.0
    end

    it 'extracts flow reward from flow state' do
      result = store.process_tick(positive_tick)
      expect(result[:sources][:flow_state]).to be > 0.0
    end

    it 'extracts error reward from error rate' do
      result = store.process_tick(positive_tick)
      expect(result[:sources][:error_avoidance]).to be > 0.0
    end

    it 'extracts novelty reward from attention' do
      result = store.process_tick(positive_tick)
      expect(result[:sources][:novelty_encounter]).to be > 0.0
    end

    it 'extracts homeostatic reward from deviation' do
      result = store.process_tick(positive_tick)
      expect(result[:sources][:homeostatic_balance]).to be > 0.0
    end

    it 'returns negative flow reward when not in flow' do
      result = store.process_tick(negative_tick)
      expect(result[:sources][:flow_state]).to be < 0.0
    end
  end
end
