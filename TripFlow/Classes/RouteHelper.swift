import Foundation
import CoreLocation
import MapKit

/// Author: Neel Solanki — MapKit utilities.
final class RouteHelper: NSObject {

    static let shared = RouteHelper()

    /// Most recent location reported by `locationManager`, if any.
    private(set) var currentLocation: CLLocation?

    private let locationManager = CLLocationManager()

    /// Stop.swift has no stored coordinate yet, so each stop's name is resolved to a
    /// coordinate once and cached here to avoid re-searching on every map refresh.
    private var geocodedCoordinates: [String: CLLocationCoordinate2D] = [:]

    private override init() {
        super.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }

    /// Drops an MKPointAnnotation for each stop on `mapView`, resolving `stop.name` to a coordinate.
    func addAnnotations(for stops: [Stop], on mapView: MKMapView) {
        mapView.removeAnnotations(mapView.annotations)

        for stop in stops {
            if let coordinate = geocodedCoordinates[stop.name] {
                addAnnotation(coordinate: coordinate, title: stop.name, on: mapView)
                continue
            }

            search(for: stop.name, region: mapView.region) { [weak self] coordinate in
                guard let coordinate else { return }
                self?.geocodedCoordinates[stop.name] = coordinate
                self?.addAnnotation(coordinate: coordinate, title: stop.name, on: mapView)
            }
        }
    }

    /// Returns the coordinate for `stopName`, using the cache populated by `addAnnotations`
    /// if available, searching fresh otherwise (e.g. when opening a stop without visiting the map first).
    func coordinate(forStopName stopName: String, completion: @escaping (CLLocationCoordinate2D?) -> Void) {
        if let cached = geocodedCoordinates[stopName] {
            completion(cached)
            return
        }

        search(for: stopName, region: MKCoordinateRegion(MKMapRect.world)) { [weak self] coordinate in
            if let coordinate {
                self?.geocodedCoordinates[stopName] = coordinate
            }
            completion(coordinate)
        }
    }

    /// Resolves `name` to a coordinate via MKLocalSearch, which (unlike CLGeocoder) is tuned for
    /// point-of-interest/landmark names rather than structured addresses - a better match for
    /// freely-typed stop names like "CN Tower" or "St. Lawrence Market". `region` only biases
    /// results, so a world region effectively removes the bias when no local context is available.
    /// The completion handler is always called on the main queue.
    private func search(for name: String, region: MKCoordinateRegion, completion: @escaping (CLLocationCoordinate2D?) -> Void) {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = name
        request.region = region

        MKLocalSearch(request: request).start { response, _ in
            completion(response?.mapItems.first?.placemark.coordinate)
        }
    }

    private func addAnnotation(coordinate: CLLocationCoordinate2D, title: String, on mapView: MKMapView) {
        let pin = MKPointAnnotation()
        pin.coordinate = coordinate
        pin.title = title
        mapView.addAnnotation(pin)
    }

    /// Computes an MKCoordinateRegion bounding every annotation on `mapView` plus the user's current
    /// location, and applies it so the map opens showing the whole trip.
    func fitRegion(on mapView: MKMapView) {
        var coordinates = mapView.annotations.map { $0.coordinate }
        if let currentLocation {
            coordinates.append(currentLocation.coordinate)
        }
        guard !coordinates.isEmpty else { return }

        let latitudes = coordinates.map { $0.latitude }
        let longitudes = coordinates.map { $0.longitude }
        let center = CLLocationCoordinate2D(
            latitude: (latitudes.min()! + latitudes.max()!) / 2,
            longitude: (longitudes.min()! + longitudes.max()!) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta: (latitudes.max()! - latitudes.min()!) * 1.4 + 0.02,
            longitudeDelta: (longitudes.max()! - longitudes.min()!) * 1.4 + 0.02
        )
        mapView.setRegion(MKCoordinateRegion(center: center, span: span), animated: true)
    }

    /// Returns e.g. "3.4 km" or "2.1 mi" between two locations, respecting `SettingsStore.units`.
    func distanceString(from userLocation: CLLocation, to stopLocation: CLLocation) -> String {
        let meters = userLocation.distance(from: stopLocation)
        if SettingsStore.shared.units == "miles" {
            return String(format: "%.1f mi", meters / 1609.34)
        }
        return String(format: "%.1f km", meters / 1000)
    }
}

extension RouteHelper: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last
    }
}
