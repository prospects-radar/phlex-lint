# frozen_string_literal: true

require "spec_helper"

RSpec.describe PhlexLint::Rules::NoRawHtmlInViews do
  def check(source, file_path: "app/views/glass_morph/admin/foo.rb")
    tree = PhlexLint::Parser.parse_source(source, file_path)
    return [] unless tree
    return [] unless described_class.applies_to_file?(file_path)

    rule = described_class.new(file_path:)
    rule.check(tree)
    rule.violations
  end

  it "flags a raw div and suggests FlexRow/FlexColumn/Section/Box" do
    violations = check(<<~RUBY)
      def view_template
        div(class: "my-wrapper") { Text() { "hi" } }
      end
    RUBY

    expect(violations.count).to eq(1)
    expect(violations.first.message).to include("FlexRow")
    expect(violations.first.message).to include("Section")
  end

  it "flags a raw span and suggests Span() or Text()" do
    violations = check(<<~RUBY)
      def view_template
        span { "text" }
      end
    RUBY

    expect(violations.count).to eq(1)
    expect(violations.first.message).to include("Span()")
    expect(violations.first.message).to include("Text()")
  end

  it "flags a raw p and suggests Paragraph()" do
    violations = check(<<~RUBY)
      def view_template
        p { "description" }
      end
    RUBY

    expect(violations.count).to eq(1)
    expect(violations.first.message).to include("Paragraph()")
  end

  it "flags a raw label and suggests Label()" do
    violations = check(<<~RUBY)
      def view_template
        label { "Name" }
      end
    RUBY

    expect(violations.count).to eq(1)
    expect(violations.first.message).to include("Label()")
  end

  it "flags a raw small and suggests Text(size: :sm)" do
    violations = check(<<~RUBY)
      def view_template
        small { "hint" }
      end
    RUBY

    expect(violations.count).to eq(1)
    expect(violations.first.message).to include("Text(size: :sm)")
  end

  it "flags multiple detected elements in one template" do
    violations = check(<<~RUBY)
      def view_template
        div { span { "hi" } }
      end
    RUBY

    expect(violations.count).to eq(2)
  end

  it "does not flag design system components" do
    violations = check(<<~RUBY)
      def view_template
        FlexColumn(gap: :md) do
          Text(color: :primary) { "hello" }
        end
      end
    RUBY

    expect(violations).to be_empty
  end

  it "does not apply to devise views" do
    violations = check(
      <<~RUBY,
        def view_template
          div { "devise content" }
        end
      RUBY
      file_path: "app/views/glass_morph/devise/sessions/new.rb"
    )

    expect(violations).to be_empty
  end

  it "does not apply to non-glass_morph view files" do
    violations = check(
      <<~RUBY,
        def view_template
          div { "hello" }
        end
      RUBY
      file_path: "app/views/admin/foo.rb"
    )

    expect(violations).to be_empty
  end

  describe ".applies_to_file?" do
    it "returns true for glass_morph view files" do
      expect(described_class.applies_to_file?("app/views/glass_morph/admin/foo.rb")).to be true
    end

    it "returns false for devise view files" do
      expect(described_class.applies_to_file?("app/views/glass_morph/devise/sessions/new.rb")).to be false
    end

    it "returns false for non-glass_morph views" do
      expect(described_class.applies_to_file?("app/views/admin/foo.rb")).to be false
    end

    it "returns false for component files" do
      expect(described_class.applies_to_file?("app/components/glass_morph/organisms/foo.rb")).to be false
    end
  end
end
