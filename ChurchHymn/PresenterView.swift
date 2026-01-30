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
    @State private var index: Int = 0
    @State private var monitor: Any?

    /// Sequence for presentation: if a chorus exists, repeat it after each verse;
    /// otherwise present each verse block in order.
    private var presentationParts: [(label: String?, lines: [String])] {
        let allBlocks = hymn.parts
        // Extract chorus blocks
        let choruses = allBlocks.filter { $0.label != nil }
        let verses = allBlocks.filter { $0.label == nil }
        if let chorusPart = choruses.first {
            // Interleave verse and chorus
            return verses.flatMap { [$0, chorusPart] }
        } else {
            // No chorus: just show each verse block
            return verses
        }
    }
    
    var body: some View {
        // Defensive: the hymn (or its lyrics) can change while this view is alive.
        // SwiftUI may re-render before our `onChange` handlers run, so always clamp.
        let safeIndex: Int = {
            guard !presentationParts.isEmpty else { return 0 }
            return min(max(0, index), presentationParts.count - 1)
        }()

        GeometryReader { _ in
            VStack(spacing: 0) {
                // MARK: Top bar: Title (centered) + Key (right)
                HStack {
                    Spacer()

                    Text(hymn.title)
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)

                    Spacer()

                    if let key = hymn.musicalKey, !key.isEmpty {
                        Text(key)
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundColor(.white.opacity(0.85))
                            .padding(.trailing, 24)
                    }
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 24)

                // Separator line (90% width, thicker)
                GeometryReader { geometry in
                    Rectangle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: geometry.size.width * 0.9, height: 2)
                        .frame(maxWidth: .infinity)
                }
                .frame(height: 2)

                // MARK: Lyrics block
                Spacer()

                if !presentationParts.isEmpty {
                    Text(presentationParts[safeIndex].lines.joined(separator: "\n"))
                        .font(.system(size: 80, weight: .bold))
                        .minimumScaleFactor(0.1)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
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

                // Separator line (90% width, thicker)
                GeometryReader { geometry in
                    Rectangle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: geometry.size.width * 0.9, height: 2)
                        .frame(maxWidth: .infinity)
                }
                .frame(height: 2)

                // MARK: Bottom bar
                HStack {
                    // Copyright bottom-left
                    Text(hymn.copyright ?? "")
                        .font(.system(size: 20))
                        .foregroundColor(.white.opacity(0.6))

                    Spacer()

                    // Verse/Chorus + end indicator
                    if !presentationParts.isEmpty {
                        HStack(spacing: 16) {
                            if let label = presentationParts[safeIndex].label {
                                Text(label)
                                    .font(.system(size: 24, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.85))
                            } else {
                                let verseNumber = presentationParts.prefix(safeIndex + 1).filter { $0.label == nil }.count
                                Text("Verse \(verseNumber)")
                                    .font(.system(size: 24, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.85))
                            }

                            // End of song indicator
                            if safeIndex == presentationParts.count - 1 {
                                Text("END")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 6)
                                    .background(Color.yellow)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 32)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black)
            .onAppear {
                startMonitor()
                onIndexChange(safeIndex)
            }
            .onDisappear {
                stopMonitor()
            }
            .onChange(of: index) { _, newIndex in
                onIndexChange(newIndex)
            }
            .onChange(of: hymn.id) { _, _ in
                // When the hymn changes, reset to the first part for a predictable live-update experience.
                index = 0
                onIndexChange(0)
            }
            .onChange(of: requestedIndex) { _, newValue in
                guard let newValue else { return }
                if !presentationParts.isEmpty, newValue >= 0, newValue < presentationParts.count {
                    index = newValue
                    onIndexChange(newValue)
                }
                // Allow re-sending the same index later.
                requestedIndex = nil
            }
        }
        .ignoresSafeArea()
    }
    
    private func advance() {
        // Only advance if we're not at the last part
        if index < presentationParts.count - 1 {
            index += 1
        }
    }
    
    private func retreat() {
        // Only retreat if we're not at the first part
        if index > 0 {
            index -= 1
        }
    }
    
    private func startMonitor() {
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            // Allow presenter navigation even when the main app window is focused,
            // but never steal keystrokes while the user is typing into a text field (e.g. search).
            if let responder = NSApp.keyWindow?.firstResponder,
               responder is NSTextView || responder is NSTextField {
                return event
            }

            // Only react if the presenter window exists (open/visible).
            let presenterIsOpen = NSApp.windows.contains(where: { win in
                win.identifier?.rawValue == "PresenterWindow" && win.isVisible
            })
            if !presenterIsOpen {
                return event
            }

            // Get the character if available
            let char = event.characters?.lowercased().first
            
            switch event.keyCode {
            case 49, 36, 124, 125: // Space, Return, Right, Down
                advance()
            case 123, 126: // Left, Up
                retreat()
            case 53: // ESC key
                DispatchQueue.main.async {
                    onRequestClose()
                }
                return nil
            default:
                // Handle number keys (1-9) for verses and 'c' for chorus
                if let character = char {
                    if character == "c" {
                        // Find and show chorus
                        if let chorusIndex = presentationParts.firstIndex(where: { $0.label?.lowercased().contains("chorus") ?? false }) {
                            index = chorusIndex
                        }
                        return nil
                    } else if character >= "1" && character <= "9" {
                        let number = Int(String(character))!
                        // Jump to verse N (verses are parts without a label)
                        var verseCount = 0
                        for (i, part) in presentationParts.enumerated() {
                            if part.label == nil {
                                verseCount += 1
                                if verseCount == number {
                                    index = i
                                    break
                                }
                            }
                        }
                        return nil
                    }
                }
                return event
            }
            return nil
        }
    }
    
    private func stopMonitor() {
        if let m = monitor { 
            NSEvent.removeMonitor(m)
            monitor = nil 
        }
    }
}
