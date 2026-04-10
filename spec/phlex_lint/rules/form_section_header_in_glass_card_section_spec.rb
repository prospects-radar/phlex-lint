# frozen_string_literal: true

require "spec_helper"

RSpec.describe PhlexLint::Rules::FormSectionHeaderInGlassCardSection do
  def violations_for(source)
    tree = PhlexLint::Parser.parse_source(source)
    rule = described_class.new(file_path: "app/components/test.rb")
    rule.check(tree)
    rule.violations
  end

  it "flags FormSectionHeader as a direct child of GlassCard(variant: :section)" do
    violations = violations_for(<<~RUBY)
      def view_template
        GlassCard(variant: :section, icon: "gear", title: t("section"), row_wrapper: false) do
          FormSectionHeader(title: t("sub_section"))
          FlexColumn(gap: :md) { }
        end
      end
    RUBY

    expect(violations.count).to eq(1)
    expect(violations.first.message).to include("duplicate header")
  end

  it "flags FormSectionHeader nested deeper inside GlassCard(variant: :section)" do
    violations = violations_for(<<~RUBY)
      def view_template
        GlassCard(variant: :section, icon: "gear", title: t("section"), row_wrapper: false) do
          FlexColumn(gap: :md) do
            FormSectionHeader(title: t("sub"))
          end
        end
      end
    RUBY

    expect(violations.count).to eq(1)
  end

  it "does not flag FormSectionHeader inside GlassCard(variant: :glass)" do
    violations = violations_for(<<~RUBY)
      def view_template
        GlassCard(variant: :glass) do
          FormSectionHeader(title: t("section"))
          FlexColumn(gap: :md) { }
        end
      end
    RUBY

    expect(violations).to be_empty
  end

  it "does not flag FormSectionHeader outside a GlassCard" do
    violations = violations_for(<<~RUBY)
      def view_template
        PageContainer do
          FormSectionHeader(title: t("section"))
        end
      end
    RUBY

    expect(violations).to be_empty
  end

  it "flags FormSectionHeader expanded from a helper inside GlassCard(variant: :section)" do
    violations = violations_for(<<~RUBY)
      def view_template
        GlassCard(variant: :section, icon: "gear", title: t("section"), row_wrapper: false) do
          render_sub_section
        end
      end

      def render_sub_section
        FormSectionHeader(title: t("sub"))
        FlexColumn(gap: :md) { }
      end
    RUBY

    expect(violations.count).to eq(1)
  end
end
