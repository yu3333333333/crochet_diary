import SwiftUI

struct StitchDetailView: View, Identifiable {
    var id: UUID { UUID() }
    let stitch: StitchItem
    @Environment(\.dismiss) private var dismiss

    // V、W、TV、TA 沒有步驟圖片，其餘依 prefix-index 從 Assets 載入
    private var hasStepImages: Bool {
        let noImageCodes: Set<String> = ["V", "W", "TV", "TA"]
        return !noImageCodes.contains(stitch.code)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // 標題區：名稱 + 代碼 + 簡述
                    VStack(alignment: .leading, spacing: 6) {
                        Text(stitch.code)
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(.secondary)
                        if !stitch.description.isEmpty {
                            Text(stitch.description)
                                .font(.system(.body, design: .rounded))
                                .foregroundStyle(Color.softBrownText.opacity(0.9))
                        }
                    }

                    // 步驟區：有圖片就照規則顯示圖片，否則顯示純文字卡片
                    if hasStepImages {
                        ForEach(1...stitch.stepCount, id: \.self) { index in
                            VStack(alignment: .leading, spacing: 8) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Color.softBeige.opacity(0.6))
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 220)

                                    let imageName = "\(stitch.stepImagePrefix)-\(index)"
                                    Image(imageName)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(maxHeight: 200)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .padding()
                                }

                                // 步驟文字
                                HStack(alignment: .top, spacing: 8) {
                                    Text("步驟 \(index)")
                                        .font(.system(.subheadline, design: .rounded))
                                        .foregroundStyle(.secondary)
                                        .frame(width: 60, alignment: .leading)

                                    Text(stitch.steps[safe: index - 1] ?? "")
                                        .font(.system(.body, design: .rounded))
                                        .foregroundStyle(Color.softBrownText)
                                }
                            }
                        }
                    } else {
                        // 無圖片時，顯示柔和背景的純文字步驟
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(1...stitch.stepCount, id: \.self) { index in
                                VStack(alignment: .leading, spacing: 8) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 14)
                                            .fill(Color.softBeige.opacity(0.35))
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 80)
                                        Text("請參考對應的原始針法")
                                            .font(.system(.subheadline, design: .rounded))
                                            .foregroundStyle(.secondary)
                                    }

                                    HStack(alignment: .top, spacing: 8) {
                                        Text("步驟 \(index)")
                                            .font(.system(.subheadline, design: .rounded))
                                            .foregroundStyle(.secondary)
                                            .frame(width: 60, alignment: .leading)

                                        Text(stitch.steps[safe: index - 1] ?? "")
                                            .font(.system(.body, design: .rounded))
                                            .foregroundStyle(Color.softBrownText)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .background(Color.creamBackground)
            .navigationTitle(stitch.name)
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

private extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
