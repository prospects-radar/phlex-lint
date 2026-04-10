# frozen_string_literal: true

require "spec_helper"
require "phlex_lint/rules/no_legacy_new_ui_reference"

RSpec.describe PhlexLint::Rules::NoLegacyNewUiReference do
  def violations_for(source)
    tree = PhlexLint::Parser.parse_source(source)
    rule = described_class.new(file_path: "app/components/test.rb")
    rule.check(tree)
    rule.violations
  end

  it "flags component whose name contains NewUi" do
    violations = violations_for(<<~RUBY)
      def view_template
        NewUiCard(title: "Settings")
      end
    RUBY

    expect(violations.count).to eq(1)
    expect(violations.first.message).to include("GlassMorph")
    expect(violations.first.message).to include("NewUi")
  end

  it "flags component whose name contains NewUi (capitalized variant)" do
    violations = violations_for(<<~RUBY)
      def view_template
        MyNewUiCard(title: "Legacy")
      end
    RUBY

    expect(violations.count).to eq(1)
  end

  it "flags component with class: containing new-ui" do
    violations = violations_for(<<~RUBY)
      def view_template
        SomeWidget(class: "new-ui-card mt-2")
      end
    RUBY

    expect(violations.count).to eq(1)
  end

  it "flags component with class: containing new_ui" do
    violations = violations_for(<<~RUBY)
      def view_template
        SomeWidget(class: "wrapper new_ui container")
      end
    RUBY

    expect(violations.count).to eq(1)
  end

  it "flags component with class: containing NEW-UI (case insensitive)" do
    violations = violations_for(<<~RUBY)
      def view_template
        SomeWidget(class: "NEW-UI legacy")
      end
    RUBY

    expect(violations.count).to eq(1)
  end

  it "does not flag GlassMorph components" do
    violations = violations_for(<<~RUBY)
      def view_template
        GlassCard(variant: :glass) { "content" }
      end
    RUBY

    expect(violations).to be_empty
  end

  it "does not flag components with unrelated class strings" do
    violations = violations_for(<<~RUBY)
      def view_template
        SomeWidget(class: "mt-2 mb-4 text-muted")
      end
    RUBY

    expect(violations).to be_empty
  end

  it "does not flag class: string that contains 'new' but not 'new-ui' or 'new_ui'" do
    violations = violations_for(<<~RUBY)
      def view_template
        SomeWidget(class: "new-item-badge mt-1")
      end
    RUBY

    expect(violations).to be_empty
  end

  it "does not flag components without class or matching name" do
    violations = violations_for(<<~RUBY)
      def view_template
        Button(text: "Save", variant: :primary)
      end
    RUBY

    expect(violations).to be_empty
  end
end
