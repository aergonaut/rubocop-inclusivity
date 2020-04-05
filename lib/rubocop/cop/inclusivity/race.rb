# frozen_string_literal: true

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
      class Race < Cop
        MSG = "`%s` may be insensitive. Consider alternatives: %s"

        def on_lvasgn(node)
          name, = *node
          return unless name

          check_name(node, name, node.loc.name)
        end
        alias on_ivasgn on_lvasgn
        alias on_cvasgn on_lvasgn
        alias on_arg on_lvasgn
        alias on_optarg on_lvasgn
        alias on_restarg on_lvasgn
        alias on_kwoptarg on_lvasgn
        alias on_kwarg on_lvasgn
        alias on_kwrestarg on_lvasgn
        alias on_blockarg on_lvasgn
        alias on_lvar on_lvasgn

        private

        def check_name(node, name, name_range)
          if (alternatives = preferred_language(name))
            msg = message(name, alternatives)
            add_offense(node, location: name_range, message: msg)
          end
        end

        def preferred_language(word)
          cop_config["Offenses"][word.to_s.downcase]
        end

        def message(insensitive, alternatives)
          format(MSG, insensitive, alternatives.join(", "))
        end
      end
    end
  end
end
