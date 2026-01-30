import SwiftUI

@MainActor
final class PresenterSession: ObservableObject {
    @Published var hymn: Hymn? = nil
    @Published var requestedIndex: Int? = nil
}

struct PresenterRootView: View {
    @ObservedObject var session: PresenterSession
    let onIndexChange: (Int?) -> Void
    let onRequestClose: () -> Void

    var body: some View {
        if let hymn = session.hymn {
            PresenterView(
                hymn: hymn,
                requestedIndex: $session.requestedIndex,
                onIndexChange: { onIndexChange($0) },
                onRequestClose: onRequestClose
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
}

