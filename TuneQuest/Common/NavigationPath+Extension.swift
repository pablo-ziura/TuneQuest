import SwiftUI

extension NavigationPath {
    var binding: Binding<NavigationPath> {
        Binding(
            get: { self },
            set: { _ in
                /* extension created to get the binding value of a NavigationPath */
            }
        )
    }
}
