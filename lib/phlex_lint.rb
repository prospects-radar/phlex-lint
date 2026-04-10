# frozen_string_literal: true

require_relative "phlex_lint/version"
require_relative "phlex_lint/phlex_node"
require_relative "phlex_lint/parser"
require_relative "phlex_lint/violation"
require_relative "phlex_lint/correction"
require_relative "phlex_lint/rule"

# === Required kwargs rules (Component completeness) ===
require_relative "phlex_lint/rules/glass_card_section_row_wrapper"
require_relative "phlex_lint/rules/glass_card_section_requires_icon_and_title"
require_relative "phlex_lint/rules/button_requires_variant"
require_relative "phlex_lint/rules/stat_card_requires_variant"
require_relative "phlex_lint/rules/badge_requires_type"
require_relative "phlex_lint/rules/page_header_requires_title"
require_relative "phlex_lint/rules/modal_requires_size"

# === Anti-pattern substitution rules ===
require_relative "phlex_lint/rules/card_content_in_glass_card"
require_relative "phlex_lint/rules/form_section_header_in_glass_card_section"
require_relative "phlex_lint/rules/light_tile_wraps_stat_card"
require_relative "phlex_lint/rules/config_card_in_settings"

# === Ancestor / structural rules ===
require_relative "phlex_lint/rules/settings_page_uses_page_container"
require_relative "phlex_lint/rules/page_header_requires_page_container"
require_relative "phlex_lint/rules/alert_banner_in_flex_row"
require_relative "phlex_lint/rules/nested_empty_state"
require_relative "phlex_lint/rules/nested_glass_card_section"
require_relative "phlex_lint/rules/page_container_in_flex_row"
require_relative "phlex_lint/rules/container_not_in_flex_row"
require_relative "phlex_lint/rules/breadcrumb_only_in_page_container"

# === Sibling ordering rules ===
require_relative "phlex_lint/rules/page_header_must_be_first_in_page_container"
require_relative "phlex_lint/rules/one_page_header_per_container"

# === Content validation rules ===
require_relative "phlex_lint/rules/tabs_requires_tab_children"
require_relative "phlex_lint/rules/data_table_not_for_stats"
require_relative "phlex_lint/rules/form_group_wrappers"

# === Design system compliance rules ===
require_relative "phlex_lint/rules/icon_must_be_approved"
require_relative "phlex_lint/rules/heading_color_validation"
require_relative "phlex_lint/rules/gap_value_validation"

# === HTML element rules ===
require_relative "phlex_lint/rules/separator_using_proper_component"
require_relative "phlex_lint/rules/link_using_proper_component"
require_relative "phlex_lint/rules/no_raw_flex_divs"
require_relative "phlex_lint/rules/no_raw_buttons"
require_relative "phlex_lint/rules/no_raw_textareas"
require_relative "phlex_lint/rules/no_raw_svg"
require_relative "phlex_lint/rules/use_real_heading"
require_relative "phlex_lint/rules/no_styled_paragraphs"
require_relative "phlex_lint/rules/no_raw_badge_spans"
require_relative "phlex_lint/rules/use_real_score_badge"
require_relative "phlex_lint/rules/no_small_element"
require_relative "phlex_lint/rules/no_gm_text_class_on_raw_html"
require_relative "phlex_lint/rules/no_raw_html_in_organisms"
require_relative "phlex_lint/rules/no_raw_html_in_views"

# === GlassMorph architecture rules ===
require_relative "phlex_lint/rules/no_preline_in_glass_morph"
require_relative "phlex_lint/rules/no_extra_classes_on_standardized_components"
require_relative "phlex_lint/rules/no_legacy_new_ui_reference"

# === Component kwarg validation rules ===
require_relative "phlex_lint/rules/badge_valid_color"
require_relative "phlex_lint/rules/glass_card_variant"
require_relative "phlex_lint/rules/no_class_on_badge"
require_relative "phlex_lint/rules/interactive_aria_required"
require_relative "phlex_lint/rules/data_parameter"
require_relative "phlex_lint/rules/class_parameter"

# === Class string validation rules ===
require_relative "phlex_lint/rules/no_raw_bi_icon_classes"
require_relative "phlex_lint/rules/no_new_tailwind_usage"
require_relative "phlex_lint/rules/enforce_design_token_classes"
require_relative "phlex_lint/rules/no_inline_styles"
require_relative "phlex_lint/rules/no_inline_event_handlers"
require_relative "phlex_lint/rules/use_parent_gap_for_spacing"
require_relative "phlex_lint/rules/modal_usage"

# === Spacing validation rules ===
require_relative "phlex_lint/rules/no_hardcoded_spacing"

# === Parser blind spot fixes ===
require_relative "phlex_lint/rules/review_interpolated_classes"
require_relative "phlex_lint/rules/no_content_tag"

# === ITCSS and class naming conventions ===
require_relative "phlex_lint/rules/no_custom_classes"
require_relative "phlex_lint/rules/class_naming_convention"
require_relative "phlex_lint/rules/no_mixing_layer_concerns"
require_relative "phlex_lint/rules/utility_in_component_position"

require_relative "phlex_lint/configuration"
require_relative "phlex_lint/rule_engine"
require_relative "phlex_lint/runner"
