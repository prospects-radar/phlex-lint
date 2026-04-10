# frozen_string_literal: true

require "spec_helper"

RSpec.describe PhlexLint::Rules::LightTileWrapsStatCard do
  def violations_for(source)
    tree = PhlexLint::Parser.parse_source(source)
    rule = described_class.new(file_path: "app/components/test.rb")
    rule.check(tree)
    rule.violations
  end

  it "flags LightTile directly wrapping StatCard" do
    violations = violations_for(<<~RUBY)
      def view_template
        LightTile(padding: :md) do
          StatCard(label: t("stat"), value: "42", variant: :info)
        end
      end
    RUBY

    expect(violations.count).to eq(1)
    expect(violations.first.message).to include("StatCard")
  end

  it "flags LightTile directly wrapping DataCard" do
    violations = violations_for(<<~RUBY)
      def view_template
        LightTile(padding: :md) do
          DataCard(title: "item", value: "val")
        end
      end
    RUBY

    expect(violations.count).to eq(1)
    expect(violations.first.message).to include("DataCard")
  end

  it "does not flag LightTile with non-tile children" do
    violations = violations_for(<<~RUBY)
      def view_template
        LightTile(padding: :md) do
          FlexRow(gap: :sm, align: :center, justify: :between) do
            Heading(level: 6, text: "Product")
            Icon(name: "arrow-right", size: :sm)
          end
        end
      end
    RUBY

    expect(violations).to be_empty
  end

  it "does not flag StatCard used without LightTile" do
    violations = violations_for(<<~RUBY)
      def view_template
        FlexColumn(gap: :md) do
          StatCard(label: t("stat"), value: "42", variant: :info)
        end
      end
    RUBY

    expect(violations).to be_empty
  end

  it "does not flag StatCard as a grandchild of LightTile" do
    violations = violations_for(<<~RUBY)
      def view_template
        LightTile(padding: :md) do
          FlexColumn(gap: :sm) do
            StatCard(label: t("stat"), value: "42", variant: :info)
          end
        end
      end
    RUBY

    # StatCard is a grandchild, not a direct child — no offense
    expect(violations).to be_empty
  end
end
