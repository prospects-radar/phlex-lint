# frozen_string_literal: true

require "spec_helper"

RSpec.describe PhlexLint::Rules::NoStyledParagraphs do
  def violations_for(source)
    tree = PhlexLint::Parser.parse_source(source)
    return [] unless tree

    rule = described_class.new(file_path: "test.rb")
    rule.check(tree)
    rule.violations
  end

  it "flags a p with text-muted class" do
    violations = violations_for(<<~RUBY)
      def view_template
        p(class: "text-muted") { "Helper text" }
      end
    RUBY

    expect(violations).not_to be_empty
    expect(violations.first.message).to include("Paragraph")
  end

  it "flags a p with small class" do
    violations = violations_for(<<~RUBY)
      def view_template
        p(class: "small mb-0") { "Hint" }
      end
    RUBY

    expect(violations).not_to be_empty
  end

  it "flags a p with fs- size utility" do
    violations = violations_for(<<~RUBY)
      def view_template
        p(class: "fs-6") { "Note" }
      end
    RUBY

    expect(violations).not_to be_empty
  end

  it "flags a p with text-light class" do
    violations = violations_for(<<~RUBY)
      def view_template
        p(class: "text-light") { "Subtle" }
      end
    RUBY

    expect(violations).not_to be_empty
  end

  it "does not flag a p with no class" do
    violations = violations_for(<<~RUBY)
      def view_template
        p { "Plain paragraph" }
      end
    RUBY

    expect(violations).to be_empty
  end

  it "does not flag a p with non-text utility classes" do
    violations = violations_for(<<~RUBY)
      def view_template
        p(class: "mb-3 mt-1") { "Spaced paragraph" }
      end
    RUBY

    expect(violations).to be_empty
  end

  it "does not flag a Paragraph component" do
    violations = violations_for(<<~RUBY)
      def view_template
        Paragraph(color: :muted) { "Note" }
      end
    RUBY

    expect(violations).to be_empty
  end

  it "does not flag a p with a dynamic class" do
    violations = violations_for(<<~RUBY)
      def view_template
        p(class: dynamic_classes) { "Dynamic" }
      end
    RUBY

    expect(violations).to be_empty
  end
end
