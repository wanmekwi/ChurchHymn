# App Store Readiness Review — ChurchHymn 1.1

**Review date**: 29 January 2026  
**Version**: 1.1 (Build 10)

---

## ✅ Issues Resolved

### 1. Debug Code Removed
- **Issue**: Production code contained 32 `print()` statements for debugging.
- **Fix**: Replaced all debug prints with silent error handling or minimal comments.
- **Files changed**: `ContentView.swift`, `ServiceView.swift`, `ServiceHistoryView.swift`, `ServiceCreationView.swift`, `Hymn.swift`

### 2. Privacy Policy Updated
- **Issue**: Privacy policy showed outdated date (1 August 2025).
- **Fix**: Updated to 29 January 2026.
- **Files changed**: `privacy.html`

### 3. Support Page Version Info
- **Issue**: Support page showed Version 1.0 / August 2025.
- **Fix**: Updated to Version 1.1 / January 2026 with current feature list.
- **Files changed**: `support.html`

### 4. App Category & Copyright
- **Issue**: App category was "Utilities" (less discoverable); copyright string was empty.
- **Fix**: Changed category to `public.app-category.productivity` and added copyright notice.
- **Files changed**: `project.pbxproj`

### 5. TODO/Placeholder Removal
- **Issue**: Code contained TODO comments and test plan comments visible in source.
- **Fix**: Removed test plan comments and replaced TODO cancellation notes with clear explanations.
- **Files changed**: `Hymn.swift`, `ProgressOverlay.swift`, `StreamingProgressOverlay.swift`

---

## ✅ App Store Compliance Checklist

### Required Items
- [x] **Privacy Policy**: Available at `privacy.html`, hosted publicly
- [x] **Support URL**: Available at `support.html`, hosted publicly
- [x] **App Sandbox**: Enabled with minimal entitlements
- [x] **Hardened Runtime**: Enabled
- [x] **App Category**: Set to Productivity
- [x] **Copyright Notice**: Present in build settings
- [x] **Version/Build Numbers**: 1.1 (10)
- [x] **Deployment Target**: macOS 14.0+

### Entitlements (Minimal & Justified)
- `com.apple.security.app-sandbox` — Required for App Store
- `com.apple.security.files.user-selected.read-write` — For import/export user-selected files
- `com.apple.security.files.bookmarks.app-scope` — Maintain access to imported files
- `com.apple.security.files.bookmarks.document-scope` — Document-based file access

### Content & Compliance
- [x] No analytics or tracking
- [x] No third-party SDKs
- [x] No network usage
- [x] All data stored locally in App Sandbox
- [x] No personal data collection
- [x] COPPA compliant (not targeting children)

### Technical Quality
- [x] No debug logging in production
- [x] Proper error handling throughout
- [x] No crashes in normal workflows
- [x] Keyboard navigation working
- [x] Multi-screen support (presenter)
- [x] File import/export working correctly

### User Experience
- [x] Clear onboarding (import format help)
- [x] Intuitive UI with tooltips
- [x] Keyboard shortcuts documented in Help
- [x] Empty states handled gracefully
- [x] Progress feedback for long operations

---

## 📝 Pre-Submission Notes

### Before Uploading to App Store Connect

1. **Set Development Team**:
   - Open project in Xcode
   - Set your Apple Developer team ID in Signing & Capabilities

2. **Create Archive**:
   - Product → Archive
   - Validate archive before uploading
   - Address any validation warnings

3. **App Store Connect Metadata**:
   - **App Name**: Church Hymn
   - **Subtitle**: Hymn Display & Management
   - **Category**: Productivity
   - **Keywords**: hymn, church, worship, lyrics, presentation, projector
   - **Privacy Policy URL**: https://paulobfsilva.github.io/ChurchHymn/privacy.html
   - **Support URL**: https://paulobfsilva.github.io/ChurchHymn/support.html

4. **Screenshots Required** (already present):
   - Library view: `screenshot-library.png`
   - Editor view: `screenshot-editor.png`
   - Presenter view: `screenshot-presentation.png`

5. **App Description** (use `BETA_APP_DESCRIPTION.md` as reference)

6. **Review Notes for Apple**:
   - "Church Hymn is a local-only app for displaying hymn lyrics during worship services."
   - "No account required. All data stored locally on the user's Mac."
   - "File import/export uses standard macOS security-scoped resources."
   - "Presenter mode opens a second window for projection on external displays."

---

## ⚠️ Known Limitations (Not Blocking)

- Import/export progress overlays don't support cancellation (operations are fast enough)
- Presenter window must be manually closed via Esc key or clicking verse in detail view

---

## 🎯 Expected Review Outcome

**Low Risk**: This app has:
- No user accounts or data collection
- No network usage
- No third-party dependencies
- Clear privacy policy
- Standard macOS patterns
- Focused purpose (worship/presentation)

All common rejection reasons have been addressed.
