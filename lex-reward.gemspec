# frozen_string_literal: true

require_relative 'lib/legion/extensions/reward/version'

Gem::Specification.new do |spec|
  spec.name          = 'lex-reward'
  spec.version       = Legion::Extensions::Reward::VERSION
  spec.authors       = ['Matthew Iverson']
  spec.email         = ['matt@legionIO.com']
  spec.summary       = 'Dopaminergic reward signal engine for LegionIO cognitive agents'
  spec.description   = 'Computes internal reward signals from cognitive outcomes, tracks reward prediction error, and drives reinforcement learning'
  spec.homepage      = 'https://github.com/LegionIO/lex-reward'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 3.4'

  spec.files = Dir['lib/**/*']
  spec.require_paths = ['lib']

  spec.metadata['rubygems_mfa_required'] = 'true'
  spec.add_development_dependency 'legion-gaia'
end
