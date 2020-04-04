# frozen_string_literal: true

require 'rubocop'

require_relative 'rubocop/inclusivity'
require_relative 'rubocop/inclusivity/version'
require_relative 'rubocop/inclusivity/inject'

RuboCop::Inclusivity::Inject.defaults!

require_relative 'rubocop/cop/inclusivity_cops'
