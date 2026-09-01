# AddBookScreen Phase 2 Plan

Mechanically refactor the large build body in lib/screen/addbook_screen.dart into private widget-builder methods, preserving exact behavior and state flow. The goal is readability and safer future edits without altering UI behavior, data flow, or validation outcomes.

## Steps

1. Freeze scope to build-section extraction only in lib/screen/addbook_screen.dart: no logic rewrites, no lifecycle changes, no pointer-event hack changes.
2. Extract visual sections from the Column children, keeping rendering order identical: Header, ISBN field, Find Book button, Divider, Book details fields, Status row, Purchase date, Reading done date conditional, Forgot-date conditional, Submit button.
3. Create private methods in the same State class with class-scoped dependency access only: _buildHeader, _buildISBNInput, _buildFindBookButton, _buildDetailsFields, _buildStatusRow, _buildPurchaseDateField, _buildFinishedDateFieldOrPlaceholder, _buildForgotDateButtonOrPlaceholder, _buildSubmitButton.
4. In each extracted method, preserve all existing setState and async flows exactly where they currently execute, especially for ISBN search, controller updates, and submit logic.
5. Keep conditional rendering unchanged for finished-state widgets by returning the same SizedBox placeholder behavior when status is not Finished.
6. Replace the original long children list with method calls in the same order, then format and run analyzer checks.
7. Perform behavior-focused validation manually (no feature changes expected), then prepare one refactor-only commit for Phase 2.

## Relevant File

- lib/screen/addbook_screen.dart

## Verification

1. Run formatter and analyzer on lib/screen/addbook_screen.dart and confirm zero errors.
2. Manual regression pass:
- Add mode renders with default purchase date.
- Status button highlight behavior remains unchanged.
- Finished toggles finished-date field and forgot button visibility as before.
- ISBN search success/failure snackbars still appear with same text and timing.
- Submit add/update still validates and pops with success message.
3. Compare pre/post behavior by tapping through add flow and edit flow once each.

## Decisions

- Included: mechanical extraction for readability only.
- Excluded: pointer-event repaint refactor, lifecycle relocation of edit-prefill logic, string/content updates.
- Risk control: no business-logic edits; extraction should be copy/move style.

## Further Considerations

1. Naming preference alignment before implementation:
Option A: semantic names (_buildFindBookButton).
Option B: section-index names (_buildSectionFindBook).
Recommendation: Option A for readability.
2. Conditional sections style:
Option A: keep inline ternary inside extracted methods.
Option B: early return with if and fallback SizedBox.
Recommendation: Option B for easier scanning while preserving behavior.
