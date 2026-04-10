# frozen_string_literal: true

require "spec_helper"
require "phlex_lint/rules/glass_card_variant"

RSpec.describe PhlexLint::Rules::GlassCardVariant do
  def violations_for(source)
    tree = PhlexLint::Parser.parse_source(source)
    rule = described_class.new(file_path: "app/components/test.rb")
    rule.check(tree)
    rule.violations
  end

  it "flags GlassCard with invalid variant: :primary" do
    violations = violations_for(<<~RUBY)
      def view_template
        GlassCard(variant: :primary) { "content" }
      end
    RUBY

    expect(violations.count).to eq(1)
    expect(violations.first.message).to include(":primary")
  end

  it "flags GlassCard with invalid variant: :dark" do
    violations = violations_for(<<~RUBY)
      def view_template
        GlassCard(variant: :dark) { "content" }
      end
    RUBY

    expect(violations.count).to eq(1)
    expect(violations.first.message).to include(":dark")
  end

  it "flags GlassCard with invalid variant: :default" do
    violations = violations_for(<<~RUBY)
      def view_template
        GlassCard(variant: :default) { "content" }
      end
    RUBY

    expect(violations.count).to eq(1)
  end

  it "does not flag GlassCard with valid variant: :glass" do
    violations = violations_for(<<~RUBY)
      def view_template
        GlassCard(variant: :glass) { "content" }
      end
    RUBY

    expect(violations).to be_empty
  end

  it "does not flag GlassCard with valid variant: :solid" do
    violations = violations_for(<<~RUBY)
      def view_template
        GlassCard(variant: :solid) { "content" }
      end
    RUBY

    expect(violations).to be_empty
  end

  it "does not flag GlassCard with valid variant: :section" do
    violations = violations_for(<<~RUBY)
      def view_template
        GlassCard(variant: :section) { "content" }
      end
    RUBY

    expect(violations).to be_empty
  end

  it "does not flag GlassCard with valid variant: :elevated" do
    violations = violations_for(<<~RUBY)
      def view_template
        GlassCard(variant: :elevated) { "content" }
      end
    RUBY

    expect(violations).to be_empty
  end

  it "does not flag GlassCard without variant" do
    violations = violations_for(<<~RUBY)
      def view_template
        GlassCard(title: "My Card") { "content" }
      end
    RUBY

    expect(violations).to be_empty
  end

  it "does not flag GlassCard with dynamic variant value" do
    violations = violations_for(<<~RUBY)
      def view_template
        GlassCard(variant: card_variant) { "content" }
      end
    RUBY

    expect(violations).to be_empty
  end
end
