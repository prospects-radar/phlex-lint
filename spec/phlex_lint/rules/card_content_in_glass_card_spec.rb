# frozen_string_literal: true

require "spec_helper"

RSpec.describe PhlexLint::Rules::CardContentInGlassCard do
  def violations_for(source, file_path: "app/components/test.rb")
    tree = PhlexLint::Parser.parse_source(source)
    rule = described_class.new(file_path:)
    rule.check(tree)
    rule.violations
  end

  it "flags CardContent as a direct child of GlassCard" do
    violations = violations_for(<<~RUBY)
      def view_template
        GlassCard(padding: :md) do
          CardContent do
            FlexColumn(gap: :md) { }
          end
        end
      end
    RUBY

    expect(violations.count).to eq(1)
    expect(violations.first.message).to include("GlassCard(variant: :section")
  end

  it "does not flag CardContent outside a GlassCard" do
    violations = violations_for(<<~RUBY)
      def view_template
        PageContainer do
          CardContent do
            FlexColumn(gap: :md) { }
          end
        end
      end
    RUBY

    expect(violations).to be_empty
  end

  it "does not flag CardContent as a grandchild of GlassCard (only direct children)" do
    violations = violations_for(<<~RUBY)
      def view_template
        GlassCard(variant: :section, row_wrapper: false) do
          FlexColumn(gap: :md) do
            CardContent do
            end
          end
        end
      end
    RUBY

    # CardContent is a grandchild of GlassCard, not a direct child
    expect(violations).to be_empty
  end

  it "flags CardContent expanded from a helper method" do
    violations = violations_for(<<~RUBY)
      def view_template
        GlassCard(padding: :md) do
          render_body
        end
      end

      def render_body
        CardContent do
          FlexColumn(gap: :md) { }
        end
      end
    RUBY

    expect(violations.count).to eq(1)
  end

  it "flags multiple CardContent children in the same GlassCard" do
    violations = violations_for(<<~RUBY)
      def view_template
        GlassCard(padding: :md) do
          CardContent do
          end
          CardContent do
          end
        end
      end
    RUBY

    expect(violations.count).to eq(2)
  end

  it "flags CardContent in multiple GlassCards" do
    violations = violations_for(<<~RUBY)
      def view_template
        PageContainer do
          GlassCard(padding: :md) do
            CardContent do
            end
          end
          GlassCard(variant: :glass) do
            CardContent do
            end
          end
        end
      end
    RUBY

    expect(violations.count).to eq(2)
  end

  it "does not flag GlassCard(variant: :section) with no CardContent" do
    violations = violations_for(<<~RUBY)
      def view_template
        GlassCard(variant: :section, row_wrapper: false, icon: "info-circle-fill", title: "Info") do
          FlexColumn(gap: :md) do
            Text(content: "hello", size: :sm)
          end
        end
      end
    RUBY

    expect(violations).to be_empty
  end
end
