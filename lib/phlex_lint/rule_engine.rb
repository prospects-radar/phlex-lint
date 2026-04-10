# frozen_string_literal: true

module PhlexLint
  # Runs all registered rules against a PhlexNode tree and returns violations.
  class RuleEngine
    RULES = [
      # === Required kwargs (Component completeness) ===
      Rules::GlassCardSectionRowWrapper,
      Rules::GlassCardSectionRequiresIconAndTitle,
      Rules::ButtonRequiresVariant,
      Rules::StatCardRequiresVariant,
      Rules::BadgeRequiresType,
      Rules::PageHeaderRequiresTitle,
      Rules::ModalRequiresSize,

      # === Anti-pattern substitution ===
      Rules::CardContentInGlassCard,
      Rules::FormSectionHeaderInGlassCardSection,
      Rules::LightTileWrapsStatCard,
      Rules::ConfigCardInSettings,

      # === Ancestor / structural ===
      Rules::SettingsPageUsesPageContainer,
      Rules::PageHeaderRequiresPageContainer,
      Rules::AlertBannerInFlexRow,
      Rules::NestedEmptyState,
      Rules::NestedGlassCardSection,
      Rules::PageContainerInFlexRow,
      Rules::ContainerNotInFlexRow,
      Rules::BreadcrumbOnlyInPageContainer,

      # === Sibling ordering ===
      Rules::PageHeaderMustBeFirstInPageContainer,
      Rules::OnePageHeaderPerContainer,

      # === Content validation ===
      Rules::TabsRequiresTabChildren,
      Rules::DataTableNotForStats,
      Rules::FormGroupWrappers,

      # === Design system compliance ===
      Rules::IconMustBeApproved,
      Rules::HeadingColorValidation,
      Rules::GapValueValidation,

      # === HTML element rules (replace raw HTML with design system components) ===
      Rules::SeparatorUsingProperComponent,
      Rules::LinkUsingProperComponent,
      Rules::NoRawFlexDivs,
      Rules::NoRawButtons,
      Rules::NoRawTextareas,
      Rules::NoRawSvg,
      Rules::UseRealHeading,
      Rules::NoStyledParagraphs,
      Rules::NoRawBadgeSpans,
      Rules::UseRealScoreBadge,
      Rules::NoSmallElement,
      Rules::NoGmTextClassOnRawHtml,

      # === File-path restricted structural rules ===
      Rules::NoRawHtmlInOrganisms,
      Rules::NoRawHtmlInViews,
      Rules::NoPrelineInGlassMorph,
      Rules::NoExtraClassesOnStandardizedComponents,
      Rules::NoLegacyNewUiReference,

      # === Component kwarg validation ===
      Rules::BadgeValidColor,
      Rules::GlassCardVariant,
      Rules::NoClassOnBadge,
      Rules::InteractiveAriaRequired,
      Rules::DataParameter,
      Rules::ClassParameter,

      # === Class string / token validation ===
      Rules::NoRawBiIconClasses,
      Rules::NoNewTailwindUsage,
      Rules::EnforceDesignTokenClasses,
      Rules::NoInlineStyles,
      Rules::NoInlineEventHandlers,
      Rules::UseParentGapForSpacing,
      Rules::ModalUsage,

      # === Spacing validation ===
      Rules::NoHardcodedSpacing,

      # === Parser blind spot fixes ===
      Rules::ReviewInterpolatedClasses,
      Rules::NoContentTag,

      # === ITCSS and class naming conventions ===
      Rules::NoCustomClasses,
      Rules::ClassNamingConvention,
      Rules::NoMixingLayerConcerns,
      Rules::UtilityInComponentPosition
    ].freeze

    def self.check(tree, file_path:, only: nil, parser: nil, config: nil)
      violations = []
      rules_to_run = if only
        # Filter rules by name — matches against both qualified and short names
        RULES.select do |rule_class|
          only.any? do |pattern|
            rule_class.qualified_name.match?(/#{pattern}/i) ||
              rule_class.short_name.match?(/#{pattern}/i)
          end
        end
      else
        RULES
      end

      rules_to_run.each do |rule_class|
        # Gate 1: code-level applies_to_file? (semantic invariants)
        next unless rule_class.applies_to_file?(file_path)

        # Gate 2: config-level Enabled / Include / Exclude (project policy)
        if config
          next unless config.applies_to_file?(rule_class.qualified_name, file_path)
        end

        rule = rule_class.new(file_path: file_path, parser: parser)
        rule.check(tree)
        violations.concat(rule.violations)
      end
      violations
    end
  end
end
