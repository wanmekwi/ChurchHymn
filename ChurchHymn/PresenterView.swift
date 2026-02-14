//
//  PresenterView.swift
//  ChurchHymn
//
//  Created by paulo on 20/05/2025.
//
import SwiftUI
import AppKit

struct PresenterView: View {
    var hymn: Hymn
    @Binding var requestedIndex: Int?
    var onIndexChange: (Int) -> Void
    var onRequestClose: () -> Void
    @ObservedObject var presenterSession: PresenterSession
    @State private var index: Int = 0
    @State private var localMonitor: Any?
    @State private var globalMonitor: Any?
    @State private var cachedPresentationParts: [(label: String?, lines: [String])] = []
    @State private var cachedHymnId: UUID?

    var body: some View {
        // Use cached presentation parts for better performance
        let parts = cachedPresentationParts

        // Defensive: the hymn (or its lyrics) can change while this view is alive.
        // SwiftUI may re-render before our `onChange` handlers run, so always clamp.
        let safeIndex: Int = {
            guard !parts.isEmpty else { return 0 }
            return min(max(0, index), parts.count - 1)
        }()

        GeometryReader { geometry in
            let barWidth = geometry.size.width * 0.9
            VStack(spacing: 0) {
                // MARK: Title section at top
                VStack(spacing: 0) {
                    Text(hymn.title)
                        .font(.system(size: 48, weight: .semibold))
                        .minimumScaleFactor(0.3)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white.opacity(0.9))
                        .padding(.horizontal, 32)
                        .padding(.top, 32)
                        .padding(.bottom, 16)

                    Rectangle()
                        .fill(Color.white.opacity(0.85))
                        .frame(width: barWidth, height: 6)
                }
                .padding(.bottom, 24)

                // MARK: Lyrics block
                Spacer()

                if !parts.isEmpty {
                    Text(parts[safeIndex].lines.joined(separator: "\n"))
                        .font(.system(size: 80, weight: .bold))
                        .minimumScaleFactor(0.1)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .id("lyrics-\(safeIndex)")
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.2), value: safeIndex)
                } else if let lyrics = hymn.lyrics, !lyrics.isEmpty {
                    Text(lyrics)
                        .font(.system(size: 60, weight: .bold))
                        .minimumScaleFactor(0.1)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                } else {
                    VStack(spacing: 20) {
                        Text("No lyrics available")
                            .font(.system(size: 44, weight: .semibold))
                            .foregroundColor(.white.opacity(0.7))
                        Text("Press ESC to close")
                            .font(.system(size: 20))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }

                Spacer()

                // Line and bottom bar: same 90% width so bar sits completely under the line (no inner GeometryReader so layout fills screen)
                VStack(spacing: 0) {
                    // Separator line (90% width); colour matches bottom bar text
                    Rectangle()
                        .fill(Color.white.opacity(0.85))
                        .frame(width: barWidth, height: 6)

                    // Bottom bar (below the line, same horizontal extent as line)
                    HStack {
                        // Song number bottom-left
                        if let songNumber = hymn.songNumber {
                            Text("#\(songNumber)")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(.white.opacity(0.75))
                        } else {
                            Text("")
                                .font(.system(size: 24))
                        }

                        Spacer()

                        // Musical key bottom-center
                        if let key = hymn.musicalKey, !key.isEmpty {
                            Text(key)
                                .font(.system(size: 28, weight: .semibold))
                                .foregroundColor(.white.opacity(0.85))
                        }

                        Spacer()

                        // Verse/Chorus with up/down arrows on either side (more content above/below)
                        if !parts.isEmpty {
                            HStack(spacing: 16) {
                                // Up triangle: left of label when more verses/chorus before (or at end)
                                if safeIndex > 0 || safeIndex == parts.count - 1 {
                                    Image(systemName: "arrowtriangle.up.fill")
                                        .font(.system(size: 21, weight: .semibold))
                                        .foregroundColor(.white.opacity(0.85))
                                        .transition(.opacity)
                                }

                                if let label = parts[safeIndex].label {
                                    Text(label)
                                        .font(.system(size: 24, weight: .semibold))
                                        .foregroundColor(.white.opacity(0.85))
                                } else {
                                    let verseNumber = parts.prefix(safeIndex + 1).filter { $0.label == nil }.count
                                    Text("Verse \(verseNumber)")
                                        .font(.system(size: 24, weight: .semibold))
                                        .foregroundColor(.white.opacity(0.85))
                                }

                                // Down triangle: right of label when more verses/chorus after
                                if safeIndex < parts.count - 1 {
                                    Image(systemName: "arrowtriangle.down.fill")
                                        .font(.system(size: 21, weight: .semibold))
                                        .foregroundColor(.white.opacity(0.85))
                                        .transition(.opacity)
                                }
                            }
                            .animation(.easeInOut(duration: 0.15), value: safeIndex)
                        } else {
                            Text("")
                        }
                    }
                    .frame(width: barWidth)
                    .padding(.vertical, 16)
                    .padding(.horizontal, 24)
                }
                .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black)
            .onAppear {
                updatePresentationPartsCache()
                onIndexChange(safeIndex)
                // Delay starting monitor to ensure window is ready
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    startMonitor()
                }
            }
            .onDisappear {
                stopMonitor()
            }
            .onChange(of: index) { _, newIndex in
                onIndexChange(newIndex)
            }
            .onChange(of: hymn.id) { _, _ in
                // When the hymn changes, update cache and reset to the first part
                updatePresentationPartsCache()
                index = 0
                onIndexChange(0)
            }
            .onChange(of: requestedIndex) { _, newValue in
                guard let newValue else { return }
                if !cachedPresentationParts.isEmpty, newValue >= 0, newValue < cachedPresentationParts.count {
                    index = newValue
                    onIndexChange(newValue)
                }
                // Allow re-sending the same index later.
                requestedIndex = nil
            }
        }
        .ignoresSafeArea()
    }

    private func updatePresentationPartsCache() {
        // Only update if hymn ID changed
        guard cachedHymnId != hymn.id else { return }

        cachedHymnId = hymn.id
        let allBlocks = hymn.parts
        let choruses = allBlocks.filter { $0.label != nil }
        let verses = allBlocks.filter { $0.label == nil }

        if let chorusPart = choruses.first {
            cachedPresentationParts = verses.flatMap { [$0, chorusPart] }
        } else {
            cachedPresentationParts = verses
        }
    }

    private func advance() {
        // Only advance if we're not at the last part
        if index < cachedPresentationParts.count - 1 {
            index += 1
        }
    }

    private func retreat() {
        // Only retreat if we're not at the first part
        if index > 0 {
            index -= 1
        }
    }
    
    private func handleKeyEvent(_ event: NSEvent) {
        // Get the character if available
        let char = event.characters?.lowercased().first

        switch event.keyCode {
        case 49, 124, 125: // Space, Right, Down
            DispatchQueue.main.async {
                self.advance()
            }
        case 123, 126: // Left, Up
            DispatchQueue.main.async {
                self.retreat()
            }
        case 53: // ESC key
            DispatchQueue.main.async {
                onRequestClose()
            }
        default:
            // Handle number keys (1-9) for verses and 'c' for chorus
            if let character = char {
                if character == "c" {
                    // Jump to the next chorus after the current position;
                    // if none found, wrap to the first chorus.
                    DispatchQueue.main.async {
                        let parts = self.cachedPresentationParts
                        let cur = self.index
                        // Search forward from current position
                        let afterCurrent = parts[(cur + 1)...].firstIndex(where: {
                            $0.label?.lowercased().contains("chorus") ?? false
                        })
                        // Wrap around: search from the beginning
                        let fromStart = parts.firstIndex(where: {
                            $0.label?.lowercased().contains("chorus") ?? false
                        })
                        if let target = afterCurrent ?? fromStart {
                            self.index = target
                        }
                    }
                } else if character >= "1" && character <= "9" {
                    let number = Int(String(character))!
                    // Jump to verse N (verses are parts without a label)
                    DispatchQueue.main.async {
                        var verseCount = 0
                        for (i, part) in self.cachedPresentationParts.enumerated() {
                            if part.label == nil {
                                verseCount += 1
                                if verseCount == number {
                                    self.index = i
                                    break
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private func startMonitor() {
        // Local monitor - can modify/consume events
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [self] event in
            // Only yield to the search field — not to other text views (e.g. List internals)
            if presenterSession.isSearchFieldActive {
                return event
            }

            // Pass Return through — HymnListView handles it to present the selected song
            if event.keyCode == 36 {
                return event
            }

            handleKeyEvent(event)
            return nil  // Consume the event
        }

        // Global monitor - for when presenter window is fullscreen on another display
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [self] event in
            // Skip Return — handled by HymnListView to present the selected song
            guard event.keyCode != 36 else { return }
            handleKeyEvent(event)
        }
    }

    private func stopMonitor() {
        if let m = localMonitor {
            NSEvent.removeMonitor(m)
            localMonitor = nil
        }
        if let m = globalMonitor {
            NSEvent.removeMonitor(m)
            globalMonitor = nil
        }
    }
}
