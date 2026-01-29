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