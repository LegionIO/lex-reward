# frozen_string_literal: true

module Legion
  module Extensions
    module Reward
      module Helpers
        class RewardStore
          attr_reader :signal

          def initialize(signal: nil)
            @signal = signal || RewardSignal.new
          end

          def process_tick(tick_results)
            source_signals = extract_signals(tick_results)
            result = @signal.compute(source_signals)

            domain = extract_domain(tick_results)
            @signal.record_domain_reward(domain, result[:reward]) if domain

            result
          end

          def domain_report(domain)
            {
              domain:  domain,
              average: @signal.domain_average(domain),
              trend:   @signal.domain_trend(domain),
              history: @signal.domain_history[domain]&.last(10) || []
            }
          end

          def all_domain_averages
            @signal.domain_history.keys.to_h do |domain|
              [domain, @signal.domain_average(domain).round(4)]
            end
          end

          def health_assessment
            avg = @signal.running_average
            vol = @signal.reward_volatility

            if @signal.anhedonic?
              { status: :anhedonic, description: 'Persistently low reward — possible disengagement', severity: :high }
            elsif @signal.euphoric?
              { status: :euphoric, description: 'Persistently high reward — possible overconfidence', severity: :moderate }
            elsif vol > 0.4
              { status: :volatile, description: 'Highly variable reward — unstable learning signals', severity: :moderate }
            elsif avg.between?(-0.1, 0.1)
              { status: :neutral, description: 'Low reward signal — minimal learning happening', severity: :low }
            else
              { status: :healthy, description: 'Balanced reward signal — healthy learning', severity: :none }
            end
          end

          private

          def extract_signals(tick_results)
            {
              prediction_accuracy: extract_prediction_reward(tick_results),
              curiosity_resolved:  extract_curiosity_reward(tick_results),
              goal_achieved:       extract_goal_reward(tick_results),
              social_approval:     extract_social_reward(tick_results),
              flow_state:          extract_flow_reward(tick_results),
              error_avoidance:     extract_error_reward(tick_results),
              novelty_encounter:   extract_novelty_reward(tick_results),
              homeostatic_balance: extract_homeostatic_reward(tick_results)
            }
          end

          def extract_prediction_reward(tick_results)
            accuracy = tick_results.dig(:prediction_engine, :rolling_accuracy)
            return 0.0 unless accuracy

            (accuracy - 0.5) * 2.0
          end

          def extract_curiosity_reward(tick_results)
            resolved = tick_results.dig(:curiosity, :resolved_count) || 0
            intensity = tick_results.dig(:curiosity, :intensity) || 0.0

            resolved_signal = [resolved * 0.3, 1.0].min
            (resolved_signal + (intensity * 0.2)).clamp(-1.0, 1.0)
          end

          def extract_goal_reward(tick_results)
            completed = tick_results.dig(:volition, :completed_count) || 0
            failed = tick_results.dig(:volition, :failed_count) || 0

            ((completed * 0.4) - (failed * 0.3)).clamp(-1.0, 1.0)
          end

          def extract_social_reward(tick_results)
            trust_delta = tick_results.dig(:trust, :composite_delta) || 0.0
            (trust_delta * 2.0).clamp(-1.0, 1.0)
          end

          def extract_flow_reward(tick_results)
            in_flow = tick_results.dig(:flow, :in_flow)
            score = tick_results.dig(:flow, :score) || 0.0

            return score * 0.8 if in_flow

            -0.1
          end

          def extract_error_reward(tick_results)
            error_rate = tick_results.dig(:prediction_engine, :error_rate)
            return 0.0 unless error_rate

            (1.0 - (error_rate * 2.0)).clamp(-1.0, 1.0)
          end

          def extract_novelty_reward(tick_results)
            novelty = tick_results.dig(:attention, :novelty_score) || 0.0
            spotlight_count = tick_results.dig(:attention, :spotlight_count) || 0

            ((novelty * 0.5) + [spotlight_count * 0.1, 0.5].min).clamp(-1.0, 1.0)
          end

          def extract_homeostatic_reward(tick_results)
            deviation = tick_results.dig(:homeostasis, :worst_deviation) || 0.0
            allostatic = tick_results.dig(:homeostasis, :allostatic_load) || 0.0

            stability = 1.0 - [deviation, allostatic].max
            (stability - 0.5).clamp(-1.0, 1.0)
          end

          def extract_domain(tick_results)
            tick_results.dig(:volition, :current_domain) ||
              tick_results.dig(:curiosity, :active_domain) ||
              tick_results.dig(:attention, :focus_domain)
          end
        end
      end
    end
  end
end
