import SwiftUI
#if os(iOS) || targetEnvironment(macCatalyst)
import UIKit
import AudioToolbox
#else
import AppKit
#endif
import AVFoundation

struct ContentView: View {
    @State private var score = 0
    @State private var timeLeft = 30
    @State private var isPlaying = false
    @State private var circlePosition = CGPoint(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY)
    @State private var circleSize: CGFloat = 100
    @State private var circleColor: Color = .blue
    @State private var timer: Timer? = nil
    @State private var pulse = false
    @State private var animateGradient = false
    private let totalTime = 30
    @State private var emitPoint: CGPoint? = nil
    @State private var emitColor: CGColor? = nil
    @State private var audioPlayer: AVAudioPlayer? = nil

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Background gradient
                ZStack {
                    // animated angular gradient
                    AngularGradient(gradient: Gradient(colors: [Color("AccentStart"), Color("AccentEnd"), Color.purple, Color.blue]), center: .center, angle: .degrees(animateGradient ? 360 : 0))
                        .ignoresSafeArea()
                        .blur(radius: 20)
                        .animation(.linear(duration: 30).repeatForever(autoreverses: false), value: animateGradient)

                    // floating blurred blobs
                    ForEach(0..<6, id: \.self) { i in
                        FloatingBlob(index: i)
                    }
                }

                VStack(spacing: 18) {
                    // Top status bar
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("SCORE")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                            Text("\(score)")
                                .font(.title2)
                                .bold()
                                .foregroundStyle(.white)
                        }

                        // App version
                        VStack(alignment: .leading, spacing: 4) {
                            Text("v \(appVersion)")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.7))
                        }

                        Spacer()

                        // Timer with progress
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("TIME")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                            HStack(spacing: 8) {
                                Text("\(timeLeft)s")
                                    .font(.headline)
                                    .bold()
                                    .foregroundColor(.white)
                                ProgressBar(progress: Double(timeLeft) / Double(totalTime))
                                    .frame(width: 120, height: 10)
                            }
                        }
                    }
                    .padding(12)
                    .background(.ultraThinMaterial.opacity(0.25))
                    .cornerRadius(14)
                    .padding(.horizontal)

                    Spacer()

                    // Play area
                    ZStack {
                        // subtle grid or glow
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color.white.opacity(0.03))
                            .frame(height: geo.size.height * 0.6)
                            .padding(.horizontal)

                        // touchable circle
                        Circle()
                            .fill(circleColor)
                            .frame(width: circleSize, height: circleSize)
                            .shadow(color: circleColor.opacity(0.5), radius: 20, x: 0, y: 8)
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
                                    .blur(radius: 6)
                            )
                            .scaleEffect(pulse && isPlaying ? 1.08 : 1.0)
                            .position(circlePosition)
                            .onTapGesture {
                                guard isPlaying else { return }
                                score += 1
                                impact()
                                // set particle data and play sound
                                emitPoint = circlePosition
                                emitColor = circleColor.toCG() ?? CGColor(gray: 1.0, alpha: 1.0)
                                playTapSound()
                                tapBurst() // small visual effect (placeholder)
                                moveCircle(in: geo.size)
                            }

                        // tap ripple (simple transient ring)
                        // ... existing code for advanced particles could be added later ...
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.horizontal, 20)
                    .frame(maxWidth: 700) // constrain for large mac windows

                    // Particle emitter overlay (listens for emitPoint)
                    ParticleEmitter(point: $emitPoint, color: $emitColor)

                    Spacer()

                    // Start / Restart button
                    if !isPlaying {
                        Button(action: startGame) {
                            HStack(spacing: 12) {
                                Image(systemName: "bolt.fill")
                                    .font(.title2)
                                Text(isPlaying ? "Playing..." : "Start Game")
                                    .font(.title3)
                                    .bold()
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(.thinMaterial)
                            .foregroundColor(.white)
                            .cornerRadius(14)
                            .padding(.horizontal)
                            .shadow(color: Color.black.opacity(0.25), radius: 10, x: 0, y: 6)
                        }
                    }
                }

                // End overlay
                if timeLeft <= 0 && !isPlaying {
                    VStack(spacing: 16) {
                        Text("Time's up!")
                            .font(.largeTitle)
                            .bold()
                        Text("Your score: \(score)")
                            .font(.title2)
                        Button(action: { resetGame(); startGame() }) {
                            Text("Play Again")
                                .bold()
                                .padding(.vertical, 10)
                                .padding(.horizontal, 24)
                                .background(Color.white.opacity(0.12))
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                    .padding(24)
                    .background(VisualEffectBlur(blurStyle: .systemThinMaterialDark))
                    .cornerRadius(16)
                    .shadow(radius: 20)
                    .padding()
                }
            }
            .onAppear {
                // initial gradient colors fallback
                pulse = false
                animateGradient = true
                loadTapSound()
            }
            .onChange(of: isPlaying) { playing in
                if playing {
                    // start subtle pulse
                    withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                        pulse = true
                    }
                } else {
                    pulse = false
                }
            }
            .onDisappear {
                timer?.invalidate()
            }
        }
    }

    // app version helper
    var appVersion: String {
        let short = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(short) (\(build))"
    }

    // MARK: - Game logic
    func startGame() {
        score = 0
        timeLeft = totalTime
        isPlaying = true
        // position in center to start
        circleSize = CGFloat.random(in: 60...110)
        circleColor = Color(hue: Double.random(in: 0...1), saturation: 0.85, brightness: 0.95)
        circlePosition = CGPoint(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY)

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

    func resetGame() {
        score = 0
        timeLeft = totalTime
        isPlaying = false
        circleSize = 100
        circleColor = .blue
        circlePosition = CGPoint(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY)
        timer?.invalidate()
    }

    func moveCircle(in size: CGSize) {
        let maxX = size.width - circleSize/2 - 24
        let maxY = size.height * 0.6 - circleSize/2 - 24
        let minX = circleSize/2 + 24
        let minY = circleSize/2 + 24

        circleSize = CGFloat.random(in: 50...120)
        circleColor = Color(hue: Double.random(in: 0...1), saturation: 0.8, brightness: 0.95)
        let x = CGFloat.random(in: minX...max(maxX, minX))
        let y = CGFloat.random(in: minY...max(maxY, minY))

        withAnimation(.interpolatingSpring(stiffness: 120, damping: 14)) {
            circlePosition = CGPoint(x: x, y: y)
        }
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

    // placeholder for visual tap burst
    func tapBurst() {
        // this can be expanded to trigger a CAEmitterLayer or overlay animation
    }

    func playTapSound() {
        // Try custom AVAudioPlayer first
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
        // try loading from app bundle first (recommended), then fall back to project Resources folder
        if let bundleURL = Bundle.main.url(forResource: "tap", withExtension: "wav", subdirectory: "sounds") {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: bundleURL)
                audioPlayer?.prepareToPlay()
                return
            } catch {
                print("Failed to load tap sound from bundle: \(error)")
            }
        }

        // fallback to project-relative Resources/sounds/tap.wav for local dev
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
    }
}

// Simple progress bar view
struct ProgressBar: View {
    var progress: Double // 0...1
    var body: some View {
        ZStack(alignment: .leading) {
            Capsule()
                .fill(Color.white.opacity(0.12))
            Capsule()
                .fill(Color.white.opacity(0.9))
                .frame(width: max(6, CGFloat(progress) * 120))
                .animation(.linear, value: progress)
        }
        .frame(height: 10)
    }
}

// VisualEffectBlur helper (UIKit wrapper) for a nice overlay background
struct VisualEffectBlur: UIViewRepresentable {
    var blurStyle: UIBlurEffect.Style

    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: blurStyle))
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

// MARK: - Particle Emitter (UIViewRepresentable)
struct ParticleEmitter: UIViewRepresentable {
    @Binding var point: CGPoint?
    @Binding var color: CGColor?

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        guard let p = point else { return }

        let emitter = CAEmitterLayer()
        emitter.emitterPosition = CGPoint(x: p.x, y: p.y)
        emitter.emitterShape = .point

        let cell = CAEmitterCell()
        cell.birthRate = 160
        cell.lifetime = 0.6
        cell.velocity = 120
        cell.velocityRange = 60
        cell.scale = 0.02
        cell.scaleRange = 0.02
        cell.emissionRange = .pi * 2
        cell.alphaSpeed = -1.5

        if let cg = color {
            cell.contents = makeCircleImage(cgColor: cg, diameter: 16)?.cgImage
        }

        emitter.emitterCells = [cell]
        uiView.layer.addSublayer(emitter)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            emitter.birthRate = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            emitter.removeFromSuperlayer()
        }

        DispatchQueue.main.async {
            self.point = nil
        }
    }

    // create UIImage from CGColor
    private func makeCircleImage(cgColor: CGColor, diameter: CGFloat) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: diameter, height: diameter))
        return renderer.image { ctx in
            let rect = CGRect(x: 0, y: 0, width: diameter, height: diameter)
            ctx.cgContext.setFillColor(cgColor)
            ctx.cgContext.fillEllipse(in: rect)
        }
    }
}

// macOS: NSViewRepresentable wrapper
#if os(macOS)
extension ParticleEmitter: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.clear.cgColor
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        guard let p = point else { return }

        let emitter = CAEmitterLayer()
        emitter.emitterPosition = CGPoint(x: p.x, y: p.y)
        emitter.emitterShape = .point

        let cell = CAEmitterCell()
        cell.birthRate = 160
        cell.lifetime = 0.6
        cell.velocity = 120
        cell.velocityRange = 60
        cell.scale = 0.02
        cell.scaleRange = 0.02
        cell.emissionRange = .pi * 2
        cell.alphaSpeed = -1.5

        if let cg = color {
            cell.contents = makeCircleImageNS(cgColor: cg, diameter: 16)?.cgImage
        }

        emitter.emitterCells = [cell]
        nsView.layer?.addSublayer(emitter)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            emitter.birthRate = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            emitter.removeFromSuperlayer()
        }

        DispatchQueue.main.async {
            self.point = nil
        }
    }

    private func makeCircleImageNS(cgColor: CGColor, diameter: CGFloat) -> NSImage? {
        let size = NSSize(width: diameter, height: diameter)
        let image = NSImage(size: size)
        image.lockFocus()
        if let ctx = NSGraphicsContext.current?.cgContext {
            ctx.setFillColor(cgColor)
            ctx.fillEllipse(in: CGRect(x: 0, y: 0, width: diameter, height: diameter))
        }
        image.unlockFocus()
        return image
    }
}
#endif

// Color -> CGColor helper
extension Color {
    func toCG() -> CGColor? {
#if os(iOS) || targetEnvironment(macCatalyst)
        return UIColor(self).cgColor
#else
        // macOS: bridge via NSColor
        if let ns = NSColor(self) {
            return ns.cgColor
        }
        return nil
#endif
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .previewDevice("iPhone 14")
    }
}

// Floating blurred blob
struct FloatingBlob: View {
    let index: Int
    var body: some View {
        let size: CGFloat = CGFloat(80 + (index * 10))
        Circle()
            .fill(Color.white.opacity(0.08))
            .frame(width: size, height: size)
            .blur(radius: 30)
            .offset(x: CGFloat((index % 3) * 60 - 80), y: CGFloat((index / 3) * 80 - 40))
            .blendMode(.screen)
            .animation(.easeInOut(duration: Double(20 + index * 3)).repeatForever(autoreverses: true), value: index)
    }
}

// Styled primary button
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(LinearGradient(colors: [Color("AccentStart"), Color("AccentEnd")], startPoint: .leading, endPoint: .trailing))
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .shadow(color: Color.black.opacity(0.25), radius: 8, x: 0, y: 6)
    }
}
