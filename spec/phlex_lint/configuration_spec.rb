# frozen_string_literal: true

require "spec_helper"
require "tmpdir"

RSpec.describe PhlexLint::Configuration do
  describe ".load" do
    it "returns empty config when no file exists" do
      config = described_class.load("/nonexistent/path")
      expect(config).to be_empty
    end

    it "loads config from .phlex-lint.yml in the given directory" do
      Dir.mktmpdir do |dir|
        File.write(File.join(dir, ".phlex-lint.yml"), <<~YAML)
          Style/NoInlineStyles:
            Enabled: false
        YAML

        config = described_class.load(dir)
        expect(config).not_to be_empty
      end
    end
  end

  describe "#applies_to_file?" do
    context "with no config" do
      it "returns true for any file" do
        config = described_class.new({})
        expect(config.applies_to_file?("Style/NoInlineStyles", "app/components/foo.rb")).to be true
      end
    end

    context "with qualified name Exclude" do
      let(:config) do
        described_class.new(
          "Style/NoInlineStyles" => {
            "Exclude" => [
              "app/components/mailer/**/*.rb",
              "app/components/json_display.rb"
            ]
          }
        )
      end

      it "excludes files matching a glob pattern" do
        expect(config.applies_to_file?("Style/NoInlineStyles", "app/components/mailer/welcome.rb")).to be false
      end

      it "excludes files matching a nested glob" do
        expect(config.applies_to_file?("Style/NoInlineStyles", "app/components/mailer/devise/confirm.rb")).to be false
      end

      it "excludes files matching an exact path" do
        expect(config.applies_to_file?("Style/NoInlineStyles", "app/components/json_display.rb")).to be false
      end

      it "allows files not matching any exclude pattern" do
        expect(config.applies_to_file?("Style/NoInlineStyles", "app/components/prospects/card.rb")).to be true
      end

      it "excludes files with absolute paths" do
        expect(config.applies_to_file?("Style/NoInlineStyles", "/project/root/app/components/mailer/welcome.rb")).to be false
      end

      it "allows non-excluded files with absolute paths" do
        expect(config.applies_to_file?("Style/NoInlineStyles", "/project/root/app/components/card.rb")).to be true
      end
    end

    context "with category-level config" do
      let(:config) do
        described_class.new(
          "Style" => {
            "Exclude" => ["app/components/mailer/**/*.rb"]
          }
        )
      end

      it "excludes files for all rules in the category" do
        expect(config.applies_to_file?("Style/NoInlineStyles", "app/components/mailer/welcome.rb")).to be false
        expect(config.applies_to_file?("Style/NoHardcodedSpacing", "app/components/mailer/welcome.rb")).to be false
      end

      it "does not affect rules in other categories" do
        expect(config.applies_to_file?("DesignSystem/NoRawButtons", "app/components/mailer/welcome.rb")).to be true
      end

      it "allows non-excluded files" do
        expect(config.applies_to_file?("Style/NoInlineStyles", "app/components/card.rb")).to be true
      end
    end

    context "with category Enabled: false" do
      let(:config) do
        described_class.new("Style" => { "Enabled" => false })
      end

      it "disables all rules in the category" do
        expect(config.applies_to_file?("Style/NoInlineStyles", "app/components/card.rb")).to be false
        expect(config.applies_to_file?("Style/NoHardcodedSpacing", "app/components/card.rb")).to be false
      end

      it "does not affect rules in other categories" do
        expect(config.applies_to_file?("DesignSystem/NoRawButtons", "app/components/card.rb")).to be true
      end
    end

    context "with Include patterns" do
      let(:config) do
        described_class.new(
          "Architecture/NoRawHtmlInViews" => {
            "Include" => ["app/views/glass_morph/**/*.rb"]
          }
        )
      end

      it "allows files matching an include pattern" do
        expect(config.applies_to_file?("Architecture/NoRawHtmlInViews", "app/views/glass_morph/admin/show.rb")).to be true
      end

      it "rejects files not matching any include pattern" do
        expect(config.applies_to_file?("Architecture/NoRawHtmlInViews", "app/views/other/index.rb")).to be false
      end
    end

    context "with both Include and Exclude" do
      let(:config) do
        described_class.new(
          "Architecture/MyRule" => {
            "Include" => ["app/views/glass_morph/**/*.rb"],
            "Exclude" => ["app/views/glass_morph/devise/**/*.rb"]
          }
        )
      end

      it "allows files matching Include but not Exclude" do
        expect(config.applies_to_file?("Architecture/MyRule", "app/views/glass_morph/admin/show.rb")).to be true
      end

      it "rejects files matching both Include and Exclude" do
        expect(config.applies_to_file?("Architecture/MyRule", "app/views/glass_morph/devise/login.rb")).to be false
      end

      it "rejects files not matching Include" do
        expect(config.applies_to_file?("Architecture/MyRule", "app/components/foo.rb")).to be false
      end
    end

    context "with qualified-name Enabled: false" do
      let(:config) do
        described_class.new("Style/NoInlineStyles" => { "Enabled" => false })
      end

      it "rejects all files for that rule" do
        expect(config.applies_to_file?("Style/NoInlineStyles", "app/components/anything.rb")).to be false
      end
    end

    context "with AllRules Exclude" do
      let(:config) do
        described_class.new(
          "AllRules" => {
            "Exclude" => ["app/components/mailer/**/*.rb"]
          }
        )
      end

      it "excludes globally for any rule" do
        expect(config.applies_to_file?("Style/NoInlineStyles", "app/components/mailer/welcome.rb")).to be false
        expect(config.applies_to_file?("DesignSystem/NoRawButtons", "app/components/mailer/welcome.rb")).to be false
      end

      it "allows non-excluded files for any rule" do
        expect(config.applies_to_file?("Style/NoInlineStyles", "app/components/card.rb")).to be true
      end
    end

    context "with AllRules, category, and per-rule Exclude combined" do
      let(:config) do
        described_class.new(
          "AllRules" => {
            "Exclude" => ["app/components/mailer/**/*.rb"]
          },
          "Style" => {
            "Exclude" => ["app/components/layouts/**/*.rb"]
          },
          "Style/NoInlineStyles" => {
            "Exclude" => ["app/components/json_display.rb"]
          }
        )
      end

      it "applies all three levels of excludes" do
        # Global exclude
        expect(config.applies_to_file?("Style/NoInlineStyles", "app/components/mailer/foo.rb")).to be false
        # Category exclude
        expect(config.applies_to_file?("Style/NoInlineStyles", "app/components/layouts/dev.rb")).to be false
        # Per-rule exclude
        expect(config.applies_to_file?("Style/NoInlineStyles", "app/components/json_display.rb")).to be false
        # None of the above
        expect(config.applies_to_file?("Style/NoInlineStyles", "app/components/card.rb")).to be true
      end

      it "category exclude applies to other rules in same category" do
        expect(config.applies_to_file?("Style/NoHardcodedSpacing", "app/components/layouts/dev.rb")).to be false
      end

      it "category exclude does not apply to rules in other categories" do
        expect(config.applies_to_file?("Lint/NoContentTag", "app/components/layouts/dev.rb")).to be true
      end
    end

    context "backward compat: short name config key" do
      let(:config) do
        described_class.new(
          "NoInlineStyles" => {
            "Exclude" => ["app/components/json_display.rb"]
          }
        )
      end

      it "matches qualified name against short-name config key" do
        expect(config.applies_to_file?("Style/NoInlineStyles", "app/components/json_display.rb")).to be false
      end
    end
  end
end
