import SwiftUI

struct WorksGalleryView: View {
    @EnvironmentObject private var vm: PatternsViewModel

    @State private var selected: CrochetPattern?
    @State private var sortOrder: SortOrder = .latestToEarliest

    var body: some View {
        ScrollView {
            if worksPatternsSorted.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("No finished works yet.")
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 60)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(worksPatternsSorted) { pattern in
                        WorkRowCard(pattern: pattern)
                            .onTapGesture {
                                selected = pattern
                            }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
        }
        .background(
            Image("鉤針紋路")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                .opacity(0.4)
        )
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack {
                    Text("- My Crochet Gallery -")
                        .font(.system(size: 28, weight: .medium, design: .serif))
                        .tracking(1.5)
                        .offset(x:20, y:20)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Picker("Sort by Date", selection: $sortOrder) {
                        Text("Earliest → Latest").tag(SortOrder.earliestToLatest)
                        Text("Latest → Earliest").tag(SortOrder.latestToEarliest)
                    }
                } label: {
                    Label("Sort", systemImage: "arrow.up.arrow.down")
                }
                .tint(.warmBrown)
            }
        }
        .sheet(item: $selected) { pattern in
            WorkDetailSheet(pattern: pattern) { toDelete in
                if let idx = vm.patterns.firstIndex(where: { $0.id == toDelete.id }) {
                    vm.delete(at: IndexSet(integer: idx))
                }
            }
        }
    }

    private var worksPatternsSorted: [CrochetPattern] {
        let works = vm.patterns.filter { $0.isInWorks == true }
        switch sortOrder {
        case .earliestToLatest:
            // Missing dates go to the end
            return works.sorted {
                switch ($0.startDate, $1.startDate) {
                case let (d0?, d1?): return d0 < d1
                case (nil, _?): return false
                case (_?, nil): return true
                default: return false
                }
            }
        case .latestToEarliest:
            // Missing dates go to the beginning
            return works.sorted {
                switch ($0.startDate, $1.startDate) {
                case let (d0?, d1?): return d0 > d1
                case (nil, _?): return true
                case (_?, nil): return false
                default: return false
                }
            }
        }
    }

    enum SortOrder: Hashable {
        case earliestToLatest
        case latestToEarliest
    }
}

private struct WorkRowCard: View {
    let pattern: CrochetPattern

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Thumbnail
            Group {
                if let uiImage = UIImage(data: pattern.imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    ZStack {
                        Color.softBeige
                        Image(systemName: "photo")
                            .font(.system(size: 28, weight: .light))
                            .foregroundStyle(Color.warmBrown.opacity(0.6))
                    }
                }
            }
            .frame(width: 120, height: 120)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.softBeige, lineWidth: 1)
            )
            .overlay(alignment: .topTrailing) {
                if pattern.isStarred {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                        .padding(6)
                        .background(.ultraThinMaterial, in: Circle())
                        .padding(6)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(pattern.name)
                    .font(.system(.headline, design: .serif))
                    .foregroundStyle(Color.softBrownText)
                    .lineLimit(2)

                if let date = pattern.startDate {
                    Text(date.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image("鉤針icon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 15)

                        Text("\(Int(pattern.hookSize * 10) / 10)mm")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if !pattern.yarn.isEmpty {
                        HStack(spacing: 4) {
                            Image("毛線icon")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 30)

                            Text(pattern.yarn)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                }


                if !pattern.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(pattern.notes)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }
            }

            Spacer()
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.softBeige, lineWidth: 1)
                )
        )
    }
}

private struct WorkDetailSheet: View {
    @EnvironmentObject private var vm: PatternsViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var localPattern: CrochetPattern
    var onDelete: (CrochetPattern) -> Void

    init(pattern: CrochetPattern, onDelete: @escaping (CrochetPattern) -> Void) {
        self._localPattern = State(initialValue: pattern)
        self.onDelete = onDelete
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .center, spacing: 16) {

                    // Combined horizontal gallery: main image + stitch images
                    if let mainImage = UIImage(data: localPattern.imageData) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                // 1) Main finished work image
                                Image(uiImage: mainImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 280, height: 280)
                                    .clipShape(RoundedRectangle(cornerRadius: 18))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 18)
                                            .stroke(Color.softBeige, lineWidth: 1)
                                    )

                                // 2) Stitch / diagram images (if any)
                                ForEach(Array(localPattern.stitchImages.enumerated()), id: \.offset) { _, data in
                                    if let ui = UIImage(data: data) {
                                        Image(uiImage: ui)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 280, height: 280)
                                            .clipShape(RoundedRectangle(cornerRadius: 18))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 18)
                                                    .stroke(Color.softBeige, lineWidth: 1)
                                            )
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.top, 8)
                            .padding(.bottom, 4)
                        }
                    } else {
                        EmptyView()
                    }

                    // Title + Star
                    HStack(alignment: .center, spacing: 12) {
                        Text(localPattern.name)
                            .font(.system(.title3, design: .serif))
                            .foregroundStyle(Color.softBrownText)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)

                        Spacer(minLength: 8)

                        Button {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                localPattern.isStarred.toggle()
                            }
                            vm.update(localPattern) // persist immediately
                        } label: {
                            Image(systemName: localPattern.isStarred ? "star.fill" : "star")
                                .font(.system(size: 22, weight: .regular))
                                .foregroundStyle(localPattern.isStarred ? .yellow : .secondary)
                                .padding(10)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white.opacity(0.9))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.softBeige, lineWidth: 1)
                                        )
                                )
                                .accessibilityLabel(localPattern.isStarred ? "Unstar" : "Star")
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal)

                    // Info Card
                    VStack(alignment: .leading, spacing: 10) {
                        if let date = localPattern.startDate {
                            HStack {
                                Label {
                                    Text(date.formatted(date: .abbreviated, time: .omitted))
                                } icon: {
                                    Image(systemName: "calendar")
                                }
                                .foregroundStyle(Color.softBrownText.opacity(0.9))
                            }
                        }

                        HStack(spacing: 16) {
                            Label {
                                Text("\(String(format: "%.1f", localPattern.hookSize)) mm")
                            } icon: {
                                Image("鉤針icon")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 30)
                            }
                            .foregroundStyle(Color.softBrownText.opacity(0.9))

                            if !localPattern.yarn.isEmpty {
                                Label {
                                    Text(localPattern.yarn)
                                } icon: {
                                    Image("毛線icon")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 60)
                                }
                                .foregroundStyle(Color.softBrownText.opacity(0.9))
                                .lineLimit(1)
                            }
                        }

                        if !localPattern.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Notes:")
                                    .font(.system(.subheadline, design: .rounded))
                                    .foregroundStyle(Color.softBrownText.opacity(0.9))
                                Text(localPattern.notes)
                                    .font(.system(.body, design: .rounded))
                                    .foregroundStyle(Color.softBrownText.opacity(0.9))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(.top, 2)
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.softBeige.opacity(0.55))
                    )
                    .padding(.horizontal)

                    // Delete Button
                    Button(role: .destructive) {
                        onDelete(localPattern)
                        dismiss()
                    } label: {
                        Label("Delete this work", systemImage: "trash")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.accentColor)
                    .padding(.horizontal)
                    .padding(.top, 4)
                    .padding(.bottom, 12)
                }
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
            .background(
                ZStack {
                    Color.creamBackground.ignoresSafeArea()
                }
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Work Details")
                        .font(.custom("DancingScript-Bold", size: 30))
                        .tracking(1)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Label("Done", systemImage: "xmark.circle.fill")
                    }
                    .tint(.warmBrown)
                }
            }
        }
    }
}
