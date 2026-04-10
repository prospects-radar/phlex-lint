# frozen_string_literal: true

require "spec_helper"

RSpec.describe PhlexLint::Rules::NoRawButtons do
  def violations_for(source)
    tree = PhlexLint::Parser.parse_source(source)
    return [] unless tree

    rule = described_class.new(file_path: "test.rb")
    rule.check(tree)
    rule.violations
  end

  it "flags a raw button element with btn class" do
    violations = violations_for(<<~RUBY)
      def view_template
        button(class: "btn btn-primary") { "Save" }
      end
    RUBY

    expect(violations).not_to be_empty
    expect(violations.first.message).to include("Button()")
  end

  it "flags a raw a element with btn class" do
    violations = violations_for(<<~RUBY)
      def view_template
        a(href: "/cancel", class: "btn btn-secondary") { "Cancel" }
      end
    RUBY

    expect(violations).not_to be_empty
    expect(violations.first.message).to include("Link()")
  end

  it "flags a button with btn among multiple classes" do
    violations = violations_for(<<~RUBY)
      def view_template
        button(class: "btn btn-danger btn-sm", type: "submit") { "Delete" }
      end
    RUBY

    expect(violations).not_to be_empty
  end

  it "does not flag a button without btn class" do
    violations = violations_for(<<~RUBY)
      def view_template
        button(type: "submit") { "Save" }
      end
    RUBY

    expect(violations).to be_empty
  end

  it "does not flag an a element without btn class" do
    violations = violations_for(<<~RUBY)
      def view_template
        a(href: "/path", class: "nav-link") { "Home" }
      end
    RUBY

    expect(violations).to be_empty
  end

  it "does not flag a button with a dynamic class" do
    violations = violations_for(<<~RUBY)
      def view_template
        button(class: dynamic_class) { "Click" }
      end
    RUBY

    expect(violations).to be_empty
  end
end
