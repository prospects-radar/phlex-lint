# frozen_string_literal: true

module PhlexLint
  # Represents a single rule violation found in a component file.
  Violation = Struct.new(:node, :message, :file_path, :rule_class, :correction, :parser, keyword_init: true) do
    def line
      node.source_node&.loc&.line
    end

    def column
      node.source_node&.loc&.column
    end

    # Returns the qualified name (e.g., "Style/NoInlineStyles") for display.
    def rule_name
      rule_class&.qualified_name || "Unknown"
    end

    # Returns just the short name (e.g., "NoInlineStyles") for disable comment matching.
    def short_rule_name
      rule_class&.short_name || "Unknown"
    end

    def documentation_url
      rule_class&.documentation_url
    end

    def disabled?
      return false unless parser

      # Check both qualified ("Style/NoInlineStyles") and short ("NoInlineStyles") forms
      parser.rule_disabled_at_line?(rule_name, line) ||
        parser.rule_disabled_at_line?(short_rule_name, line)
    end

    def to_s
      return "" if disabled?
      "#{file_path}:#{line}:#{column}: [#{rule_name}] #{message}"
    end

    def to_s_with_docs
      return "" if disabled?
      base = to_s
      docs = documentation_url
      auto_correct = correction ? "✅ auto-correctable" : "⚠️  manual fix"
      parts = [base, auto_correct]
      parts << "📚 Learn more: #{docs}" if docs
      parts.join("\n  ")
    end

    def auto_correctable?
      !correction.nil?
    end

    def apply_correction
      return false unless auto_correctable?
      return false if disabled?

      correction.apply
    end
  end
end
