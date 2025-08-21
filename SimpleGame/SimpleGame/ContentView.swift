import SwiftUI
import AVFoundation
#if os(iOS) || targetEnvironment(macCatalyst)
import UIKit
#else
import AppKit
#endif

struct ContentView: View {
    @State private var score = 0
    @State private var timeLeft = 30
    @State private var isPlaying = false
    @State private var circlePosition: CGPoint = .zero
    @State private var circleSize: CGFloat = 100
    @State private var circleColor: Color = .blue
    @State private var timer: Timer? = nil
    @State private var animateGradient = false
    @State private var audioPlayer: AVAudioPlayer? = nil

    var body: some View {
        GeometryReader { geo in
            ZStack {
                AngularGradient(gradient: Gradient(colors: [Color("AccentStart"), Color("AccentEnd"), Color.purple]), center: .center, angle: .degrees(animateGradient ? 360 : 0))
                    .ignoresSafeArea()
                    .opacity(0.28)
                    .blur(radius: 18)
                    .animation(.linear(duration: 28).repeatForever(autoreverses: false), value: animateGradient)

                ForEach(0..<5, id: \.self) { i in
                    FloatingBlob(index: i)
                }

                VStack(spacing: 20) {
                    HStack {
                        Text("Score: \(score)")
                            .font(.title)
                            .bold()
                        Spacer()
                        Text("v\(appVersion)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("Time: \(timeLeft)s")
                            .font(.title2)
                    }
                    .padding()

                    Spacer()

                    ZStack {
                        Circle()
                            .fill(circleColor)
                            .frame(width: circleSize, height: circleSize)
                            .shadow(radius: 10)
                            .position(circlePosition == .zero ? CGPoint(x: geo.size.width/2, y: geo.size.height/2) : circlePosition)
                            .onTapGesture {
                                guard isPlaying else { return }
                                score += 1
                                impact()
                                playTapSound()
                                moveCircle(in: geo.size)
                            }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.horizontal, 20)
                    .frame(maxWidth: 700)

                    Spacer()

                    if !isPlaying {
                        Button(action: { startGame(in: geo.size) }) {
                            Text("Start Game")
                                .font(.title2)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.accentColor)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding()

                if timeLeft <= 0 && !isPlaying {
                    VStack {
                        Text("Time's up!")
                            .font(.largeTitle)
                            .bold()
                        Text("Your score: \(score)")
                            .font(.title)
                        Button("Play Again") {
                            resetGame(in: geo.size)
                            startGame(in: geo.size)
                        }
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .padding()
                    .background(OverlayBackground())
                    .cornerRadius(12)
                    .shadow(radius: 10)
                }
            }
            .onAppear {
                animateGradient = true
                loadTapSound()
                if circlePosition == .zero {
                    circlePosition = CGPoint(x: geo.size.width/2, y: geo.size.height/2)
                }
            }
            .onDisappear {
                timer?.invalidate()
            }
        }
    }

    // MARK: - Game control (geometry-aware)
    func startGame(in size: CGSize) {
        score = 0
        timeLeft = 30
        isPlaying = true
        circleSize = CGFloat.random(in: 60...110)
        circleColor = Color(hue: Double.random(in: 0...1), saturation: 0.85, brightness: 0.95)
        circlePosition = CGPoint(x: size.width/2, y: size.height/2)

        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if timeLeft > 0 {
                timeLeft -= 1
            } else {
                isPlaying = false
                timer?.invalidate()
            }
        }
    }

    func resetGame(in size: CGSize) {
        score = 0
        timeLeft = 30
        isPlaying = false
        circleSize = 100
        circleColor = .blue
        circlePosition = CGPoint(x: size.width/2, y: size.height/2)
        timer?.invalidate()
    }

    func moveCircle(in size: CGSize) {
        let maxX = max(size.width - circleSize/2 - 24, circleSize/2)
        let maxY = max(size.height * 0.6 - circleSize/2 - 24, circleSize/2)
        let minX = circleSize/2 + 24
        let minY = circleSize/2 + 24

        circleSize = CGFloat.random(in: 50...120)
        circleColor = Color(hue: Double.random(in: 0...1), saturation: 0.8, brightness: 0.9)
        let x = CGFloat.random(in: minX...max(maxX, minX))
        let y = CGFloat.random(in: minY...max(maxY, minY))

        withAnimation(.easeInOut(duration: 0.3)) {
            circlePosition = CGPoint(x: x, y: y)
        }
    }

    // app version helper
    var appVersion: String {
        let short = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(short) (\(build))"
    }

    // small haptic (noop on macOS)
    func impact() {
#if os(iOS) || targetEnvironment(macCatalyst)
        let gen = UIImpactFeedbackGenerator(style: .medium)
        gen.impactOccurred()
#else
        // no haptics on macOS
#endif
    }

    // Audio
    func playTapSound() {
        if let player = audioPlayer {
            player.currentTime = 0
            player.play()
            return
        }

#if os(iOS) || targetEnvironment(macCatalyst)
        AudioServicesPlaySystemSound(1104)
#else
        NSSound.beep()
#endif
    }

    func loadTapSound() {
#if os(iOS) || targetEnvironment(macCatalyst)
        if let bundleURL = Bundle.main.url(forResource: "tap", withExtension: "wav", subdirectory: "sounds") {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: bundleURL)
                audioPlayer?.prepareToPlay()
                return
            } catch {
                print("Failed to load tap sound from bundle: \(error)")
            }
        }

        let relPath = "Resources/sounds/tap.wav"
        let base = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let url = base.appendingPathComponent(relPath)
        if FileManager.default.fileExists(atPath: url.path) {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: url)
                audioPlayer?.prepareToPlay()
            } catch {
                print("Failed to load tap sound: \(error)")
            }
        }
#else
        if let bundleURL = Bundle.main.url(forResource: "tap", withExtension: "wav", subdirectory: "sounds") {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: bundleURL)
                audioPlayer?.prepareToPlay()
                return
            } catch {
                print("Failed to load tap sound from bundle: \(error)")
            }
        }
#endif
    }
}

// Floating blurred blob
struct FloatingBlob: View {
    let index: Int
    var body: some View {
        let size: CGFloat = CGFloat(60 + (index * 12))
        Circle()
            .fill(Color.white.opacity(0.06))
            .frame(width: size, height: size)
            .blur(radius: 28)
            .offset(x: CGFloat((index % 3) * 70 - 100), y: CGFloat((index / 3) * 90 - 50))
            .blendMode(.screen)
            .animation(.easeInOut(duration: Double(22 + index * 4)).repeatForever(autoreverses: true), value: index)
    }
}

// Overlay background that uses modern materials on macOS 12+ and falls back otherwise
struct OverlayBackground: View {
    var body: some View {
        #if os(macOS)
        if #available(macOS 12.0, *) {
            Color.clear.background(.ultraThinMaterial)
        } else {
            Color(NSColor.windowBackgroundColor).opacity(0.85)
        }
        #else
        Color.clear.background(.ultraThinMaterial)
        #endif
    }
}

// Color -> CGColor helper
extension Color {
    func toCG() -> CGColor? {
    #if os(iOS) || targetEnvironment(macCatalyst)
        return UIColor(self).cgColor
    #else
        if #available(macOS 13.0, *) {
            return NSColor(self).cgColor
        } else {
            return nil
        }
    #endif
    }

}
