import SwiftUI

import AppKit

@MainActor
final class PresenterSession: ObservableObject {
    @Published var hymn: Hymn? = nil
    @Published var requestedIndex: Int? = nil
    /// True when the search field in HymnListView is focused.
    /// The presenter keyboard monitor yields to the search field when this is set.
    @Published var isSearchFieldActive: Bool = false
    /// Key event handler set by the active PresenterView.
    /// PresenterRootView forwards keyboard events here.
    var keyEventHandler: ((NSEvent) -> Void)?
}

struct PresenterRootView: View {
    @ObservedObject var session: PresenterSession
    let onIndexChange: (Int?) -> Void
    let onRequestClose: () -> Void
    @State private var localMonitor: Any?
    @State private var globalMonitor: Any?

    var body: some View {
        Group {
            if let hymn = session.hymn {
                PresenterView(
                    hymn: hymn,
                    requestedIndex: $session.requestedIndex,
                    onIndexChange: { onIndexChange($0) },
                    onRequestClose: onRequestClose,
                    presenterSession: session
                )
            } else {
                VStack(spacing: 18) {
                    Text("No hymn selected")
                        .font(.system(size: 44, weight: .bold))
                        .foregroundColor(.white)

                    Text("Select a hymn in ChurchHymn to display it here.")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white.opacity(0.75))
                        .multilineTextAlignment(.center)

                    Text("Press ESC to close")
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(0.6))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)
                .ignoresSafeArea()
                .onAppear {
                    onIndexChange(nil)
                }
            }
        }
        .onAppear {
            startMonitor()
        }
        .onDisappear {
            stopMonitor()
        }
    }

    private func startMonitor() {
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if session.isSearchFieldActive { return event }
            if event.keyCode == 36 { return event }

            // ESC handled at root level so it works even without a hymn
            if event.keyCode == 53 {
                onRequestClose()
                return nil
            }

            session.keyEventHandler?(event)
            return nil
        }

        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            guard event.keyCode != 36 else { return }

            if event.keyCode == 53 {
                onRequestClose()
                return
            }

            session.keyEventHandler?(event)
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
        session.keyEventHandler = nil
    }
}

