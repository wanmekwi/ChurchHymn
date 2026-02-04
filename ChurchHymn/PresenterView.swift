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
    var onIndexChange: (Int) -> Void
    var onDismiss: () -> Void
    @State private var index: Int = 0
    @State private var monitor: Any?
    @Environment(\.dismiss) private var dismiss

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
        GeometryReader { geo in
            let barWidth = geo.size.width * 0.9
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

                Spacer()
                // Lyrics block
                if !presentationParts.isEmpty {
                    Text(presentationParts[index].lines.joined(separator: "\n"))
                        .font(.system(size: 80, weight: .bold))
                        .minimumScaleFactor(0.1)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white)
                        .padding()
                } else if let lyrics = hymn.lyrics, !lyrics.isEmpty {
                    // Fallback: show raw lyrics if parts parsing failed
                    Text(lyrics)
                        .font(.system(size: 60, weight: .bold))
                        .minimumScaleFactor(0.1)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white)
                        .padding()
                } else {
                    // Show a test message when no lyrics are available
                    VStack(spacing: 20) {
                        Text("Test Hymn Display")
                            .font(.system(size: 60))
                            .foregroundColor(.white)
                        Text("This is a test to verify the presenter is working correctly.")
                            .font(.system(size: 30))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                        Text("Press ESC to close")
                            .font(.system(size: 20))
                            .foregroundColor(.yellow)
                    }
                    .padding()
                }
                Spacer()
                // Label or verse number at bottom right
                HStack {
                    // Copyright bottom-left
                    Text(hymn.copyright ?? "")
                        .font(.system(size: 15))
                        .foregroundColor(.white)
                    Spacer()
                    // Verse/Chorus bottom-right
                    if !presentationParts.isEmpty {
                        HStack(spacing: 8) {
                            Group {
                                if let label = presentationParts[index].label {
                                    Text(label)
                                } else {
                                    let verseNumber = presentationParts[0...index].filter { $0.label == nil }.count
                                    Text("Verse \(verseNumber)")
                                }
                            }
                            .font(.system(size: 15))
                            .foregroundColor(.white)
                            
                            // Show end indicator if we're at the last part
                            if index == presentationParts.count - 1 {
                                Image(systemName: "arrow.up.circle.fill")
                                    .font(.system(size: 15))
                                    .foregroundColor(.white.opacity(0.6))
                                    .symbolEffect(.pulse)
                            }
                        }
                    }
                }
                .padding([.bottom, .horizontal], 20)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black)
            .onAppear {
                startMonitor()
                onIndexChange(index)
            }
            .onDisappear {
                stopMonitor()
                onDismiss()
            }
            .onChange(of: index) { _, newIndex in
                onIndexChange(newIndex)
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
            // Get the character if available
            let char = event.characters?.lowercased().first
            
            switch event.keyCode {
            case 49, 36, 124, 125: // Space, Return, Right, Down
                advance()
            case 123, 126: // Left, Up
                retreat()
            case 53: // ESC key
                DispatchQueue.main.async {
                    dismiss()
                }
                return nil
            default:
                // Handle number keys (1-9) and 'c' for chorus
                if let character = char {
                    if character == "c" {
                        // Find and show chorus
                        if let chorusIndex = presentationParts.firstIndex(where: { $0.label?.lowercased().contains("chorus") ?? false }) {
                            index = chorusIndex
                            return nil
                        }
                    } else if let number = Int(String(character)) {
                        // Find and show the requested verse
                        var verseCount = 0
                        for (i, part) in presentationParts.enumerated() {
                            if part.label == nil {
                                verseCount += 1
                                if verseCount == number {
                                    index = i
                                    return nil
                                }
                            }
                        }
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
