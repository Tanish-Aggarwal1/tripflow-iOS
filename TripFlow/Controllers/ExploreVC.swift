import UIKit

/// Explore tab: lists hard-coded sample trips (SampleTripProvider), lets the
/// user search-filter them by name, and copies a tapped trip (plus its stops)
/// into the user's own My Trips list.
class ExploreVC: UIViewController {

    /// Table view listing the sample trips.
    @IBOutlet weak var tableView: UITableView!

    /// Filters sample trips by name (Pratham's extra tech).
    private let searchController = UISearchController(searchResultsController: nil)

    /// Sample trips currently shown, narrowed by the active search text.
    private var filteredTrips: [SampleTrip] = SampleTripProvider.allTrips

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Explore"
        tableView.dataSource = self
        tableView.delegate = self
        setUpSearchController()
    }

    /// Attaches the search controller to the nav bar and wires it up to filter the table.
    private func setUpSearchController() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search sample trips"
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
    }

    /// Inserts a copy of the sample trip (and all its stops) into SQLite, then confirms with an alert.
    private func copyToMyTrips(_ sampleTrip: SampleTrip) {
        guard let tripId = DatabaseManager.shared.insertTrip(name: sampleTrip.name, days: sampleTrip.days, startDate: nil) else { return }

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
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

extension ExploreVC: UITableViewDataSource, UITableViewDelegate {
    /// One row per filtered sample trip.
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        filteredTrips.count
    }

    /// Shows the sample trip's name and stop count.
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SampleTripCell", for: indexPath)
        let trip = filteredTrips[indexPath.row]
        cell.textLabel?.text = trip.name
        cell.detailTextLabel?.text = "\(trip.stops.count) stop\(trip.stops.count == 1 ? "" : "s")"
        return cell
    }

    /// Copies the tapped sample trip into My Trips.
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        copyToMyTrips(filteredTrips[indexPath.row])
    }
}

extension ExploreVC: UISearchResultsUpdating {
    /// Narrows filteredTrips to sample trips whose name contains the search text.
    func updateSearchResults(for searchController: UISearchController) {
        let query = searchController.searchBar.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        filteredTrips = query.isEmpty
            ? SampleTripProvider.allTrips
            : SampleTripProvider.allTrips.filter { $0.name.localizedCaseInsensitiveContains(query) }
        tableView.reloadData()
    }
}
