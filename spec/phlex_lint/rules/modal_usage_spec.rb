# frozen_string_literal: true

require "spec_helper"

RSpec.describe PhlexLint::Rules::ModalUsage do
  def check(source)
    tree = PhlexLint::Parser.parse_source(source)
    return [] unless tree

    rule = described_class.new(file_path: "test.rb")
    rule.check(tree)
    rule.violations
  end

  it "flags a div with modal and fade classes" do
    violations = check(<<~RUBY)
      def view_template
        div(class: "modal fade", id: "myModal")
      end
    RUBY

    expect(violations.count).to eq(1)
    expect(violations.first.message).to include("Modal()")
  end

  it "flags a div with modal-dialog class" do
    violations = check(<<~RUBY)
      def view_template
        div(class: "modal-dialog")
      end
    RUBY

    expect(violations.count).to eq(1)
  end

  it "flags a div with modal-content class" do
    violations = check(<<~RUBY)
      def view_template
        div(class: "modal-content")
      end
    RUBY

    expect(violations.count).to eq(1)
  end

  it "flags modal with modal-dialog nested pattern" do
    violations = check(<<~RUBY)
      def view_template
        div(class: "modal fade") do
          div(class: "modal-dialog modal-lg") do
            div(class: "modal-content")
          end
        end
      end
    RUBY

    expect(violations.count).to eq(3)
  end

  it "does not flag a Modal() component call" do
    violations = check(<<~RUBY)
      def view_template
        Modal(id: "confirm-dialog", title: "Are you sure?") do
          p { "This cannot be undone." }
        end
      end
    RUBY

    expect(violations).to be_empty
  end

  it "does not flag a div with unrelated modal-adjacent class names" do
    violations = check(<<~RUBY)
      def view_template
        div(class: "gm-card modal-trigger")
      end
    RUBY

    # "modal-trigger" has "modal" but not "fade", "modal-dialog", or "modal-content"
    expect(violations).to be_empty
  end

  it "does not flag a dynamic class value" do
    violations = check(<<~RUBY)
      def view_template
        div(class: dynamic_class)
      end
    RUBY

    expect(violations).to be_empty
  end

  it "does not flag a plain modal class without modal-dialog or fade" do
    violations = check(<<~RUBY)
      def view_template
        div(class: "modal")
      end
    RUBY

    expect(violations).to be_empty
  end
end
