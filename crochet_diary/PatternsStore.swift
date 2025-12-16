import SwiftUI

final class PatternsStore {
    @AppStorage("patterns_data") private var storedData: Data = Data()

    func load() -> [CrochetPattern] {
        guard !storedData.isEmpty else { return [] }
        do {
            // First try decoding new schema
            let decoded = try JSONDecoder().decode([CrochetPattern].self, from: storedData)
            return decoded
        } catch {
            // Attempt a lightweight migration from old schema with `isFinished`
            do {
                struct OldPattern: Identifiable, Codable, Equatable {
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
                    var isFinished: Bool
                    var startDate: Date?
                }
                let old = try JSONDecoder().decode([OldPattern].self, from: storedData)
                let migrated: [CrochetPattern] = old.map {
                    CrochetPattern(
                        id: $0.id,
                        name: $0.name,
                        imageData: $0.imageData,
                        hookSize: $0.hookSize,
                        yarn: $0.yarn,
                        notes: $0.notes,
                        currentRound: $0.currentRound,
                        currentStitch: $0.currentStitch,
                        markerXRatio: $0.markerXRatio,
                        markerYRatio: $0.markerYRatio,
                        isInWorks: $0.isFinished,    // map old finished -> isInWorks
                        isStarred: false,            // default for new field
                        startDate: $0.startDate
                    )
                }
                // Save migrated data forward to new schema
                save(migrated)
                return migrated
            } catch {
                print("Failed to decode/migrate patterns: \(error)")
                return []
            }
        }
    }

    func save(_ patterns: [CrochetPattern]) {
        do {
            let data = try JSONEncoder().encode(patterns)
            storedData = data
        } catch {
            print("Failed to encode patterns: \(error)")
        }
    }
}

