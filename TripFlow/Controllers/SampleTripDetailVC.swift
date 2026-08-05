import UIKit

/// Read-only preview of a sample trip's stops, reached by tapping a row on the Explore tab.
/// Nothing here is persisted until the user taps "Copy Trip", which inserts the trip and its
/// stops into SQLite exactly as ExploreVC's row tap used to do directly.
final class SampleTripDetailVC: UIViewController {

    private let sampleTrip: SampleTrip
    private let tableView = UITableView(frame: .zero, style: .plain)

    init(sampleTrip: SampleTrip) {
        self.sampleTrip = sampleTrip
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = sampleTrip.name
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Copy Trip", style: .done, target: self, action: #selector(copyTapped))
        setUpTableView()
    }

    private func setUpTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(StopCell.self, forCellReuseIdentifier: "StopCell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    /// Inserts the sample trip (and all its stops) into SQLite, confirms, then pops back to Explore.
    @objc private func copyTapped() {
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
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        })
        present(alert, animated: true)
    }
}

extension SampleTripDetailVC: UITableViewDataSource, UITableViewDelegate {
    /// One row per stop.
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sampleTrip.stops.count
    }

    /// Shows the trip's day count above its stops.
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        "\(sampleTrip.days) day\(sampleTrip.days == 1 ? "" : "s")"
    }

    /// Configures a StopCell for the stop at the given row, same as TripDetailVC's own list.
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "StopCell", for: indexPath) as! StopCell
        cell.configure(with: sampleTrip.stops[indexPath.row])
        cell.selectionStyle = .none
        return cell
    }
}
