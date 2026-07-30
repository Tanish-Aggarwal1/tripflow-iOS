import Foundation

/// Author: Joann Monteiro
/// In-memory cache of a single trip's stops, backed by DatabaseManager. Screens
/// mutate stops through this store rather than talking to the database directly,
/// so the table view's in-memory order always matches what's persisted.
final class TripStore {

    /// Id of the trip this store manages.
    let tripId: Int64

    /// Stops for this trip, kept in their saved sort order.
    private(set) var stops: [Stop] = []

    init(tripId: Int64) {
        self.tripId = tripId
    }

    /// Reloads stops for this trip from the database.
    func reload() {
        stops = DatabaseManager.shared.fetchStops(tripId: tripId)
    }

    /// Removes the stop at `index` from both the database and the in-memory array.
    func deleteStop(at index: Int) {
        let stop = stops[index]
        DatabaseManager.shared.deleteStop(id: stop.id)
        stops.remove(at: index)
    }

    /// Moves the stop at `sourceIndex` to `destinationIndex` and persists the new order for every stop.
    func moveStop(from sourceIndex: Int, to destinationIndex: Int) {
        let stop = stops.remove(at: sourceIndex)
        stops.insert(stop, at: destinationIndex)
        DatabaseManager.shared.reorderStops(tripId: tripId, orderedStopIds: stops.map { $0.id })
    }
}
