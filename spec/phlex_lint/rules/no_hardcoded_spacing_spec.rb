# frozen_string_literal: true

require "spec_helper"

RSpec.describe PhlexLint::Rules::NoHardcodedSpacing do
  def check(source, file_path: "app/components/glass_morph/organisms/foo.rb")
    tree = PhlexLint::Parser.parse_source(source, file_path)
    return [] unless tree

    rule = described_class.new(file_path:)
    rule.check(tree)
    rule.violations
  end

  it "does not flag standardized component Text with mt-3 (covered by UseParentGapForSpacing)" do
    violations = check(<<~RUBY)
      def view_template
        Text(class: "mt-3") { "hello" }
      end
    RUBY

    expect(violations).to be_empty
  end

  it "does not flag standardized component Heading with mb-2 (covered by UseParentGapForSpacing)" do
    violations = check(<<~RUBY)
      def view_template
        Heading(level: 2, class: "mb-2") { "Title" }
      end
    RUBY

    expect(violations).to be_empty
  end

  it "flags a raw div with pt-4 padding class" do
    violations = check(<<~RUBY)
      def view_template
        div(class: "pt-4") { "content" }
      end
    RUBY

    expect(violations.count).to eq(1)
    expect(violations.first.message).to include("pt-4")
  end

  it "flags px- and py- axis spacing classes" do
    violations = check(<<~RUBY)
      def view_template
        span(class: "px-2 py-1") { "text" }
      end
    RUBY

    expect(violations.count).to eq(1)
  end

  it "does not flag standardized component Text nodes with spacing classes (covered by UseParentGapForSpacing)" do
    violations = check(<<~RUBY)
      def view_template
        Text(class: "mb-3") { "first" }
        Text(class: "mt-2") { "second" }
      end
    RUBY

    expect(violations).to be_empty
  end

  it "flags a custom component (not standardized) with mb-3" do
    violations = check(<<~RUBY)
      def view_template
        CustomWidget(class: "mb-3") { "hello" }
      end
    RUBY

    expect(violations.count).to eq(1)
  end

  it "allows layout container FlexRow with spacing class" do
    violations = check(<<~RUBY)
      def view_template
        FlexRow(class: "mb-4") { Text() { "hi" } }
      end
    RUBY

    expect(violations).to be_empty
  end

  it "allows layout container FlexColumn with spacing class" do
    violations = check(<<~RUBY)
      def view_template
        FlexColumn(class: "mt-3") { Text() { "hi" } }
      end
    RUBY

    expect(violations).to be_empty
  end

  it "allows layout container Box with spacing class" do
    violations = check(<<~RUBY)
      def view_template
        Box(class: "p-4") { "content" }
      end
    RUBY

    expect(violations).to be_empty
  end

  it "allows layout container GlassCard with spacing class" do
    violations = check(<<~RUBY)
      def view_template
        GlassCard(class: "mb-2") { "content" }
      end
    RUBY

    expect(violations).to be_empty
  end

  it "allows layout container Section with spacing class" do
    violations = check(<<~RUBY)
      def view_template
        Section(class: "pt-3") { "content" }
      end
    RUBY

    expect(violations).to be_empty
  end

  it "allows layout container PageContainer with spacing class" do
    violations = check(<<~RUBY)
      def view_template
        PageContainer(class: "pb-5") { "content" }
      end
    RUBY

    expect(violations).to be_empty
  end

  it "does not flag components without spacing classes" do
    violations = check(<<~RUBY)
      def view_template
        Text(class: "fw-bold gm-text-primary") { "hello" }
      end
    RUBY

    expect(violations).to be_empty
  end

  it "does not flag components without a class kwarg" do
    violations = check(<<~RUBY)
      def view_template
        Text(color: :primary) { "hello" }
      end
    RUBY

    expect(violations).to be_empty
  end

  it "does not flag dynamic class values" do
    violations = check(<<~RUBY)
      def view_template
        Text(class: computed_classes) { "hello" }
      end
    RUBY

    expect(violations).to be_empty
  end
end
