# frozen_string_literal: true

require "spec_helper"

RSpec.describe PhlexLint::Rules::NestedEmptyState do
  def violations_for(source)
    tree = PhlexLint::Parser.parse_source(source)
    rule = described_class.new(file_path: "app/components/test.rb")
    rule.check(tree)
    rule.violations
  end

  it "flags EmptyState nested inside another EmptyState" do
    violations = violations_for(<<~RUBY)
      def view_template
        EmptyState(icon: "inbox", message: t("no_data")) do
          EmptyState(icon: "search", message: t("try_search"))
        end
      end
    RUBY

    expect(violations.count).to eq(1)
    expect(violations.first.message).to include("nested")
  end

  it "does not flag a single EmptyState" do
    violations = violations_for(<<~RUBY)
      def view_template
        PageContainer do
          EmptyState(icon: "inbox", message: t("no_data"))
        end
      end
    RUBY

    expect(violations).to be_empty
  end

  it "does not flag two sibling EmptyStates (inside conditional branches)" do
    violations = violations_for(<<~RUBY)
      def view_template
        PageContainer do
          if @show_first
            EmptyState(icon: "inbox", message: t("no_data"))
          else
            EmptyState(icon: "search", message: t("try_search"))
          end
        end
      end
    RUBY

    expect(violations).to be_empty
  end
end
