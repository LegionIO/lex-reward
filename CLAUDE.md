# lex-reward

**Level 3 Leaf Documentation**
- **Parent**: `/Users/miverso2/rubymine/legion/extensions-agentic/CLAUDE.md`
- **Gem**: `lex-reward`
- **Version**: 0.1.0
- **Namespace**: `Legion::Extensions::Reward`

## Purpose

Reward prediction error (RPE) and composite reward signal. Computes a weighted reward each tick by extracting signals from eight reward sources (prediction accuracy, curiosity resolution, goal achievement, social approval, flow state, error avoidance, novelty, homeostatic balance). Tracks running average reward, predicts expected reward via EMA, computes RPE = actual - predicted, and classifies learning signals. Detects anhedonia and euphoria states.

## Gem Info

- **Homepage**: https://github.com/LegionIO/lex-reward
- **License**: MIT
- **Ruby**: >= 3.4

## File Structure

```
lib/legion/extensions/reward/
  version.rb
  client.rb
  helpers/
    constants.rb      # REWARD_SOURCES, alphas, RPE_LEVELS, thresholds
    reward_signal.rb  # RewardSignal — EMA tracking, RPE, history, domain tracking
    reward_store.rb   # RewardStore — orchestrates signal extraction from tick_results
  runners/
    reward.rb         # Runner module
spec/
  helpers/constants_spec.rb
  helpers/reward_signal_spec.rb
  helpers/reward_store_spec.rb
  runners/reward_spec.rb
  client_spec.rb
```

## Key Constants

From `Helpers::Constants`:
- `REWARD_SOURCES`: 8 sources with weights summing to 1.0: `prediction_accuracy` (0.20), `curiosity_resolved` (0.15), `goal_achieved` (0.20), `social_approval` (0.10), `flow_state` (0.10), `error_avoidance` (0.10), `novelty_encounter` (0.10), `homeostatic_balance` (0.05)
- `REWARD_ALPHA = 0.15` (EMA for running average), `PREDICTION_ALPHA = 0.1`
- `RPE_THRESHOLD = 0.05`, `TEMPORAL_DISCOUNT = 0.95`
- `ANHEDONIA_THRESHOLD = -0.3`, `EUPHORIA_THRESHOLD = 0.7`
- `MAX_REWARD_HISTORY = 200`, `MAX_DOMAIN_HISTORY = 50`, `MOMENTUM_WINDOW = 10`
- `RPE_LEVELS`: `large_positive: 0.3`, `positive: 0.1`, `neutral: 0.05`, `negative: -0.1`, `large_negative: -0.3`

## Runners

| Method | Key Parameters | Returns |
|---|---|---|
| `compute_reward` | `tick_results: {}` | reward, rpe, rpe_class, learning_signal, source_breakdown |
| `reward_status` | — | running_average, predicted_reward, volatility + health assessment |
| `reward_for` | `domain:` | `{ domain:, average:, trend:, history: }` |
| `reward_history` | `limit: 20` | `{ history:, total:, discounted_return: }` |
| `domain_rewards` | — | `{ domains:, domain_count:, best_domain:, worst_domain: }` |
| `reward_stats` | — | running_average, predicted_reward, volatility, tick_count, health, domains_tracked, history_size, discounted_return, anhedonic, euphoric |

## Helpers

### `Helpers::RewardSignal`
Tracks running average (EMA), predicted reward (EMA), RPE, and history. `compute(source_signals)` weights each source by `REWARD_SOURCES[source][:weight]`, sums to composite reward. Computes RPE = reward - predicted_reward. Classifies RPE against `RPE_LEVELS`. `learning_signal` = RPE if |RPE| > `RPE_THRESHOLD`, else 0. Updates running_average and predicted_reward via EMA. `anhedonic?` = running_average < -0.3. `euphoric?` = running_average > 0.7. `reward_volatility` = std dev of last `MOMENTUM_WINDOW` rewards. `discounted_return(n)` = temporally discounted sum. `domain_history` hash per domain. `recent_rewards(limit)`.

### `Helpers::RewardStore`
Extracts signals from tick_results and delegates to RewardSignal. Eight extraction methods map tick_results keys to signal values: `extract_prediction_reward` -> `(accuracy - 0.5) * 2.0`; `extract_curiosity_reward` -> resolved_count + intensity; `extract_goal_reward` -> (completed * 0.4) - (failed * 0.3); `extract_social_reward` -> trust_delta * 2.0; `extract_flow_reward` -> flow score or -0.1; `extract_error_reward` -> `1 - error_rate * 2`; `extract_novelty_reward` -> novelty_score + spotlight_count; `extract_homeostatic_reward` -> stability - deviation. `health_assessment` classifies by anhedonia/euphoria/volatility/neutral/healthy.

## Integration Points

- `compute_reward` consumes `tick_results` directly from `lex-tick`
- `reward_status` health output feeds `lex-reflection` as learning health metric
- Large positive RPE events reinforce `lex-memory` trace strength
- `anhedonic?` state can trigger `lex-emotion` valence recalibration
- `domain_rewards` feeds `lex-preference-learning` to align preferences with rewarding domains
- `best_domain` / `worst_domain` can guide `lex-planning` goal selection

## Development Notes

- Source extraction: each source reads from a specific `tick_results` key; missing keys default to 0 or neutral
- `flow_state` extraction: returns `score * 0.8` if `in_flow` true, else `-0.1` (penalizes non-flow states)
- RPE classification uses thresholds in order: large_positive (> 0.3), positive (> 0.1), neutral (|RPE| <= 0.05), negative, large_negative
- Domain is extracted from `volition.current_domain`, `curiosity.active_domain`, or `attention.focus_domain`
- `reward_volatility` uses std dev over last `MOMENTUM_WINDOW = 10` rewards
- All state is in-memory; reset on process restart
