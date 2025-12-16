import SwiftUI
import PhotosUI

struct AddPatternView: View {
    @EnvironmentObject private var vm: PatternsViewModel

    @State private var name: String = ""
    @State private var imageData: Data?
    @State private var hookSize: Double = 3.0
    @State private var hookNumber: Double = 5.0
    @State private var yarn: String = ""
    @State private var notes: String = ""
    @State private var isInWorks: Bool = false
    @State private var isStarred: Bool = false
    @State private var startDate: Date = Date()

    @State private var showAlert = false
    @State private var alertMessage = ""
    
    private let hookPairs: [(mm: Double, number: Double)] = [
        (2.0, 2.0),
        (2.3, 3.0),
        (2.5, 4.0),
        (3.0, 5.0),
        (3.5, 6.0),
        (4.0, 7.0),
        (4.5, 7.5),
        (5.0, 8.0),
        (5.5, 9.0),
        (6.0, 10.0)
    ]
    @State private var hookIndex: Int = 3

    // Stitch / diagram images (multiple, optional)
    @State private var stitchImages: [Data] = []
    @State private var stitchPickerItems: [PhotosPickerItem] = []

    var body: some View {
        Form {
            Section("Basic Info") {
                HStack {
                    TextField("Pattern name", text: $name)
                        .textInputAutocapitalization(.words)

                    Button {
                        isStarred.toggle()
                    } label: {
                        Image(systemName: isStarred ? "star.fill" : "star")
                            .foregroundStyle(isStarred ? .yellow : .secondary)
                            .imageScale(.large)
                            .accessibilityLabel(isStarred ? "Unstar" : "Star")
                    }
                    .buttonStyle(.plain)
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Hook Size")
                        Spacer()
                        Text("\(String(format: "%.1f", currentPair.mm)) mm")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Hook Number")
                        Spacer()
                        Text(formattedHookNumber(currentPair.number))
                            .foregroundStyle(.secondary)
                    }
                }

                Slider(
                    value: Binding(
                        get: { Double(hookIndex) },
                        set: { newValue in
                            let rounded = Int((newValue).rounded())
                            hookIndex = min(max(rounded, 0), hookPairs.count - 1)
                            hookSize = currentPair.mm
                            hookNumber = currentPair.number
                        }
                    ),
                    in: 0...Double(hookPairs.count - 1),
                    step: 1
                )

                TextField("Yarn description", text: $yarn)
            }

            // Finished Work Image (single)
            Section("作品圖片") {
                if let imageData, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.softBeige, lineWidth: 1)
                        )
                } else {
                    Text("尚未選擇作品圖片")
                        .foregroundStyle(.secondary)
                }
                ImagePicker(imageData: $imageData)
            }

            // Stitch / Diagram Images (multiple, optional)
            Section("織法／圖解圖片（可選）") {
                if !stitchImages.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(Array(stitchImages.enumerated()), id: \.offset) { _, data in
                                if let img = UIImage(data: data) {
                                    Image(uiImage: img)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 120, height: 120)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.softBeige, lineWidth: 1)
                                        )
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                } else {
                    Text("可上傳多張織法／圖解／細節圖片")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                PhotosPicker(
                    selection: $stitchPickerItems,
                    maxSelectionCount: 20,
                    matching: .images
                ) {
                    Label("新增織法／圖解圖片", systemImage: "photo.stack")
                }
                .onChange(of: stitchPickerItems) { _, newItems in
                    guard !newItems.isEmpty else { return }
                    Task {
                        var newDatas: [Data] = []
                        for item in newItems {
                            if let data = try? await item.loadTransferable(type: Data.self) {
                                newDatas.append(data)
                            }
                        }
                        await MainActor.run {
                            stitchImages.append(contentsOf: newDatas)
                            stitchPickerItems = []
                        }
                    }
                }

                if !stitchImages.isEmpty {
                    Button(role: .destructive) {
                        stitchImages.removeAll()
                    } label: {
                        Label("清除所有織法／圖解圖片", systemImage: "trash")
                    }
                }
            }

            // Start date: its own section
            Section {
                DatePicker("Start date", selection: $startDate, displayedComponents: .date)
            }

            Section("Details") {
                Toggle("加入我的作品集", isOn: $isInWorks)
                Text("開啟後將只顯示於作品集，不會加入收藏")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                TextEditor(text: $notes)
                    .frame(minHeight: 120)
            }

            Section {
                Button {
                    addPattern()
                } label: {
                    Label("Save Pattern", systemImage: "square.and.arrow.down")
                }
                .tint(.warmBrown)
            }
        }
        .onAppear {
            hookIndex = closestIndex(toMM: hookSize)
            hookSize = currentPair.mm
            hookNumber = currentPair.number
        }
        .scrollContentBackground(.hidden)
        .background(
            ZStack(alignment: .top) {
                Color.creamBackground
                    .ignoresSafeArea()
                Image("毛線1")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 430)
                    .offset(x:90, y:-230)
                    .allowsHitTesting(false)
                Image("毛線2")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 330)
                    .offset(x:-120, y:140)
                    .allowsHitTesting(false)
                Image("毛線3")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 230)
                    .offset(x:80, y:400)
                    .allowsHitTesting(false)
            }
        )
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack {
                    Text("Add Pattern")
                        .font(.system(size: 33, weight: .medium, design: .serif))
                        .tracking(1.5)
                        .offset(x:-80, y:20)
                }
            }
        }
        .alert("Cannot Save", isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
    }

    private var currentPair: (mm: Double, number: Double) {
        hookPairs[hookIndex]
    }

    private func formattedHookNumber(_ number: Double) -> String {
        number == 7.5 ? "7.5 號鉤針" : "\(Int(number)) 號鉤針"
    }

    private func closestIndex(toMM mm: Double) -> Int {
        var bestIndex = 0
        var bestDiff = Double.greatestFiniteMagnitude
        for (i, pair) in hookPairs.enumerated() {
            let d = abs(pair.mm - mm)
            if d < bestDiff {
                bestDiff = d
                bestIndex = i
            }
        }
        return bestIndex
    }

    private func addPattern() {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            alertMessage = "Pattern name is required."
            showAlert = true
            return
        }
        guard let imageData else {
            alertMessage = "Please select a diagram image."
            showAlert = true
            return
        }

        let selected = currentPair

        let pattern = CrochetPattern(
            name: name,
            imageData: imageData,
            hookSize: selected.mm,
            yarn: yarn,
            notes: notes,
            currentRound: 0,
            currentStitch: 0,
            markerXRatio: 0.5,
            markerYRatio: 0.5,
            isInWorks: isInWorks,
            isStarred: isStarred,
            startDate: startDate,
            stitchImages: stitchImages // IMPORTANT: pass the images here
        )
        vm.add(pattern)

        // Reset form
        name = ""
        self.imageData = nil
        hookIndex = 3
        hookSize = currentPair.mm
        hookNumber = currentPair.number
        yarn = ""
        notes = ""
        isInWorks = false
        isStarred = false
        startDate = Date()
        stitchImages = []
    }
}
