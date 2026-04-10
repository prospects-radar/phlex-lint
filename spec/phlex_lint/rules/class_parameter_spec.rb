# frozen_string_literal: true

require "spec_helper"
require "phlex_lint/rules/class_parameter"

RSpec.describe PhlexLint::Rules::ClassParameter do
  def violations_for(source)
    tree = PhlexLint::Parser.parse_source(source)
    rule = described_class.new(file_path: "app/components/test.rb")
    rule.check(tree)
    rule.violations
  end

  it "flags Button using css_class:" do
    violations = violations_for(<<~RUBY)
      def view_template
        Button(text: "Save", variant: :primary, css_class: "mt-2")
      end
    RUBY

    expect(violations.count).to eq(1)
    expect(violations.first.message).to include("css_class:")
    expect(violations.first.message).to include("class:")
  end

  it "flags GlassCard using css_class:" do
    violations = violations_for(<<~RUBY)
      def view_template
        GlassCard(css_class: "mb-4") { "content" }
      end
    RUBY

    expect(violations.count).to eq(1)
  end

  it "flags any arbitrary component using css_class:" do
    violations = violations_for(<<~RUBY)
      def view_template
        SomeWidget(label: "test", css_class: "custom-style")
      end
    RUBY

    expect(violations.count).to eq(1)
  end

  it "flags multiple components using css_class: in one file" do
    violations = violations_for(<<~RUBY)
      def view_template
        Button(text: "A", variant: :primary, css_class: "mt-1")
        GlassCard(css_class: "mb-2") { "b" }
      end
    RUBY

    expect(violations.count).to eq(2)
  end

  it "does not flag component using class:" do
    violations = violations_for(<<~RUBY)
      def view_template
        Button(text: "Save", variant: :primary, class: "mt-2")
      end
    RUBY

    expect(violations).to be_empty
  end

  it "does not flag component with no class kwargs" do
    violations = violations_for(<<~RUBY)
      def view_template
        Button(text: "Save", variant: :primary)
      end
    RUBY

    expect(violations).to be_empty
  end
end
