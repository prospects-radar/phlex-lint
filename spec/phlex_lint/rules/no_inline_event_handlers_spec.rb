# frozen_string_literal: true

require "spec_helper"

RSpec.describe PhlexLint::Rules::NoInlineEventHandlers do
  def check(source)
    tree = PhlexLint::Parser.parse_source(source)
    return [] unless tree

    rule = described_class.new(file_path: "test.rb")
    rule.check(tree)
    rule.violations
  end

  it "flags onclick inline event handler" do
    violations = check(<<~RUBY)
      def view_template
        button(onclick: "doSomething()")
      end
    RUBY

    expect(violations.count).to eq(1)
    expect(violations.first.message).to include("onclick")
  end

  it "flags onchange inline event handler" do
    violations = check(<<~RUBY)
      def view_template
        input(onchange: "handleChange(this)")
      end
    RUBY

    expect(violations.count).to eq(1)
    expect(violations.first.message).to include("onchange")
  end

  it "flags onsubmit inline event handler" do
    violations = check(<<~RUBY)
      def view_template
        form(onsubmit: "return validateForm()")
      end
    RUBY

    expect(violations.count).to eq(1)
    expect(violations.first.message).to include("onsubmit")
  end

  it "flags onkeyup inline event handler" do
    violations = check(<<~RUBY)
      def view_template
        input(onkeyup: "search()")
      end
    RUBY

    expect(violations.count).to eq(1)
    expect(violations.first.message).to include("onkeyup")
  end

  it "flags onfocus inline event handler" do
    violations = check(<<~RUBY)
      def view_template
        input(onfocus: "highlight(this)")
      end
    RUBY

    expect(violations.count).to eq(1)
    expect(violations.first.message).to include("onfocus")
  end

  it "flags onblur inline event handler" do
    violations = check(<<~RUBY)
      def view_template
        input(onblur: "validate(this)")
      end
    RUBY

    expect(violations.count).to eq(1)
    expect(violations.first.message).to include("onblur")
  end

  it "does not flag a node with only data: controller attributes" do
    violations = check(<<~RUBY)
      def view_template
        button(data: { controller: "my-feature", action: "click->my-feature#doSomething" })
      end
    RUBY

    expect(violations).to be_empty
  end

  it "does not flag a node with no event handler kwargs" do
    violations = check(<<~RUBY)
      def view_template
        div(class: "gm-card", id: "main-content")
      end
    RUBY

    expect(violations).to be_empty
  end

  it "flags multiple nodes each with different event handlers" do
    violations = check(<<~RUBY)
      def view_template
        button(onclick: "save()")
        input(onchange: "update()")
      end
    RUBY

    expect(violations.count).to eq(2)
  end
end
