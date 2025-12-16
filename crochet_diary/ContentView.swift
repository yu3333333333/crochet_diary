import SwiftUI
import Lottie

struct ContentView: View {
    @StateObject private var vm = PatternsViewModel()
    @State private var isShowingSplash = true
    @State private var splashOpacity: Double = 1.0

    var body: some View {
        ZStack {
            // Main app content
            TabView {
                NavigationStack {
                    PatternLibraryView()
                }
                .tabItem {
                    Label("Library", systemImage: "books.vertical")
                }

                NavigationStack {
                    StitchGuideView()
                }
                .tabItem {
                    Label("Stitches", systemImage: "list.bullet.rectangle")
                }

                NavigationStack {
                    AddPatternView()
                }
                .tabItem {
                    Label("Add", systemImage: "plus.circle")
                }

                NavigationStack {
                    WorksGalleryView()
                }
                .tabItem {
                    Label("Works", systemImage: "photo.on.rectangle.angled")
                }
            }
            .tint(.warmBrown)
            .background(Color.creamBackground.ignoresSafeArea())

            // Splash overlay
            if isShowingSplash {
                SplashView()
                    .transition(.opacity)
                    .opacity(splashOpacity)
                    .onAppear {
                        // 約 5 秒後淡出
                        Task { @MainActor in
                            try? await Task.sleep(nanoseconds: 5_000_000_000)
                            withAnimation(.easeInOut(duration: 0.6)) {
                                splashOpacity = 0
                            }
                            // 動畫結束後移除
                            try? await Task.sleep(nanoseconds: 600_000_000)
                            isShowingSplash = false
                        }
                    }
            }
        }
        .environmentObject(vm)
    }
}

private struct SplashView: View {
    var body: some View {
        ZStack {
            Color.creamBackground.ignoresSafeArea()

            // Lottie 動畫
            LottieView(
                animationName: "CirclesAnimation",
                loopMode: .playOnce
            )
            .frame(width: 220, height: 220)
            
            // 標語文字
            Text(
                """
                 A cozy crochet companion
                
                 — helps you track, learn, 
                and treasure every stitch.
                """
            )
            .font(.custom("DancingScript-Bold", size: 27))
            .font(.system(.headline, design: .rounded))
            .foregroundStyle(Color.softBrownText)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 28)
            
        }
    }
}

struct LottieView: UIViewRepresentable {
    let animationName: String
    let loopMode: LottieLoopMode

    func makeUIView(context: Context) -> LottieAnimationView {
        let view = LottieAnimationView(name: animationName)
        view.contentMode = .scaleAspectFit
        view.loopMode = loopMode
        return view
    }

    func updateUIView(_ uiView: LottieAnimationView, context: Context) {
        if !uiView.isAnimationPlaying {
            uiView.play()
        }
    }
}


#Preview {
    ContentView()
}
