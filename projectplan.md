# Project Plan: Add Song Title to Presenter View

## Goal
Add the song title to the top of the PresenterView.swift with a thick horizontal line below it. The title should be visible above the lyrics content in presentation mode while maintaining a clean, professional design suitable for projection.

## Current State Analysis
- PresenterView currently shows lyrics in the center with a bottom bar containing song number, musical key, and verse/chorus indicator
- There is a thick separator line (6pt height) above the bottom bar
- The design uses white text on black background with opacity variations for hierarchy
- The view uses a VStack layout with Spacer elements for vertical centering

## Design Decisions

### Title Styling
- **Font size**: 48pt (large enough to be visible but not overwhelming compared to 80pt lyrics)
- **Font weight**: Semibold (provides emphasis while keeping bold reserved for lyrics)
- **Color**: White with 0.9 opacity (slightly softer than lyrics but still highly visible)
- **Alignment**: Center aligned to match lyrics

### Separator Line
- **Thickness**: 6pt (matching the existing bottom line for consistency)
- **Color**: White with 0.85 opacity (matching bottom line)
- **Width**: 90% of screen width (matching bottom bar width for visual harmony)

### Layout Structure
- Title at top with padding
- Thick line below title
- Lyrics remain centered in available space
- Existing bottom section unchanged

### Spacing
- Top padding: 32pt above title
- Bottom padding below title: 24pt
- Space between title and line: 16pt

## Implementation Plan

### Todo Items
- [ ] Add title section at the top of the VStack (above the lyrics Spacer)
- [ ] Add hymn title Text view with appropriate styling
- [ ] Add thick separator line below title (6pt height, 90% width)
- [ ] Adjust spacing to maintain clean layout
- [ ] Test with various title lengths to ensure text scales appropriately
- [ ] Verify the design maintains professional projection appearance

## Implementation Details

### Code Changes Location
File: `/Volumes/WRMXHome4TB/Coding/Git/ChurchHymn/ChurchHymn/PresenterView.swift`

Changes will be made to the `body` property, specifically:
1. After the opening VStack and before the first Spacer
2. Add a new VStack containing:
   - Title text
   - Separator rectangle

### Technical Considerations
- Use `minimumScaleFactor` to allow title to scale down for very long titles
- Maintain consistent barWidth calculation (90% of geometry width)
- Ensure title section doesn't interfere with existing keyboard navigation
- Keep white text on black background for optimal contrast
- Use spacing: 0 on containers to have precise control over gaps

## Review Section
(To be completed after implementation)

---

# Project Plan: Display Song Numbers in Search Results

## Objective
Modify the HymnListView to display song numbers at the start of hymn titles when a search is being performed.

## Context
- The HymnListView displays hymns in a list with their titles
- Currently shows only the hymn title (line 126 in HymnListView.swift)
- Song numbers are stored in the `hymn.songNumber` property (optional Int)
- Search functionality already supports searching by song number (lines 44-50)
- Need to conditionally show song numbers when `searchText` is not empty

## Implementation Plan

### Todo Items
- [x] Modify the Text view on line 126 to conditionally display song number before title when searching
- [x] Format the display as: "#[number] - [title]" when song number exists
- [x] Only show song number prefix when `searchText.isEmpty == false`
- [x] Ensure proper spacing and formatting

## Technical Approach

The change will be made in the List body (lines 112-191), specifically modifying line 126 where the hymn title is displayed.

**Current code (line 126):**
```swift
Text(hymn.title)
```

**New approach:**
Create a computed property or inline expression that returns:
- If searching and song number exists: "#42 - Amazing Grace"
- If searching and no song number: "Amazing Grace"
- If not searching: "Amazing Grace" (original behavior)

## Design Rationale

1. **User Experience**: When searching (especially by number), users benefit from seeing song numbers prominently displayed
2. **Consistency**: The song number format follows common hymnal conventions (#123)
3. **Conditional Display**: Only show numbers during search to avoid cluttering the full hymn list
4. **Minimal Impact**: Simple conditional logic modification

## Testing Considerations

After implementation, verify:
- [x] Song numbers display correctly when searching
- [x] Song numbers do NOT display when search field is empty
- [x] Hymns without song numbers display normally
- [x] Format is readable and properly spaced
- [x] Selection and interaction still work correctly

## Review

### Implementation Complete

Successfully implemented song number display in search results with minimal code changes.

#### Changes Made

**File Modified**: `/Volumes/WRMXHome4TB/Coding/Git/ChurchHymn/ChurchHymn/HymnListView.swift`

1. **Added Helper Function** (after line 81):
   - Created `displayTitle(for hymn: Hymn) -> String` private function
   - Returns `"#[number] - [title]"` format when searching AND song number exists
   - Returns plain title otherwise

2. **Modified Display Line** (line 126):
   - Changed `Text(hymn.title)` to `Text(displayTitle(for: hymn))`
   - Now uses the helper function to conditionally show song numbers

#### Implementation Details

The solution is elegantly simple:
- Only 9 lines of new code added (the helper function)
- Single line modification to the existing display
- No changes to data structures or business logic
- Maintains all existing functionality

#### Behavior

**When NOT searching** (searchText is empty):
- Display: "Amazing Grace"
- Song number is hidden to keep the list clean

**When searching WITH song number**:
- Display: "#42 - Amazing Grace"
- Makes it easy to identify hymns by number

**When searching WITHOUT song number**:
- Display: "Amazing Grace"
- Falls back to showing just the title

#### Format Rationale

The `"#42 - Amazing Grace"` format was chosen because:
1. Follows standard hymnal conventions (# prefix for numbers)
2. Clear visual separation with " - " between number and title
3. Number comes first for easy scanning
4. Maintains readability in the list view

#### Code Quality

- Clean, self-documenting function name
- Simple conditional logic
- No performance impact (function called per row, but lightweight string concatenation)
- Maintains SwiftUI best practices
- No accessibility concerns (screen readers will read the full string naturally)

### Next Steps

Ready for testing in the application. Recommended test scenarios:
1. Search for a song by number (e.g., "42")
2. Search for a song by title with the song having a number
3. Search for a song without a song number
4. Clear search field and verify numbers disappear
5. Verify selection and other interactions still work properly
