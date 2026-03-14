# lex-reward

Reward prediction error and composite reward signal for the LegionIO cognitive architecture. Implements dopaminergic-style reward learning with RPE classification.

## What It Does

Computes a weighted reward each tick from eight sources: prediction accuracy, curiosity resolution, goal achievement, social approval, flow state, error avoidance, novelty encounters, and homeostatic balance. Tracks a running average and predicted reward via EMA. Reward prediction error (RPE = actual - predicted) drives learning signal classification. Detects anhedonia (persistently low reward) and euphoria (persistently high reward). Tracks reward history per domain.

## Usage

```ruby
client = Legion::Extensions::Reward::Client.new

# Compute reward from tick results
result = client.compute_reward(
  tick_results: {
    prediction_engine:    { rolling_accuracy: 0.75, error_rate: 0.2 },
    curiosity:            { resolved_count: 2, intensity: 0.6 },
    volition:             { completed_count: 1, failed_count: 0, current_domain: :infrastructure },
    trust:                { composite_delta: 0.05 },
    attention:            { novelty_score: 0.4, spotlight_count: 3 },
    homeostasis:          { worst_deviation: 0.1, allostatic_load: 0.2 }
  }
)
# => { reward: 0.42, rpe: 0.17, rpe_class: :positive,
#      learning_signal: 0.17, sources: { prediction_accuracy: 0.5, ... } }

# Check reward health
client.reward_status
# => { running_average: 0.32, predicted_reward: 0.25, volatility: 0.08,
#      health: { status: :healthy, description: 'Balanced reward signal', severity: :none } }

# Domain-specific reward
client.reward_for(domain: :infrastructure)
client.domain_rewards

# Historical analysis
client.reward_history(limit: 20)
client.reward_stats
```

## Reward Sources

| Source | Weight | Signal |
|--------|--------|--------|
| `prediction_accuracy` | 0.20 | `(accuracy - 0.5) * 2` |
| `goal_achieved` | 0.20 | completed - failed completions |
| `curiosity_resolved` | 0.15 | wonder resolution satisfaction |
| `attention` (novelty) | 0.10 | novelty_score + spotlight |
| `social_approval` | 0.10 | trust composite delta |
| `flow_state` | 0.10 | in-flow score |
| `error_avoidance` | 0.10 | `1 - error_rate * 2` |
| `homeostatic_balance` | 0.05 | system stability |

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

MIT
