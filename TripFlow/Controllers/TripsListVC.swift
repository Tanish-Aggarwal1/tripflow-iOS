import UIKit

/// Author: Tanish Aggarwal
/// Root screen of the My Trips tab: lists every saved trip, lets the user
/// create a new one, delete one via swipe, or tap through to its detail screen.
class TripsListVC: UIViewController {

    /// Table view listing all saved trips.
    @IBOutlet weak var tableView: UITableView!

    /// Trips loaded from the database, refreshed each time the screen appears.
    private var trips: [Trip] = []

    /// Sets the nav title, wires up the + button, and hooks up the table view.
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "My Trips"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addTapped))
        tableView.dataSource = self
        tableView.delegate = self
    }

    /// Reloads trips from the database every time the screen appears, so a
    /// newly created (or deleted) trip is reflected immediately.
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        trips = DatabaseManager.shared.fetchTrips()
        tableView.reloadData()
    }

    /// Presents CreateTripVC modally so the user can add a new trip. Uses .fullScreen
    /// rather than the default page-sheet style, since a page sheet never fully removes
    /// this screen from the hierarchy — leaving it on-screen dismisses without firing
    /// viewWillAppear, so the newly created trip wouldn't show up until switching tabs.
    @objc private func addTapped() {
        let storyboard = UIStoryboard(name: "TanishTrips", bundle: nil)
        let createVC = storyboard.instantiateViewController(withIdentifier: "CreateTripVC")
        let nav = UINavigationController(rootViewController: createVC)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }
}

extension TripsListVC: UITableViewDataSource, UITableViewDelegate {
    /// One row per saved trip.
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        trips.count
    }

    /// Configures a TripCell for the trip at the given row.
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TripCell", for: indexPath) as! TripCell
        cell.configure(with: trips[indexPath.row])
        return cell
    }

    /// Pushes TripDetailVC (Joann's screen) for the tapped trip, passing its id.
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let trip = trips[indexPath.row]
        let storyboard = UIStoryboard(name: "JoannStops", bundle: nil)
        let detailVC = storyboard.instantiateViewController(withIdentifier: "TripDetailVC") as! TripDetailVC
        detailVC.tripId = trip.id
        navigationController?.pushViewController(detailVC, animated: true)
    }

    /// Deletes the swiped trip from the database and removes its row.
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        let trip = trips[indexPath.row]
        DatabaseManager.shared.deleteTrip(id: trip.id)
        trips.remove(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: .automatic)
    }
}
