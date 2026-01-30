# Project Plan: Today's Worship Service (macOS) — Phase 1 (Data Foundation)

## Goal

Add the data foundation for the “Today’s Worship Service” feature by introducing SwiftData models and a small operations layer, without changing any UI yet.

## TODOs

- [ ] Add SwiftData model `WorshipService`
- [ ] Add SwiftData model `ServiceHymn` (stores `hymnId` + ordering, links to `WorshipService`)
- [ ] Add `ServiceOperations` patterned after `HymnOperations` (CRUD + ordering helpers)
- [ ] Register new models in `ChurchHymnApp.swift` model container
- [ ] Add unit tests for basic CRUD + ordering (in-memory SwiftData container)
- [ ] Build with `xcodebuild` to ensure compilation

## Notes / Assumptions

- Adding new SwiftData models should not require a custom migration plan; existing stores will simply gain new tables/entities.
- Keep fields optional where reasonable for future schema flexibility (mirroring the safety approach used in `Hymn`).

## Review (fill in after implementation)

- **Files added/changed**:
- **What changed**:
- **How to test**:
- **Follow-ups**:

---

# Project Plan: UI Upgrade — Phase A (Toolbar cleanup)

## Goal

Implement Phase A of `ui_update.md`: streamline the toolbar to be less crowded and more macOS-native, while preserving all existing actions and shortcuts.

## TODOs

- [ ] Update `HymnToolbar.swift`:
  - Keep only primary actions as direct toolbar buttons: **Present**, **Add Hymn** (icon-only, with tooltips).
  - Move secondary actions into menus: **Service** (with count badge), **Export**, **Manage**, **Help**.
  - Avoid shortcut collisions: rely on menu bar shortcuts (toolbar buttons are convenience).
- [ ] Verify all previous actions remain reachable (toolbar or menu bar) and multi-select still works.
- [ ] Build with `xcodebuild` to ensure compilation.

## Acceptance checks

- Toolbar fits comfortably at standard window sizes.
- “Present” and “Add Hymn” are obvious and quick; everything else is in menus.
- Keyboard shortcuts still work as defined in the app menu.

## Review (fill in after implementation)

- **Files changed**: `HymnToolbar.swift`, `projectplan.md`
- **What changed**: Streamlined the app toolbar to icon-only primary actions (Present, Add) and moved secondary actions into Service/Export/Manage/Help menus, reducing clutter while keeping actions reachable.
- **How to test**:
  - Run the app, confirm the toolbar shows icon-only buttons for Present/Add plus menus for Service/Export/Manage/Help.
  - Confirm menu-bar shortcuts still work (e.g. ⌘N add, ⌘I import, ⌘E edit, Export menu items, Service menu items).
  - Confirm delete is still reachable (context menu and Manage → Delete).
- **Follow-ups**: Continue with Phase B (`ContentView.swift` + `HymnListView.swift`) for sidebar layout improvements.

---

# Project Plan: UI Upgrade — Phase B (Sidebar layout improvements)

## Goal

Implement Phase B of `ui_update.md`: refine the Library sidebar layout to improve hierarchy and symmetry.

## TODOs

- [ ] Keep the Filter segmented control at the top (All / Today’s Service), but refine spacing/alignment.
- [ ] Replace the segmented Sort control with a compact menu (“Sort: Title ▾”).
- [ ] Make search field styling more macOS-native and reduce vertical density.
- [ ] Make the “in today’s service” list indicator subtle (dot/badge), and keep footer count as caption text.
- [ ] Verify multi-select UI remains clear and consistent.

## Review (fill in after implementation)

- **Files changed**: `ContentView.swift`, `HymnListView.swift`, `projectplan.md`
- **What changed**: Refined the Library sidebar header spacing, replaced the segmented sort control with a compact menu, updated search to a macOS-native rounded field, and changed the “in today’s service” indicator to a subtle dot.
- **How to test**:
  - In Library view, confirm search + sort are compact and aligned, and sort uses a menu.
  - Confirm list rows show a small dot (not an icon) for hymns in Today’s Service.
  - Confirm multi-select still works and row context menus still work.
- **Follow-ups**: Phase C (`ServiceView.swift`) redesign.

---

# Project Plan: UI Upgrade — Phase C (Service view redesign)

## Goal

Implement Phase C of `ui_update.md`: make Today’s Service feel like a first-class mode with a balanced header and a compact, icon-first action row, while preserving current service CRUD and reorder behavior.

## TODOs

- [ ] Update `ServiceView.swift` header:
  - Left: service title + date
  - Right: hymn count badge
  - Below: compact icon-only action row (Add Hymns, New Service, History, Archive, Clear)
- [ ] Update list presentation:
  - Subtle number column
  - Keep reorder via macOS-native drag (existing `onMove`)
  - Context menu per row: Remove
  - Keep empty states minimal and consistent

## Review (fill in after implementation)

- **Files changed**: `ServiceView.swift`, `projectplan.md`
- **What changed**: Redesigned the Today’s Service header to be more balanced (title/date + count badge) and replaced the busy text-button row with a compact, icon-only action row (Add, New Service, History, Archive, Clear). Polished the list’s number column and ensured reorder remains available.
- **How to test**:
  - Switch to Today’s Service: confirm the header layout and icon-only action row with tooltips.
  - Add hymns to the service, then drag to reorder; confirm order persists.
  - Right-click a row → Remove from Service works.
  - Confirm Archive/Clear still show confirmations and work as before.
- **Follow-ups**: Phase D detail view polish; Phase E live presenter sync.

---

# Project Plan: UI Upgrade — Phase D (Detail view polish)

## Goal

Implement Phase D of `ui_update.md`: make hymn details easier to scan and more “finished” by improving typography hierarchy and separating metadata from lyrics (styling only).

## TODOs

- [ ] Update `DetailView.swift` styling:
  - Title > metadata > lyrics hierarchy
  - Subtle “Presenting” badge when presenter is active (optional)
  - Keep existing actions/controls and behavior unchanged
- [ ] Update `LyricsDetailView.swift` styling:
  - More elegant section labels
  - Subtle card background to separate lyrics blocks
  - Keep current presenting highlight behavior
- [ ] Verify no functional changes.

## Review (fill in after implementation)

- **Files changed**: `DetailView.swift`, `LyricsDetailView.swift`, `projectplan.md`
- **What changed**: Improved detail typography hierarchy, added subtle metadata “pills”, added an optional “Presenting” badge when presentation is active, and made each lyrics block look like a clean card with a subtle border while preserving the current highlight behavior.
- **How to test**:
  - Open a hymn: confirm title/metadata/lyrics are more clearly separated and easier to scan.
  - Present a hymn: confirm “Presenting” badge appears and the current verse highlight still works.
  - Scroll behavior while presenting still auto-scrolls to the current verse.
- **Follow-ups**: Phase E live presenter sync; Phase F consistency pass.

---

# Project Plan: UI Upgrade — Phase E (Live presenter sync)

## Goal

Implement Phase E of `ui_update.md`: keep the presenter window alive and automatically update it when the user selects a new hymn (when Live Mode is enabled), eliminating the “dismiss/re-present” flow.

## TODOs

- [ ] Add shared presentation state in `ContentView.swift`:
  - `isLivePresenting` toggle (default ON)
  - `presentedHymnId` tracking
  - persistent presenter window hosting (reuse window)
- [ ] When selection changes:
  - if Live Mode ON and selection is non-nil → update `presentedHymnId` and presenter content
  - if selection becomes nil → keep last presented hymn
- [ ] Keep manual Present behavior:
  - Live Mode OFF: Present sets `presentedHymnId` and shows window
  - Live Mode ON: Present shows/activates window (selection drives content)
- [ ] Handle edge cases:
  - if hymn is deleted while presenting → show safe empty state (don’t crash)

## Review (fill in after implementation)

- **Files changed**: `ContentView.swift`, `HymnToolbar.swift`, `PresenterView.swift`, `PresenterSession.swift`, `projectplan.md`
- **What changed**: Added a persistent presenter session and reusable presenter window. When “Live presenter updates” is enabled, selecting a hymn updates the presenter content immediately without needing to dismiss/re-present. Manual Present behavior is preserved when Live Mode is off.
- **How to test**:
  - Enable “Live presenter updates” (Manage menu) and click Present to open the presenter window.
  - With the presenter open, click different hymns in the library and confirm the presenter updates immediately.
  - Turn Live Mode off, open presenter, change selection: presenter should NOT change until you press Present again.
  - Delete a hymn that’s currently presented and confirm presenter shows a safe empty state (no crash).
- **Follow-ups**: Phase F consistency pass.

---

# Project Plan: UI Upgrade — Phase F (Consistency pass)

## Goal

Light-touch consistency cleanup across updated views: standardize spacing (8/12/16), alignments, and subtle backgrounds so the app feels cohesive.

## TODOs

- [ ] Normalize spacing/alignment in updated headers (Library, Service, Detail).
- [ ] Ensure consistent divider usage and footer styling.
- [ ] Keep changes purely visual (no behavior changes).

## Review (fill in after implementation)

- **Files changed**: `ServiceView.swift`, `DetailView.swift`, `HymnListView.swift`, `projectplan.md`
- **What changed**: Standardized small spacing differences to the 8/12/16 rhythm, added a subtle divider above the Library footer, and slightly tightened alignment/spacing in Service + Detail headers for a more cohesive feel.
- **How to test**:
  - Browse Library / Today’s Service / Detail views and confirm headers and footers feel evenly spaced and aligned.
  - Verify no behavior changes: selection, multi-select, service reorder, presenter interactions still work.
- **Follow-ups**: Optional further visual tweaks can be folded into future small passes as needed.

---

# Project Plan: App Store Readiness Review

## Goal

Prepare ChurchHymn 1.1 for App Store submission by addressing common rejection reasons and ensuring compliance.

## Issues Found & Resolved

1. **Debug logging** → Removed 32 print() statements from production code
2. **Outdated privacy policy** → Updated date to 29 January 2026
3. **Outdated support page** → Updated to Version 1.1 with current features
4. **Missing app category** → Changed from Utilities to Productivity
5. **Empty copyright** → Added proper copyright notice to build settings
6. **TODO comments** → Removed placeholder/test comments from user-facing code

## Files Changed

- Swift files: `ContentView.swift`, `ServiceView.swift`, `ServiceHistoryView.swift`, `ServiceCreationView.swift`, `Hymn.swift`, `ProgressOverlay.swift`, `StreamingProgressOverlay.swift`
- Web files: `privacy.html`, `support.html`
- Project: `project.pbxproj`
- Documentation: `APP_STORE_READINESS.md` (new)

## Review

- **Compliance status**: Ready for submission
- **Entitlements**: Minimal (sandbox + user-selected file access only)
- **Privacy**: No data collection, no network, all local
- **Technical quality**: No crashes, no debug code, proper error handling
- **Next steps**: Set development team in Xcode, create archive, upload to App Store Connect

See `APP_STORE_READINESS.md` for detailed checklist and pre-submission notes.