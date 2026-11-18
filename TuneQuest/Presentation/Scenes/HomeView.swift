import SwiftUI

struct HomeView: View {
    @Environment(Router.self) private var router

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                Image(systemName: "music.note.list")
                    .font(.largeTitle)
                    .foregroundStyle(.tint)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Put music in its place")
                        .font(.largeTitle.bold())
                    Text("Build a timeline of songs, from oldest to newest.")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 16) {
                    Label("Start with one song and its release year.", systemImage: "music.note")
                    Label("Choose where the next song belongs, then confirm.", systemImage: "plus.circle")
                    Label("Place 10 songs correctly to win. You have 3 lives.", systemImage: "heart")
                    Label("A wrong answer costs one life. Try the same song again.", systemImage: "arrow.clockwise")
                }
                Text("We use the original release year of each recording, including an earlier album release. Songs from the same year can go in either order.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Button {
                    router.push(.gameOnePlayer)
                } label: {
                    Label("Play solo", systemImage: "play.fill")
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.borderedProminent)

                Text("Tap Play to listen. Audio previews and artwork are provided by Deezer and need an internet connection. You can still play if a preview is unavailable.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(24)
            .frame(maxWidth: 520, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("TuneQuest")
    }
}
