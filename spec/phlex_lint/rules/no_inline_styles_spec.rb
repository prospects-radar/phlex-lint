# frozen_string_literal: true

require "spec_helper"

RSpec.describe PhlexLint::Rules::NoInlineStyles do
  def check(source)
    tree = PhlexLint::Parser.parse_source(source)
    return [] unless tree

    rule = described_class.new(file_path: "test.rb")
    rule.check(tree)
    rule.violations
  end

  it "flags a raw HTML element with a string style: kwarg" do
    violations = check(<<~RUBY)
      def view_template
        div(style: "margin-top: 16px")
      end
    RUBY

    expect(violations.count).to eq(1)
    expect(violations.first.message).to include("inline style")
  end

  it "flags a component with a string style: kwarg" do
    violations = check(<<~RUBY)
      def view_template
        GlassCard(style: "border: 1px solid red")
      end
    RUBY

    expect(violations.count).to eq(1)
  end

  it "flags multiple nodes with inline styles" do
    violations = check(<<~RUBY)
      def view_template
        div(style: "color: blue") do
          span(style: "font-weight: bold")
        end
      end
    RUBY

    expect(violations.count).to eq(2)
  end

  it "does not flag a node without style: kwarg" do
    violations = check(<<~RUBY)
      def view_template
        div(class: "gm-card")
      end
    RUBY

    expect(violations).to be_empty
  end

  it "does not flag a dynamic style: value" do
    violations = check(<<~RUBY)
      def view_template
        div(style: computed_style)
      end
    RUBY

    expect(violations).to be_empty
  end

  it "does not flag nodes with only class: kwargs" do
    violations = check(<<~RUBY)
      def view_template
        FlexRow(gap: :md) do
          Button(variant: :primary, text: "Save")
        end
      end
    RUBY

    expect(violations).to be_empty
  end
end
