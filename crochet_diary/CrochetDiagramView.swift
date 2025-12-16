import SwiftUI

struct CrochetDiagramView: View, Identifiable {
    var id: UUID { pattern.id }
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var vm: PatternsViewModel

    let pattern: CrochetPattern

    // Pinch zoom + pan
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    // 3-step zoom button state (0 -> 1.0, 1 -> 1.8, 2 -> 2.6)
    @State private var zoomStep: Int = 0

    // Marker drag
    @State private var markerDragOffset: CGSize = .zero

    // Alert
    @State private var showResetAlert = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.creamBackground.ignoresSafeArea()

                VStack(spacing: 12) {
                    ZStack {
                        diagramArea
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.white.opacity(0.6))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .padding()

                        // Fixed-position zoom button overlay (not scaled with image)
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Button {
                                    cycleZoomStep()
                                } label: {
                                    Image(systemName: "plus.magnifyingglass")
                                        .font(.system(size: 18, weight: .semibold))
                                        .padding(12)
                                        .background(.ultraThinMaterial, in: Circle())
                                }
                                .tint(.warmBrown)
                                .padding(.trailing, 24)
                                .padding(.bottom, 24)
                            }
                        }
                        .allowsHitTesting(true)
                    }

                    // Bottom fixed control bar with exactly two counters and a single reset
                    bottomBar
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                }
            }
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Label("Close", systemImage: "xmark.circle.fill")
                            .labelStyle(.iconOnly)
                    }
                    .tint(.warmBrown)
                }
                ToolbarItem(placement: .principal) {
                    Text(pattern.name)
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(Color.softBrownText)
                }
            }
            .alert("Reset progress?", isPresented: $showResetAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    vm.resetProgress(for: pattern)
                    withAnimation(.easeInOut(duration: 0.2)) {
                        // Reset local zoom/pan and marker drag and 3-step zoom
                        scale = 1.0
                        lastScale = 1.0
                        zoomStep = 0
                        offset = .zero
                        lastOffset = .zero
                        markerDragOffset = .zero
                    }
                }
            } message: {
                Text("This will reset the round, stitch, and marker position.")
            }
        }
    }

    // MARK: - Bottom Bar (Two Counters + Single Reset)
    private var bottomBar: some View {
        HStack(spacing: 16) {
            // 圈數
            HStack(spacing: 8) {
                Text("圈數")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(Color.softBrownText)
                Stepper(value: Binding(
                    get: { currentPattern.currentRound },
                    set: { vm.updateProgress(for: pattern, round: $0) }
                ), in: 0...999) {
                    Text("\(currentPattern.currentRound)")
                        .font(.system(.headline, design: .rounded))
                        .frame(minWidth: 36)
                }
                .labelsHidden()
            }
            .padding(10)
            .background(Color.creamBackground.opacity(0.9))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // 針數
            HStack(spacing: 8) {
                Text("針數")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(Color.softBrownText)
                Stepper(value: Binding(
                    get: { currentPattern.currentStitch },
                    set: { vm.updateProgress(for: pattern, stitch: $0) }
                ), in: 0...999) {
                    Text("\(currentPattern.currentStitch)")
                        .font(.system(.headline, design: .rounded))
                        .frame(minWidth: 36)
                }
                .labelsHidden()
            }
            .padding(10)
            .background(Color.creamBackground.opacity(0.9))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Spacer()

            // The ONLY reset button in this view
            Button {
                showResetAlert = true
            } label: {
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

    // MARK: - Image Area (Pinch Zoom + Pan + Stable Marker)
    private var diagramArea: some View {
        GeometryReader { geo in
            let containerSize = geo.size

            ZStack {
                if let uiImage = UIImage(data: currentPattern.imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .scaleEffect(scale)
                        .offset(offset)
                        .gesture(zoomGesture().simultaneously(with: panGesture()))
                        .overlay(alignment: .topLeading) {
                            markerOverlay(containerSize: containerSize, imageSize: imageSize(in: containerSize, for: uiImage))
                        }
                        .animation(.spring(response: 0.25, dampingFraction: 0.9), value: scale)
                        .animation(.spring(response: 0.25, dampingFraction: 0.9), value: offset)
                } else {
                    Text("Image unavailable")
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // Computes the displayed image rect when using .scaledToFit inside given container
    private func imageSize(in container: CGSize, for image: UIImage) -> CGSize {
        let imageAspect = image.size.width / image.size.height
        let containerAspect = container.width / container.height

        if imageAspect > containerAspect {
            // Width fits, height letterboxed
            let width = container.width
            let height = width / imageAspect
            return CGSize(width: width, height: height)
        } else {
            // Height fits, width letterboxed
            let height = container.height
            let width = height * imageAspect
            return CGSize(width: width, height: height)
        }
    }

    // Marker overlay positioned using normalized ratios, then transformed by current zoom/pan
    private func markerOverlay(containerSize: CGSize, imageSize: CGSize) -> some View {
        // Calculate the image origin inside the container (centered)
        let imageOrigin = CGPoint(
            x: (containerSize.width - imageSize.width) / 2.0,
            y: (containerSize.height - imageSize.height) / 2.0
        )

        // Base (untransformed) position in container coordinates
        let baseX = imageOrigin.x + imageSize.width * currentPattern.markerXRatio
        let baseY = imageOrigin.y + imageSize.height * currentPattern.markerYRatio

        // Apply zoom and pan transforms
        let transformedX = (baseX - containerSize.width / 2) * scale + containerSize.width / 2 + offset.width
        let transformedY = (baseY - containerSize.height / 2) * scale + containerSize.height / 2 + offset.height

        return ZStack {
            Circle()
                .fill(Color.accentRose.opacity(0.8))
                .frame(width: 22, height: 22)
                .overlay(
                    Circle().stroke(Color.white, lineWidth: 2)
                )
                .position(x: transformedX + markerDragOffset.width,
                          y: transformedY + markerDragOffset.height)
                .gesture(markerDragGesture(containerSize: containerSize, imageSize: imageSize, imageOrigin: imageOrigin))
                .accessibilityLabel("Progress Marker")
        }
    }

    // Dragging the marker updates normalized ratios in the view model
    private func markerDragGesture(containerSize: CGSize, imageSize: CGSize, imageOrigin: CGPoint) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                markerDragOffset = value.translation
            }
            .onEnded { value in
                // Convert final drag position back to container coordinates
                let finalX = value.location.x
                let finalY = value.location.y

                // Inverse transform to get base (unzoomed/unpanned) position
                let invX = ((finalX - offset.width) - containerSize.width / 2) / scale + containerSize.width / 2
                let invY = ((finalY - offset.height) - containerSize.height / 2) / scale + containerSize.height / 2

                // Clamp to image rect
                let clampedX = min(max(invX, imageOrigin.x), imageOrigin.x + imageSize.width)
                let clampedY = min(max(invY, imageOrigin.y), imageOrigin.y + imageSize.height)

                // Convert to normalized ratios
                let xRatio = (clampedX - imageOrigin.x) / imageSize.width
                let yRatio = (clampedY - imageOrigin.y) / imageSize.height

                vm.updateProgress(for: pattern, xRatio: xRatio, yRatio: yRatio)
                markerDragOffset = .zero
            }
    }

    // Pinch to zoom
    private func zoomGesture() -> some Gesture {
        MagnificationGesture()
            .onChanged { value in
                let delta = value / lastScale
                scale = (scale * delta).clamped(to: 1.0...4.0)
                lastScale = value
            }
            .onEnded { _ in
                lastScale = 1.0
                // synchronize zoomStep to nearest step for consistency with button
                syncZoomStepToScale()
            }
    }

    // Pan when zoomed
    private func panGesture() -> some Gesture {
        DragGesture()
            .onChanged { value in
                offset = CGSize(width: lastOffset.width + value.translation.width,
                                height: lastOffset.height + value.translation.height)
            }
            .onEnded { _ in
                lastOffset = offset
            }
    }

    private func cycleZoomStep() {
        zoomStep = (zoomStep + 1) % 3
        let targetScale: CGFloat
        switch zoomStep {
        case 1: targetScale = 1.8
        case 2: targetScale = 2.6
        default: targetScale = 1.0
        }
        withAnimation(.easeInOut(duration: 0.2)) {
            scale = targetScale
        }
    }

    private func syncZoomStepToScale() {
        // Map current scale back to nearest step
        let steps: [CGFloat] = [1.0, 1.8, 2.6]
        let nearest = steps.enumerated().min(by: { abs($0.element - scale) < abs($1.element - scale) })?.offset ?? 0
        zoomStep = nearest
    }

    private var currentPattern: CrochetPattern {
        vm.patterns.first(where: { $0.id == pattern.id }) ?? pattern
    }
}

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
