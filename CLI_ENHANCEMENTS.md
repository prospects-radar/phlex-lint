# phlex-lint CLI Enhancements

## New Features

### 1. Rule Names in Output

Violations now show the specific rule name in brackets:

```bash
# Before
app/views/show.rb:12:8: [phlex-lint] Button must have an explicit variant: kwarg

# After
app/views/show.rb:12:8: [ButtonRequiresVariant] Button must have an explicit variant: kwarg
```

### 2. Skip Annotations (rubocop-compatible)

You can disable/enable specific rules using comments in your source files:

```ruby
def view_template
  # Disable a specific rule
  # phlex-lint:disable NoCustomClasses
  div(class: "my-widget") { "content" }  # No violation

  # Re-enable the rule
  # phlex-lint:enable NoCustomClasses
  div(class: "my-widget") { "content" }  # Violation reported

  # Disable multiple rules
  # phlex-lint:disable ButtonRequiresVariant,NoRawButtons
  button(class: "btn") { "Submit" }  # No violations for these rules

  # Re-enable all rules
  # phlex-lint:enable
  Button(text: "Save")  # All rules enabled

  # Disable all rules
  # phlex-lint:disable
  span(class: "custom") { "text" }  # No violations
end
```

### 3. --only Flag (rubocop-like)

Run only specific rules:

```bash
# Run only one rule
phlex-lint --only ButtonRequiresVariant

# Run multiple rules
phlex-lint --only ButtonRequiresVariant,NoRawButtons

# Use partial matching
phlex-lint --only Button  # Matches ButtonRequiresVariant, ButtonVariant, etc.
```

### 4. --list-rules

List all available rules with descriptions:

```bash
phlex-lint --list-rules
```

Output:

```
Available rules:

  - ButtonRequiresVariant
    Button must have an explicit variant: kwarg (:primary, :secondary, ...
  - NoCustomClasses
    Avoid custom CSS classes. Use design tokens (gm-*), Bootstrap utilities...
  - ClassNamingConvention
    CSS class names must use kebab-case (lowercase with hyphens)...
  ...
```

### 5. --exclude-files

Exclude files matching a pattern:

```bash
phlex-lint --exclude-files "app/views/legacy/**/*"
```

## Usage Examples

### Common Workflows

```bash
# Full check with rule names
phlex-lint

# Check only design system violations
phlex-lint --only NoCustomClasses,ClassNamingConvention,NoMixingLayerConcerns

# Check only ITCSS compliance
phlex-lint --only NoCustomClasses,ClassNamingConvention,NoMixingLayerConcerns,UtilityInComponentPosition

# Check only missing variants
phlex-lint --only ButtonRequiresVariant,StatCardRequiresVariant,BadgeRequiresType

# Check for raw HTML usage
phlex-lint --only NoRawButtons,NoRawFlexDivs,NoRawSvg

# Check for interpolated classes (blind spots)
phlex-lint --only ReviewInterpolatedClasses

# List all rules
phlex-lint --list-rules

# Run specific rules with verbose output
phlex-lint --only NoCustomClasses --verbose

# Exclude legacy files
phlex-lint --exclude-files "app/views/legacy/**/*"

# Check only components (not views)
phlex-lint "app/components/**/*.rb"

# Use with skip annotations in source
# phlex-lint:disable RuleName
```

### CI/CD Integration

```yaml
- name: Lint Phlex components
  run: |
    phlex-lint --only NoCustomClasses,ClassNamingConvention
```

```yaml
- name: Lint with JSON output
  run: |
    phlex-lint --format json > violations.json
```

## Annotation Syntax Reference

| Annotation                         | Effect                                | Example                                                      |
| ---------------------------------- | ------------------------------------- | ------------------------------------------------------------ |
| `# phlex-lint:disable`             | Disable all rules for following lines | `# phlex-lint:disable`                                       |
| `# phlex-lint:enable`              | Enable all rules for following lines  | `# phlex-lint:enable`                                        |
| `# phlex-lint:disable RuleName`    | Disable specific rule                 | `# phlex-lint:disable NoCustomClasses`                       |
| `# phlex-lint:enable RuleName`     | Enable specific rule                  | `# phlex-lint:enable NoCustomClasses`                        |
| `# phlex-lint:disable Rule1,Rule2` | Disable multiple rules                | `# phlex-lint:disable NoCustomClasses,ClassNamingConvention` |
| `# phlex-lint:enable Rule1,Rule2`  | Enable specific rules                 | `# phlex-lint:enable NoCustomClasses,ClassNamingConvention`  |

## Notes

- Skip annotations apply from the line **after** the comment
- `# phlex-lint:enable` without arguments enables **all** rules
- `# phlex-lint:enable RuleName` doesn't work as expected (it's treated as enabling only those rules, not clearing them)
- Best practice: use `# phlex-lint:enable` (without arguments) to re-enable all rules
