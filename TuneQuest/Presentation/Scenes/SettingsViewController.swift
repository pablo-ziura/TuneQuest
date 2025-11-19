import UIKit

class SettingsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!

    var optionList: [String] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        // Simulate network data
        for index in 1...20 {
            optionList.append("Opción \(index)")
        }

        tableView.dataSource = self
        tableView.delegate = self
    }

    @IBAction func button1Tapped(_ sender: Any) {
        print("Botón 1")
    }

    @IBAction func button2Tapped(_ sender: Any) {
        print("Botón 2")
    }

    // MARK: - UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return optionList.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as? SettingsCell
        else { return UITableViewCell() }

        cell.titleLabel.text = optionList[indexPath.row]
        cell.subtitleLabel.text = "Subtitle for \(optionList[indexPath.row])"
        cell.descriptionLabel.text =
            "This is a description for \(optionList[indexPath.row]). It can be longer and wrap to multiple lines."
        cell.iconImageView.image = UIImage(systemName: "gear")

        return cell
    }
}
