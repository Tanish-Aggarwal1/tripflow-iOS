import Foundation

/// Author: Joann Monteiro
/// A single stop on a trip: a place, with an optional category, notes, and photo.
struct Stop {
    /// Database row id.
    let id: Int64
    /// Id of the trip this stop belongs to.
    let tripId: Int64
    /// Display name of the stop.
    let name: String
    /// One of the fixed categories (Food/Sightseeing/Hotel/Other), if set.
    let category: String?
    /// Free-text notes about the stop, if any.
    let notes: String?
    /// Filename (not full path) of the stop's saved photo in Documents, if any.
    let photoPath: String?
    /// Position within the trip's stop list; lower sorts first.
    let sortOrder: Int
    /// Whether the user has marked this stop complete.
    let completed: Bool
}

extension Stop {
    /// Full file URL for this stop's saved photo, if it has one. Rebuilt from the
    /// stored filename each time (rather than cached) since the sandbox's Documents
    /// URL can change between app installs.
    var photoURL: URL? {
        guard let photoPath else { return nil }
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsDirectory.appendingPathComponent(photoPath)
    }
}
