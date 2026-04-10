# frozen_string_literal: true

require "spec_helper"

RSpec.describe PhlexLint::Rules::AlertBannerInFlexRow do
  def violations_for(source)
    tree = PhlexLint::Parser.parse_source(source)
    rule = described_class.new(file_path: "app/components/test.rb")
    rule.check(tree)
    rule.violations
  end

  it "flags AlertBanner as a direct child of FlexRow" do
    violations = violations_for(<<~RUBY)
      def view_template
        FlexRow(gap: :md, align: :center) do
          Icon(name: "info-circle-fill", size: :sm)
          AlertBanner(icon: "exclamation-triangle-fill", title: t("warning"), variant: :warning)
        end
      end
    RUBY

    expect(violations.count).to eq(1)
    expect(violations.first.message).to include("FlexRow")
  end

  it "does not flag AlertBanner inside FlexColumn" do
    violations = violations_for(<<~RUBY)
      def view_template
        FlexColumn(gap: :md) do
          AlertBanner(icon: "info-circle-fill", title: t("info"), variant: :info)
          FlexRow(gap: :sm) { }
        end
      end
    RUBY

    expect(violations).to be_empty
  end

  it "does not flag AlertBanner as a direct child of GlassCard" do
    violations = violations_for(<<~RUBY)
      def view_template
        GlassCard(variant: :section, icon: "gear", title: t("section"), row_wrapper: false) do
          FlexColumn(gap: :md) do
            AlertBanner(icon: "exclamation-triangle-fill", title: t("warning"), variant: :warning)
          end
        end
      end
    RUBY

    expect(violations).to be_empty
  end

  it "does not flag AlertBanner without any FlexRow ancestor" do
    violations = violations_for(<<~RUBY)
      def view_template
        PageContainer do
          AlertBanner(icon: "info-circle-fill", title: t("info"), variant: :info)
        end
      end
    RUBY

    expect(violations).to be_empty
  end
end
