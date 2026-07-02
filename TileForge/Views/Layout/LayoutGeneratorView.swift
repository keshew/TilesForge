import SwiftUI

struct LayoutGeneratorView: View {
    let room: Room
    let project: Project
    @EnvironmentObject var projectVM: ProjectViewModel
    @Environment(\.presentationMode) var dismiss

    @State private var config: LayoutConfig
    @State private var layoutResult: TileLayoutResult?
    @State private var isGenerating = false
    @State private var selectedPresetIdx = 2
    @State private var groutText = "3"
    @State private var startXOffset = 0.5
    @State private var startYOffset = 0.5
    @State private var showSaved = false
    @State private var showCompareSheet = false

    @AppStorage("wasteBuffer") private var wasteBuffer: Double = 10.0

    init(room: Room, project: Project) {
        self.room = room
        self.project = project
        _config = State(initialValue: room.layoutConfig ?? LayoutConfig.default)
        if let lc = room.layoutConfig {
            _selectedPresetIdx = State(initialValue: TileSize.presets.firstIndex(where: { $0.name == lc.tileSize.name }) ?? 2)
            _groutText = State(initialValue: String(lc.groutMM))
            _startXOffset = State(initialValue: lc.startX)
            _startYOffset = State(initialValue: lc.startY)
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(room.name)
                            .font(AppFont.bold(22))
                            .foregroundColor(.textPrimary)
                        Text(room.areaFormatted)
                            .font(AppFont.regular(13))
                            .foregroundColor(.textSecondary)
                    }
                    Spacer()
                    if showSaved {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill").foregroundColor(.statusDone)
                            Text("Saved").font(AppFont.medium(13)).foregroundColor(.statusDone)
                        }
                        .transition(.opacity.combined(with: .scale))
                    }
                }
                .padding(.horizontal, 18)

                // 2D Layout Preview
                TFCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Layout Preview")
                            .font(AppFont.semibold(14))
                            .foregroundColor(.textSecondary)
                            .padding(.horizontal, 16)
                            .padding(.top, 14)

                        if let result = layoutResult {
                            TileGridPreview(result: result, config: config)
                                .frame(height: 220)
                                .padding(.horizontal, 12)
                        } else {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.bgSecondary)
                                    .frame(height: 220)
                                VStack(spacing: 8) {
                                    Image(systemName: "square.grid.3x3")
                                        .font(.system(size: 40))
                                        .foregroundColor(.textInactive)
                                    Text("Tap Generate to see layout")
                                        .font(AppFont.medium(13))
                                        .foregroundColor(.textSecondary)
                                }
                            }
                            .padding(.horizontal, 12)
                        }

                        // Stats row
                        if let result = layoutResult {
                            HStack(spacing: 0) {
                                LayoutStat(value: "\(result.totalTiles)", label: "Total tiles", color: .accentBlue)
                                Divider().frame(height: 40)
                                LayoutStat(value: "\(result.cutTiles)", label: "Cut tiles", color: .accentOrange)
                                Divider().frame(height: 40)
                                LayoutStat(value: String(format: "%.1f%%", result.wastePercent), label: "Waste", color: wasteColor(result.wastePercent))
                                Divider().frame(height: 40)
                                LayoutStat(value: "\(result.fullTiles)", label: "Full tiles", color: .statusDone)
                            }
                            .padding(.vertical, 12)
                        }
                    }
                }
                .padding(.horizontal, 18)

                // Tile Size Selection
                VStack(alignment: .leading, spacing: 10) {
                    Text("Tile Size")
                        .font(AppFont.semibold(15))
                        .foregroundColor(.textPrimary)
                        .padding(.horizontal, 18)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(Array(TileSize.presets.enumerated()), id: \.offset) { idx, preset in
                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        selectedPresetIdx = idx
                                        config.tileSize = preset
                                    }
                                } label: {
                                    Text(preset.name)
                                        .font(AppFont.medium(13))
                                        .foregroundColor(selectedPresetIdx == idx ? .white : .textPrimary)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(selectedPresetIdx == idx ? Color.accentBlue : Color.cardWhite)
                                        .cornerRadius(10)
                                        .shadow(color: Color.black.opacity(0.05), radius: 4, y: 2)
                                }
                            }
                        }
                        .padding(.horizontal, 18)
                    }
                }

                // Pattern Selection
                VStack(alignment: .leading, spacing: 10) {
                    Text("Layout Pattern")
                        .font(AppFont.semibold(15))
                        .foregroundColor(.textPrimary)
                        .padding(.horizontal, 18)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        ForEach(TilePattern.allCases, id: \.self) { pattern in
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    config.pattern = pattern
                                }
                            } label: {
                                VStack(spacing: 6) {
                                    Image(systemName: pattern.icon)
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(config.pattern == pattern ? .white : .accentBlue)
                                    Text(pattern.rawValue)
                                        .font(AppFont.medium(11))
                                        .foregroundColor(config.pattern == pattern ? .white : .textPrimary)
                                        .multilineTextAlignment(.center)
                                        .lineLimit(2)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(config.pattern == pattern ? Color.accentBlue : Color.cardWhite)
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.05), radius: 4, y: 2)
                            }
                        }
                    }
                    .padding(.horizontal, 18)
                }

                // Grout & Offsets
                TFCard {
                    VStack(spacing: 16) {
                        HStack {
                            Text("Grout Width")
                                .font(AppFont.medium(14))
                                .foregroundColor(.textPrimary)
                            Spacer()
                            HStack(spacing: 8) {
                                Button {
                                    let v = (Double(groutText) ?? 3) - 1
                                    groutText = String(max(0, v))
                                    config.groutMM = max(0, v)
                                } label: {
                                    Image(systemName: "minus.circle").foregroundColor(.accentBlue).font(.system(size: 20))
                                }
                                Text("\(groutText) mm")
                                    .font(AppFont.bold(15))
                                    .foregroundColor(.textPrimary)
                                    .frame(width: 55, alignment: .center)
                                Button {
                                    let v = (Double(groutText) ?? 3) + 1
                                    groutText = String(v)
                                    config.groutMM = v
                                } label: {
                                    Image(systemName: "plus.circle").foregroundColor(.accentBlue).font(.system(size: 20))
                                }
                            }
                        }

                        Divider()

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Horizontal Start Offset")
                                .font(AppFont.medium(13))
                                .foregroundColor(.textSecondary)
                            HStack {
                                Text("0%").font(AppFont.regular(11)).foregroundColor(.textInactive)
                                Slider(value: $startXOffset, in: 0...1, onEditingChanged: { _ in config.startX = startXOffset })
                                    .accentColor(.accentBlue)
                                Text("100%").font(AppFont.regular(11)).foregroundColor(.textInactive)
                            }
                            Text("Start at \(Int(startXOffset * 100))% of tile width")
                                .font(AppFont.regular(11))
                                .foregroundColor(.textInactive)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Vertical Start Offset")
                                .font(AppFont.medium(13))
                                .foregroundColor(.textSecondary)
                            HStack {
                                Text("0%").font(AppFont.regular(11)).foregroundColor(.textInactive)
                                Slider(value: $startYOffset, in: 0...1, onEditingChanged: { _ in config.startY = startYOffset })
                                    .accentColor(.accentBlue)
                                Text("100%").font(AppFont.regular(11)).foregroundColor(.textInactive)
                            }
                        }
                    }
                    .padding(16)
                }
                .padding(.horizontal, 18)

                // Waste Analysis
                if let result = layoutResult {
                    WasteAnalysisCard(result: result, config: config, wasteBuffer: wasteBuffer)
                        .padding(.horizontal, 18)

                    CutBreakdownCard(result: result)
                        .padding(.horizontal, 18)

                    ShoppingCard(result: result, wasteBuffer: wasteBuffer)
                        .padding(.horizontal, 18)
                }

                // Action Buttons
                VStack(spacing: 12) {
                    Button {
                        generateLayout()
                    } label: {
                        HStack {
                            if isGenerating {
                                ProgressView().tint(.white).scaleEffect(0.8)
                            } else {
                                Image(systemName: "wand.and.stars")
                            }
                            Text(isGenerating ? "Generating..." : "Generate Layout")
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())

                    HStack(spacing: 12) {
                        Button("Shift Layout") {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                startXOffset = Double.random(in: 0.1...0.9)
                                startYOffset = Double.random(in: 0.1...0.9)
                                config.startX = startXOffset
                                config.startY = startYOffset
                            }
                            generateLayout()
                        }
                        .buttonStyle(SecondaryButtonStyle())

                        Button("Save Layout") {
                            projectVM.saveLayout(config, roomID: room.id, projectID: project.id)
                            withAnimation { showSaved = true }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation { showSaved = false }
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle(color: .statusDone))
                    }
                }
                .padding(.horizontal, 18)

                Spacer().frame(height: 100)
            }
            .padding(.top, 16)
        }
        .background(Color.bgPrimary.ignoresSafeArea())
        .navigationTitle("Layout Generator")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if room.layoutConfig != nil { generateLayout() }
        }
    }

    func generateLayout() {
        isGenerating = true
        config.groutMM = Double(groutText) ?? 3
        config.startX = startXOffset
        config.startY = startYOffset
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                layoutResult = TileLayoutCalculator.calculate(room: room, config: config)
                isGenerating = false
            }
        }
    }

    func wasteColor(_ pct: Double) -> Color {
        if pct < 10 { return .statusDone }
        if pct < 20 { return .statusWarning }
        return .statusError
    }
}

// MARK: - Tile Grid Preview
struct TileGridPreview: View {
    let result: TileLayoutResult
    let config: LayoutConfig

    var body: some View {
        GeometryReader { geo in
            let rows = result.gridCells.count
            let cols = result.gridCells.first?.count ?? 1
            let cellW = (geo.size.width) / CGFloat(cols)
            let cellH = (geo.size.height) / CGFloat(rows)

            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.bgDepth)

                VStack(spacing: 1.5) {
                    ForEach(0..<rows, id: \.self) { r in
                        HStack(spacing: 1.5) {
                            ForEach(0..<cols, id: \.self) { c in
                                let cellType = result.gridCells[r][c]
                                TileCell(type: cellType, width: cellW - 1.5, height: cellH - 1.5)
                            }
                        }
                    }
                }
                .padding(4)
            }
        }
    }
}

struct TileCell: View {
    let type: TileLayoutResult.TileCellType
    let width: CGFloat
    let height: CGFloat

    var fillColor: Color {
        switch type {
        case .full: return Color.accentBlue.opacity(0.75)
        case .cutLeft, .cutRight: return Color.accentOrange.opacity(0.7)
        case .cutTop, .cutBottom: return Color.accentOrangeSoft.opacity(0.6)
        case .corner: return Color.statusError.opacity(0.6)
        case .cutDiag: return Color.statusWarning.opacity(0.7)
        }
    }

    var body: some View {
        RoundedRectangle(cornerRadius: 1.5)
            .fill(fillColor)
            .frame(width: max(4, width), height: max(4, height))
            .overlay(
                type != .full ?
                Image(systemName: "scissors")
                    .font(.system(size: min(width, height) * 0.3))
                    .foregroundColor(.white.opacity(0.5))
                : nil
            )
    }
}

// MARK: - Waste Analysis Card
struct WasteAnalysisCard: View {
    let result: TileLayoutResult
    let config: LayoutConfig
    let wasteBuffer: Double

    var wasteColor: Color {
        if result.wastePercent < 10 { return .statusDone }
        if result.wastePercent < 20 { return .statusWarning }
        return .statusError
    }

    var body: some View {
        TFCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Waste Analysis")
                    .font(AppFont.semibold(16))
                    .foregroundColor(.textPrimary)

                HStack(alignment: .top, spacing: 16) {
                    // Waste gauge
                    ZStack {
                        Circle()
                            .stroke(Color.bgSecondary, lineWidth: 8)
                            .frame(width: 80, height: 80)
                        Circle()
                            .trim(from: 0, to: min(result.wastePercent / 100, 1))
                            .stroke(wasteColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .frame(width: 80, height: 80)
                            .rotationEffect(.degrees(-90))
                        Text(String(format: "%.0f%%", result.wastePercent))
                            .font(AppFont.bold(16))
                            .foregroundColor(wasteColor)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Circle().fill(wasteColor).frame(width: 8, height: 8)
                            Text("Waste: \(String(format: "%.1f", result.wastePercent))%")
                                .font(AppFont.medium(13)).foregroundColor(.textPrimary)
                        }
                        HStack {
                            Circle().fill(Color.accentBlue).frame(width: 8, height: 8)
                            Text("Full tiles: \(result.fullTiles)")
                                .font(AppFont.medium(13)).foregroundColor(.textPrimary)
                        }
                        HStack {
                            Circle().fill(Color.accentOrange).frame(width: 8, height: 8)
                            Text("Cut tiles: \(result.cutTiles)")
                                .font(AppFont.medium(13)).foregroundColor(.textPrimary)
                        }
                    }
                    Spacer()
                }

                // Edge cuts info
                Divider()
                VStack(spacing: 6) {
                    EdgeCutRow(side: "Left", mm: result.leftEdgeMM, tileW: config.tileSize.widthMM)
                    EdgeCutRow(side: "Right", mm: result.rightEdgeMM, tileW: config.tileSize.widthMM)
                    EdgeCutRow(side: "Top", mm: result.topEdgeMM, tileW: config.tileSize.heightMM)
                    EdgeCutRow(side: "Bottom", mm: result.bottomEdgeMM, tileW: config.tileSize.heightMM)
                }
            }
            .padding(16)
        }
    }
}

struct EdgeCutRow: View {
    let side: String
    let mm: Double
    let tileW: Double
    var percent: Double { mm / tileW * 100 }
    var body: some View {
        HStack {
            Text(side).font(AppFont.regular(13)).foregroundColor(.textSecondary).frame(width: 55, alignment: .leading)
            ProgressView(value: min(percent / 100, 1))
                .progressViewStyle(LinearProgressViewStyle(tint: percent < 95 ? .accentOrange : .statusDone))
            Text(String(format: "%.0f mm", mm)).font(AppFont.medium(12)).foregroundColor(.textPrimary).frame(width: 55, alignment: .trailing)
        }
    }
}

// MARK: - Cut Breakdown Card
struct CutBreakdownCard: View {
    let result: TileLayoutResult
    var body: some View {
        TFCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Cut Breakdown")
                    .font(AppFont.semibold(16)).foregroundColor(.textPrimary)
                HStack(spacing: 0) {
                    CutStat(icon: "arrow.left.and.right", label: "Side cuts", value: result.tilesPerColumn * 2, color: .accentOrange)
                    Divider().frame(height: 50)
                    CutStat(icon: "arrow.up.and.down", label: "Top/Bottom", value: result.tilesPerRow * 2, color: .accentOrangeSoft)
                    Divider().frame(height: 50)
                    CutStat(icon: "square.fill.on.square.fill", label: "Corners", value: 4, color: .statusError)
                }
            }
            .padding(16)
        }
    }
}

struct CutStat: View {
    let icon: String; let label: String; let value: Int; let color: Color
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon).foregroundColor(color).font(.system(size: 18))
            Text("\(value)").font(AppFont.bold(18)).foregroundColor(.textPrimary)
            Text(label).font(AppFont.regular(11)).foregroundColor(.textSecondary).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Shopping Card
struct ShoppingCard: View {
    let result: TileLayoutResult
    let wasteBuffer: Double

    var totalWithBuffer: Int { Int(ceil(Double(result.totalTiles) * (1 + wasteBuffer / 100))) }

    var body: some View {
        TFCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Shopping List")
                        .font(AppFont.semibold(16)).foregroundColor(.textPrimary)
                    Spacer()
                    Text("Buffer: +\(Int(wasteBuffer))%")
                        .font(AppFont.medium(12))
                        .foregroundColor(.accentOrange)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Color.accentOrange.opacity(0.12))
                        .cornerRadius(8)
                }
                Divider()
                ShoppingRow(label: "Tiles needed (exact)", value: "\(result.totalTiles) pcs")
                ShoppingRow(label: "With waste buffer", value: "\(totalWithBuffer) pcs", highlight: true)
                ShoppingRow(label: "Full boxes (est.~10)", value: "\(Int(ceil(Double(totalWithBuffer) / 10))) boxes")
            }
            .padding(16)
        }
    }
}

struct ShoppingRow: View {
    let label: String; let value: String; var highlight = false
    var body: some View {
        HStack {
            Text(label).font(AppFont.regular(14)).foregroundColor(highlight ? .textPrimary : .textSecondary)
            Spacer()
            Text(value).font(AppFont.bold(14)).foregroundColor(highlight ? .accentBlue : .textPrimary)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Layout Stat
struct LayoutStat: View {
    let value: String; let label: String; let color: Color
    var body: some View {
        VStack(spacing: 2) {
            Text(value).font(AppFont.bold(18)).foregroundColor(color)
            Text(label).font(AppFont.regular(11)).foregroundColor(.textSecondary).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}
