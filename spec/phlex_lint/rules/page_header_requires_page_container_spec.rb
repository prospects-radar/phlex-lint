# frozen_string_literal: true

require "spec_helper"

RSpec.describe PhlexLint::Rules::PageHeaderRequiresPageContainer do
  def violations_for(source)
    tree = PhlexLint::Parser.parse_source(source)
    rule = described_class.new(file_path: "app/components/test.rb")
    rule.check(tree)
    rule.violations
  end

  it "flags PageHeader without a PageContainer ancestor" do
    violations = violations_for(<<~RUBY)
      def view_template
        FlexColumn(gap: :lg) do
          PageHeader(title: t("page.title"))
        end
      end
    RUBY

    expect(violations.count).to eq(1)
    expect(violations.first.message).to include("PageContainer")
  end

  it "does not flag PageHeader inside PageContainer" do
    violations = violations_for(<<~RUBY)
      def view_template
        PageContainer do
          PageHeader(title: t("page.title"))
        end
      end
    RUBY

    expect(violations).to be_empty
  end

  it "does not flag PageHeader nested deeply inside PageContainer" do
    violations = violations_for(<<~RUBY)
      def view_template
        PageContainer do
          FlexColumn(gap: :lg) do
            PageHeader(title: t("page.title"))
          end
        end
      end
    RUBY

    expect(violations).to be_empty
  end

  it "flags PageHeader at the root level (no wrapper)" do
    violations = violations_for(<<~RUBY)
      def view_template
        PageHeader(title: t("page.title"))
        GlassCard(variant: :section, icon: "gear", title: t("section"), row_wrapper: false) do
        end
      end
    RUBY

    expect(violations.count).to eq(1)
  end

  it "flags PageHeader expanded from a helper without PageContainer" do
    violations = violations_for(<<~RUBY)
      def view_template
        FlexColumn(gap: :lg) do
          render_header
        end
      end

      def render_header
        PageHeader(title: t("page.title"))
      end
    RUBY

    expect(violations.count).to eq(1)
  end
end
