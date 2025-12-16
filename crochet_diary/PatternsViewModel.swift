import Combine
import SwiftUI

@MainActor
final class PatternsViewModel: ObservableObject {
    @Published private(set) var patterns: [CrochetPattern] = [] {
        didSet { store.save(patterns) }
    }

    private let store = PatternsStore()

    init() {
        self.patterns = store.load()
    }

    func add(_ pattern: CrochetPattern) {
        patterns.insert(pattern, at: 0)
    }

    func update(_ pattern: CrochetPattern) {
        guard let idx = patterns.firstIndex(where: { $0.id == pattern.id }) else { return }
        patterns[idx] = pattern
    }

    func delete(at offsets: IndexSet) {
        patterns.remove(atOffsets: offsets)
    }

    // Removed toggleFinished; patterns are assigned at creation time via isInWorks
    func resetProgress(for pattern: CrochetPattern) {
        guard let idx = patterns.firstIndex(of: pattern) else { return }
        patterns[idx].currentRound = 0
        patterns[idx].currentStitch = 0
        patterns[idx].markerXRatio = 0.5
        patterns[idx].markerYRatio = 0.5
    }

    func updateProgress(for pattern: CrochetPattern, round: Int? = nil, stitch: Int? = nil, xRatio: Double? = nil, yRatio: Double? = nil) {
        guard let idx = patterns.firstIndex(of: pattern) else { return }
        if let round { patterns[idx].currentRound = max(0, round) }
        if let stitch { patterns[idx].currentStitch = max(0, stitch) }
        if let xRatio { patterns[idx].markerXRatio = min(max(0, xRatio), 1) }
        if let yRatio { patterns[idx].markerYRatio = min(max(0, yRatio), 1) }
    }
}

