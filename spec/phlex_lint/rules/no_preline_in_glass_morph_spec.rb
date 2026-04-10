# frozen_string_literal: true

require "spec_helper"

RSpec.describe PhlexLint::Rules::NoPrelineInGlassMorph do
  def check(source, file_path: "app/components/glass_morph/organisms/foo.rb")
    tree = PhlexLint::Parser.parse_source(source, file_path)
    return [] unless tree
    return [] unless described_class.applies_to_file?(file_path)

    rule = described_class.new(file_path:)
    rule.check(tree)
    rule.violations
  end

  it "flags a PrelineCard component" do
    violations = check(<<~RUBY)
      def view_template
        PrelineCard(title: "Foo") { Text() { "body" } }
      end
    RUBY

    expect(violations.count).to eq(1)
    expect(violations.first.message).to include("Preline")
    expect(violations.first.message).to include("GlassMorph")
  end

  it "flags a PrelineNavbar component" do
    violations = check(<<~RUBY)
      def view_template
        PrelineNavbar(links: [])
      end
    RUBY

    expect(violations.count).to eq(1)
  end

  it "flags multiple Preline components in one template" do
    violations = check(<<~RUBY)
      def view_template
        PrelineCard(title: "A") do
          PrelineButton(label: "B")
        end
      end
    RUBY

    expect(violations.count).to eq(2)
  end

  it "does not flag GlassMorph components" do
    violations = check(<<~RUBY)
      def view_template
        GlassCard do
          FlexRow(gap: :md) { Text() { "ok" } }
        end
      end
    RUBY

    expect(violations).to be_empty
  end

  it "does not flag components that merely contain 'Preline' in a non-leading position" do
    violations = check(<<~RUBY)
      def view_template
        MyPrelineWrapper { "ok" }
      end
    RUBY

    expect(violations).to be_empty
  end

  it "does not apply to non-glass_morph component files" do
    violations = check(
      <<~RUBY,
        def view_template
          PrelineCard(title: "Foo") { }
        end
      RUBY
      file_path: "app/components/preline/card.rb"
    )

    expect(violations).to be_empty
  end

  describe ".applies_to_file?" do
    it "returns true for glass_morph component files" do
      expect(described_class.applies_to_file?("app/components/glass_morph/atoms/icon.rb")).to be true
    end

    it "returns true for glass_morph organism files" do
      expect(described_class.applies_to_file?("app/components/glass_morph/organisms/account_row.rb")).to be true
    end

    it "returns false for non-glass_morph files" do
      expect(described_class.applies_to_file?("app/components/preline/card.rb")).to be false
    end

    it "returns false for view files" do
      expect(described_class.applies_to_file?("app/views/glass_morph/admin/foo.rb")).to be false
    end
  end
end
