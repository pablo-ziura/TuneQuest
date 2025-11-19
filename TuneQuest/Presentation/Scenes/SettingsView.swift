import SwiftUI
import UIKit

struct SettingsView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> SettingsViewController {
        let storyboard = UIStoryboard(name: "Settings", bundle: nil)
        guard
            let viewController = storyboard.instantiateViewController(
                withIdentifier: "SettingsViewController") as? SettingsViewController
        else {
            fatalError("Could not instantiate SettingsViewController from storyboard")
        }
        return viewController
    }

    func updateUIViewController(_ uiViewController: SettingsViewController, context: Context) {
        // Updates if needed
    }
}
