import Accessibility
import SwiftUI

struct GameOnePlayerView: View {
    @Environment(Router.self) private var router
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var viewModel: GameOnePlayerViewModel
    @State private var startAttempt = 0
    @State private var showingExitConfirmation = false

    init(viewModel: GameOnePlayerViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        Group {
            if let game = viewModel.session {
                if game.phase.isFinished {
                    results(game)
                } else {
                    playing(game)
                }
            } else if let message = viewModel.errorMessage {
                ContentUnavailableView {
                    Label("Game unavailable", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(message)
                } actions: {
                    Button("Retry") { startAttempt += 1 }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                }
            } else {
                ProgressView("Preparing your timeline…")
            }
        }
        .navigationTitle("Solo timeline")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Exit", systemImage: "xmark") {
                    if viewModel.session?.phase.isFinished == false {
                        showingExitConfirmation = true
                    } else {
                        router.popToRoot()
                    }
                }
            }
        }
        .confirmationDialog("Leave this game?", isPresented: $showingExitConfirmation, titleVisibility: .visible) {
            Button("Leave game", role: .destructive) { router.popToRoot() }
            Button("Keep playing", role: .cancel) {}
        } message: {
            Text("Your progress will be lost.")
        }
        .task(id: startAttempt) { await viewModel.start() }
        .task(id: viewModel.previewRequestID) { await viewModel.preparePreview() }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { viewModel.player.pause() }
        }
        .onChange(of: viewModel.session?.phase) { _, phase in
            let message: String?
            switch phase {
            case .correct: message = String(localized: "Correct placement. Continue to the next song.")
            case .incorrect: message = String(localized: "Incorrect placement. One life lost. Try the same song again.")
            case .won: message = String(localized: "You completed the timeline!")
            case .lost: message = String(localized: "No lives left. Game over.")
            default: message = nil
            }
            if let message { AccessibilityNotification.Announcement(message).post() }
        }
        .onDisappear { viewModel.cancel() }
    }

    private func playing(_ game: GameSession) -> some View {
        GeometryReader { geometry in
            if dynamicTypeSize.isAccessibilitySize || geometry.size.height < 560 {
                ScrollView {
                    VStack(spacing: 20) {
                        status(game)
                        timeline(game, interactive: true)
                        pendingPanel(game)
                    }
                    .padding()
                    .frame(maxWidth: 560)
                    .frame(maxWidth: .infinity)
                }
            } else {
                VStack(spacing: 0) {
                    status(game).padding()
                    ScrollView {
                        timeline(game, interactive: true)
                            .padding(.horizontal)
                            .padding(.bottom)
                            .frame(maxWidth: 560)
                            .frame(maxWidth: .infinity)
                    }
                }
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    pendingPanel(game)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(.background)
                        .overlay(alignment: .top) { Divider() }
                }
            }
        }
    }

    private func status(_ game: GameSession) -> some View {
        VStack(spacing: 10) {
            Group {
                if dynamicTypeSize.isAccessibilitySize {
                    VStack(alignment: .leading, spacing: 8) {
                        livesLabel(game)
                        progressLabel(game)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    HStack {
                        livesLabel(game)
                        Spacer(minLength: 12)
                        progressLabel(game)
                    }
                }
            }
            .font(.subheadline.weight(.semibold))
            ProgressView(value: Double(game.correctPlacements), total: Double(game.configuration.targetCorrectPlacements))
                .accessibilityLabel("Correct placements")
                .accessibilityValue("\(game.correctPlacements) of \(game.configuration.targetCorrectPlacements)")
        }
        .frame(maxWidth: 560)
    }

    private func livesLabel(_ game: GameSession) -> some View {
        Label("\(game.remainingLives) lives left", systemImage: "heart.fill")
            .fixedSize(horizontal: false, vertical: true)
    }

    private func progressLabel(_ game: GameSession) -> some View {
        Text("\(game.correctPlacements) / \(game.configuration.targetCorrectPlacements) correct")
            .fixedSize(horizontal: false, vertical: true)
    }

    private func timeline(_ game: GameSession, interactive: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Oldest to newest")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)
            if interactive {
                Text("Choose a gap, then confirm your placement.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            ForEach(Array(game.timeline.enumerated()), id: \.element.id) { index, track in
                if interactive { gap(at: index, game: game) }
                TimelineTrackView(track: track)
            }
            if interactive { gap(at: game.timeline.count, game: game) }
        }
    }

    private func gap(at index: Int, game: GameSession) -> some View {
        let selected = viewModel.selectedPosition == index
        return Button {
            viewModel.selectPosition(index)
        } label: {
            Label(gapTitle(at: index, game: game), systemImage: selected ? "checkmark.circle.fill" : "plus.circle")
                .font(.subheadline)
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                .padding(.horizontal, 12)
                .background(selected ? Color.accentColor.opacity(0.14) : Color.clear,
                            in: RoundedRectangle(cornerRadius: 10))
                .overlay {
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(selected ? Color.accentColor : Color.secondary.opacity(0.35),
                                      style: StrokeStyle(lineWidth: selected ? 2 : 1, dash: selected ? [] : [4]))
                }
        }
        .buttonStyle(.plain)
        .disabled(game.phase != .placing)
        .accessibilityLabel(positionDescription(at: index, game: game))
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityIdentifier("timeline-gap-\(index)")
    }

    private func pendingPanel(_ game: GameSession) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if game.phase == .correct {
                Label("Correct! Released in \(String(game.pendingTrack.originalReleaseYear)).", systemImage: "checkmark.circle.fill")
                    .font(.headline)
                Text(game.pendingTrack.title)
                    .foregroundStyle(.secondary)
                Button("Continue", action: viewModel.advance)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            } else {
                pendingTrack(game.pendingTrack)
                if game.phase == .incorrect {
                    Label("Incorrect. You lost one life.", systemImage: "xmark.circle.fill")
                        .font(.headline)
                    Text("Try the same song in another position. Its year is still hidden.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Button("Try again", action: viewModel.advance)
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                } else {
                    previewControls
                    if let index = viewModel.selectedPosition {
                        Text(positionDescription(at: index, game: game))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Select a position in the timeline.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    Button(action: viewModel.confirm) {
                        Text("Confirm").frame(maxWidth: .infinity, minHeight: 30)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(!viewModel.canConfirm)
                }
            }
        }
        .frame(maxWidth: 560, alignment: .leading)
    }

    private func pendingTrack(_ track: CatalogEntry) -> some View {
        HStack(alignment: .top, spacing: 12) {
            AsyncImage(url: viewModel.player.currentTrack?.album?.coverMedium.flatMap(URL.init(string:))) { phase in
                if let image = phase.image {
                    image.resizable().scaledToFill()
                } else {
                    Image(systemName: "music.note")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(.quaternary)
                }
            }
            .frame(width: 64, height: 64)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text("Song to place").font(.caption).foregroundStyle(.secondary)
                Text(track.title).font(.headline)
                Text(track.artist).font(.subheadline).foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)
        }
    }

    private var previewControls: some View {
        VStack(alignment: .leading, spacing: 8) {
            if viewModel.player.isLoading {
                ProgressView("Loading preview…")
            } else if viewModel.player.errorMessage != nil || viewModel.player.currentTrack?.preview == nil {
                Text("Audio unavailable. You can still place this song.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Button("Retry audio", action: viewModel.retryPreview)
                    .buttonStyle(.bordered)
                    .controlSize(.large)
            } else {
                HStack(spacing: 20) {
                    Button(action: viewModel.player.togglePlayback) {
                        Label(viewModel.player.isPlaying || viewModel.player.isBuffering ? "Pause" : "Play",
                              systemImage: viewModel.player.isPlaying || viewModel.player.isBuffering ? "pause.fill" : "play.fill")
                            .frame(minHeight: 44)
                    }
                    Button(action: viewModel.player.stop) {
                        Label("Stop", systemImage: "stop.fill").frame(minHeight: 44)
                    }
                    if viewModel.player.isBuffering { ProgressView("Buffering…") }
                }
                .disabled(!viewModel.player.canPlay)
            }
            Text("Audio previews provided by Deezer")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private func results(_ game: GameSession) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Label(game.phase == .won ? "Timeline complete!" : "No lives left",
                      systemImage: game.phase == .won ? "trophy.fill" : "heart.slash")
                    .font(.title.bold())
                    .accessibilityAddTraits(.isHeader)
                status(game)
                if game.phase == .lost {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("The song you were placing").font(.headline)
                        TimelineTrackView(track: game.pendingTrack)
                        Text(positionDescription(at: game.correctPosition, game: game))
                            .font(.subheadline)
                    }
                }
                VStack(spacing: 12) {
                    Button("Play again") { startAttempt += 1 }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    Button("Home") { router.popToRoot() }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                }
                .frame(maxWidth: .infinity)
                timeline(game, interactive: false)
            }
            .padding(24)
            .frame(maxWidth: 560, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
    }

    private func gapTitle(at index: Int, game: GameSession) -> String {
        if index == 0 { return String(localized: "Before \(String(game.timeline[0].originalReleaseYear))") }
        if index == game.timeline.count {
            return String(localized: "After \(String(game.timeline[index - 1].originalReleaseYear))")
        }
        return String(localized: "Between \(String(game.timeline[index - 1].originalReleaseYear)) and \(String(game.timeline[index].originalReleaseYear))")
    }

    private func positionDescription(at index: Int, game: GameSession) -> String {
        if index == 0 { return String(localized: "Before \(game.timeline[0].title)") }
        if index == game.timeline.count { return String(localized: "After \(game.timeline[index - 1].title)") }
        return String(localized: "Between \(game.timeline[index - 1].title) and \(game.timeline[index].title)")
    }
}

private struct TimelineTrackView: View {
    let track: CatalogEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(String(track.originalReleaseYear)).font(.headline).foregroundStyle(.tint)
            Text(track.title).font(.body.weight(.semibold))
            Text(track.artist).font(.subheadline).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
    }
}
