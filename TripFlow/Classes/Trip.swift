import Foundation

/// Author: Tanish Aggarwal
/// Data model for a saved trip, mirroring a row of the `trips` SQLite table.
struct Trip {
    /// Primary key from the `trips` table.
    let id: Int64
    /// User-entered trip name.
    let name: String
    /// Trip length in days, set via the stepper on CreateTripVC.
    let days: Int
    /// ISO 8601 start date string, or nil if none was set.
    let startDate: String?
    /// ISO 8601 timestamp of when the trip was created, used for ordering.
    let createdAt: String
}
