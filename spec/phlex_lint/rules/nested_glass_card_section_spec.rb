# frozen_string_literal: true

require "spec_helper"

RSpec.describe PhlexLint::Rules::NestedGlassCardSection do
  def violations_for(source)
    tree = PhlexLint::Parser.parse_source(source)
    rule = described_class.new(file_path: "app/components/test.rb")
    rule.check(tree)
    rule.violations
  end

  it "flags GlassCard(variant: :section) nested inside another GlassCard" do
    violations = violations_for(<<~RUBY)
      def view_template
        GlassCard(variant: :section, icon: "gear", title: t("outer"), row_wrapper: false) do
          GlassCard(variant: :section, icon: "info-circle-fill", title: t("inner"), row_wrapper: false) do
          end
        end
      end
    RUBY

    expect(violations.count).to eq(1)
    expect(violations.first.message).to include("section")
  end

  it "does not flag GlassCard(variant: :glass) inside GlassCard(variant: :section)" do
    violations = violations_for(<<~RUBY)
      def view_template
        GlassCard(variant: :section, icon: "gear", title: t("outer"), row_wrapper: false) do
          GlassCard(variant: :glass) do
          end
        end
      end
    RUBY

    expect(violations).to be_empty
  end

  it "does not flag top-level GlassCard(variant: :section)" do
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

  it "flags GlassCard(variant: :section) inside GlassCard(variant: :glass)" do
    violations = violations_for(<<~RUBY)
      def view_template
        GlassCard(variant: :glass) do
          GlassCard(variant: :section, icon: "info-circle-fill", title: t("inner"), row_wrapper: false) do
          end
        end
      end
    RUBY

    expect(violations.count).to eq(1)
  end
end
