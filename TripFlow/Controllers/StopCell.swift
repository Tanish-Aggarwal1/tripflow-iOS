import UIKit

/// Author: Joann Monteiro
/// Notifies the cell's owner when the user taps the mark-complete button.
protocol StopCellDelegate: AnyObject {
    func stopCellDidTapComplete(_ cell: StopCell)
}

/// Author: Joann Monteiro
/// Table view cell displaying a single stop's name, category, photo thumbnail,
/// and a tappable complete/incomplete indicator.
final class StopCell: UITableViewCell {

    weak var delegate: StopCellDelegate?

    /// Accessory button toggling this stop's completed state.
    private let completeButton = UIButton(type: .system)

    /// Wires up the complete button as this cell's accessory view.
    override func awakeFromNib() {
        super.awakeFromNib()
        setUpCompleteButton()
    }

    /// Also wires up the complete button when the cell is created programmatically.
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setUpCompleteButton()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setUpCompleteButton()
    }

    private func setUpCompleteButton() {
        completeButton.frame = CGRect(x: 0, y: 0, width: 32, height: 32)
        completeButton.addTarget(self, action: #selector(completeTapped), for: .touchUpInside)
        accessoryView = completeButton
    }

    /// Populates the cell's labels, thumbnail, and complete state from the given stop.
    func configure(with stop: Stop) {
        textLabel?.text = stop.name
        detailTextLabel?.text = stop.category
        if let photoURL = stop.photoURL {
            imageView?.image = UIImage(contentsOfFile: photoURL.path)
        } else {
            imageView?.image = nil
        }

        let symbolName = stop.completed ? "checkmark.circle.fill" : "circle"
        completeButton.setImage(UIImage(systemName: symbolName), for: .normal)
        textLabel?.alpha = stop.completed ? 0.5 : 1.0
    }

    @objc private func completeTapped() {
        delegate?.stopCellDidTapComplete(self)
    }
}
