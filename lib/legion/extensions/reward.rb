# frozen_string_literal: true

require 'legion/extensions/reward/version'
require 'legion/extensions/reward/helpers/constants'
require 'legion/extensions/reward/helpers/reward_signal'
require 'legion/extensions/reward/helpers/reward_store'
require 'legion/extensions/reward/runners/reward'
require 'legion/extensions/reward/client'

module Legion
  module Extensions
    module Reward
      extend Legion::Extensions::Core if Legion::Extensions.const_defined?(:Core)
    end
  end
end
