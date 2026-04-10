# frozen_string_literal: true

require "spec_helper"

RSpec.describe PhlexLint::Rules::IconMustBeApproved do

  def parse(source)
    PhlexLint::Parser.parse_source(source, "test.rb")
  end
  subject(:rule) { described_class.new(file_path: "test.rb") }

  describe "#check" do
    it "flags unapproved icon names" do
      tree = parse(<<~RUBY)
        def view_template
          Icon(name: "unicorn")
        end
      RUBY

      rule.check(tree)
      expect(rule.violations.count).to eq(1)
      expect(rule.violations.first.message).to include("unicorn")
    end

    it "allows approved icon names" do
      tree = parse(<<~RUBY)
        def view_template
          Icon(name: "trash")
          Icon(name: "search")
          Icon(name: "linkedin")
        end
      RUBY

      rule.check(tree)
      expect(rule.violations).to be_empty
    end

    it "ignores dynamic icon names" do
      tree = parse(<<~RUBY)
        def view_template
          Icon(name: @icon_name)
        end
      RUBY

      rule.check(tree)
      expect(rule.violations).to be_empty
    end

    it "flags typo in approved icon name" do
      tree = parse(<<~RUBY)
        def view_template
          Icon(name: "trash-can")
        end
      RUBY

      rule.check(tree)
      expect(rule.violations.count).to eq(1)
    end
  end
end
