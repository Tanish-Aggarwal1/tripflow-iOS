import UIKit

class TripsListVC: UIViewController {

    @IBOutlet weak var tableView: UITableView!

    private var trips: [Trip] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "My Trips"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addTapped))
        tableView.dataSource = self
        tableView.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        trips = DatabaseManager.shared.fetchTrips()
        tableView.reloadData()
    }

    @objc private func addTapped() {
        let storyboard = UIStoryboard(name: "TanishTrips", bundle: nil)
        let createVC = storyboard.instantiateViewController(withIdentifier: "CreateTripVC")
        present(UINavigationController(rootViewController: createVC), animated: true)
    }
}

extension TripsListVC: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        trips.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TripCell", for: indexPath) as! TripCell
        cell.configure(with: trips[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let trip = trips[indexPath.row]
        let storyboard = UIStoryboard(name: "JoannStops", bundle: nil)
        let detailVC = storyboard.instantiateViewController(withIdentifier: "TripDetailVC") as! TripDetailVC
        detailVC.tripId = trip.id
        navigationController?.pushViewController(detailVC, animated: true)
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        let trip = trips[indexPath.row]
        DatabaseManager.shared.deleteTrip(id: trip.id)
        trips.remove(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: .automatic)
    }
}
