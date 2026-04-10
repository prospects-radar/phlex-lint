# frozen_string_literal: true

require "spec_helper"

RSpec.describe PhlexLint::Rules::NoGmTextClassOnRawHtml do
  def check(source, file_path: "app/components/glass_morph/organisms/foo.rb")
    tree = PhlexLint::Parser.parse_source(source, file_path)
    return [] unless tree

    rule = described_class.new(file_path:)
    rule.check(tree)
    rule.violations
  end

  it "flags span with gm-text-muted" do
    violations = check(<<~RUBY)
      def view_template
        span(class: "gm-text-muted") { "Label" }
      end
    RUBY

    expect(violations.count).to eq(1)
    expect(violations.first.message).to include("Text(color: :muted)")
    expect(violations.first.message).to include("gm-text-muted")
  end

  it "flags p with gm-text-primary" do
    violations = check(<<~RUBY)
      def view_template
        p(class: "gm-text-primary fw-bold") { "Title" }
      end
    RUBY

    expect(violations.count).to eq(1)
    expect(violations.first.message).to include("Text(color: :primary)")
  end

  it "does not flag div with gm-text-secondary (divs are layout containers using CSS inheritance)" do
    violations = check(<<~RUBY)
      def view_template
        div(class: "gm-text-secondary") { "Note" }
      end
    RUBY

    expect(violations).to be_empty
  end

  it "flags span with gm-text-white" do
    violations = check(<<~RUBY)
      def view_template
        span(class: "gm-text-white") { "Bright" }
      end
    RUBY

    expect(violations.count).to eq(1)
    expect(violations.first.message).to include("Text(color: :light)")
  end

  it "flags small with gm-text-muted" do
    violations = check(<<~RUBY)
      def view_template
        small(class: "gm-text-muted") { "Caption" }
      end
    RUBY

    expect(violations.count).to eq(1)
  end

  it "flags label with gm-text-muted" do
    violations = check(<<~RUBY)
      def view_template
        label(class: "gm-text-muted") { "Field" }
      end
    RUBY

    expect(violations.count).to eq(1)
  end

  it "flags multiple raw HTML nodes with gm-text tokens" do
    violations = check(<<~RUBY)
      def view_template
        span(class: "gm-text-muted") { "a" }
        p(class: "gm-text-primary") { "b" }
      end
    RUBY

    expect(violations.count).to eq(2)
  end

  it "does not flag gm-text-* palette colors (amber, blue, etc.) — not covered by Text atom" do
    violations = check(<<~RUBY)
      def view_template
        span(class: "gm-text-amber-500") { "Score" }
      end
    RUBY

    expect(violations).to be_empty
  end

  it "does not flag raw HTML without a gm-text token" do
    violations = check(<<~RUBY)
      def view_template
        span(class: "fw-bold") { "Bold" }
      end
    RUBY

    expect(violations).to be_empty
  end

  it "does not flag Text atom using gm-text-muted (it is the source of the class)" do
    violations = check(<<~RUBY)
      def view_template
        Text(class: "gm-text-muted") { "ok" }
      end
    RUBY

    expect(violations).to be_empty
  end

  it "does not flag layout containers using gm-text for color inheritance" do
    violations = check(<<~RUBY)
      def view_template
        FlexRow(class: "gm-text-muted") { Text() { "hi" } }
      end
    RUBY

    expect(violations).to be_empty
  end

  it "does not flag dynamic class values" do
    violations = check(<<~RUBY)
      def view_template
        span(class: computed_class) { "text" }
      end
    RUBY

    expect(violations).to be_empty
  end
end
