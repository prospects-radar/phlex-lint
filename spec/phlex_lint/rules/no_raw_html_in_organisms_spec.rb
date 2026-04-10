# frozen_string_literal: true

require "spec_helper"

RSpec.describe PhlexLint::Rules::NoRawHtmlInOrganisms do
  def check(source, file_path: "app/components/glass_morph/organisms/foo.rb")
    tree = PhlexLint::Parser.parse_source(source, file_path)
    return [] unless tree
    return [] unless described_class.applies_to_file?(file_path)

    rule = described_class.new(file_path:)
    rule.check(tree)
    rule.violations
  end

  it "flags a raw div element" do
    violations = check(<<~RUBY)
      def view_template
        div(class: "my-section") { Text(color: :primary) { "hello" } }
      end
    RUBY

    expect(violations.count).to eq(1)
    expect(violations.first.message).to include("div")
    expect(violations.first.message).to include("atoms/molecules")
  end

  it "flags a raw span element" do
    violations = check(<<~RUBY)
      def view_template
        span { "some text" }
      end
    RUBY

    expect(violations.count).to eq(1)
    expect(violations.first.message).to include("span")
  end

  it "flags a raw a element without target: _blank" do
    violations = check(<<~RUBY)
      def view_template
        a(href: "/foo") { "link" }
      end
    RUBY

    expect(violations.count).to eq(1)
    expect(violations.first.message).to include(":a")
  end

  it "flags multiple different raw HTML elements" do
    violations = check(<<~RUBY)
      def view_template
        div { span { "text" } }
      end
    RUBY

    expect(violations.count).to eq(2)
  end

  it "allows table structural elements" do
    violations = check(<<~RUBY)
      def view_template
        table do
          thead do
            tr { th { "Header" } }
          end
          tbody do
            tr { td { "Cell" } }
          end
        end
      end
    RUBY

    expect(violations).to be_empty
  end

  it "allows a link with target: _blank" do
    violations = check(<<~RUBY)
      def view_template
        a(href: "https://example.com", target: "_blank") { "External" }
      end
    RUBY

    expect(violations).to be_empty
  end

  it "does not flag design system components" do
    violations = check(<<~RUBY)
      def view_template
        FlexRow(gap: :md) do
          Text(color: :primary) { "hello" }
        end
      end
    RUBY

    expect(violations).to be_empty
  end

  it "does not apply to non-organism files" do
    violations = check(
      <<~RUBY,
        def view_template
          div { "hello" }
        end
      RUBY
      file_path: "app/components/glass_morph/molecules/foo.rb"
    )

    expect(violations).to be_empty
  end

  it "does not apply to views files" do
    violations = check(
      <<~RUBY,
        def view_template
          div { "hello" }
        end
      RUBY
      file_path: "app/views/glass_morph/foo.rb"
    )

    expect(violations).to be_empty
  end

  describe ".applies_to_file?" do
    it "returns true for organism files" do
      expect(described_class.applies_to_file?("app/components/glass_morph/organisms/account_row.rb")).to be true
    end

    it "returns true for nested organism paths" do
      expect(described_class.applies_to_file?("app/components/glass_morph/organisms/settings/pricing_page.rb")).to be true
    end

    it "returns false for molecule files" do
      expect(described_class.applies_to_file?("app/components/glass_morph/molecules/card.rb")).to be false
    end

    it "returns false for atom files" do
      expect(described_class.applies_to_file?("app/components/glass_morph/atoms/icon.rb")).to be false
    end
  end
end
