# frozen_string_literal: true

require "active_support"

# https://github.com/rubocop-hq/rubocop-ast/blob/5cd306f40e5d5ba4dacf78c698354747cdac7825/docs/modules/ROOT/pages/node_types.adoc

module RuboCop
  module Cop
    module Inclusivity
      # Detects potentially insensitive langugae used in variable names and
      # suggests alternatives that promote inclusivity.
      #
      # The `Offenses` config parameter can be used to configure the cop with
      # your list of insensitive words.
      #
      # @example Using insensitive language
      #   # bad
      #   blacklist = 1
      #
      #   # good
      #   banlist = 1
      #
      class Race < Base
        extend AutoCorrector
        include ActiveSupport::Inflector

        ALLOWLIST = "Allowlist"
        OFFENSES = "Offenses"
        DOUBLE_QUOTE = "\""
        MSG = "`%s` may be insensitive. Consider alternatives: %s"
        PARTIAL = "partial"
        SINGLE_QUOTE = "'"
        SYMBOL = ":"
        UTF_8 = "UTF-8"

        def simple_substitution(node)
          name, = *node
          name && check(node.loc.name, name)
        end
        alias on_lvasgn simple_substitution
        alias on_ivasgn simple_substitution
        alias on_cvasgn simple_substitution
        alias on_arg simple_substitution
        alias on_optarg simple_substitution
        alias on_restarg simple_substitution
        alias on_kwoptarg simple_substitution
        alias on_kwarg simple_substitution
        alias on_kwrestarg simple_substitution
        alias on_blockarg simple_substitution
        alias on_lvar simple_substitution
        alias on_cvar simple_substitution

        def on_casgn(node)
          _parent, constant_name, _value = *node
          check(node.loc.name, constant_name) { |alternative| alternative.upcase }
        end

        def on_sym(node)
          name, = *node
          check(node.source_range, name) { |replacement| node.source[0] == SYMBOL ? ":#{replacement}" : replacement }
        end

        def on_str(node)
          name, = *node
          check(node.source_range, name) do |replacement|
            quote = determine_quote(node.source)
            "#{quote}#{replacement.downcase}#{quote}"
          end
        end

        def on_def(node)
          name, _args, _forward_args = *node
          check(node.loc.name, name)
        end

        def on_send(node)
          match_methods_and_variables(node) do |variable_name|
            check(node.loc.selector, variable_name.to_s.delete_suffix("="))
          end
        end

        def on_const(node)
          match_consts(node) do |const_name|
            check(node.loc.name, const_name)
          end
        end

        private

        def_node_matcher :match_methods_and_variables, <<~PATTERN
          (send _ $_ ...)
        PATTERN

        def_node_matcher :match_consts, <<~PATTERN
          (const ... $_)
        PATTERN

        def determine_quote(source)
          return SINGLE_QUOTE if source[0] == SINGLE_QUOTE
          DOUBLE_QUOTE if source[0] == DOUBLE_QUOTE
        end

        def check(range, input)
          string = input.to_s.encode(Encoding.find(UTF_8), invalid: :replace, undef: :replace, replace: "")
          alternatives = preferred_language(string)
          return unless alternatives

          add_offense(range, message: format(MSG, string, alternatives.join(", "))) do |corrector|
            replacement = block_given? ? yield(alternatives.first) : alternatives.first
            corrector.replace(range, replacement)
          end
        end

        def preferred_language(word)
          exclusive_language_matcher.match(word) do |match|
            next if allow?(word)

            offense = match[0].downcase
            alternatives = cop_config["Offenses"].fetch(offense)
            matcher = %r{#{offense}}i

            alternatives.map do |alternative|
              word.to_s.gsub(matcher) { |match| replace_match(match, alternative) }
            end
          end
        end

        def on_new_investigation
          processed_source.comments.each do |comment|
            start_position = comment.location.expression.to_range.first
            comment.text.split(" ").each do |word|
              alternatives = preferred_language(word)
              next unless alternatives

              buffer = @processed_source.buffer
              end_position = start_position + word.to_s.size
              range = Parser::Source::Range.new(buffer, start_position, end_position)
              add_offense(range, message: format(MSG, word.to_s, alternatives.join(", "))) do |corrector|
                corrector.replace(range, alternatives.first)
              end
            ensure
              start_position += word.size + 1
            end
          end
        end

        def replace_match(word, alternative)
          normalized_alternative = alternative.downcase
          return normalized_alternative if word.downcase == word
          return normalized_alternative.upcase if word.upcase == word
          return underscore(normalized_alternative) if underscore(word) == word
          return camelize(normalized_alternative) if camelize(word) == word
          return camelize(normalized_alternative, false) if camelize(word, false) == word
          word
        end

        def allow?(text)
          allowlist.any? do |(allow, config)|
            config.fetch(PARTIAL, false) ? text.to_s.match(%r{#{allow}}i) : text.to_s.downcase == allow.to_s.downcase
          end
        end

        def allowlist
          @_allowlist ||= cop_config[ALLOWLIST] || {}
        end

        def exclusive_language_matcher
          @_exclusive_language_matcher ||= %r{(#{cop_config[OFFENSES].keys.join("|")})}i
        end
      end
    end
  end
end
