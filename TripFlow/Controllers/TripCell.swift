import UIKit

final class TripCell: UITableViewCell {
    func configure(with trip: Trip) {
        textLabel?.text = trip.name
        var subtitle = "\(trip.days) day\(trip.days == 1 ? "" : "s")"
        if let startDate = trip.startDate {
            subtitle += " · starts \(startDate.prefix(10))"
        }
        detailTextLabel?.text = subtitle
    }
}
