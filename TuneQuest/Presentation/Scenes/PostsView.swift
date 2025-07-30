import SwiftUI

struct PostsView: View {
    @Environment(PostsViewModel.self) private var viewModel

    var body: some View {
        VStack {
            Text("Posts View")
        }
        .task {
            viewModel.fetchData()
        }
    }
}
