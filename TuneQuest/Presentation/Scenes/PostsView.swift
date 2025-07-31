import SwiftUI

struct PostsView: View {
    @Environment(PostsViewModel.self) private var viewModel

    var body: some View {
        VStack {
            Text("Posts View")
            List(viewModel.posts, id: \.id) { post in
                Text(post.title)
            }
        }
        .task {
            await viewModel.fetchData()
        }
    }
}
