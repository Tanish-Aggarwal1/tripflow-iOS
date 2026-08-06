import Foundation

/// A hard-coded sample itinerary shown on the Explore tab, copyable into the user's own trips.
struct SampleTrip {
    let name: String
    let days: Int
    let stops: [Stop]
}

/// Author: Pratham
/// Provides the fixed set of sample trips shown on ExploreVC. Stops use
/// placeholder id/tripId values (0) since they aren't persisted until copied;
/// DatabaseManager.insertStop assigns real ids at that point.
final class SampleTripProvider {

    static let allTrips: [SampleTrip] = [
        SampleTrip(name: "Toronto Food Tour", days: 1, stops: [
            sampleStop("St. Lawrence Market", category: "Food", notes: "Historic market hall famous for peameal bacon sandwiches."),
            sampleStop("Kensington Market", category: "Food", notes: "Eclectic neighborhood packed with street food and cafes."),
            sampleStop("PAI Northern Thai Kitchen", category: "Food", notes: "Popular spot for authentic northern Thai dishes.")
        ]),
        SampleTrip(name: "Niagara Day Trip", days: 1, stops: [
            sampleStop("Niagara Falls", category: "Sightseeing", notes: "The main event — get close on the Hornblower boat tour."),
            sampleStop("Clifton Hill", category: "Sightseeing", notes: "Tourist strip with arcades, mini golf, and attractions."),
            sampleStop("Skylon Tower", category: "Sightseeing", notes: "Observation deck with panoramic falls views."),
            sampleStop("Niagara-on-the-Lake", category: "Sightseeing", notes: "Charming wine-country town nearby.")
        ]),
        SampleTrip(name: "Muskoka Weekend Getaway", days: 3, stops: [
            sampleStop("Algonquin Park", category: "Sightseeing", notes: "Canoeing and hiking in classic Ontario wilderness."),
            sampleStop("Bala Falls", category: "Sightseeing", notes: "Small-town waterfalls right in Muskoka's \"cranberry capital\"."),
            sampleStop("Muskoka Wharf", category: "Sightseeing", notes: "Lakeside shops and steamship cruises."),
            sampleStop("JW Marriott Rosseau", category: "Hotel", notes: "Resort stay on Lake Rosseau."),
            sampleStop("The Blue Elephant", category: "Food", notes: "Local favorite for lunch after a day on the water.")
        ])
    ]

    /// Builds a placeholder Stop for a sample trip (id/tripId are unused until the trip is copied).
    private static func sampleStop(_ name: String, category: String, notes: String) -> Stop {
        Stop(id: 0, tripId: 0, name: name, category: category, notes: notes, photoPath: nil, sortOrder: 0, completed: false)
    }
}
