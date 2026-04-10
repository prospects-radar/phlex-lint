# frozen_string_literal: true

require "spec_helper"
require "phlex_lint/rules/interactive_aria_required"

RSpec.describe PhlexLint::Rules::InteractiveAriaRequired do
  def violations_for(source)
    tree = PhlexLint::Parser.parse_source(source)
    rule = described_class.new(file_path: "app/components/test.rb")
    rule.check(tree)
    rule.violations
  end

  it "flags Button with icon but no text or aria_label" do
    violations = violations_for(<<~RUBY)
      def view_template
        Button(icon: "trash", variant: :danger)
      end
    RUBY

    expect(violations.count).to eq(1)
    expect(violations.first.message).to include("aria_label:")
    expect(violations.first.message).to include("Button")
  end

  it "flags Link with icon but no text or aria_label" do
    violations = violations_for(<<~RUBY)
      def view_template
        Link(icon: "arrow-right", href: "/next")
      end
    RUBY

    expect(violations.count).to eq(1)
    expect(violations.first.message).to include("Link")
  end

  it "flags LinkButton with icon but no text or aria_label" do
    violations = violations_for(<<~RUBY)
      def view_template
        LinkButton(icon: "pencil", href: "/edit", variant: :secondary)
      end
    RUBY

    expect(violations.count).to eq(1)
    expect(violations.first.message).to include("LinkButton")
  end

  it "flags IconButton with icon but no aria_label" do
    violations = violations_for(<<~RUBY)
      def view_template
        IconButton(icon: "gear")
      end
    RUBY

    expect(violations.count).to eq(1)
    expect(violations.first.message).to include("IconButton")
  end

  it "does not flag Button with icon and aria_label" do
    violations = violations_for(<<~RUBY)
      def view_template
        Button(icon: "trash", variant: :danger, aria_label: t("actions.delete"))
      end
    RUBY

    expect(violations).to be_empty
  end

  it "does not flag Button with icon and text" do
    violations = violations_for(<<~RUBY)
      def view_template
        Button(icon: "save", text: t("actions.save"), variant: :primary)
      end
    RUBY

    expect(violations).to be_empty
  end

  it "does not flag Button without icon" do
    violations = violations_for(<<~RUBY)
      def view_template
        Button(text: t("actions.save"), variant: :primary)
      end
    RUBY

    expect(violations).to be_empty
  end

  it "does not flag IconButton with aria_label" do
    violations = violations_for(<<~RUBY)
      def view_template
        IconButton(icon: "pencil", aria_label: t("actions.edit"))
      end
    RUBY

    expect(violations).to be_empty
  end

  it "flags multiple icon-only components in one file" do
    violations = violations_for(<<~RUBY)
      def view_template
        FlexRow do
          Button(icon: "trash", variant: :danger)
          IconButton(icon: "pencil")
        end
      end
    RUBY

    expect(violations.count).to eq(2)
  end

  it "does not flag Link without icon" do
    violations = violations_for(<<~RUBY)
      def view_template
        Link(text: "View details", href: "/details")
      end
    RUBY

    expect(violations).to be_empty
  end
end
