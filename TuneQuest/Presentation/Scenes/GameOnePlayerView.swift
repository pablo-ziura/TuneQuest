import SwiftUI

struct GameOnePlayerView: View {
    @Environment(PreviewPlayerManager.self) private var playerManager

    var body: some View {
        VStack(spacing: 32) {
            Text("Deezer Preview")
                .font(.title2)
            PreviewPlayerView()
        }
        .padding()
        .task {
            await playerManager.loadPreview(trackId: 3135556)
        }
        .navigationTitle("One Player")
    }
}

#Preview {
    GameOnePlayerView()
        .environment(PreviewPlayerManager())
}
