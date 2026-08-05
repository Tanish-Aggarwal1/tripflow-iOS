import UIKit
import MapKit

/// Author: Neel Solanki — shows the current trip's stops as pins, centered on the user's location.
class MapVC: UIViewController {

    /// Trip to plot. Set by TripDetailVC before pushing when opened via its "View on Map" button;
    /// left nil for the Map tab itself, which falls back to the most recently created trip.
    var tripId: Int64?

    /// Map view pinned to the safe area; shows the user's current location plus a pin per stop.
    @IBOutlet weak var mapView: MKMapView!

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Map"
        mapView.showsUserLocation = true
    }

    /// Refreshes pins every time the screen appears, in case stops changed elsewhere.
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadTrip()
    }

    /// Plots `tripId`'s stops if set; otherwise, since the Map tab has no trip-selection screen
    /// of its own, falls back to whichever trip was created most recently. Fits the region only
    /// after every stop has resolved to a coordinate, since resolving them is asynchronous -
    /// fitting any earlier would fit to whatever pins existed before this load (usually none).
    private func loadTrip() {
        guard let targetTripId = tripId ?? DatabaseManager.shared.fetchTrips().first?.id else { return }
        let stops = DatabaseManager.shared.fetchStops(tripId: targetTripId)
        RouteHelper.shared.addAnnotations(for: stops, on: mapView) { [weak self] in
            guard let self else { return }
            RouteHelper.shared.fitRegion(on: mapView)
            applyZoomPreference()
        }
    }

    /// Applies the user's saved zoom preference on top of the auto-fit region.
    private func applyZoomPreference() {
        var region = mapView.region
        region.span = MKCoordinateSpan(latitudeDelta: SettingsStore.shared.mapZoom, longitudeDelta: SettingsStore.shared.mapZoom)
        mapView.setRegion(region, animated: false)
    }
}
