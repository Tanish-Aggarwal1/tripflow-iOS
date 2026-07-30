import UIKit

/// Author: Joann Monteiro
/// Trip Detail screen: lists every stop on a trip, lets the user add one,
/// remove one via swipe, or reorder them by dragging.
class TripDetailVC: UIViewController {

    /// Set by the presenting controller (TripsListVC) before push.
    var tripId: Int64?

    /// Table view listing the trip's stops.
    @IBOutlet weak var tableView: UITableView!

    /// In-memory store for this trip's stops, backed by DatabaseManager.
    private var store: TripStore?

    /// Sets the nav title, wires up the + and Edit buttons, and hooks up the table view.
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Stops"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addStopTapped))
        navigationItem.leftBarButtonItem = editButtonItem
        tableView.dataSource = self
        tableView.delegate = self

        if let tripId {
            store = TripStore(tripId: tripId)
        }
    }

    /// Reloads stops from the database every time the screen appears, so a
    /// newly added (or deleted) stop is reflected immediately.
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        store?.reload()
        tableView.reloadData()
    }

    /// Toggles the table view's own edit mode (enables drag-to-reorder handles) with the Edit button.
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        tableView.setEditing(editing, animated: animated)
    }

    /// Presents AddStopVC for this trip, positioning the new stop at the end of the list.
    @objc private func addStopTapped() {
        guard let tripId, let store else { return }
        let storyboard = UIStoryboard(name: "JoannStops", bundle: nil)
        let addVC = storyboard.instantiateViewController(withIdentifier: "AddStopVC") as! AddStopVC
        addVC.tripId = tripId
        addVC.nextSortOrder = store.stops.count
        navigationController?.pushViewController(addVC, animated: true)
    }
}

extension TripDetailVC: UITableViewDataSource, UITableViewDelegate {
    /// One row per stop.
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        store?.stops.count ?? 0
    }

    /// Configures a StopCell for the stop at the given row.
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "StopCell", for: indexPath) as! StopCell
        if let stop = store?.stops[indexPath.row] {
            cell.configure(with: stop)
        }
        return cell
    }

    /// Deletes the swiped stop from the database and fades its row out.
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        store?.deleteStop(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: .fade)
    }

    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        true
    }

    /// Persists the new stop order (via TripStore) after a drag-to-reorder.
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        store?.moveStop(from: sourceIndexPath.row, to: destinationIndexPath.row)
    }

    /// Deselects the tapped row. Pushing into Pratham's StopDetailVC belongs here
    /// once IP-19 ships — this screen intentionally doesn't reference that class yet
    /// since it doesn't exist in this branch.
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
