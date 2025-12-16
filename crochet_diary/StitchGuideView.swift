import SwiftUI

struct StitchGuideView: View {
    @State private var selected: StitchItem?

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 16)], spacing: 16) {
                ForEach(StitchItem.samples) { stitch in
                    VStack(spacing: 8) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.softBeige.opacity(0.6))
                                .frame(height: 120)

                            Image(stitch.name)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 100)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }

                        // 中文名稱
                        Text(stitch.name)
                            .font(.system(.headline, design: .rounded))
                            .foregroundStyle(Color.softBrownText)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)

                        // 字母代碼
                        Text(stitch.code)
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                    .onTapGesture { selected = stitch }
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.white.opacity(0.85))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.softBeige, lineWidth: 1)
                            )
                    )
                }
            }
            .padding()
        }
        .background(
            ZStack(alignment: .top) {
                Color.creamBackground
                    .ignoresSafeArea()

                Image("辮子針裝飾")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 460)
                    .offset(x:90, y:-230)
                    .allowsHitTesting(false)
                Image("辮子針裝飾2")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 700)
                    .offset(x:-50, y:180)
                    .allowsHitTesting(false)
            }
        )
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack {
                    Text("Stitch Guide")
                        .font(.system(size: 33, weight: .medium, design: .serif))
                        .tracking(1.5)
                        .offset(x:-80, y:20)
                }
            }
        }
        .sheet(item: $selected) { stitch in
            StitchDetailView(stitch: stitch)
        }
    }
}

struct StitchItem: Identifiable, Equatable {
    let id = UUID()

    /// Chinese name (also used as symbol asset image name)
    let name: String

    /// Stitch letter code (CH, X, V...)
    let code: String

    /// Short description shown in detail view
    let description: String

    /// Step image prefix used in Assets (e.g. "CH", "X")
    let stepImagePrefix: String

    /// Number of step images (e.g. 3 → CH-1, CH-2, CH-3)
    let stepCount: Int

    /// Step text descriptions (must match stepCount)
    let steps: [String]
}

extension StitchItem {
    static let samples: [StitchItem] = [
        StitchItem(
            name: "鎖針",
            code: "CH",
            description: "起針",
            stepImagePrefix: "CH",
            stepCount: 3,
            steps: [
                "在鉤針上製作一個活結。",
                "繞線後拉過鉤針上的線圈。",
                "完成一針，重複上述動作至所需長度。"
            ]
        ),

        StitchItem(
            name: "短針",
            code: "X",
            description: "短針",
            stepImagePrefix: "X",
            stepCount: 5,
            steps: [
                "將鉤針插入上一行針目的頭針2條線中。",
                "針上掛線後，沿箭頭方向引拔出。",
                "引拔出的長度約為1針鎖針的長度。",
                "再次在針上掛線，依照箭頭所示一次引拔穿過2個線圈。",
                "完成短針。"
            ]
        ),

        StitchItem(
            name: "短針加針",
            code: "V",
            description: "一個針目裡勾兩個短針",
            stepImagePrefix: "V",
            stepCount: 3,
            steps: [
                "在同一針目中完成第一個短針。",
                "再次插入同一針目。",
                "完成第二個短針。"
            ]
        ),

        StitchItem(
            name: "短針加三針",
            code: "W",
            description: "一個針目裡勾三個短針",
            stepImagePrefix: "W",
            stepCount: 3,
            steps: [
                "在同一針目中完成第一個短針。",
                "完成第二個短針。",
                "完成第三個短針。"
            ]
        ),

        StitchItem(
            name: "中長針",
            code: "T",
            description: "鉤針纏繞一圈一次性帶過",
            stepImagePrefix: "T",
            stepCount: 5,
            steps: [
                "針上掛線，插入上一行針目的頭針2根線中。",
                "針上掛線，依箭頭所示引拔拉出線。",
                "引拔拉出的長度約為2針鎖針的長度。",
                "再次在針上掛線，依照箭頭所示一次引拔穿過3個線圈。",
                "中長針鉤織完成。"
            ]
        ),

        StitchItem(
            name: "中長針加針",
            code: "TV",
            description: "一個針目裡勾兩個中長針",
            stepImagePrefix: "TV",
            stepCount: 3,
            steps: [
                "在同一針目完成第一個中長針。",
                "再次繞線。",
                "完成第二個中長針。"
            ]
        ),

        StitchItem(
            name: "中長針減針",
            code: "TA",
            description: "兩個中長針合為一針",
            stepImagePrefix: "TA",
            stepCount: 3,
            steps: [
                "完成第一個未完成中長針。",
                "完成第二個未完成中長針。",
                "一次性帶過。"
            ]
        ),

        StitchItem(
            name: "引拔針",
            code: "SL",
            description: "收針",
            stepImagePrefix: "SL",
            stepCount: 4,
            steps: [
                "鉤針插入上一行針目的頭針兩根線中。",
                "掛上線，引拔拉出線",
                "下一針也是將鉤針插入上一行針目的頭針兩根線中",
                "拉線直接穿過所有線圈。"
            ]
        ),

        StitchItem(
            name: "長針",
            code: "F",
            description: "鉤針纏繞一圈，分兩次帶出來",
            stepImagePrefix: "F",
            stepCount: 6,
            steps: [
                "針上掛線，插入上一行針目的頭針2條線中。",
                "針上掛線，依箭頭所示引拔拉出線。",
                "引拔拉出的長度約為2針鎖針的長度。",
                "再次在針上掛線，依照箭頭所示引拔穿過2個線圈。",
                "再次在針上掛線，依照箭頭所示一次引拔穿過剩下的2個線圈。",
                "長針鉤織完成。"
            ]
        ),

        StitchItem(
            name: "長長針",
            code: "E",
            description: "鉤針纏繞兩圈，分三次帶出來",
            stepImagePrefix: "E",
            stepCount: 6,
            steps: [
                "線在針上繞2圈，然後將鉤針插入上一行針目的頭針2根線中。",
                "針上掛線，依箭頭所示引拔拉出線。引拔拉出的長度約為2針鎖針的長度。",
                "針上掛線，依箭頭所示引拔穿過2個線圈。",
                "再次在針上掛線，依照箭頭所示引拔穿過2個線圈。",
                "再次在針上掛線，一次引拔穿過剩下的2個線圈。",
                "長長針鉤織完成。"
            ]
        ),

        StitchItem(
            name: "爆米花針",
            code: "B",
            description: "五針長針爆米花針",
            stepImagePrefix: "B",
            stepCount: 3,
            steps: [
                "在同一針目中鉤織5針長針，暫時將針取出，然後插入最初的針目和放開的線圈中，之後接照箭頭所示引拔拉出。",
                "鉤織1針鎖針，引拔拉緊線。",
                "長針5針的爆米花針鉤織完成。"
            ]
        ),

        StitchItem(
            name: "棗形針",
            code: "Q",
            description: "三針中長針合併",
            stepImagePrefix: "Q",
            stepCount: 5,
            steps: [
                "針上掛線，將鉤針插入上一行的針目中（此處是鎖針的里山和半針中），掛線後引拔拉出，引拔出的長度約為2針鎖針的長度。",
                "針上掛線，依箭頭所示，引拔穿過2個線圈（未完成的長針)。",
                "針上掛線，將鉤針插入同一針目中，再鉤織2針未完成的長針。",
                "針上掛線，按照箭頭所示，一次引拔穿過所有的線圈。",
                "長針3針的棗形針鉤織完成。"
            ]
        )
    ]
}
