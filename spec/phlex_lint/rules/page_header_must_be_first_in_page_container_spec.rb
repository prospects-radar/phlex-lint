# frozen_string_literal: true

require "spec_helper"

RSpec.describe PhlexLint::Rules::PageHeaderMustBeFirstInPageContainer do
  def violations_for(source)
    tree = PhlexLint::Parser.parse_source(source)
    rule = described_class.new(file_path: "app/components/test.rb")
    rule.check(tree)
    rule.violations
  end

  it "flags PageHeader when a GlassCard precedes it in PageContainer" do
    violations = violations_for(<<~RUBY)
      def view_template
        PageContainer do
          GlassCard(variant: :section, icon: "gear", title: t("section"), row_wrapper: false) do
          end
          PageHeader(title: t("page.title"))
        end
      end
    RUBY

    expect(violations.count).to eq(1)
    expect(violations.first.message).to include("PageHeader")
    expect(violations.first.message).to include("GlassCard")
  end

  it "does not flag PageHeader when it is the first child" do
    violations = violations_for(<<~RUBY)
      def view_template
        PageContainer do
          PageHeader(title: t("page.title"))
          GlassCard(variant: :section, icon: "gear", title: t("section"), row_wrapper: false) do
          end
        end
      end
    RUBY

    expect(violations).to be_empty
  end

  it "does not flag PageHeader when Breadcrumb precedes it" do
    violations = violations_for(<<~RUBY)
      def view_template
        PageContainer do
          Breadcrumb(items: [{ label: t("home"), href: "/" }])
          PageHeader(title: t("page.title"))
          GlassCard(variant: :section, icon: "gear", title: t("section"), row_wrapper: false) do
          end
        end
      end
    RUBY

    expect(violations).to be_empty
  end

  it "does not flag PageContainer with no PageHeader" do
    violations = violations_for(<<~RUBY)
      def view_template
        PageContainer do
          GlassCard(variant: :section, icon: "gear", title: t("section"), row_wrapper: false) do
          end
        end
      end
    RUBY

    expect(violations).to be_empty
  end

  it "flags when both Breadcrumb and another element precede PageHeader" do
    violations = violations_for(<<~RUBY)
      def view_template
        PageContainer do
          Breadcrumb(items: [])
          GlassCard(padding: :md) { }
          PageHeader(title: t("page.title"))
        end
      end
    RUBY

    expect(violations.count).to eq(1)
    expect(violations.first.message).to include("GlassCard")
  end
end
