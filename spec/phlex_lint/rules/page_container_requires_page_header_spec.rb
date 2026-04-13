# frozen_string_literal: true

require "spec_helper"
require "phlex_lint"

RSpec.describe PhlexLint::Rules::PageContainerRequiresPageHeader do
  def violations_for(source)
    tree = PhlexLint::Parser.parse_source(source)
    rule = described_class.new(file_path: "app/components/test.rb")
    rule.check(tree)
    rule.violations
  end

  it "flags PageContainer without a PageHeader inside" do
    violations = violations_for(<<~RUBY)
      def view_template
        PageContainer do
          FlexColumn(gap: :lg) do
            GlassCard { "content" }
          end
        end
      end
    RUBY

    expect(violations.count).to eq(1)
    expect(violations.first.message).to include("PageHeader")
  end

  it "does not flag PageContainer with a direct PageHeader child" do
    violations = violations_for(<<~RUBY)
      def view_template
        PageContainer do
          PageHeader(title: "My Page")
          GlassCard { "content" }
        end
      end
    RUBY

    expect(violations).to be_empty
  end

  it "does not flag PageContainer with PageHeader nested inside" do
    violations = violations_for(<<~RUBY)
      def view_template
        PageContainer do
          FlexColumn(gap: :lg) do
            PageHeader(title: "My Page")
            GlassCard { "content" }
          end
        end
      end
    RUBY

    expect(violations).to be_empty
  end

  it "does not flag code with no PageContainer" do
    violations = violations_for(<<~RUBY)
      def view_template
        FlexColumn(gap: :lg) do
          GlassCard { "content" }
        end
      end
    RUBY

    expect(violations).to be_empty
  end

  it "flags each PageContainer that lacks a PageHeader" do
    violations = violations_for(<<~RUBY)
      def view_template
        PageContainer do
          GlassCard { "first" }
        end
        PageContainer do
          GlassCard { "second" }
        end
      end
    RUBY

    expect(violations.count).to eq(2)
  end
end
