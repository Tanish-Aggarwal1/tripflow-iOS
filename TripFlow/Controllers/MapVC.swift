import UIKit
import MapKit

/// Author: Neel Solanki — shows the current trip's stops as pins, centered on the user's location.
class MapVC: UIViewController {

    /// Map view pinned to the safe area; shows the user's current location plus a pin per stop.
    @IBOutlet weak var mapView: MKMapView!

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Map"
        mapView.showsUserLocation = true
    }

    /// Refreshes pins every time the tab appears, in case stops changed elsewhere.
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadMostRecentTrip()
    }

    /// There's no trip-selection screen yet, so the Map tab shows whichever trip was created most recently.
    private func loadMostRecentTrip() {
        guard let mostRecentTrip = DatabaseManager.shared.fetchTrips().first else { return }
        let stops = DatabaseManager.shared.fetchStops(tripId: mostRecentTrip.id)
        RouteHelper.shared.addAnnotations(for: stops, on: mapView)
        RouteHelper.shared.fitRegion(on: mapView)
        applyZoomPreference()
    }

    /// Applies the user's saved zoom preference on top of the auto-fit region.
    private func applyZoomPreference() {
        var region = mapView.region
        region.span = MKCoordinateSpan(latitudeDelta: SettingsStore.shared.mapZoom, longitudeDelta: SettingsStore.shared.mapZoom)
        mapView.setRegion(region, animated: true)
    }
}
