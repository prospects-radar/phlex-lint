# frozen_string_literal: true

module PhlexLint
  module Rules
    # Detect raw span/div elements with score-badge class.
    #
    # Raw `span(class: "score-badge ...")` elements bypass the ScoreBadge
    # component, which handles colour thresholds, accessibility labels, and
    # the Dutch naming scale automatically.
    #
    # @example Bad
    #   span(class: "score-badge score-badge--high") { "82" }
    #   div(class: "score-badge") { score }
    #
    # @example Good
    #   ScoreBadge(score: 82)
    class UseRealScoreBadge < Rule
      category "DesignSystem"

      MESSAGE = "Use ScoreBadge(score: ...) component instead of raw span/div with score-badge class."

      def check(tree)
        %i[span div].each do |tag|
          tree.each_node(tag) do |node|
            class_val = node.kwarg(:class)
            next unless class_val.is_a?(String)
            next unless class_val.match?(/\bscore-badge\b/)

            violation(node, MESSAGE)
          end
        end
      end
    end
  end
end
