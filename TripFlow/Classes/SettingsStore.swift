import Foundation

/// Author: Neel Solanki — persists Map & Settings preferences in UserDefaults.
final class SettingsStore {

    static let shared = SettingsStore()

    private let defaults = UserDefaults.standard
    private let mapZoomKey = "settings.mapZoom"
    private let unitsKey = "settings.units"

    private init() {}

    /// Latitude/longitude span used to zoom the map. Defaults to 0.05 (~5km) before the user ever touches the slider.
    var mapZoom: Double {
        get {
            let stored = defaults.double(forKey: mapZoomKey)
            return stored == 0 ? 0.05 : stored
        }
        set { defaults.set(newValue, forKey: mapZoomKey) }
    }

    /// Distance unit used for labels: "km" or "miles". Defaults to "km".
    var units: String {
        get { defaults.string(forKey: unitsKey) ?? "km" }
        set { defaults.set(newValue, forKey: unitsKey) }
    }
}
