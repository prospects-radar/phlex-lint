# frozen_string_literal: true

require "spec_helper"

RSpec.describe PhlexLint::Rules::NoLegacyTitleClass do
  def violations_for(source)
    tree = PhlexLint::Parser.parse_source(source)
    return [] unless tree

    rule = described_class.new(file_path: "test.rb")
    rule.check(tree)
    rule.violations
  end

  it "flags Heading with prospects-title class" do
    violations = violations_for(<<~RUBY)
      def view_template
        Heading(level: 1, class: "prospects-title") { @title }
      end
    RUBY

    expect(violations).not_to be_empty
    expect(violations.first.message).to include("prospects-title")
  end

  it "flags Heading with pricing-title class" do
    violations = violations_for(<<~RUBY)
      def view_template
        Heading(level: 1, class: "pricing-title") { t(".title") }
      end
    RUBY

    expect(violations).not_to be_empty
    expect(violations.first.message).to include("pricing-title")
  end

  it "flags Heading with value-hero-title class" do
    violations = violations_for(<<~RUBY)
      def view_template
        Heading(level: 1, class: "value-hero-title") { t("dashboard.title") }
      end
    RUBY

    expect(violations).not_to be_empty
    expect(violations.first.message).to include("value-hero-title")
  end

  it "flags Heading with deprecated class among other classes" do
    violations = violations_for(<<~RUBY)
      def view_template
        Heading(level: 1, class: "mb-0 prospects-title") { @title }
      end
    RUBY

    expect(violations).not_to be_empty
  end

  it "does not flag Heading with hero-title class" do
    violations = violations_for(<<~RUBY)
      def view_template
        Heading(level: 1, class: "hero-title") { @title }
      end
    RUBY

    expect(violations).to be_empty
  end

  it "does not flag Heading with no class" do
    violations = violations_for(<<~RUBY)
      def view_template
        Heading(level: 2, color: :dark) { "Section" }
      end
    RUBY

    expect(violations).to be_empty
  end

  it "does not flag Heading with dynamic class" do
    violations = violations_for(<<~RUBY)
      def view_template
        Heading(level: 1, class: computed_class) { @title }
      end
    RUBY

    expect(violations).to be_empty
  end
end
