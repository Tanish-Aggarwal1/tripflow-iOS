import UIKit

/// Author: Tanish Aggarwal
/// Table view cell displaying a single trip's name and a day/start-date subtitle.
final class TripCell: UITableViewCell {
    /// Populates the cell's labels from the given trip.
    func configure(with trip: Trip) {
        textLabel?.text = trip.name
        var subtitle = "\(trip.days) day\(trip.days == 1 ? "" : "s")"
        if let startDate = trip.startDate {
            subtitle += " · starts \(startDate.prefix(10))"
        }
        detailTextLabel?.text = subtitle
    }
}
