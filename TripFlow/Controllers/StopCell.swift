import UIKit

/// Author: Joann Monteiro
/// Table view cell displaying a single stop's name, category, and photo thumbnail.
final class StopCell: UITableViewCell {
    /// Populates the cell's labels and thumbnail from the given stop.
    func configure(with stop: Stop) {
        textLabel?.text = stop.name
        detailTextLabel?.text = stop.category
        if let photoURL = stop.photoURL {
            imageView?.image = UIImage(contentsOfFile: photoURL.path)
        } else {
            imageView?.image = nil
        }
    }
}
