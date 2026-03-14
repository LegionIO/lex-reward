# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Legion::Extensions::Reward::Client do
  describe '#initialize' do
    it 'creates a default reward store' do
      client = described_class.new
      expect(client.reward_store).to be_a(Legion::Extensions::Reward::Helpers::RewardStore)
    end

    it 'accepts an injected reward store' do
      store = Legion::Extensions::Reward::Helpers::RewardStore.new
      client = described_class.new(reward_store: store)
      expect(client.reward_store).to be(store)
    end

    it 'ignores unknown kwargs' do
      expect { described_class.new(unknown: true) }.not_to raise_error
    end
  end

  describe 'runner integration' do
    let(:client) { described_class.new }

    it { expect(client).to respond_to(:compute_reward) }
    it { expect(client).to respond_to(:reward_status) }
    it { expect(client).to respond_to(:reward_for) }
    it { expect(client).to respond_to(:reward_history) }
    it { expect(client).to respond_to(:domain_rewards) }
    it { expect(client).to respond_to(:reward_stats) }
  end

  describe 'shared state' do
    it 'accumulates across multiple compute calls' do
      client = described_class.new
      tick = { prediction_engine: { rolling_accuracy: 0.7, error_rate: 0.2 } }
      15.times { client.compute_reward(tick_results: tick) }
      expect(client.reward_history[:total]).to eq(15)
    end
  end
end
