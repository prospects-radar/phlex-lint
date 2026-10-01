# frozen_string_literal: true

require "spec_helper"

RSpec.describe PhlexLint::Rules::NoDeprecatedMutedDarkColor do
  def violations_for(source)
    tree = PhlexLint::Parser.parse_source(source)
    return [] unless tree

    rule = described_class.new(file_path: "test.rb")
    rule.check(tree)
    rule.violations
  end

  it "flags Span with color: :muted_dark" do
    violations = violations_for(<<~RUBY)
      def view_template
        Span(color: :muted_dark) { label }
      end
    RUBY

    expect(violations).not_to be_empty
    expect(violations.first.message).to include("tone: :dark")
    expect(violations.first.message).to include("Span")
  end

  it "flags Text with color: :muted_dark" do
    violations = violations_for(<<~RUBY)
      def view_template
        Text(content: body, color: :muted_dark)
      end
    RUBY

    expect(violations).not_to be_empty
    expect(violations.first.message).to include("Text")
  end

  it "flags Paragraph with color: :muted_dark" do
    violations = violations_for(<<~RUBY)
      def view_template
        Paragraph(text: note, color: :muted_dark, size: :sm)
      end
    RUBY

    expect(violations).not_to be_empty
    expect(violations.first.message).to include("Paragraph")
  end

  it "does not flag Span with tone: :dark" do
    violations = violations_for(<<~RUBY)
      def view_template
        Span(tone: :dark) { label }
      end
    RUBY

    expect(violations).to be_empty
  end

  it "does not flag Span with other valid color" do
    violations = violations_for(<<~RUBY)
      def view_template
        Span(color: :primary) { label }
      end
    RUBY

    expect(violations).to be_empty
  end

  it "does not flag components that don't support the color API" do
    violations = violations_for(<<~RUBY)
      def view_template
        GlassCard(color: :muted_dark) { content }
      end
    RUBY

    expect(violations).to be_empty
  end
end
