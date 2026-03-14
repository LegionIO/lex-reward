# frozen_string_literal: true

require 'legion/extensions/reward/helpers/constants'
require 'legion/extensions/reward/helpers/reward_signal'
require 'legion/extensions/reward/helpers/reward_store'
require 'legion/extensions/reward/runners/reward'

module Legion
  module Extensions
    module Reward
      class Client
        include Runners::Reward

        attr_reader :reward_store

        def initialize(reward_store: nil, **)
          @reward_store = reward_store || Helpers::RewardStore.new
        end
      end
    end
  end
end
