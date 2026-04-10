# frozen_string_literal: true

module PhlexLint
  module Rules
    # Badge color/variant must use design system tokens, not Bootstrap colors.
    #
    # Bootstrap color names (:primary, :secondary, etc.) are not valid in the
    # GlassMorph design system. Use semantic design tokens instead.
    #
    # @example Bad
    #   Badge(type: :status, color: :primary)
    #   Badge(type: :status, variant: :danger)
    #
    # @example Good
    #   Badge(type: :status, color: :teal)
    #   Badge(type: :status, variant: :green)
    class BadgeValidColor < Rule
      category "ComponentAPI"

      MESSAGE = "Badge color/variant must use design system tokens " \
                "(:slate, :teal, :green, :amber, :red, :blue). " \
                "Got: %<actual>s. Bootstrap colors are not valid."

      VALID_VALUES = %i[slate teal green amber red blue purple orange pink].freeze
      BOOTSTRAP_VALUES = %i[primary secondary success danger warning info light dark].freeze

      def check(tree)
        tree.each_node(:Badge) do |node|
          %i[color variant].each do |kwarg_key|
            next unless node.kwargs.key?(kwarg_key)

            value = node.kwarg(kwarg_key)
            next if value == :__dynamic__ || value == :__interpolated__
            next if VALID_VALUES.include?(value)

            violation(node, format(MESSAGE, actual: value.inspect))
          end
        end
      end
    end
  end
end
