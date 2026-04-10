# Phlex-Lint Quick Start

## Installation

The gem is already included in the project. Run from the project root:

```bash
bundle install
```

## Basic Usage

### Run the linter

```bash
# Lint all components and views (shows all violations)
bundle exec rake phlex_lint

# Or via CLI
ruby vendor/local_gems/phlex-lint/bin/phlex-lint

# Lint just components
bundle exec rake phlex_lint:components

# Lint just views
bundle exec rake phlex_lint:views

# Lint specific namespace
bundle exec rake phlex_lint:settings    # Settings components
bundle exec rake phlex_lint:admin       # Admin components
bundle exec rake phlex_lint:organisms   # Glass morph organisms
```

### Auto-fix violations

```bash
# Auto-fix all correctable violations
ruby vendor/local_gems/phlex-lint/bin/phlex-lint --auto-fix

# View which violations can be auto-fixed
ruby vendor/local_gems/phlex-lint/bin/phlex-lint
# Output will show:
#   ✅ 15 auto-correctable (use --auto-fix)
#   ⚠️  3 require manual fixes
```

### View documentation links

```bash
# Show documentation links for each violation
ruby vendor/local_gems/phlex-lint/bin/phlex-lint --docs
```

## How Auto-Corrections Work

### Button Variants (Auto-Inferred)

Phlex-Lint analyzes button text to choose the right variant:

```ruby
# Before
Button(text: "Save")          # Missing variant
Button(text: "Delete")        # Missing variant
Button(text: "Learn More")    # Missing variant

# After --auto-fix
Button(text: "Save", variant: :primary)        # Inferred from "Save"
Button(text: "Delete", variant: :danger)       # Inferred from "Delete"
Button(text: "Learn More", variant: :tertiary) # Inferred from "Learn"
```

**Pattern Matching:**
- `delete`, `remove`, `destroy` → `:danger`
- `cancel`, `dismiss`, `close` → `:secondary`
- `save`, `create`, `submit`, `add` → `:primary`
- `learn`, `view`, `preview`, `download` → `:tertiary`
- Everything else → `:primary`

### StatCard Variants (Auto-Inferred)

Phlex-Lint analyzes card labels to choose semantic colors:

```ruby
# Before
StatCard(label: "Revenue", value: "100k")           # Missing variant
StatCard(label: "Failed Deployments", value: "2")  # Missing variant
StatCard(label: "Success Rate", value: "98%")      # Missing variant

# After --auto-fix
StatCard(label: "Revenue", value: "100k", variant: :info)
StatCard(label: "Failed Deployments", value: "2", variant: :danger)
StatCard(label: "Success Rate", value: "98%", variant: :success)
```

**Pattern Matching:**
- `error`, `fail`, `issue`, `problem`, `offline` → `:danger`
- `warning`, `alert`, `pending`, `review` → `:warning`
- `success`, `active`, `online`, `completed` → `:success`
- `score`, `rating`, `opportunity`, `opportunity` → `:purple`
- Everything else → `:info`

### GlassCard Row Wrapper (Auto-Fixed)

```ruby
# Before
GlassCard(variant: :section, icon: "info", title: "Details")

# After --auto-fix
GlassCard(variant: :section, icon: "info", title: "Details", row_wrapper: false)
```

## What Can Be Auto-Fixed

✅ **Auto-Correctable:**
- Missing `Button` variant (inferred from text)
- Missing `StatCard` variant (inferred from label)
- Missing `GlassCard(variant: :section)` row_wrapper

❌ **Requires Manual Fix:**
- Multi-line method calls (complex to parse)
- Missing `PageContainer` wrapper (structural changes)
- Nested components that violate hierarchy

## CI/CD Integration

### Pre-commit Hook

Add to `.git/hooks/pre-commit`:

```bash
#!/bin/bash
ruby vendor/local_gems/phlex-lint/bin/phlex-lint --auto-fix
if [ $? -ne 0 ]; then
  echo "Fix linting issues before committing"
  exit 1
fi
exit 0
```

### CI Pipeline

Add to your CI workflow:

```yaml
- name: Lint Phlex Components
  run: |
    bundle exec rake phlex_lint
```

## Output Examples

### Text Format (Default)

```
app/components/button_example.rb:5:2: [phlex-lint] Button must have explicit variant
  ✅ auto-correctable (use --auto-fix)
  📚 Learn more: .claude/skills/design-system/SKILL.md

phlex-lint: 1 violation(s) found.
  ✅ 1 auto-correctable (use --auto-fix)
```

### JSON Format (For Parsing)

```bash
ruby vendor/local_gems/phlex-lint/bin/phlex-lint --format json
```

Returns:

```json
[
  {
    "file": "app/components/button.rb",
    "line": 5,
    "column": 2,
    "message": "Button must have an explicit variant kwarg",
    "rule": "ButtonRequiresVariant",
    "auto_correctable": true,
    "documentation": ".claude/skills/design-system/SKILL.md"
  }
]
```

## Customizing Heuristics

Edit the rule classes to adjust heuristics:

```ruby
# In lib/phlex_lint/rules/button_requires_variant.rb
def infer_button_variant(node)
  text = extract_text_content(node)
  return :primary unless text
  
  # Add your own patterns here
  return :danger if text.downcase.include?("custom_word")
  
  :primary
end
```

## See Also

- `HEURISTICS.md` — Detailed pattern documentation
- `.claude/skills/design-system/SKILL.md` — Design system component guide
- `lib/phlex_lint/rules/` — All rule implementations
