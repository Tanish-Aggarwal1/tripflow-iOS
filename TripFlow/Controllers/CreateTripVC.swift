import UIKit
import UserNotifications

/// Author: Tanish Aggarwal
/// Modal form for creating a new trip: collects a name, a day count, and an
/// optional start date, then saves via DatabaseManager and (if a reminder
/// can be delivered) schedules a local notification for the start date.
class CreateTripVC: UIViewController {

    /// Trip name text entry.
    @IBOutlet weak var nameField: UITextField!
    /// Stepper controlling the trip's length in days.
    @IBOutlet weak var daysStepper: UIStepper!
    /// Displays the stepper's current value as text.
    @IBOutlet weak var daysValueLabel: UILabel!
    /// Picker for the trip's start date, used both for display and for scheduling the reminder.
    @IBOutlet weak var startDatePicker: UIDatePicker!

    /// Sets up the nav bar (Cancel/Save), keyboard dismissal, and initial days label.
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "New Trip"
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveTapped))
        nameField.delegate = self
        view.addGestureRecognizer(UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing)))
        updateDaysLabel()
    }

    /// Keeps the days label in sync whenever the stepper value changes.
    @IBAction func stepperChanged(_ sender: UIStepper) {
        updateDaysLabel()
    }

    /// Renders the stepper's current value into daysValueLabel.
    private func updateDaysLabel() {
        daysValueLabel.text = "\(Int(daysStepper.value))"
    }

    /// Dismisses the form without saving.
    @objc private func cancelTapped() {
        dismiss(animated: true)
    }

    /// Validates the name, inserts the trip into the database, schedules a
    /// reminder notification if one can be delivered, then dismisses.
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
    /// No-ops if the user hasn't granted notification permission, since a request
    /// added without authorization would never actually be delivered.
    private func scheduleReminder(tripId: Int64, tripName: String, startDate: Date) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else { return }

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
}

extension CreateTripVC: UITextFieldDelegate {
    /// Dismisses the keyboard when the user taps Return in the name field.
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
