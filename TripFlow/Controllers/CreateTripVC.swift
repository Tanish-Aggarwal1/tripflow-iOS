import UIKit
import UserNotifications

class CreateTripVC: UIViewController {

    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var daysStepper: UIStepper!
    @IBOutlet weak var daysValueLabel: UILabel!
    @IBOutlet weak var startDatePicker: UIDatePicker!

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "New Trip"
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveTapped))
        updateDaysLabel()
    }

    @IBAction func stepperChanged(_ sender: UIStepper) {
        updateDaysLabel()
    }

    private func updateDaysLabel() {
        daysValueLabel.text = "\(Int(daysStepper.value))"
    }

    @objc private func cancelTapped() {
        dismiss(animated: true)
    }

    @objc private func saveTapped() {
        let name = nameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !name.isEmpty else {
            let alert = UIAlertController(title: "Trip name required", message: nil, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }

        let startDate = ISO8601DateFormatter().string(from: startDatePicker.date)
        if let tripId = DatabaseManager.shared.insertTrip(name: name, days: Int(daysStepper.value), startDate: startDate) {
            scheduleReminder(tripId: tripId, tripName: name, startDate: startDatePicker.date)
        }
        dismiss(animated: true)
    }

    /// Fires a local notification on the morning of the trip's start date (IP-14 extra tech).
    private func scheduleReminder(tripId: Int64, tripName: String, startDate: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Trip Reminder"
        content.body = "\(tripName) starts today!"
        content.sound = .default

        var components = Calendar.current.dateComponents([.year, .month, .day], from: startDate)
        components.hour = 9
        components.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: "trip-reminder-\(tripId)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                print("Failed to schedule trip reminder: \(error)")
            }
        }
    }
}
