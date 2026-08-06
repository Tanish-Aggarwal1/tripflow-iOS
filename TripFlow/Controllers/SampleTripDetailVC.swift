import UIKit

/// Author: Pratham
/// Read-only preview of a sample trip's stops, reached by tapping a row on the Explore tab.
/// Nothing here is persisted until the user taps "Copy Trip", which inserts the trip and its
/// stops into SQLite exactly as ExploreVC's row tap used to do directly.
final class SampleTripDetailVC: UIViewController {

    /// Set by ExploreVC before push.
    var sampleTrip: SampleTrip?

    /// Table view listing the sample trip's stops.
    @IBOutlet weak var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        title = sampleTrip?.name ?? "Trip"
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Copy Trip", style: .done, target: self, action: #selector(copyTapped))
        tableView.dataSource = self
        tableView.delegate = self
    }

    /// Inserts the sample trip (and all its stops) into SQLite, confirms, then pops back to Explore.
    @objc private func copyTapped() {
        guard let sampleTrip, let tripId = DatabaseManager.shared.insertTrip(name: sampleTrip.name, days: sampleTrip.days, startDate: nil) else { return }

        for (index, stop) in sampleTrip.stops.enumerated() {
            DatabaseManager.shared.insertStop(
                tripId: tripId,
                name: stop.name,
                category: stop.category,
                notes: stop.notes,
                photoPath: nil,
                sortOrder: index
            )
        }

        let alert = UIAlertController(title: "Copied to My Trips!", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        })
        present(alert, animated: true)
    }
}

extension SampleTripDetailVC: UITableViewDataSource, UITableViewDelegate {
    /// One row per stop.
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sampleTrip?.stops.count ?? 0
    }

    /// Shows the trip's day count above its stops.
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let sampleTrip else { return nil }
        return "\(sampleTrip.days) day\(sampleTrip.days == 1 ? "" : "s")"
    }

    /// Configures a StopCell for the stop at the given row, same as TripDetailVC's own list.
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "StopCell", for: indexPath) as! StopCell
        cell.selectionStyle = .none
        if let stop = sampleTrip?.stops[indexPath.row] {
            cell.configure(with: stop)
        }
        return cell
    }
}
