# frozen_string_literal: true

require "spec_helper"

RSpec.describe PhlexLint::Rules::StatCardRequiresVariant do
  def violations_for(source)
    tree = PhlexLint::Parser.parse_source(source)
    rule = described_class.new(file_path: "app/components/test.rb")
    rule.check(tree)
    rule.violations
  end

  it "flags StatCard without variant: kwarg" do
    violations = violations_for(<<~RUBY)
      def view_template
        StatCard(label: t("stats.connections"), value: "42", icon: "people")
      end
    RUBY

    expect(violations.count).to eq(1)
    expect(violations.first.message).to include("variant:")
  end

  it "does not flag StatCard with variant: :info" do
    violations = violations_for(<<~RUBY)
      def view_template
        StatCard(label: t("stats.connections"), value: "42", icon: "people", variant: :info)
      end
    RUBY

    expect(violations).to be_empty
  end

  it "does not flag StatCard with variant: :success" do
    violations = violations_for(<<~RUBY)
      def view_template
        StatCard(label: t("stats.synced"), value: "10", icon: "check-circle-fill", variant: :success)
      end
    RUBY

    expect(violations).to be_empty
  end

  it "does not flag StatCard with variant: :default (explicit choice)" do
    violations = violations_for(<<~RUBY)
      def view_template
        StatCard(label: t("stats.last_sync"), value: "Never", icon: "clock", variant: :default)
      end
    RUBY

    expect(violations).to be_empty
  end

  it "flags multiple StatCards missing variant" do
    violations = violations_for(<<~RUBY)
      def view_template
        FlexRow(gap: :md) do
          StatCard(label: t("stats.a"), value: "1")
          StatCard(label: t("stats.b"), value: "2")
        end
      end
    RUBY

    expect(violations.count).to eq(2)
  end
end
