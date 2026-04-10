# Phlex-Lint Auto-Correction Heuristics

Phlex-Lint uses intelligent heuristics to auto-correct missing variant kwargs, analyzing button text and stat card labels to infer the most appropriate design system variant.

## Button Variant Heuristics

When a `Button` component is missing the `variant:` kwarg, phlex-lint analyzes the button's `text:` kwarg to infer the most appropriate variant.

### Pattern Matching Rules

| Pattern | Variant | Examples |
|---------|---------|----------|
| `delete`, `remove`, `destroy`, `discard` | `:danger` | "Delete Account", "Remove Item" |
| `close`, `dismiss`, `cancel` | `:secondary` | "Cancel", "Close" |
| `save`, `create`, `add`, `submit`, `update`, `confirm` | `:primary` | "Save Changes", "Create", "Submit" |
| `learn`, `view`, `preview`, `download` | `:tertiary` | "Learn More", "Preview", "Download" |
| *(anything else)* | `:primary` | "Help", "Next", "Settings" |

### Examples

```ruby
# Before (missing variant)
Button(text: "Delete Account")
Button(text: "Save Changes")
Button(text: "Learn More")
Button(icon: "download")

# After (auto-corrected)
Button(text: "Delete Account", variant: :danger)
Button(text: "Save Changes", variant: :primary)
Button(text: "Learn More", variant: :tertiary)
Button(icon: "download", variant: :primary)
```

### Limitations

- **Dynamic text only**: Heuristics only work with literal string values for `text:`. If using `text: t("key")` or other method calls, the default `:primary` is used.
- **Case-insensitive**: Pattern matching is case-insensitive to handle "Delete", "delete", "DELETE", etc.
- **Manual override**: Developers can always override the inferred variant in code — the auto-correction is a starting point.

## StatCard Variant Heuristics

When a `StatCard` component is missing the `variant:` kwarg, phlex-lint analyzes the `label:` kwarg to infer semantic color meaning.

### Pattern Matching Rules

| Pattern | Variant | Semantic Meaning | Examples |
|---------|---------|-----------------|----------|
| `error`, `fail(ed)`, `issue`, `problem`, `down`, `offline`, `inactive` | `:danger` | ❌ Critical/Failure | "Failed Deployments", "Errors" |
| `warning`, `alert`, `at risk`, `pending`, `review` | `:warning` | ⚠️ Attention Needed | "Pending Reviews", "At Risk" |
| `success`, `active`, `complete(d)`, `online`, `resolved`, `healthy` | `:success` | ✅ Positive State | "Success Rate", "Active Users" |
| `score`, `rating`, `index`, `ai`, `opportunit(y/ies)`, `potential` | `:purple` | 🎯 Unique/Featured | "Deal Score", "Opportunities" |
| *(anything else)* | `:info` | ℹ️ Neutral/Informational | "Revenue", "Users", "API Calls" |

### Examples

```ruby
# Before (missing variant)
StatCard(label: "Revenue", value: "100k")
StatCard(label: "Failed Deployments", value: "2")
StatCard(label: "Success Rate", value: "98%")
StatCard(label: "Opportunities", value: "15")

# After (auto-corrected)
StatCard(label: "Revenue", value: "100k", variant: :info)
StatCard(label: "Failed Deployments", value: "2", variant: :danger)
StatCard(label: "Success Rate", value: "98%", variant: :success)
StatCard(label: "Opportunities", value: "15", variant: :purple)
```

### Limitations

- **Label-based only**: Heuristics analyze the `label:` kwarg, not the `value:`. Consider using clearer label text.
- **Dynamic labels only**: Heuristics only work with literal string values. If using `label: t("key")`, the default `:info` is used.
- **Plural matching**: Patterns use substring matching (e.g., `opportunit` matches both `opportunity` and `opportunities`).

## Running Auto-Corrections

```bash
# View violations with inferred variants
ruby vendor/local_gems/phlex-lint/bin/phlex-lint

# Auto-correct all violations with inferred variants
ruby vendor/local_gems/phlex-lint/bin/phlex-lint --auto-fix

# See which violations are auto-correctable
ruby vendor/local_gems/phlex-lint/bin/phlex-lint --docs
```

## Adding More Heuristics

To add heuristics for other components:

1. Add an `infer_variant` method to the rule class
2. Call it from the `auto_correct` method
3. Update this file with the new patterns

Example:

```ruby
# In lib/phlex_lint/rules/badge_requires_type.rb
def infer_badge_type(node)
  label = extract_label(node)
  return :info unless label

  label_lower = label.downcase
  
  return :success if label_lower.match?(/complete|done|ok/)
  return :danger if label_lower.match?(/error|failed/)
  
  :info
end
```
