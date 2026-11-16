import SwiftUI

struct HomeView: View {
    @Environment(Router.self) private var router

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Image(systemName: "music.note.list")
                    .font(.largeTitle)
                    .foregroundStyle(.tint)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Work in progress")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text("A music game in the making")
                        .font(.title2.bold())
                    Text("Explore a small catalog and listen to song previews. This prototype focuses on browsing and playback; gameplay is still to come.")
                }

                Button {
                    router.push(.gameOnePlayer)
                } label: {
                    Label("Explore catalog", systemImage: "play.fill")
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.borderedProminent)

                Text("Previews and artwork are provided by Deezer. An internet connection is required. Previews play automatically when you open the catalog or change tracks.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Still to come")
                        .font(.headline)
                        .accessibilityAddTraits(.isHeader)
                    Text("Guessing rounds, scoring, multiplayer and settings are not implemented yet.")
                        .foregroundStyle(.secondary)
                }
            }
            .padding(24)
            .frame(maxWidth: 520, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("TuneQuest")
    }
}
