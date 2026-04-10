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

    def rule_name
      rule_class&.name&.split("::")&.last || "Unknown"
    end

    def qualified_rule_name
      rule_class&.qualified_name || rule_name
    end

    def documentation_url
      rule_class&.documentation_url
    end

    # Check if this violation is disabled via a skip annotation comment.
    def disabled?
      return false unless parser && line

      parser.disabled_at?(line, rule_name)
    end

    def to_s
      "#{file_path}:#{line}:#{column}: [phlex-lint:#{qualified_rule_name}] #{message}"
    end

    def to_s_with_docs
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

      correction.apply
    end
  end
end
