# frozen_string_literal: true

require "spec_helper"

RSpec.describe PhlexLint::Rules::UseRealScoreBadge do
  def violations_for(source)
    tree = PhlexLint::Parser.parse_source(source)
    return [] unless tree

    rule = described_class.new(file_path: "test.rb")
    rule.check(tree)
    rule.violations
  end

  it "flags a span with score-badge class" do
    violations = violations_for(<<~RUBY)
      def view_template
        span(class: "score-badge score-badge--high") { "82" }
      end
    RUBY

    expect(violations).not_to be_empty
    expect(violations.first.message).to include("ScoreBadge")
  end

  it "flags a div with score-badge class" do
    violations = violations_for(<<~RUBY)
      def view_template
        div(class: "score-badge") { @score }
      end
    RUBY

    expect(violations).not_to be_empty
  end

  it "flags a span with score-badge among other classes" do
    violations = violations_for(<<~RUBY)
      def view_template
        span(class: "d-inline-block score-badge rounded") { "75" }
      end
    RUBY

    expect(violations).not_to be_empty
  end

  it "does not flag a span without score-badge class" do
    violations = violations_for(<<~RUBY)
      def view_template
        span(class: "badge bg-info") { "Info" }
      end
    RUBY

    expect(violations).to be_empty
  end

  it "does not flag a div without score-badge class" do
    violations = violations_for(<<~RUBY)
      def view_template
        div(class: "score-indicator") { "high" }
      end
    RUBY

    expect(violations).to be_empty
  end

  it "does not flag a ScoreBadge component" do
    violations = violations_for(<<~RUBY)
      def view_template
        ScoreBadge(score: 82)
      end
    RUBY

    expect(violations).to be_empty
  end

  it "does not flag a span with a dynamic class" do
    violations = violations_for(<<~RUBY)
      def view_template
        span(class: score_badge_classes) { score }
      end
    RUBY

    expect(violations).to be_empty
  end
end
