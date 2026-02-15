//
//  LyricsDetailView.swift
//  ChurchHymn
//
//  Created by paulo on 20/05/2025.
//
import SwiftUI

struct LyricsDetailView: View {
    let hymn: Hymn
    var currentPresentationIndex: Int?
    var isPresenting: Bool
    var onSelectPart: ((Int) -> Void)? = nil
    
    @Namespace private var scrollSpace
    @State private var parts: [(label: String?, lines: [String])] = []
    @State private var cachedHymnId: UUID?

    private func updatePartsCache() {
        guard cachedHymnId != hymn.id else { return }
        cachedHymnId = hymn.id
        let allBlocks = hymn.parts
        let choruses = allBlocks.filter { $0.label != nil }
        let verses = allBlocks.filter { $0.label == nil }
        if let chorusPart = choruses.first {
            parts = verses.flatMap { [$0, chorusPart] }
        } else {
            parts = verses
        }
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if hymn.lyrics != nil {
                        ForEach(Array(parts.enumerated()), id: \.offset) { index, part in
                            VStack(alignment: .leading, spacing: 8) {
                                // Part label (if any)
                                if let label = part.label {
                                    Text(label)
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.secondary)
                                        .textCase(.uppercase)
                                } else {
                                    Text("Verse \(parts[0..<index].filter { $0.label == nil }.count + 1)")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.secondary)
                                        .textCase(.uppercase)
                                }
                                
                                // Lyrics
                                Text(part.lines.joined(separator: "\n"))
                                    .font(.body)
                                    .padding(10)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color(NSColor.textBackgroundColor))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.accentColor.opacity(isPresenting && currentPresentationIndex == index ? 0.12 : 0.0))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .strokeBorder(.quaternary, lineWidth: 1)
                                    )
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        onSelectPart?(index)
                                    }
                                    .animation(.easeInOut(duration: 0.3), value: currentPresentationIndex)
                            }
                            .id(index) // Add id for scrolling
                        }
                    } else {
                        Text("No lyrics available")
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
                .padding(16)
            }
            .onChange(of: currentPresentationIndex) { _, newIndex in
                if let index = newIndex {
                    // Scroll to the current verse with animation
                    withAnimation(.easeInOut(duration: 0.3)) {
                        proxy.scrollTo(index, anchor: .center)
                    }
                } else {
                    // When presentation ends, scroll to top
                    withAnimation(.easeInOut(duration: 0.3)) {
                        proxy.scrollTo(0, anchor: .top)
                    }
                }
            }
            .onChange(of: isPresenting) { _, presenting in
                if !presenting {
                    // When presentation ends, scroll to top
                    withAnimation(.easeInOut(duration: 0.3)) {
                        proxy.scrollTo(0, anchor: .top)
                    }
                }
            }
            .onAppear {
                updatePartsCache()
            }
            .onChange(of: hymn.id) { _, _ in
                updatePartsCache()
            }
        }
    }
}
