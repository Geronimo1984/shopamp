import SwiftUI

/// Палитра скина Winamp
enum Winamp {
    static let screen = Color(hex: 0x0D0F2C)
    static let bodyTop = Color(hex: 0x2B3070)
    static let bodyBottom = Color(hex: 0x1D2156)
    static let frameLight = Color(hex: 0x5057A8)
    static let frameDark = Color(hex: 0x080A20)

    static let lcd = Color(hex: 0x04050B)
    static let lcdDot = Color(hex: 0x2A3158)
    static let green = Color(hex: 0x22EE22)
    static let greenDim = Color(hex: 0x135F17)
    static let listGreen = Color(hex: 0x46D446)
    static let listBought = Color(hex: 0x1D6A22)
    static let listDue = Color(hex: 0x8FA88F)
    static let white = Color(hex: 0xF4F4F4)

    static let label = Color(hex: 0xDCE2F2)
    static let labelDim = Color(hex: 0x8A90B8)
    static let clutter = Color(hex: 0x2D3364)

    static let stripeLight = Color(hex: 0xE2D9A6)
    static let stripeShine = Color(hex: 0xFBF5D6)
    static let stripeDark = Color(hex: 0x4E4A30)

    static let faceTop = Color(hex: 0xDCE3F2)
    static let faceBottom = Color(hex: 0xA2AECB)
    static let bevelLight = Color(hex: 0xF7FAFF)
    static let bevelShadow = Color(hex: 0x56628A)
    static let glyphFill = Color(hex: 0xEEF2FF)
    static let ink = Color(hex: 0x252E5E)

    static let goldTop = Color(hex: 0xF4E6A8)
    static let goldBottom = Color(hex: 0xB59A4E)

    static let ledOn = Color(hex: 0x3CF23C)
    static let ledOff = Color(hex: 0x1E3826)
}

// MARK: - Корпус окна

struct WindowBody: View {
    var line: CGFloat = 6

    var body: some View {
        ZStack {
            Rectangle()
                .fill(LinearGradient(colors: [Winamp.bodyTop, Winamp.bodyBottom], startPoint: .top, endPoint: .bottom))
            Rectangle()
                .strokeBorder(Winamp.frameDark, lineWidth: line)
            Rectangle()
                .strokeBorder(Winamp.frameLight.opacity(0.55), lineWidth: line / 3)
                .padding(line)
        }
    }
}

// MARK: - Объёмная кнопка

struct Bevel: View {
    var pressed = false
    var edge: CGFloat = 3
    var top = Winamp.faceTop
    var bottom = Winamp.faceBottom

    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height, e = edge, i = edge * 1.5
            ZStack {
                Rectangle().fill(Winamp.frameDark)
                Rectangle()
                    .fill(LinearGradient(colors: pressed ? [bottom, top] : [top, bottom],
                                         startPoint: .top, endPoint: .bottom))
                    .padding(e * 0.7)
                Path { p in
                    p.move(to: CGPoint(x: i, y: h - i))
                    p.addLine(to: CGPoint(x: i, y: i))
                    p.addLine(to: CGPoint(x: w - i, y: i))
                }
                .stroke(pressed ? Winamp.bevelShadow : Winamp.bevelLight, lineWidth: e)
                Path { p in
                    p.move(to: CGPoint(x: i, y: h - i))
                    p.addLine(to: CGPoint(x: w - i, y: h - i))
                    p.addLine(to: CGPoint(x: w - i, y: i))
                }
                .stroke(pressed ? Winamp.bevelLight : Winamp.bevelShadow, lineWidth: e)
            }
        }
    }
}

struct SkinButtonStyle: ButtonStyle {
    var edge: CGFloat = 3

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .offset(x: configuration.isPressed ? edge * 0.7 : 0,
                    y: configuration.isPressed ? edge * 0.7 : 0)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Bevel(pressed: configuration.isPressed, edge: edge))
            .contentShape(Rectangle())
    }
}

struct SkinButton<Label: View>: View {
    var edge: CGFloat = 3
    let action: () -> Void
    let label: Label

    init(edge: CGFloat = 3, action: @escaping () -> Void, @ViewBuilder label: () -> Label) {
        self.edge = edge
        self.action = action
        self.label = label()
    }

    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            label
        }
        .buttonStyle(SkinButtonStyle(edge: edge))
    }
}

/// Кнопка-переключатель с лампочкой (EQ, PL, SHUFFLE…)
struct LedLabel<Content: View>: View {
    let on: Bool
    var ledSize = CGSize(width: 16, height: 11)
    var inset: CGFloat = 10
    let content: Content

    init(on: Bool, ledSize: CGSize = CGSize(width: 16, height: 11), inset: CGFloat = 10,
         @ViewBuilder content: () -> Content) {
        self.on = on
        self.ledSize = ledSize
        self.inset = inset
        self.content = content()
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.leading, ledSize.width * 0.8)
            Rectangle()
                .fill(on ? Winamp.ledOn : Winamp.ledOff)
                .frame(width: ledSize.width, height: ledSize.height)
                .overlay(Rectangle().stroke(Winamp.frameDark, lineWidth: ledSize.height * 0.18))
                .shadow(color: on ? Winamp.ledOn.opacity(0.8) : .clear, radius: ledSize.height * 0.4)
                .padding(inset)
        }
    }
}

// MARK: - Значки транспорта

struct TransportGlyph: Shape {
    enum Kind { case prev, play, pause, stop, next, eject }
    let kind: Kind

    func path(in r: CGRect) -> Path {
        let x = r.minX, y = r.minY, w = r.width, h = r.height
        var p = Path()
        switch kind {
        case .play:
            p.move(to: CGPoint(x: x, y: y))
            p.addLine(to: CGPoint(x: x + w, y: y + h / 2))
            p.addLine(to: CGPoint(x: x, y: y + h))
            p.closeSubpath()
        case .prev:
            p.addRect(CGRect(x: x, y: y, width: w * 0.2, height: h))
            p.move(to: CGPoint(x: x + w, y: y))
            p.addLine(to: CGPoint(x: x + w * 0.3, y: y + h / 2))
            p.addLine(to: CGPoint(x: x + w, y: y + h))
            p.closeSubpath()
        case .next:
            p.move(to: CGPoint(x: x, y: y))
            p.addLine(to: CGPoint(x: x + w * 0.7, y: y + h / 2))
            p.addLine(to: CGPoint(x: x, y: y + h))
            p.closeSubpath()
            p.addRect(CGRect(x: x + w * 0.8, y: y, width: w * 0.2, height: h))
        case .pause:
            p.addRect(CGRect(x: x, y: y, width: w * 0.36, height: h))
            p.addRect(CGRect(x: x + w * 0.64, y: y, width: w * 0.36, height: h))
        case .stop:
            p.addRect(CGRect(x: x, y: y, width: w, height: h))
        case .eject:
            p.move(to: CGPoint(x: x, y: y + h * 0.6))
            p.addLine(to: CGPoint(x: x + w / 2, y: y))
            p.addLine(to: CGPoint(x: x + w, y: y + h * 0.6))
            p.closeSubpath()
            p.addRect(CGRect(x: x, y: y + h * 0.76, width: w, height: h * 0.24))
        }
        return p
    }
}

extension Shape {
    func skinGlyph(line: CGFloat = 4) -> some View {
        ZStack {
            fill(Winamp.glyphFill)
            stroke(Winamp.ink, style: StrokeStyle(lineWidth: line, lineJoin: .round))
        }
    }
}

struct BoltShape: Shape {
    func path(in r: CGRect) -> Path {
        let pts: [(CGFloat, CGFloat)] = [
            (0.62, 0.0), (0.12, 0.56), (0.44, 0.56), (0.26, 1.0),
            (0.88, 0.40), (0.56, 0.40), (0.80, 0.0),
        ]
        var p = Path()
        for (i, pt) in pts.enumerated() {
            let point = CGPoint(x: r.minX + pt.0 * r.width, y: r.minY + pt.1 * r.height)
            if i == 0 { p.move(to: point) } else { p.addLine(to: point) }
        }
        p.closeSubpath()
        return p
    }
}

struct BoltLogo: View {
    var body: some View {
        ZStack {
            BoltShape()
                .fill(LinearGradient(colors: [Winamp.goldTop, Color(hex: 0xD98A2B)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
            BoltShape()
                .stroke(Color(hex: 0x3A2A10), style: StrokeStyle(lineWidth: 4, lineJoin: .round))
        }
        .rotationEffect(.degrees(18))
        .shadow(color: .black.opacity(0.6), radius: 0, x: 3, y: 3)
    }
}

// MARK: - Заголовок окна

enum TitleButtonKind: Hashable, Identifiable {
    case help, minimize, shade, close
    var id: Self { self }
}

struct TitleButton: View {
    let kind: TitleButtonKind

    var body: some View {
        GeometryReader { g in
            let s = g.size.width
            ZStack {
                RoundedRectangle(cornerRadius: s * 0.15)
                    .fill(LinearGradient(colors: [Winamp.stripeShine, Winamp.stripeLight],
                                         startPoint: .top, endPoint: .bottom))
                RoundedRectangle(cornerRadius: s * 0.15)
                    .stroke(Winamp.stripeDark, lineWidth: s * 0.1)
                switch kind {
                case .help:
                    Text("?")
                        .font(.system(size: s * 0.7, weight: .black))
                        .foregroundStyle(Winamp.stripeDark)
                case .minimize:
                    Rectangle().fill(Winamp.stripeDark)
                        .frame(width: s * 0.5, height: s * 0.14)
                        .offset(y: s * 0.18)
                case .shade:
                    RoundedRectangle(cornerRadius: s * 0.08)
                        .stroke(Winamp.stripeDark, lineWidth: s * 0.12)
                        .frame(width: s * 0.5, height: s * 0.36)
                case .close:
                    Path { p in
                        p.move(to: CGPoint(x: s * 0.28, y: s * 0.28))
                        p.addLine(to: CGPoint(x: s * 0.72, y: s * 0.72))
                        p.move(to: CGPoint(x: s * 0.72, y: s * 0.28))
                        p.addLine(to: CGPoint(x: s * 0.28, y: s * 0.72))
                    }
                    .stroke(Winamp.stripeDark, lineWidth: s * 0.14)
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

struct Stripes: View {
    var body: some View {
        GeometryReader { g in
            let h = g.size.height
            ZStack {
                RoundedRectangle(cornerRadius: h * 0.35).fill(Winamp.stripeDark)
                VStack(spacing: h * 0.2) {
                    ForEach(0..<2, id: \.self) { _ in
                        Capsule()
                            .fill(LinearGradient(colors: [Winamp.stripeLight, Winamp.stripeShine, Winamp.stripeLight],
                                                 startPoint: .top, endPoint: .bottom))
                            .frame(height: h * 0.26)
                    }
                }
                .padding(.horizontal, h * 0.18)
            }
        }
    }
}

struct TitleBar: View {
    let title: String
    var showIcon = true
    var buttons: [TitleButtonKind] = [.minimize, .shade, .close]
    var onClose: (() -> Void)? = nil
    /// Нажатие на значок слева (в главном окне — выбор скина)
    var onIcon: (() -> Void)? = nil
    var onHelp: (() -> Void)? = nil
    /// Долгое нажатие на значок (пасхалка)
    var onIconLong: (() -> Void)? = nil
    @State private var longFiredAt = Date.distantPast

    var body: some View {
        GeometryReader { g in
            let h = g.size.height
            HStack(spacing: h * 0.25) {
                if showIcon {
                    BoltShape()
                        .fill(Winamp.labelDim)
                        .frame(width: h * 0.5, height: h * 0.62)
                        .padding(h * 0.15)
                        .contentShape(Rectangle())
                        .simultaneousGesture(LongPressGesture(minimumDuration: 0.8).onEnded { _ in
                            longFiredAt = Date()
                            Haptics.tap()
                            onIconLong?()
                        })
                        .pressable(.winamp) {
                            // после долгого нажатия кнопка не должна ещё и открывать выбор скина
                            guard Date().timeIntervalSince(longFiredAt) > 1 else { return }
                            Haptics.tap()
                            onIcon?()
                        }
                        .padding(-h * 0.15)
                }
                Stripes().frame(height: h * 0.44)
                Text(title)
                    .font(.system(size: h * 0.56, weight: .black))
                    .tracking(h * 0.05)
                    .foregroundStyle(Winamp.label)
                    .shadow(color: .black.opacity(0.85), radius: 0, x: h * 0.04, y: h * 0.04)
                    .lineLimit(1)
                    .fixedSize()
                Stripes().frame(height: h * 0.44)
                HStack(spacing: h * 0.12) {
                    ForEach(buttons) { kind in
                        TitleButton(kind: kind)
                            .frame(width: h * 0.44, height: h * 0.44)
                            .contentShape(Rectangle())
                            .pressable(.winamp) {
                                if kind == .close { onClose?() }
                                if kind == .help {
                                    Haptics.tap()
                                    onHelp?()
                                }
                            }
                    }
                }
            }
            .padding(.horizontal, h * 0.3)
            .frame(width: g.size.width, height: h)
        }
    }
}

// MARK: - LCD

struct LCDBox<Content: View>: View {
    var alignment: Alignment = .leading
    var line: CGFloat = 4
    let content: Content

    init(alignment: Alignment = .leading, line: CGFloat = 4, @ViewBuilder content: () -> Content) {
        self.alignment = alignment
        self.line = line
        self.content = content()
    }

    var body: some View {
        ZStack(alignment: alignment) {
            Rectangle().fill(Winamp.lcd)
            content
        }
        .clipped()
        .overlay(Rectangle().strokeBorder(Winamp.frameDark, lineWidth: line))
        .overlay(
            Rectangle()
                .strokeBorder(Winamp.frameLight.opacity(0.35), lineWidth: line / 2)
                .padding(-line / 2)
        )
    }
}

struct SevenSegDigit: Shape {
    let char: Character

    private static let map: [Character: String] = [
        "0": "abcdef", "1": "bc", "2": "abged", "3": "abgcd", "4": "fgbc",
        "5": "afgcd", "6": "afgedc", "7": "abc", "8": "abcdefg", "9": "abcdfg", "-": "g",
    ]

    func path(in r: CGRect) -> Path {
        let x = r.minX, y = r.minY, w = r.width, h = r.height
        let t = w * 0.17
        let gap = t * 0.3
        let mid = y + h / 2
        var p = Path()
        func horizontal(_ yy: CGFloat) {
            p.addRect(CGRect(x: x + t / 2 + gap, y: yy, width: w - t - 2 * gap, height: t))
        }
        func vertical(_ xx: CGFloat, _ y0: CGFloat, _ y1: CGFloat) {
            p.addRect(CGRect(x: xx, y: y0 + gap, width: t, height: y1 - y0 - 2 * gap))
        }
        for segment in Self.map[char] ?? "" {
            switch segment {
            case "a": horizontal(y)
            case "g": horizontal(mid - t / 2)
            case "d": horizontal(y + h - t)
            case "f": vertical(x, y + t / 2, mid)
            case "b": vertical(x + w - t, y + t / 2, mid)
            case "e": vertical(x, mid, y + h - t / 2)
            case "c": vertical(x + w - t, mid, y + h - t / 2)
            default: break
            }
        }
        return p
    }
}

/// Большие цифры «02:53»
struct LCDDigits: View {
    let minus: Bool
    let left: Int
    let right: Int
    var digit = CGSize(width: 42, height: 62)

    var body: some View {
        let l = String(format: "%02d", min(left, 99))
        let r = String(format: "%02d", min(right, 99))
        HStack(spacing: digit.width * 0.25) {
            SevenSegDigit(char: minus ? "-" : " ")
                .fill(Winamp.green)
                .frame(width: digit.width * 0.6, height: digit.height)
            ForEach(Array(l.enumerated()), id: \.offset) { item in
                SevenSegDigit(char: item.element).fill(Winamp.green)
                    .frame(width: digit.width, height: digit.height)
            }
            VStack(spacing: digit.height * 0.26) {
                Rectangle().fill(Winamp.green).frame(width: digit.width * 0.18, height: digit.width * 0.18)
                Rectangle().fill(Winamp.green).frame(width: digit.width * 0.18, height: digit.width * 0.18)
            }
            ForEach(Array(r.enumerated()), id: \.offset) { item in
                SevenSegDigit(char: item.element).fill(Winamp.green)
                    .frame(width: digit.width, height: digit.height)
            }
        }
        .shadow(color: Winamp.green.opacity(0.45), radius: 3)
    }
}

/// Бегущая строка в стиле Winamp: символы сдвигаются по кругу
struct Marquee: View {
    let text: String
    let maxChars: Int
    let size: CGFloat
    var step = 0.28

    var body: some View {
        TimelineView(.periodic(from: .now, by: step)) { context in
            Text(visible(at: context.date))
                .font(.system(size: size, weight: .bold, design: .monospaced))
                .foregroundStyle(Winamp.green)
                .shadow(color: Winamp.green.opacity(0.4), radius: 2)
                .lineLimit(1)
                .fixedSize()
        }
    }

    private func visible(at date: Date) -> String {
        let chars = Array(text)
        guard chars.count > maxChars else { return text }
        let loop = chars + Array("  ***  ")
        let start = Int(date.timeIntervalSinceReferenceDate / step) % loop.count
        return String((0..<maxChars).map { loop[(start + $0) % loop.count] })
    }
}

/// Спектр-анализатор под цифрами
struct Visualizer: View {
    let playing: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: 0.09, paused: !playing)) { context in
            Canvas { c, size in
                let t = context.date.timeIntervalSinceReferenceDate
                let dot: CGFloat = 3
                // пунктир по краям, как на оригинале
                for x in stride(from: CGFloat(0), to: size.width, by: dot * 2.5) {
                    c.fill(Path(CGRect(x: x, y: size.height - dot, width: dot, height: dot)),
                           with: .color(Winamp.lcdDot))
                }
                for y in stride(from: CGFloat(0), to: size.height, by: dot * 2.5) {
                    c.fill(Path(CGRect(x: 0, y: y, width: dot, height: dot)), with: .color(Winamp.lcdDot))
                }
                guard playing else { return }
                let bars = 19
                let barW = (size.width - 10) / CGFloat(bars)
                let gradient = Gradient(colors: [Color(hex: 0xEF3B1E), Color(hex: 0xF0C42A),
                                                 Color(hex: 0x56E02A), Color(hex: 0x1FA51F)])
                for i in 0..<bars {
                    let d = Double(i)
                    let v = (sin(t * 3.1 + d * 0.9) + sin(t * 5.7 + d * 1.9) + sin(t * 1.3 + d * 0.4) + 3) / 6
                    let height = CGFloat(v) * (size.height - dot * 2)
                    let rect = CGRect(x: 8 + CGFloat(i) * barW, y: size.height - dot * 2 - height,
                                      width: barW - 4, height: height)
                    c.fill(Path(rect), with: .linearGradient(gradient,
                                                             startPoint: .zero,
                                                             endPoint: CGPoint(x: 0, y: size.height)))
                }
            }
        }
    }
}

// MARK: - Слайдеры

struct GripLines: View {
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { _ in
                Rectangle().fill(Winamp.ink).frame(width: 3, height: 16)
            }
        }
    }
}

struct HSkinSlider: View {
    var value: Double
    let track: [Color]
    var thumbWidth: CGFloat = 58
    var onChange: (Double) -> Void
    var onEnd: (() -> Void)? = nil

    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            let x = (w - thumbWidth) * CGFloat(min(max(value, 0), 1))
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(LinearGradient(colors: track, startPoint: .top, endPoint: .bottom))
                    .overlay(Capsule().stroke(Winamp.frameDark, lineWidth: 3))
                    .frame(height: h * 0.5)
                Bevel(edge: 3)
                    .overlay(GripLines())
                    .frame(width: thumbWidth, height: h)
                    .offset(x: x)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { drag in
                        let v = (drag.location.x - thumbWidth / 2) / (w - thumbWidth)
                        onChange(Double(min(max(v, 0), 1)))
                    }
                    .onEnded { _ in onEnd?() }
            )
        }
    }
}
