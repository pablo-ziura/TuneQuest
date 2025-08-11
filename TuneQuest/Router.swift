import SwiftUI

@Observable
final class Router {
    var path = NavigationPath()

    var pathBinding: Binding<NavigationPath> {
        Binding(
            get: { self.path },
            set: { self.path = $0 }
        )
    }

    func push(_ route: Route) {
        path.append(route)
    }

    func pop() {
        path.removeLast()
    }

    func popToRoot() {
        path.removeLast(path.count)
    }
}

enum Route: Hashable {
    case home
    case gameOnePlayer
    case gameMultiplayer
    case settings
}
