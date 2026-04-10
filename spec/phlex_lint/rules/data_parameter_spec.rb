# frozen_string_literal: true

require "spec_helper"
require "phlex_lint/rules/data_parameter"

RSpec.describe PhlexLint::Rules::DataParameter do
  def violations_for(source)
    tree = PhlexLint::Parser.parse_source(source)
    rule = described_class.new(file_path: "app/components/test.rb")
    rule.check(tree)
    rule.violations
  end

  it "flags any component using additional_data_attrs:" do
    violations = violations_for(<<~RUBY)
      def view_template
        Button(text: "Save", variant: :primary, additional_data_attrs: { controller: "form" })
      end
    RUBY

    expect(violations.count).to eq(1)
    expect(violations.first.message).to include("additional_data_attrs")
    expect(violations.first.message).to include("data:")
  end

  it "flags any component using data_attributes:" do
    violations = violations_for(<<~RUBY)
      def view_template
        Modal(id: "confirm", data_attributes: { action: "click->modal#open" })
      end
    RUBY

    expect(violations.count).to eq(1)
    expect(violations.first.message).to include("data_attributes")
  end

  it "flags a non-standard component using additional_data_attrs:" do
    violations = violations_for(<<~RUBY)
      def view_template
        GlassCard(additional_data_attrs: { turbo_frame: "content" }) { "hello" }
      end
    RUBY

    expect(violations.count).to eq(1)
  end

  it "flags both deprecated params when both appear in file" do
    violations = violations_for(<<~RUBY)
      def view_template
        Button(text: "A", variant: :primary, additional_data_attrs: { x: 1 })
        Modal(id: "m", data_attributes: { y: 2 })
      end
    RUBY

    expect(violations.count).to eq(2)
  end

  it "does not flag component using data:" do
    violations = violations_for(<<~RUBY)
      def view_template
        Button(text: "Save", variant: :primary, data: { controller: "form" })
      end
    RUBY

    expect(violations).to be_empty
  end

  it "does not flag component with no data kwargs" do
    violations = violations_for(<<~RUBY)
      def view_template
        Button(text: "Save", variant: :primary)
      end
    RUBY

    expect(violations).to be_empty
  end
end
