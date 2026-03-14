# frozen_string_literal: true

module Legion
  module Extensions
    module Reward
      module Helpers
        module Constants
          # Reward sources with weights (sum to 1.0)
          # Each source contributes independently to the composite reward signal
          REWARD_SOURCES = {
            prediction_accuracy: { weight: 0.20, description: 'Correct predictions reinforced' },
            curiosity_resolved:  { weight: 0.15, description: 'Wonder resolution satisfaction' },
            goal_achieved:       { weight: 0.20, description: 'Intention completion reward' },
            social_approval:     { weight: 0.10, description: 'Trust increase from peers' },
            flow_state:          { weight: 0.10, description: 'Intrinsic flow motivation' },
            error_avoidance:     { weight: 0.10, description: 'Low error rate maintenance' },
            novelty_encounter:   { weight: 0.10, description: 'Novel experience exploration' },
            homeostatic_balance: { weight: 0.05, description: 'System stability maintenance' }
          }.freeze

          # EMA alpha for running reward average
          REWARD_ALPHA = 0.15

          # EMA alpha for reward prediction (expected reward baseline)
          PREDICTION_ALPHA = 0.1

          # Minimum RPE magnitude to trigger learning signal
          RPE_THRESHOLD = 0.05

          # Reward signal range
          REWARD_RANGE = { min: -1.0, max: 1.0 }.freeze

          # RPE classification thresholds
          RPE_LEVELS = {
            large_positive: 0.3,   # "Way better than expected!" — strong reinforcement
            positive:       0.1,   # "Better than expected" — moderate reinforcement
            neutral:        0.05,  # "About as expected" — maintenance
            negative:       -0.1,  # "Worse than expected" — mild suppression
            large_negative: -0.3   # "Way worse than expected!" — strong suppression
          }.freeze

          # Temporal discount factor (per tick, for weighted history)
          TEMPORAL_DISCOUNT = 0.95

          # History cap
          MAX_REWARD_HISTORY = 200

          # Domain-specific reward history cap
          MAX_DOMAIN_HISTORY = 50

          # Anhedonia threshold — running average below this triggers concern
          ANHEDONIA_THRESHOLD = -0.3

          # Euphoria threshold — running average above this triggers concern
          EUPHORIA_THRESHOLD = 0.7

          # Reward momentum (how much prior reward influences next prediction)
          MOMENTUM_WINDOW = 10
        end
      end
    end
  end
end
