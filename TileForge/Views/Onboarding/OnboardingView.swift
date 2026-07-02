import SwiftUI

#Preview {
    OnboardingView()
}

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentPage = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(colors: [Color(hex: "#F8FAFC"), Color(hex: "#EEF2F7")], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                TabView(selection: $currentPage) {
                    OnboardingPage1().tag(0)
                    OnboardingPage2().tag(1)
                    OnboardingPage3().tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .ignoresSafeArea()

                VStack(spacing: 20) {
                    // Page indicators
                    HStack(spacing: 8) {
                        ForEach(0..<3) { i in
                            Capsule()
                                .fill(i == currentPage ? Color.accentBlue : Color.divider)
                                .frame(width: i == currentPage ? 24 : 8, height: 8)
                                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: currentPage)
                        }
                    }

                    // Buttons
                    HStack(spacing: 12) {
                        if currentPage < 2 {
                            Button("Skip") {
                                withAnimation { hasCompletedOnboarding = true }
                            }
                            .buttonStyle(SecondaryButtonStyle())

                            Button("Next") {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    currentPage += 1
                                }
                            }
                            .buttonStyle(PrimaryButtonStyle())
                        } else {
                            Button("Get Started") {
                                withAnimation { hasCompletedOnboarding = true }
                            }
                            .buttonStyle(PrimaryButtonStyle())
                        }
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 48)
            }
        }
    }
}

// MARK: - Page 1: Tap to Trigger
struct OnboardingPage1: View {
    @State private var tapped = false
    @State private var particles: [ParticleDot] = []
    @State private var isLooping = false

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: "#F8FAFC"), Color(hex: "#EEF2F7")], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Interactive tile grid
                ZStack {
                    // Tile grid illustration
                    VStack(spacing: 3) {
                        ForEach(0..<5, id: \.self) { row in
                            HStack(spacing: 3) {
                                ForEach(0..<4, id: \.self) { col in
                                    let isCut = (row == 0 || row == 4 || col == 0 || col == 3)
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(isCut ? Color(hex: "#FDBA74") : Color.accentBlue.opacity(0.85))
                                        .frame(width: isCut ? 30 : 58, height: isCut ? 30 : 58)
                                        .opacity(tapped ? 1 : (isCut ? 0 : 0.7))
                                        .scaleEffect(tapped ? 1 : 0.85)
                                        .animation(.spring(response: 0.4, dampingFraction: 0.6).delay(Double(row + col) * 0.04), value: tapped)
                                }
                            }
                        }
                    }
                    .padding(20)
                    .background(Color.white)
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.08), radius: 16, y: 6)

                    // Particle burst
                    ForEach(particles) { p in
                        Circle()
                            .fill(p.color)
                            .frame(width: p.size, height: p.size)
                            .offset(p.offset)
                            .opacity(p.opacity)
                    }

                    // Tap hint
                    if !tapped {
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Label("Tap to reveal", systemImage: "hand.tap.fill")
                                    .font(AppFont.medium(12))
                                    .foregroundColor(.accentBlue)
                                    .padding(8)
                                    .background(Color.accentBlue.opacity(0.1))
                                    .cornerRadius(10)
                                    .padding(12)
                            }
                        }
                        .frame(height: 220)
                    }
                }
                .frame(height: 260)
                .onTapGesture { triggerBurst() }

                Spacer().frame(height: 48)

                VStack(spacing: 12) {
                    Text("Understand the problem")
                        .font(AppFont.bold(28))
                        .foregroundColor(.textPrimary)
                        .multilineTextAlignment(.center)

                    Text("Tiles don't always line up nicely. Small cuts at edges look bad and waste material. See the layout before you buy.")
                        .font(AppFont.regular(16))
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .padding(.horizontal, 32)

                Spacer()
                Spacer()
            }
        }
        .onDisappear { isLooping = false }
    }

    func triggerBurst() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { tapped = true }
        particles = (0..<16).map { i in
            let angle = Double(i) / 16.0 * 2 * .pi
            let dist = CGFloat.random(in: 80...140)
            return ParticleDot(
                id: UUID(),
                color: [Color.accentBlue, Color.accentOrange, Color.statusDone][i % 3],
                size: CGFloat.random(in: 6...14),
                offset: CGSize(width: cos(angle) * dist, height: sin(angle) * dist),
                opacity: 0
            )
        }
        withAnimation(.easeOut(duration: 0.7)) {
            particles = particles.map { var p = $0; p.opacity = 0.8; return p }
        }
        withAnimation(.easeIn(duration: 0.5).delay(0.5)) {
            particles = particles.map { var p = $0; p.opacity = 0; return p }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { tapped = false; particles = [] }
        }
    }
}

struct ParticleDot: Identifiable {
    let id: UUID
    var color: Color
    var size: CGFloat
    var offset: CGSize
    var opacity: Double
}

// MARK: - Page 2: Drag to adjust
struct OnboardingPage2: View {
    @State private var dragOffset: CGFloat = 0
    @State private var appeared = false
    @GestureState private var isDragging = false

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: "#F0F7FF"), Color(hex: "#E8F0FE")], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Draggable layout shifter
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.08), radius: 16, y: 6)
                        .frame(height: 220)

                    // Room outline
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.divider, lineWidth: 2)
                        .frame(width: 260, height: 160)

                    // Tiles sliding
                    let shiftAmount = dragOffset / 3
                    HStack(spacing: 3) {
                        ForEach(0..<5, id: \.self) { i in
                            VStack(spacing: 3) {
                                ForEach(0..<4, id: \.self) { j in
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(Color.accentBlue.opacity(0.7))
                                        .frame(width: 44, height: 34)
                                }
                            }
                        }
                    }
                    .offset(x: shiftAmount)
                    .frame(width: 240, height: 160)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                    // Drag handle
                    HStack {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.accentBlue)
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.accentBlue)
                            .frame(width: 48, height: 30)
                            .overlay(Image(systemName: "arrow.left.and.right").foregroundColor(.white).font(.system(size: 14, weight: .bold)))
                            .offset(x: dragOffset * 0.4)
                            .gesture(
                                DragGesture()
                                    .onChanged { v in dragOffset = v.translation.width }
                                    .onEnded { _ in withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) { dragOffset = 0 } }
                            )
                        Image(systemName: "chevron.right")
                            .foregroundColor(.accentBlue)
                    }
                    .offset(y: 90)

                    // Instruction label
                    Text("← Drag to shift layout →")
                        .font(AppFont.medium(12))
                        .foregroundColor(.textSecondary)
                        .offset(y: 118)
                }
                .padding(.horizontal, 24)
                .scaleEffect(appeared ? 1 : 0.85)
                .opacity(appeared ? 1 : 0)

                Spacer().frame(height: 48)

                VStack(spacing: 12) {
                    Text("Track everything")
                        .font(AppFont.bold(28))
                        .foregroundColor(.textPrimary)
                        .multilineTextAlignment(.center)

                    Text("Shift the tile layout to find the best starting position. See cuts and waste update in real time.")
                        .font(AppFont.regular(16))
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .padding(.horizontal, 32)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)

                Spacer()
                Spacer()
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2)) { appeared = true }
        }
        .onDisappear { appeared = false }
    }
}

// MARK: - Page 3: Scroll-driven animation
struct OnboardingPage3: View {
    @State private var progress: CGFloat = 0
    @State private var appeared = false
    @State private var timerActive = false

    let items = [
        ("checkmark.seal.fill", "Compare layouts", Color.statusDone),
        ("scissors", "See cuts upfront", Color.accentOrange),
        ("cart.fill", "Calculate tile count", Color.accentBlue),
        ("doc.text.fill", "Export report", Color.statusWarning),
    ]

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: "#F8FFF4"), Color(hex: "#F0FAFF")], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Animated checklist
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.08), radius: 16, y: 6)

                    VStack(spacing: 0) {
                        HStack {
                            Text("Project Summary")
                                .font(AppFont.bold(16))
                                .foregroundColor(.textPrimary)
                            Spacer()
                            Text("4 steps")
                                .font(AppFont.medium(12))
                                .foregroundColor(.textSecondary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)

                        Divider().padding(.top, 12)

                        ForEach(Array(items.enumerated()), id: \.offset) { idx, item in
                            let isCompleted = CGFloat(idx) < progress * CGFloat(items.count)
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(isCompleted ? item.2 : Color.bgSecondary)
                                        .frame(width: 36, height: 36)
                                    Image(systemName: item.0)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(isCompleted ? .white : .textInactive)
                                }
                                .animation(.spring(response: 0.4, dampingFraction: 0.7).delay(Double(idx) * 0.1), value: isCompleted)

                                Text(item.1)
                                    .font(AppFont.medium(15))
                                    .foregroundColor(isCompleted ? .textPrimary : .textInactive)
                                    .animation(.easeIn.delay(Double(idx) * 0.1), value: isCompleted)

                                Spacer()

                                if isCompleted {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(item.2)
                                        .transition(.scale.combined(with: .opacity))
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)

                            if idx < items.count - 1 { Divider().padding(.leading, 66) }
                        }
                        .padding(.bottom, 8)
                    }
                }
                .padding(.horizontal, 24)
                .scaleEffect(appeared ? 1 : 0.85)
                .opacity(appeared ? 1 : 0)

                // Progress slider (scroll-like)
                Slider(value: $progress, in: 0...1)
                    .accentColor(.accentBlue)
                    .padding(.horizontal, 32)
                    .padding(.top, 16)
                    .opacity(appeared ? 1 : 0)

                Text("Drag to see progress")
                    .font(AppFont.medium(12))
                    .foregroundColor(.textSecondary)
                    .padding(.top, 4)

                Spacer().frame(height: 40)

                VStack(spacing: 12) {
                    Text("Get better results")
                        .font(AppFont.bold(28))
                        .foregroundColor(.textPrimary)
                        .multilineTextAlignment(.center)

                    Text("Use clear checks, visual reports and layout comparisons. Know your tile count before you buy.")
                        .font(AppFont.regular(16))
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .padding(.horizontal, 32)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)

                Spacer()
                Spacer()
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2)) { appeared = true }
            animateProgress()
        }
        .onDisappear { appeared = false; timerActive = false }
    }

    func animateProgress() {
        timerActive = true
        withAnimation(.easeInOut(duration: 2.5).delay(0.5)) { progress = 1.0 }
    }
}
