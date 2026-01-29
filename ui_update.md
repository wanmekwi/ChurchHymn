# UI Redesign Plan — ChurchHymn macOS App

## Goals (no feature loss)

- Make the UI **less crowded**, more **symmetrical**, and more **professional**.
- Preserve **all existing features/functionality** (import/export, multi-select, service management, presenter).
- Improve worship flow by enabling **automatic presenter updates** when the user selects a new hymn (no need to press Escape).

---

## Current Issues (What we’re fixing)

### Visual / Layout
- **Crowded toolbar**: Too many prominent buttons with stacked icon + text.
- **Weak hierarchy in sidebar**: Filter + search + sort compete for attention.
- **Inconsistent spacing/alignment**: Some areas feel “off” and asymmetrical.
- **Service view header is busy**: Too many buttons, mixed styles.
- **Service membership indicator feels heavy**: Icon-based indicator draws too much attention.

### Workflow
- **Presenter flow is interruptive**: Changing hymns requires dismissing the presenter and re-presenting.

---

## Design Principles

- **Hierarchy first**: Primary actions are obvious; secondary actions live in menus.
- **Consistency**: Standard padding/typography/controls across views.
- **Mac-native patterns**: Prefer menus, tooltips, icon-only toolbar buttons, context menus.
- **Reduced chrome**: Use subtle separators/backgrounds rather than heavy UI.

---

## Proposed UX / UI Changes

### 1) Streamlined Toolbar

**Goal**: Reduce clutter while keeping every action accessible.

- Convert large “icon + label stacks” into **icon-only buttons** with `.help(...)` tooltips.
- Keep **only primary actions** as direct buttons:
  - Present
  - Add Hymn
- Move secondary actions into menus:
  - **Service** menu (with count badge)
  - Export menu (existing)
  - Manage menu (existing)
  - Help (existing)
- Keep keyboard shortcuts; avoid collisions:
  - Use menu shortcuts as the authoritative map, toolbar buttons are for convenience.

**Acceptance checks**
- Toolbar fits comfortably at standard window sizes.
- All previous actions remain reachable via toolbar or menu bar.

---

### 2) Refined Sidebar Layout (Library)

**Goal**: Clear hierarchy and symmetry with more breathing room.

- Keep the **Filter** segmented control at the top (All / Today’s Service).
- Replace the segmented **Sort** control with a **compact menu** (“Sort: Title ▾”) to reduce width pressure.
- Make search field styling consistent with macOS patterns and reduce vertical density.
- Keep list rows clean:
  - Title aligned
  - Service indicator becomes a **subtle dot/badge** instead of a loud icon.
- Footer count stays, but as subtle caption text.

**Acceptance checks**
- Sidebar controls are visually aligned and evenly spaced.
- List rows look consistent in both normal and multi-select modes.

---

### 3) Elegant Service View & Management

**Goal**: Service view should feel like a first-class mode, not an “extra panel”.

- Header structure:
  - Left: Service title + date
  - Right: Hymn count badge
  - Below: compact action row with icon-only buttons:
    - Add Hymns (switch back to library)
    - New Service
    - History
    - Archive
    - Clear
- List:
  - Number column with subtle styling
  - Reorder UX should use macOS-native behavior (drag/drop or a `Table` if needed)
  - Context menu per row: Remove
- Empty states: consistent and minimal.

**Acceptance checks**
- Service header is balanced and not crowded.
- Reorder feels natural on macOS.

---

### 4) Detail View Polish

**Goal**: Make hymn details easier to scan, more elegant.

- Improve typography hierarchy (title > metadata > lyrics).
- Separate metadata and lyrics visually (subtle background or spacing).
- Optional: show a small “Currently Presenting” / “Live” badge when applicable.

**Acceptance checks**
- Detail view looks readable and “finished”.

---

### 5) Live Presenter Sync (Key UX Fix)

**Goal**: When a new hymn is selected, the presenter automatically updates **without** forcing Escape/dismiss.

**Core concept**
- Keep the presenter window alive and have it observe a shared “presented hymn” state.

**Implementation strategy**
- Introduce a `@State` or `@StateObject` in `ContentView`:
  - `@State private var isLivePresenting = true` (toggle)
  - `@State private var presentedHymnId: UUID?`
- When the user selects a hymn:
  - If Live Mode is ON, update `presentedHymnId` immediately.
  - Presenter view observes changes and swaps the displayed hymn (with a short transition).
- Keep the manual “Present” button:
  - If Live Mode is OFF, “Present” sets `presentedHymnId`.
  - If Live Mode is ON, “Present” opens/activates the presenter window (but selection drives content).

**Safety / Edge cases**
- If selection becomes nil, do nothing (keep last presented hymn).
- If hymn is deleted while presenting, fall back to a safe empty state in presenter.

**Acceptance checks**
- With Live Mode ON: selecting hymn A then B updates the external display immediately.
- Presenter window stays open; no Escape required for switching hymns.
- With Live Mode OFF: current manual behavior still works.

---

### 6) Visual Consistency Pass

**Goal**: Make the whole app feel cohesive.

- Standardize spacing: 8 / 12 / 16pt.
- Standardize corner radius: 6–8pt.
- Reduce accent color usage to highlights only.
- Ensure consistent alignment across:
  - Toolbar content
  - Sidebar controls
  - Service header
  - Footer and empty states

**Acceptance checks**
- UI looks consistent across all views and modes (library/service/multi-select).

---

## Implementation Phases (Independent, Checkable)

### Phase A — Toolbar cleanup
- Update `HymnToolbar.swift` to icon-only + menus.
- Verify all actions still reachable + shortcuts still work.

### Phase B — Sidebar layout improvements
- Update `ContentView.swift` + `HymnListView.swift` for refined control layout and sort menu.
- Verify multi-select UI still works cleanly.

### Phase C — Service view redesign
- Update `ServiceView.swift` header/actions/list presentation.
- Verify service CRUD actions still work; verify reorder UX.

### Phase D — Detail view polish
- Update `DetailView.swift` / `LyricsDetailView.swift` styling only.
- Verify no functional changes.

### Phase E — Live presenter sync
- Update `ContentView.swift` and `PresenterView.swift` to support Live Mode.
- Verify selection-driven presenter updates.

### Phase F — Consistency pass
- Light touch spacing/alignment cleanup across all modified views.

---

## Recommended Order

1) Toolbar cleanup (quick win, big impact)  
2) Sidebar layout improvements  
3) Service view redesign  
4) Live presenter sync (most value for worship flow; most careful changes)  
5) Detail view polish + consistency pass

