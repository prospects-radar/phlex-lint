# frozen_string_literal: true

require "spec_helper"
require "phlex_lint/rules/badge_valid_color"

RSpec.describe PhlexLint::Rules::BadgeValidColor do
  def violations_for(source)
    tree = PhlexLint::Parser.parse_source(source)
    rule = described_class.new(file_path: "app/components/test.rb")
    rule.check(tree)
    rule.violations
  end

  it "flags Badge with Bootstrap color: :primary" do
    violations = violations_for(<<~RUBY)
      def view_template
        Badge(type: :status, color: :primary)
      end
    RUBY

    expect(violations.count).to eq(1)
    expect(violations.first.message).to include(":primary")
    expect(violations.first.message).to include("Bootstrap colors are not valid")
  end

  it "flags Badge with Bootstrap variant: :danger" do
    violations = violations_for(<<~RUBY)
      def view_template
        Badge(type: :status, variant: :danger)
      end
    RUBY

    expect(violations.count).to eq(1)
    expect(violations.first.message).to include(":danger")
  end

  it "flags Badge with Bootstrap color: :secondary" do
    violations = violations_for(<<~RUBY)
      def view_template
        Badge(type: :status, color: :secondary)
      end
    RUBY

    expect(violations.count).to eq(1)
  end

  it "flags Badge with Bootstrap color: :success" do
    violations = violations_for(<<~RUBY)
      def view_template
        Badge(type: :status, color: :success)
      end
    RUBY

    expect(violations.count).to eq(1)
  end

  it "does not flag Badge with valid color: :teal" do
    violations = violations_for(<<~RUBY)
      def view_template
        Badge(type: :status, color: :teal)
      end
    RUBY

    expect(violations).to be_empty
  end

  it "does not flag Badge with valid color: :green" do
    violations = violations_for(<<~RUBY)
      def view_template
        Badge(type: :status, color: :green)
      end
    RUBY

    expect(violations).to be_empty
  end

  it "does not flag Badge with valid variant: :amber" do
    violations = violations_for(<<~RUBY)
      def view_template
        Badge(type: :status, variant: :amber)
      end
    RUBY

    expect(violations).to be_empty
  end

  it "does not flag Badge without color or variant" do
    violations = violations_for(<<~RUBY)
      def view_template
        Badge(type: :status, label: "Active")
      end
    RUBY

    expect(violations).to be_empty
  end

  it "does not flag Badge with dynamic color value" do
    violations = violations_for(<<~RUBY)
      def view_template
        Badge(type: :status, color: computed_color)
      end
    RUBY

    expect(violations).to be_empty
  end

  it "does not flag Badge with dynamic variant value" do
    violations = violations_for(<<~RUBY)
      def view_template
        Badge(type: :status, variant: badge_variant)
      end
    RUBY

    expect(violations).to be_empty
  end

  it "flags both color and variant if both are invalid" do
    violations = violations_for(<<~RUBY)
      def view_template
        Badge(type: :status, color: :primary, variant: :danger)
      end
    RUBY

    expect(violations.count).to eq(2)
  end
end
