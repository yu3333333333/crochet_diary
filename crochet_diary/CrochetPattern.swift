import Foundation

struct CrochetPattern: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var imageData: Data
    var hookSize: Double
    var yarn: String
    var notes: String
    var currentRound: Int
    var currentStitch: Int
    var markerXRatio: Double
    var markerYRatio: Double

    /// Determines destination page after saving
    /// true  -> My Works (Page 4) only
    /// false -> Pattern Library (Page 1) only
    var isInWorks: Bool

    /// Marks this pattern as important
    var isStarred: Bool

    var startDate: Date?

    /// Stitch / diagram / process images (zero or many)
    var stitchImages: [Data] = []

    init(
        id: UUID = UUID(),
        name: String,
        imageData: Data,
        hookSize: Double = 3.0,
        yarn: String = "",
        notes: String = "",
        currentRound: Int = 0,
        currentStitch: Int = 0,
        markerXRatio: Double = 0.5,
        markerYRatio: Double = 0.5,
        isInWorks: Bool = false,
        isStarred: Bool = false,
        startDate: Date? = nil,
        stitchImages: [Data] = []
    ) {
        self.id = id
        self.name = name
        self.imageData = imageData
        self.hookSize = hookSize
        self.yarn = yarn
        self.notes = notes
        self.currentRound = currentRound
        self.currentStitch = currentStitch
        self.markerXRatio = markerXRatio
        self.markerYRatio = markerYRatio
        self.isInWorks = isInWorks
        self.isStarred = isStarred
        self.startDate = startDate
        self.stitchImages = stitchImages
    }
}
