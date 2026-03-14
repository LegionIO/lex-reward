# frozen_string_literal: true

module Legion
  module Extensions
    module Reward
      module Helpers
        class RewardSignal
          attr_reader :running_average, :predicted_reward, :last_rpe,
                      :history, :domain_history, :tick_count

          def initialize
            @running_average = 0.0
            @predicted_reward = 0.0
            @last_rpe = 0.0
            @history = []
            @domain_history = {}
            @tick_count = 0
          end

          def compute(source_signals)
            @tick_count += 1
            raw_reward = weighted_sum(source_signals)
            reward = raw_reward.clamp(Constants::REWARD_RANGE[:min], Constants::REWARD_RANGE[:max])

            @last_rpe = reward - @predicted_reward
            @running_average = ema(@running_average, reward, Constants::REWARD_ALPHA)
            @predicted_reward = ema(@predicted_reward, reward, Constants::PREDICTION_ALPHA)

            record(reward, source_signals)

            {
              reward:           reward.round(4),
              rpe:              @last_rpe.round(4),
              rpe_class:        classify_rpe(@last_rpe),
              running_average:  @running_average.round(4),
              predicted_reward: @predicted_reward.round(4),
              sources:          source_signals,
              learning_signal:  learning_signal?
            }
          end

          def record_domain_reward(domain, reward)
            @domain_history[domain] ||= []
            @domain_history[domain] << { reward: reward, at: Time.now.utc }
            @domain_history[domain].shift while @domain_history[domain].size > Constants::MAX_DOMAIN_HISTORY
          end

          def domain_average(domain)
            entries = @domain_history[domain]
            return 0.0 if entries.nil? || entries.empty?

            entries.sum { |e| e[:reward] } / entries.size.to_f
          end

          def domain_trend(domain)
            entries = @domain_history[domain]
            return :no_data if entries.nil? || entries.size < 5

            recent = entries.last(10)
            values = recent.map { |e| e[:reward] }
            first_half = values[0...(values.size / 2)]
            second_half = values[(values.size / 2)..]
            diff = mean(second_half) - mean(first_half)

            if diff > 0.05
              :improving
            elsif diff < -0.05
              :declining
            else
              :stable
            end
          end

          def anhedonic?
            @running_average < Constants::ANHEDONIA_THRESHOLD
          end

          def euphoric?
            @running_average > Constants::EUPHORIA_THRESHOLD
          end

          def learning_signal?
            @last_rpe.abs >= Constants::RPE_THRESHOLD
          end

          def recent_rewards(limit = 20)
            @history.last(limit)
          end

          def discounted_return(window = nil)
            entries = window ? @history.last(window) : @history
            return 0.0 if entries.empty?

            total = 0.0
            entries.reverse_each.with_index do |entry, idx|
              total += entry[:reward] * (Constants::TEMPORAL_DISCOUNT**idx)
            end
            total
          end

          def reward_volatility
            return 0.0 if @history.size < 3

            recent = @history.last(Constants::MOMENTUM_WINDOW).map { |h| h[:reward] }
            avg = mean(recent)
            variance = recent.sum { |r| (r - avg)**2 } / recent.size.to_f
            Math.sqrt(variance)
          end

          def to_h
            {
              running_average:  @running_average.round(4),
              predicted_reward: @predicted_reward.round(4),
              last_rpe:         @last_rpe.round(4),
              rpe_class:        classify_rpe(@last_rpe),
              tick_count:       @tick_count,
              learning_signal:  learning_signal?,
              anhedonic:        anhedonic?,
              euphoric:         euphoric?,
              volatility:       reward_volatility.round(4),
              domains_tracked:  @domain_history.keys.size,
              history_size:     @history.size
            }
          end

          private

          def weighted_sum(source_signals)
            total = 0.0
            Constants::REWARD_SOURCES.each do |source, config|
              value = source_signals[source] || 0.0
              total += value * config[:weight]
            end
            total
          end

          def classify_rpe(rpe)
            if rpe >= Constants::RPE_LEVELS[:large_positive]
              :large_positive
            elsif rpe >= Constants::RPE_LEVELS[:positive]
              :positive
            elsif rpe >= -Constants::RPE_LEVELS[:neutral]
              :neutral
            elsif rpe >= Constants::RPE_LEVELS[:large_negative]
              :negative
            else
              :large_negative
            end
          end

          def ema(current, observed, alpha)
            (current * (1.0 - alpha)) + (observed * alpha)
          end

          def mean(values)
            return 0.0 if values.empty?

            values.sum / values.size.to_f
          end

          def record(reward, sources)
            @history << {
              reward:  reward,
              rpe:     @last_rpe,
              sources: sources,
              at:      Time.now.utc
            }
            @history.shift while @history.size > Constants::MAX_REWARD_HISTORY
          end
        end
      end
    end
  end
end
