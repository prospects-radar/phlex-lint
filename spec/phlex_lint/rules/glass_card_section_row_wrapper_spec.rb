# frozen_string_literal: true

require "spec_helper"

RSpec.describe PhlexLint::Rules::GlassCardSectionRowWrapper do
  def violations_for(source, file_path: "app/components/test.rb")
    tree = PhlexLint::Parser.parse_source(source)
    rule = described_class.new(file_path:)
    rule.check(tree)
    rule.violations
  end

  it "flags GlassCard(variant: :section) without row_wrapper: false" do
    violations = violations_for(<<~RUBY)
      def view_template
        GlassCard(variant: :section, icon: "info-circle-fill", title: "Title") do
          FlexColumn(gap: :md) { }
        end
      end
    RUBY

    expect(violations.count).to eq(1)
    expect(violations.first.message).to include("row_wrapper: false")
  end

  it "does not flag GlassCard(variant: :section) when row_wrapper: false is present" do
    violations = violations_for(<<~RUBY)
      def view_template
        GlassCard(variant: :section, icon: "info-circle-fill", title: "Title", row_wrapper: false) do
          FlexColumn(gap: :md) { }
        end
      end
    RUBY

    expect(violations).to be_empty
  end

  it "does not flag GlassCard without variant: :section" do
    violations = violations_for(<<~RUBY)
      def view_template
        GlassCard(padding: :md) do
          FlexColumn(gap: :md) { }
        end
      end
    RUBY

    expect(violations).to be_empty
  end

  it "does not flag GlassCard(variant: :glass)" do
    violations = violations_for(<<~RUBY)
      def view_template
        GlassCard(variant: :glass) do
        end
      end
    RUBY

    expect(violations).to be_empty
  end

  it "flags a GlassCard(variant: :section) inside a helper method" do
    violations = violations_for(<<~RUBY)
      def view_template
        PageContainer do
          render_section
        end
      end

      def render_section
        GlassCard(variant: :section, icon: "info-circle-fill", title: "Info") do
          FlexColumn(gap: :md) { }
        end
      end
    RUBY

    expect(violations.count).to eq(1)
  end

  it "does not flag when row_wrapper: false is in a helper's GlassCard" do
    violations = violations_for(<<~RUBY)
      def view_template
        PageContainer do
          render_section
        end
      end

      def render_section
        GlassCard(variant: :section, icon: "info-circle-fill", title: "Info", row_wrapper: false) do
          FlexColumn(gap: :md) { }
        end
      end
    RUBY

    expect(violations).to be_empty
  end

  it "flags multiple GlassCard(variant: :section) violations in one file" do
    violations = violations_for(<<~RUBY)
      def view_template
        PageContainer do
          GlassCard(variant: :section, title: "One") do
          end
          GlassCard(variant: :section, title: "Two") do
          end
        end
      end
    RUBY

    expect(violations.count).to eq(2)
  end
end
