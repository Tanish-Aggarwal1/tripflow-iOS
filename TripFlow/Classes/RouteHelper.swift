import Foundation
import CoreLocation
import MapKit

/// Author: Neel Solanki — MapKit utilities.
final class RouteHelper: NSObject {

    static let shared = RouteHelper()

    /// Most recent location reported by `locationManager`, if any.
    private(set) var currentLocation: CLLocation?

    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()

    /// Stop.swift has no stored coordinate yet, so each stop's name is geocoded
    /// once and cached here to avoid re-hitting the geocoder on every map refresh.
    private var geocodedCoordinates: [String: CLLocationCoordinate2D] = [:]

    private override init() {
        super.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }

    /// Drops an MKPointAnnotation for each stop on `mapView`, geocoding `stop.name` to a coordinate.
    func addAnnotations(for stops: [Stop], on mapView: MKMapView) {
        mapView.removeAnnotations(mapView.annotations)

        for stop in stops {
            if let coordinate = geocodedCoordinates[stop.name] {
                addAnnotation(coordinate: coordinate, title: stop.name, on: mapView)
                continue
            }

            geocoder.geocodeAddressString(stop.name) { [weak self] placemarks, _ in
                guard let coordinate = placemarks?.first?.location?.coordinate else { return }
                // CLGeocoder's completion runs on an arbitrary background queue, and multiple
                // stops geocode concurrently, so both the cache write and the annotation add
                // must happen on the same (main) queue to avoid racing on geocodedCoordinates.
                DispatchQueue.main.async {
                    self?.geocodedCoordinates[stop.name] = coordinate
                    self?.addAnnotation(coordinate: coordinate, title: stop.name, on: mapView)
                }
            }
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
