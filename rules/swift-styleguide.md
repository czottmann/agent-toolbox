## Swift styleguide

Applies to all `**/*.swift` files.

### Indentation

2 spaces, no tabs.

### Code comments & code documentation

- You MUST use triple slash (`///`) for documentation comments.
- Use double slash (`//`) for Xcode directive comments ("MARK:", "TODO:", etc.) and for temporarily disabling blocks of code.
- NEVER use double slash (`//`) for documentation comments.

### `guard` clauses

`guard` clauses MUST be written multi-line. If a clause combines multiple conditions, each condition MUST be on its own line.

#### Examples

```swift
// ❌ Bad
guard somethingCondition else { return }

// ✅ Good
guard somethingCondition else {
  return
}

// ❌ Bad
guard !somethingCondition1, let something else { return }

// ✅ Good
guard !somethingCondition1,
      let something
else {
  return
}
```

Any `guard` clause must be followed by a blank line.

### `if` blocks

`if` clauses must be written multi-line. If a clause combines multiple conditions, each condition should be on its own line. If there is more than one condition, the opening bracket (`{`) should be on its own line.

#### Examples

```swift
// ❌ Bad
if !somethingCondition1, let something {
  return
}

// ✅ Good
if !somethingCondition1,
   let something
{
  return
}
```
