# Up Next

This is the short reminder list for the current stage of the app.

## High priority

### 1) Clean up the button color hack in the add-book screen
- Remove the pointer-event workaround used to force the selected button color refresh.
- Replace it with a clean `setState` pattern that updates the selected status immediately.
- Apply the same cleanup to the "forgot date" toggle button.
- Review [lib/screen/addbook_screen.dart](../lib/screen/addbook_screen.dart) after the change to confirm UI state remains consistent.

### 2) Improve the wording and clarity of the "forgot date" flow
- Replace casual text like "i forgot lol" with a clear user-facing label.
- Keep the action understandable and polished for end users.
- Make sure the toggle still preserves the intended behavior: clearing the finished date when the user genuinely does not know it.

### 3) Re-check the default date policy for new books
- Decide whether new books should start with a default purchase date or stay empty until the user selects one.
- Confirm that missing purchase dates still resolve safely when a book is marked as finished.
- Keep the fallback behavior aligned with the app's intent and user expectations.

## Verification tasks

### 4) Run a focused regression test after UI cleanup
- Re-run `flutter test test/widget_test.dart` after each cleanup patch.
- Confirm the date resolution rules still pass for blank, invalid, future, and past purchase dates.

### 5) Manual app QA
- Add a new book with no purchase date.
- Mark it as finished.
- Confirm the finish date resolves correctly.
- Clear dates via the X icon and verify the form still behaves as expected.
- Save and reopen the entry to confirm data remains consistent.

## Notes
- The date logic is already centralized and validated; the remaining work is mostly UX cleanup and verification.
- Keep changes small and focused so the app behavior remains easy to reason about.
