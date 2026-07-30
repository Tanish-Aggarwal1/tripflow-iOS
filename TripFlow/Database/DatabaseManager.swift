import Foundation
import SQLite3

private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

/// Author: Tanish Aggarwal
/// Singleton gateway to the app's SQLite database, using the raw C `sqlite3`
/// API directly (no ORM). Owns the `trips` and `stops` tables and exposes
/// CRUD methods used by every screen in the app.
final class DatabaseManager {

    /// Shared singleton instance; the database connection is opened once and reused.
    static let shared = DatabaseManager()

    /// Underlying sqlite3 connection handle.
    private var db: OpaquePointer?

    private init() {
        openDatabase()
    }

    // MARK: - Setup

    /// Copies the bundled database into Documents on first launch, then opens it.
    private func openDatabase() {
        let destinationURL = DatabaseManager.databaseURL()

        if !FileManager.default.fileExists(atPath: destinationURL.path) {
            copyDatabaseFromBundle(to: destinationURL)
        }

        if sqlite3_open(destinationURL.path, &db) != SQLITE_OK {
            print("DatabaseManager: failed to open database at \(destinationURL.path) - \(errorMessage)")
            db = nil
            return
        }

        sqlite3_exec(db, "PRAGMA foreign_keys = ON;", nil, nil, nil)
    }

    /// Path to the writable copy of the database in the app's Documents directory.
    private static func databaseURL() -> URL {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsDirectory.appendingPathComponent("tripflow.sqlite")
    }

    /// Copies the seed `tripflow.sqlite` from the app bundle to `destinationURL`, if not already present.
    private func copyDatabaseFromBundle(to destinationURL: URL) {
        guard let bundleURL = Bundle.main.url(forResource: "tripflow", withExtension: "sqlite") else {
            print("DatabaseManager: tripflow.sqlite not found in app bundle")
            return
        }

        do {
            try FileManager.default.copyItem(at: bundleURL, to: destinationURL)
        } catch {
            print("DatabaseManager: failed to copy tripflow.sqlite into Documents - \(error)")
        }
    }

    /// Human-readable text for the most recent sqlite3 error on this connection.
    private var errorMessage: String {
        guard let cString = sqlite3_errmsg(db) else { return "unknown error" }
        return String(cString: cString)
    }

    // MARK: - Trips

    /// Inserts a new trip row and returns its generated id, or nil on failure.
    @discardableResult
    func insertTrip(name: String, days: Int, startDate: String?) -> Int64? {
        let sql = "INSERT INTO trips (name, days, start_date, created_at) VALUES (?, ?, ?, ?);"
        var statement: OpaquePointer?
        defer { sqlite3_finalize(statement) }

        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            print("insertTrip: prepare failed - \(errorMessage)")
            return nil
        }

        sqlite3_bind_text(statement, 1, name, -1, SQLITE_TRANSIENT)
        sqlite3_bind_int(statement, 2, Int32(days))
        if let startDate {
            sqlite3_bind_text(statement, 3, startDate, -1, SQLITE_TRANSIENT)
        } else {
            sqlite3_bind_null(statement, 3)
        }
        sqlite3_bind_text(statement, 4, ISO8601DateFormatter().string(from: Date()), -1, SQLITE_TRANSIENT)

        guard sqlite3_step(statement) == SQLITE_DONE else {
            print("insertTrip: step failed - \(errorMessage)")
            return nil
        }

        return sqlite3_last_insert_rowid(db)
    }

    /// Returns all saved trips, most recently created first.
    func fetchTrips() -> [Trip] {
        let sql = "SELECT id, name, days, start_date, created_at FROM trips ORDER BY created_at DESC;"
        var statement: OpaquePointer?
        defer { sqlite3_finalize(statement) }

        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            print("fetchTrips: prepare failed - \(errorMessage)")
            return []
        }

        var trips: [Trip] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            let id = sqlite3_column_int64(statement, 0)
            let name = String(cString: sqlite3_column_text(statement, 1))
            let days = Int(sqlite3_column_int(statement, 2))
            let startDate = sqlite3_column_text(statement, 3).map { String(cString: $0) }
            let createdAt = String(cString: sqlite3_column_text(statement, 4))
            trips.append(Trip(id: id, name: name, days: days, startDate: startDate, createdAt: createdAt))
        }
        return trips
    }

    /// Deletes the trip with the given id (and, via foreign key cascade, its stops).
    @discardableResult
    func deleteTrip(id: Int64) -> Bool {
        let sql = "DELETE FROM trips WHERE id = ?;"
        var statement: OpaquePointer?
        defer { sqlite3_finalize(statement) }

        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            print("deleteTrip: prepare failed - \(errorMessage)")
            return false
        }

        sqlite3_bind_int64(statement, 1, id)

        guard sqlite3_step(statement) == SQLITE_DONE else {
            print("deleteTrip: step failed - \(errorMessage)")
            return false
        }

        return true
    }

    // MARK: - Stops

    /// Inserts a new stop under the given trip and returns its generated id, or nil on failure.
    @discardableResult
    func insertStop(tripId: Int64, name: String, category: String?, notes: String?, photoPath: String?, sortOrder: Int) -> Int64? {
        let sql = "INSERT INTO stops (trip_id, name, category, notes, photo_path, sort_order, completed) VALUES (?, ?, ?, ?, ?, ?, 0);"
        var statement: OpaquePointer?
        defer { sqlite3_finalize(statement) }

        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            print("insertStop: prepare failed - \(errorMessage)")
            return nil
        }

        sqlite3_bind_int64(statement, 1, tripId)
        sqlite3_bind_text(statement, 2, name, -1, SQLITE_TRANSIENT)
        bindOptionalText(statement, index: 3, value: category)
        bindOptionalText(statement, index: 4, value: notes)
        bindOptionalText(statement, index: 5, value: photoPath)
        sqlite3_bind_int(statement, 6, Int32(sortOrder))

        guard sqlite3_step(statement) == SQLITE_DONE else {
            print("insertStop: step failed - \(errorMessage)")
            return nil
        }

        return sqlite3_last_insert_rowid(db)
    }

    /// Returns all stops for the given trip, ordered by their saved sort order.
    func fetchStops(tripId: Int64) -> [Stop] {
        let sql = "SELECT id, trip_id, name, category, notes, photo_path, sort_order, completed FROM stops WHERE trip_id = ? ORDER BY sort_order ASC;"
        var statement: OpaquePointer?
        defer { sqlite3_finalize(statement) }

        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            print("fetchStops: prepare failed - \(errorMessage)")
            return []
        }

        sqlite3_bind_int64(statement, 1, tripId)

        var stops: [Stop] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            let id = sqlite3_column_int64(statement, 0)
            let stopTripId = sqlite3_column_int64(statement, 1)
            let name = String(cString: sqlite3_column_text(statement, 2))
            let category = sqlite3_column_text(statement, 3).map { String(cString: $0) }
            let notes = sqlite3_column_text(statement, 4).map { String(cString: $0) }
            let photoPath = sqlite3_column_text(statement, 5).map { String(cString: $0) }
            let sortOrder = Int(sqlite3_column_int(statement, 6))
            let completed = sqlite3_column_int(statement, 7) != 0
            stops.append(Stop(id: id, tripId: stopTripId, name: name, category: category, notes: notes, photoPath: photoPath, sortOrder: sortOrder, completed: completed))
        }
        return stops
    }

    /// Deletes the stop with the given id.
    @discardableResult
    func deleteStop(id: Int64) -> Bool {
        let sql = "DELETE FROM stops WHERE id = ?;"
        var statement: OpaquePointer?
        defer { sqlite3_finalize(statement) }

        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            print("deleteStop: prepare failed - \(errorMessage)")
            return false
        }

        sqlite3_bind_int64(statement, 1, id)

        guard sqlite3_step(statement) == SQLITE_DONE else {
            print("deleteStop: step failed - \(errorMessage)")
            return false
        }

        return true
    }

    /// Persists all mutable fields of `stop` (name, category, notes, photo, sort order, completed).
    @discardableResult
    func updateStop(_ stop: Stop) -> Bool {
        let sql = """
        UPDATE stops SET name = ?, category = ?, notes = ?, photo_path = ?, sort_order = ?, completed = ?
        WHERE id = ?;
        """
        var statement: OpaquePointer?
        defer { sqlite3_finalize(statement) }

        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            print("updateStop: prepare failed - \(errorMessage)")
            return false
        }

        sqlite3_bind_text(statement, 1, stop.name, -1, SQLITE_TRANSIENT)
        bindOptionalText(statement, index: 2, value: stop.category)
        bindOptionalText(statement, index: 3, value: stop.notes)
        bindOptionalText(statement, index: 4, value: stop.photoPath)
        sqlite3_bind_int(statement, 5, Int32(stop.sortOrder))
        sqlite3_bind_int(statement, 6, stop.completed ? 1 : 0)
        sqlite3_bind_int64(statement, 7, stop.id)

        guard sqlite3_step(statement) == SQLITE_DONE else {
            print("updateStop: step failed - \(errorMessage)")
            return false
        }

        return true
    }

    /// Persists a new stop order for a trip. `orderedStopIds` must already be in the desired order.
    @discardableResult
    func reorderStops(tripId: Int64, orderedStopIds: [Int64]) -> Bool {
        let sql = "UPDATE stops SET sort_order = ? WHERE id = ? AND trip_id = ?;"
        var statement: OpaquePointer?
        defer { sqlite3_finalize(statement) }

        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            print("reorderStops: prepare failed - \(errorMessage)")
            return false
        }

        for (index, stopId) in orderedStopIds.enumerated() {
            sqlite3_bind_int(statement, 1, Int32(index))
            sqlite3_bind_int64(statement, 2, stopId)
            sqlite3_bind_int64(statement, 3, tripId)

            guard sqlite3_step(statement) == SQLITE_DONE else {
                print("reorderStops: step failed - \(errorMessage)")
                return false
            }

            sqlite3_reset(statement)
        }

        return true
    }

    // MARK: - Helpers

    /// Binds `value` as text at `index`, or binds SQL NULL if it's nil.
    private func bindOptionalText(_ statement: OpaquePointer?, index: Int32, value: String?) {
        if let value {
            sqlite3_bind_text(statement, index, value, -1, SQLITE_TRANSIENT)
        } else {
            sqlite3_bind_null(statement, index)
        }
    }
}
