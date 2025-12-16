import SwiftUI
import Foundation
import UIKit

// MARK: - Persisted Workspace State

private struct Marker: Codable, Equatable {
    var x: CGFloat
    var y: CGFloat
}

private struct PatternWorkspaceState: Codable, Equatable {
    var round: Int
    var stitch: Int
    var markers: [Marker] // main first, then stitch images
}

private struct WorkspaceStateStore {
    @AppStorage("workspace_state_dict") private static var raw: Data = Data()

    static func loadAll() -> [String: PatternWorkspaceState] {
        guard !raw.isEmpty else { return [:] }
        return (try? JSONDecoder().decode([String: PatternWorkspaceState].self, from: raw)) ?? [:]
    }

    static func saveAll(_ dict: [String: PatternWorkspaceState]) {
        if let data = try? JSONEncoder().encode(dict) {
            raw = data
        }
    }
}

// MARK: - Recommended Catalog

private struct RecommendedPattern: Identifiable, Hashable {
    let id: String
    let name: String
    let mainAsset: String
    let stitchPrefix: String
    let initialStitchCount: Int
    let hookText: Float
    let yarnText: String
}

private extension RecommendedPattern {
    static let all: [RecommendedPattern] = [
        .init(id: "recommended.A", name: "Pattern A", mainAsset: "patternA", stitchPrefix: "patternA-", initialStitchCount: 1, hookText: 2.5, yarnText: "Color：01/24/26"),
        .init(id: "recommended.B", name: "Pattern B", mainAsset: "patternB", stitchPrefix: "patternB-", initialStitchCount: 1, hookText: 2.0, yarnText: "Color：01/01/10/09/11"),
        .init(id: "recommended.C", name: "Pattern C", mainAsset: "patternC", stitchPrefix: "patternC-", initialStitchCount: 1, hookText: 2.0, yarnText: "Color：01/02/15/05/09"),
        .init(id: "recommended.D", name: "Pattern D", mainAsset: "patternD", stitchPrefix: "patternD-", initialStitchCount: 1, hookText: 2.0, yarnText: "Color：01/16/15/10")
    ]

    func availableStitchAssets() -> [String] {
        var assets: [String] = []
        var index = 1
        while true {
            let name = "\(stitchPrefix)\(index)"
            if UIImage(named: name) != nil {
                assets.append(name)
                index += 1
            } else {
                break
            }
        }
        return assets
    }
}

// MARK: - Shared Card (used by both sections)

private struct GridPatternCard: View {
    let title: String
    let image: Image?
    let fixedWidth: CGFloat        // injected width so two cards fit per row
    private let outerHeight: CGFloat = 150
    private let imageHeight: CGFloat = 140

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // Fixed outer panel size
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.softBeige.opacity(0.6))
                    .frame(width: fixedWidth, height: outerHeight)

                // Fixed inner image area, cropped to fill
                Group {
                    if let image {
                        image
                            .resizable()
                            .scaledToFill()
                            .clipped()
                    } else {
                        ZStack {
                            Color.white.opacity(0.7)
                            Image(systemName: "photo")
                                .font(.system(size: 28, weight: .light))
                                .foregroundStyle(Color.warmBrown.opacity(0.6))
                        }
                    }
                }
                .frame(width: fixedWidth - 16, height: imageHeight)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.softBeige, lineWidth: 1)
                )
                .padding(8)
            }

            // Title line is single-line; does not affect card height
            Text(title)
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(Color.softBrownText)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .frame(width: fixedWidth) // lock title width to card width
        }
        .padding(7)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.softBeige, lineWidth: 1)
                )
        )
        // Optional: lock overall card width to align backgrounds too
        .frame(width: fixedWidth + 14) // inner fixedWidth + horizontal padding(8)*2
    }
}

// Helper to compute cell/card width so that exactly two cards fit per row
private struct TwoColumnWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

private func twoColumnCardWidth(containerWidth: CGFloat, horizontalPadding: CGFloat, interItemSpacing: CGFloat) -> CGFloat {
    // Available width inside the grid after outer horizontal padding
    let available = containerWidth - horizontalPadding * 2
    // Two items + one inter-item spacing
    return (available - interItemSpacing) / 2.0
}

// MARK: - Workspace (fullScreenCover)

private struct PatternWorkspaceView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var vm: PatternsViewModel

    enum Source: Equatable {
        case recommended(RecommendedPattern)
        case user(CrochetPattern)

        var persistenceKey: String {
            switch self {
            case .recommended(let r): return r.id
            case .user(let p): return p.id.uuidString
            }
        }

        var title: String {
            switch self {
            case .recommended(let r): return r.name
            case .user(let p): return p.name
            }
        }

        func images() -> [Image] {
            switch self {
            case .recommended(let r):
                var result: [Image] = []
                if let main = UIImage(named: r.mainAsset) {
                    result.append(Image(uiImage: main))
                }
                let stitches = r.availableStitchAssets().compactMap { UIImage(named: $0) }.map(Image.init(uiImage:))
                result.append(contentsOf: stitches)
                return result
            case .user(let p):
                var result: [Image] = []
                if let main = UIImage(data: p.imageData) {
                    result.append(Image(uiImage: main))
                }
                let stitches = p.stitchImages.compactMap { UIImage(data: $0) }.map(Image.init(uiImage:))
                result.append(contentsOf: stitches)
                return result
            }
        }

        func imageCount() -> Int { images().count }
    }

    let source: Source

    @State private var stateDict: [String: PatternWorkspaceState] = WorkspaceStateStore.loadAll()
    @State private var localState: PatternWorkspaceState
    @State private var showResetAlert = false

    // NEW: delete confirmation
    @State private var showDeleteAlert = false

    @State private var zoomSteps: [Int]
    @State private var panOffsets: [CGSize]
    @State private var lastPanOffsets: [CGSize]

    init(source: Source) {
        self.source = source
        let count = source.imageCount()
        let defaultState = PatternWorkspaceState(
            round: 0,
            stitch: 0,
            markers: Array(repeating: Marker(x: 0.5, y: 0.5), count: max(1, count))
        )
        let dict = WorkspaceStateStore.loadAll()
        _stateDict = State(initialValue: dict)
        let loaded = dict[source.persistenceKey] ?? defaultState
        _localState = State(initialValue: loaded)
        _zoomSteps = State(initialValue: Array(repeating: 0, count: max(1, count)))
        _panOffsets = State(initialValue: Array(repeating: .zero, count: max(1, count)))
        _lastPanOffsets = State(initialValue: Array(repeating: .zero, count: max(1, count)))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.creamBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: 16) {
                            // Break up type-checking by precomputing images
                            let images = source.images()
                            ForEach(Array(images.enumerated()), id: \.offset) { index, image in
                                // Precompute each binding to simplify the call
                                let zoomBinding = Binding<Int>(
                                    get: { zoomSteps.indices.contains(index) ? zoomSteps[index] : 0 },
                                    set: { newValue in
                                        if zoomSteps.indices.contains(index) { zoomSteps[index] = newValue }
                                    }
                                )
                                let panBinding = Binding<CGSize>(
                                    get: { panOffsets.indices.contains(index) ? panOffsets[index] : .zero },
                                    set: { newValue in
                                        if panOffsets.indices.contains(index) { panOffsets[index] = newValue }
                                    }
                                )
                                let lastPanBinding = Binding<CGSize>(
                                    get: { lastPanOffsets.indices.contains(index) ? lastPanOffsets[index] : .zero },
                                    set: { newValue in
                                        if lastPanOffsets.indices.contains(index) { lastPanOffsets[index] = newValue }
                                    }
                                )
                                let markerBinding = Binding<Marker>(
                                    get: {
                                        if localState.markers.indices.contains(index) {
                                            return localState.markers[index]
                                        } else {
                                            return Marker(x: 0.5, y: 0.5)
                                        }
                                    },
                                    set: { newMarker in
                                        ensureMarkerCapacity(for: index)
                                        localState.markers[index] = newMarker
                                    }
                                )

                                ZoomableImageWithMarker(
                                    image: image,
                                    zoomStep: zoomBinding,
                                    panOffset: panBinding,
                                    lastPanOffset: lastPanBinding,
                                    marker: markerBinding
                                )
                                .padding(.horizontal)
                            }

                            infoCard
                                .padding(.horizontal)
                                .padding(.top, 4)
                        }
                        .padding(.vertical, 12)
                        .padding(.bottom, 80)
                    }

                    bottomBar
                        .background(
                            VisualEffectBackground()
                                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        )
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                }
            }
            .navigationTitle(source.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        saveAndDismiss()
                    } label: {
                        Label("Close", systemImage: "xmark.circle.fill")
                            .labelStyle(.iconOnly)
                    }
                    .tint(.warmBrown)
                }
            }
            .onDisappear { saveState() }
            .alert("Reset progress?", isPresented: $showResetAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) { performReset() }
            } message: {
                Text("This will reset the round, stitch, and marker position.")
            }
            // Delete confirmation alert
            .alert("Delete this work?", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    if case .user(let pattern) = source {
                        if let idx = vm.patterns.firstIndex(where: { $0.id == pattern.id }) {
                            vm.delete(at: IndexSet(integer: idx))
                        }
                        dismiss()
                    }
                }
            } message: {
                Text("This action cannot be undone.")
            }
        }
    }

    // MARK: - Info Card shown under images
    private var infoCard: some View {
        let hookText: String
        let yarnText: String
        let noteText: String

        switch source {
        case .user(let p):
            hookText = String(format: "%.1f mm", p.hookSize)
            yarnText = p.yarn.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "（none）" : p.yarn
            noteText = p.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "" : p.notes
        case .recommended(let r):
            hookText = String(format: "%.1f mm", r.hookText)
            yarnText = r.yarnText
            noteText = ""
        }

        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 16) {
                Label {
                    Text(hookText)
                } icon: {
                    Image("鉤針icon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30)
                }
                .foregroundStyle(Color.softBrownText.opacity(0.9))

                Label {
                    Text(yarnText)
                } icon: {
                    Image("毛線icon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60)
                }
                .foregroundStyle(Color.softBrownText.opacity(0.9))
                .lineLimit(1)
            }
            VStack(alignment: .leading, spacing: 6) {
                Text("Notes:")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(Color.softBrownText.opacity(0.9))
                Text(noteText)
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(Color.softBrownText.opacity(0.9))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, 2)

            // Delete button only for user-collected patterns
            if case .user = source {
                Button(role: .destructive) {
                    showDeleteAlert = true
                } label: {
                    Label("Delete this work", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.accentColor)
                .padding(.top, 8)
            }
            
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.softBeige.opacity(0.55))
        )
    }

    private var bottomBar: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 4) {
                    Text("圈數：")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(Color.softBrownText)
                    Text("\(localState.round)")
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(Color.warmBrown)
                        .frame(minWidth: 36)
                        .padding(.vertical, 4)
                        .background(Color.softBeige.opacity(0.6))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                CapsuleStepper(value: $localState.round, range: 0...999)
            }
            .padding(12)
            .background(Color.creamBackground.opacity(0.9))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 4) {
                    Text("針數：")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(Color.softBrownText)
                    Text("\(localState.stitch)")
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(Color.warmBrown)
                        .frame(minWidth: 36)
                        .padding(.vertical, 4)
                        .background(Color.softBeige.opacity(0.6))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                CapsuleStepper(value: $localState.stitch, range: 0...999)
            }
            .padding(12)
            .background(Color.creamBackground.opacity(0.9))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Spacer()

            Button(role: .destructive) { showResetAlert = true } label: {
                Label("重置", systemImage: "arrow.counterclockwise")
            }
            .buttonStyle(.borderedProminent)
            .tint(.accentRose)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.softBeige.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.softBeige, lineWidth: 1)
                )
        )
    }

    private struct CapsuleStepper: View {
        @Binding var value: Int
        let range: ClosedRange<Int>

        var body: some View {
            HStack(spacing: 0) {
                Button { if value > range.lowerBound { value -= 1 } } label: {
                    Image(systemName: "minus")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .contentShape(Rectangle())

                Rectangle()
                    .fill(Color.softBrownText.opacity(0.25))
                    .frame(width: 1)

                Button { if value < range.upperBound { value += 1 } } label: {
                    Image(systemName: "plus")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .contentShape(Rectangle())
            }
            .frame(height: 36)
            .font(.system(.headline, design: .rounded))
            .foregroundStyle(Color.softBrownText)
            .background(Color.softBeige)
            .clipShape(Capsule())
        }
    }

    private func ensureMarkerCapacity(for index: Int) {
        if index >= localState.markers.count {
            localState.markers.append(contentsOf: Array(repeating: Marker(x: 0.5, y: 0.5), count: index - localState.markers.count + 1))
        }
    }

    private func performReset() {
        let count = source.imageCount()
        localState.round = 0
        localState.stitch = 0
        localState.markers = Array(repeating: Marker(x: 0.5, y: 0.5), count: max(1, count))
        zoomSteps = Array(repeating: 0, count: max(1, count))
        panOffsets = Array(repeating: .zero, count: max(1, count))
        lastPanOffsets = Array(repeating: .zero, count: max(1, count))
        saveState()
    }

    private func saveState() {
        stateDict[source.persistenceKey] = localState
        WorkspaceStateStore.saveAll(stateDict)
    }

    private func saveAndDismiss() {
        saveState()
        dismiss()
    }
}

private struct VisualEffectBackground: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 18)
            .fill(Color.white.opacity(0.85))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.softBeige, lineWidth: 1)
            )
    }
}

// MARK: - Zoomable Image + Marker

private struct ZoomableImageWithMarker: View {
    let image: Image

    @Binding var zoomStep: Int
    @Binding var panOffset: CGSize
    @Binding var lastPanOffset: CGSize
    @Binding var marker: Marker

    @State private var fittedSize: CGSize = .zero

    var body: some View {
        GeometryReader { geo in
            let container = geo.size

            ZStack {
                Color.white.opacity(0.6)

                ZStack(alignment: .topLeading) {
                    image
                        .resizable()
                        .scaledToFit()
                        .background(
                            GeometryReader { inner in
                                Color.clear
                                    .onAppear { fittedSize = inner.size }
                                    .onChange(of: inner.size) { _, newValue in
                                        fittedSize = newValue
                                    }
                            }
                        )

                    MarkerOverlay(marker: $marker,
                                  containerSize: container,
                                  imageSize: fittedSize)
                }
                .scaleEffect(scaleForStep(zoomStep))
                .offset(panOffset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            panOffset = CGSize(width: lastPanOffset.width + value.translation.width,
                                               height: lastPanOffset.height + value.translation.height)
                        }
                        .onEnded { _ in
                            lastPanOffset = panOffset
                        }
                )

                // Fixed controls (bottom-right): Recenter + Zoom
                VStack {
                    Spacer()
                    HStack(spacing: 10) {
                        Spacer()
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                panOffset = .zero
                                lastPanOffset = .zero
                            }
                        } label: {
                            Image(systemName: "dot.scope")
                                .font(.system(size: 18, weight: .semibold))
                                .padding(10)
                                .background(.ultraThinMaterial, in: Circle())
                        }
                        .tint(.warmBrown)

                        Button {
                            zoomStep = (zoomStep + 1) % 3
                        } label: {
                            Image(systemName: "plus.magnifyingglass")
                                .font(.system(size: 18, weight: .semibold))
                                .padding(10)
                                .background(.ultraThinMaterial, in: Circle())
                        }
                        .tint(.warmBrown)
                    }
                    .padding(10)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.softBeige, lineWidth: 1)
            )
        }
        .frame(height: 280)
    }

    private func scaleForStep(_ step: Int) -> CGFloat {
        switch step {
        case 1: return 1.8
        case 2: return 2.6
        default: return 1.0
        }
    }
}

private struct MarkerOverlay: View {
    @Binding var marker: Marker
    let containerSize: CGSize
    let imageSize: CGSize

    @State private var dragOffset: CGSize = .zero

    var body: some View {
        let origin = CGPoint(
            x: (containerSize.width - imageSize.width) / 2.0,
            y: (containerSize.height - imageSize.height) / 2.0
        )

        let baseX = origin.x + imageSize.width * marker.x
        let baseY = origin.y + imageSize.height * marker.y

        Circle()
            .fill(Color.accentRose.opacity(0.85))
            .frame(width: 20, height: 20)
            .overlay(Circle().stroke(Color.white, lineWidth: 2))
            .position(x: baseX + dragOffset.width, y: baseY + dragOffset.height)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        dragOffset = value.translation
                    }
                    .onEnded { value in
                        let finalX = value.location.x
                        let finalY = value.location.y

                        let clampedX = min(max(finalX, origin.x), origin.x + imageSize.width)
                        let clampedY = min(max(finalY, origin.y), origin.y + imageSize.height)

                        let xRatio = (clampedX - origin.x) / imageSize.width
                        let yRatio = (clampedY - origin.y) / imageSize.height

                        marker = Marker(x: xRatio, y: yRatio)
                        dragOffset = .zero
                    }
            )
            .accessibilityLabel("Progress Marker")
    }
}

private extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Main Library View

struct PatternLibraryView: View {
    @EnvironmentObject private var vm: PatternsViewModel

    @State private var selectedRecommended: RecommendedPattern?
    @State private var selectedUser: CrochetPattern?

    // Shared grid: 2 columns, spacing 12 — used by both sections to guarantee identical layout
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    private let gridInterItemSpacing: CGFloat = 22
    private let outerHorizontalPadding: CGFloat = 22

    var body: some View {
        GeometryReader { proxy in
            let containerWidth = proxy.size.width
            let cardWidth = twoColumnCardWidth(containerWidth: containerWidth,
                                               horizontalPadding: outerHorizontalPadding,
                                               interItemSpacing: gridInterItemSpacing)

            ScrollView {
                VStack(alignment: .leading, spacing: 25) {

                    Spacer(minLength: 1)

                    // Recommended
                    if !RecommendedPattern.all.isEmpty {
                        Text("Recommended")
                            .font(.custom("DancingScript-Bold", size: 30))
                            .foregroundStyle(Color.softBrownText)
                            .padding(.horizontal)

                        LazyVGrid(columns: columns, spacing: gridInterItemSpacing) {
                            ForEach(RecommendedPattern.all) { item in
                                let mainImage = UIImage(named: item.mainAsset).map(Image.init(uiImage:))
                                GridPatternCard(title: item.name, image: mainImage, fixedWidth: cardWidth)
                                    .onTapGesture { selectedRecommended = item }
                            }
                        }
                        .padding(.horizontal, outerHorizontalPadding)
                    }

                    // My Collection
                    let myCollection = vm.patterns.filter { $0.isInWorks == false }
                    Text("My Collection")
                        .font(.custom("DancingScript-Bold", size: 30))
                        .foregroundStyle(Color.softBrownText)
                        .padding(.horizontal)

                    if myCollection.isEmpty {
                        Text("No images have been collected yet.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)
                    } else {
                        LazyVGrid(columns: columns, spacing: gridInterItemSpacing) {
                            ForEach(myCollection) { pattern in
                                let mainImage = UIImage(data: pattern.imageData).map(Image.init(uiImage:))
                                GridPatternCard(title: pattern.name, image: mainImage, fixedWidth: cardWidth)
                                    .onTapGesture { selectedUser = pattern }
                            }
                        }
                        .padding(.horizontal, outerHorizontalPadding)
                        .padding(.bottom, 24)
                    }
                }
                .padding(.top, 12)
            }
        }
        .background(LinearGradient(colors: [.creamBackgroundDark, .creamBackground],
            startPoint: .top, endPoint: .bottom))
        
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack {
                    Text("Pattern Library")
                        .font(.system(size: 33, weight: .medium, design: .serif))
                        .tracking(1.5)
                        .offset(x:-60, y:20)
                }
            }
        }
        .fullScreenCover(item: $selectedRecommended) { item in
            PatternWorkspaceView(source: .recommended(item))
                .environmentObject(vm)
        }
        .fullScreenCover(item: $selectedUser) { item in
            PatternWorkspaceView(source: .user(item))
                .environmentObject(vm)
        }
    }
}
