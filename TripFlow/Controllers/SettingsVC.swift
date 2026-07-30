import UIKit

/// Author: Neel Solanki — lets the user tune map zoom and distance units, persisted via SettingsStore.
class SettingsVC: UIViewController {

    /// Controls the latitude/longitude span (map zoom level) saved to SettingsStore.
    @IBOutlet weak var zoomSlider: UISlider!

    /// Picks the distance unit ("km" or "miles") saved to SettingsStore.
    @IBOutlet weak var unitsPicker: UIPickerView!

    private let unitOptions = ["km", "miles"]

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Settings"
        unitsPicker.dataSource = self
        unitsPicker.delegate = self

        zoomSlider.value = Float(SettingsStore.shared.mapZoom)
        if let row = unitOptions.firstIndex(of: SettingsStore.shared.units) {
            unitsPicker.selectRow(row, inComponent: 0, animated: false)
        }
    }

    @IBAction func zoomSliderChanged(_ sender: UISlider) {
        SettingsStore.shared.mapZoom = Double(sender.value)
    }
}

extension SettingsVC: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        unitOptions.count
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        unitOptions[row]
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        SettingsStore.shared.units = unitOptions[row]
    }
}
