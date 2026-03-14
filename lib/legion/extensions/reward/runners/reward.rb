# frozen_string_literal: true

module Legion
  module Extensions
    module Reward
      module Runners
        module Reward
          include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers) &&
                                                      Legion::Extensions::Helpers.const_defined?(:Lex)

          def compute_reward(tick_results: {}, **)
            result = reward_store.process_tick(tick_results)

            Legion::Logging.debug "[reward] reward=#{result[:reward]} rpe=#{result[:rpe]} " \
                                  "class=#{result[:rpe_class]} learning=#{result[:learning_signal]}"

            result
          end

          def reward_status(**)
            sig = reward_store.signal
            health = reward_store.health_assessment

            Legion::Logging.debug "[reward] status: avg=#{sig.running_average.round(3)} " \
                                  "predicted=#{sig.predicted_reward.round(3)} health=#{health[:status]}"

            sig.to_h.merge(health: health)
          end

          def reward_for(domain:, **)
            report = reward_store.domain_report(domain)
            Legion::Logging.debug "[reward] domain=#{domain} avg=#{report[:average].round(3)} trend=#{report[:trend]}"
            report
          end

          def reward_history(limit: 20, **)
            recent = reward_store.signal.recent_rewards(limit)
            Legion::Logging.debug "[reward] history: #{recent.size} entries"

            {
              history:           recent,
              total:             reward_store.signal.history.size,
              discounted_return: reward_store.signal.discounted_return(limit).round(4)
            }
          end

          def domain_rewards(**)
            averages = reward_store.all_domain_averages
            Legion::Logging.debug "[reward] domains: #{averages.size} tracked"

            {
              domains:      averages,
              domain_count: averages.size,
              best_domain:  averages.max_by { |_, v| v }&.first,
              worst_domain: averages.min_by { |_, v| v }&.first
            }
          end

          def reward_stats(**)
            sig = reward_store.signal
            health = reward_store.health_assessment

            Legion::Logging.debug '[reward] stats'

            {
              running_average:   sig.running_average.round(4),
              predicted_reward:  sig.predicted_reward.round(4),
              volatility:        sig.reward_volatility.round(4),
              tick_count:        sig.tick_count,
              health:            health,
              domains_tracked:   sig.domain_history.keys.size,
              history_size:      sig.history.size,
              discounted_return: sig.discounted_return.round(4),
              anhedonic:         sig.anhedonic?,
              euphoric:          sig.euphoric?
            }
          end

          private

          def reward_store
            @reward_store ||= Helpers::RewardStore.new
          end
        end
      end
    end
  end
end
