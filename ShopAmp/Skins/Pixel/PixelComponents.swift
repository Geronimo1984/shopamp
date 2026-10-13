import SwiftUI

/// Палитра пастельного пиксельного скина
enum Px {
    // Мягкая пастельная «ночная» палитра: сливово-индиго контур, нежный розовый, лаванда,
    // ночные панели в тон фону автомата Kirby
    static let ink = Color(hex: 0x433A9E)
    static let navy = Color(hex: 0x262463)
    static let nightTop = Color(hex: 0x3A3486)
    static let pink = Color(hex: 0xEC6AA8)
    static let pinkSoft = Color(hex: 0xF3A6CB)
    static let pinkLight = Color(hex: 0xFFD6EB)
    static let blush = Color(hex: 0xFBEDF6)
    static let lavender = Color(hex: 0x9EA3F2)
    static let mortar = Color(hex: 0x7471D2)
    static let lavenderLight = Color(hex: 0xECE8FB)
    static let sky = Color(hex: 0xBFD6FF)
    static let paper = Color(hex: 0xFFF9FD)
    static let gold = Color(hex: 0xFFD978)

    static func title(_ size: CGFloat) -> Font { .custom("Press Start 2P", size: size) }
    static func body(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        Font.custom([.medium, .semibold, .bold, .heavy, .black].contains(weight) ? "Monocraft-Bold" : "Monocraft", size: size * 0.9)
    }
}

// MARK: - Пиксельные формы

/// Прямоугольник со «ступенчатыми» пиксельными углами
struct PixelRect: InsettableShape {
    var step: CGFloat = 3
    var inset: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        let r = rect.insetBy(dx: inset, dy: inset)
        let s = step
        var p = Path()
        p.move(to: CGPoint(x: r.minX + s, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX - s, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX - s, y: r.minY + s))
        p.addLine(to: CGPoint(x: r.maxX, y: r.minY + s))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY - s))
        p.addLine(to: CGPoint(x: r.maxX - s, y: r.maxY - s))
        p.addLine(to: CGPoint(x: r.maxX - s, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX + s, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX + s, y: r.maxY - s))
        p.addLine(to: CGPoint(x: r.minX, y: r.maxY - s))
        p.addLine(to: CGPoint(x: r.minX, y: r.minY + s))
        p.addLine(to: CGPoint(x: r.minX + s, y: r.minY + s))
        p.closeSubpath()
        return p
    }

    func inset(by amount: CGFloat) -> PixelRect {
        var copy = self
        copy.inset += amount
        return copy
    }
}

/// Пиксельная панель: заливка, контур и сплошная тень со сдвигом
struct PixelPanel: View {
    var fill = Px.paper
    var border = Px.ink
    var shadow: Color? = Px.navy
    var line: CGFloat = 3

    var body: some View {
        ZStack {
            if let shadow {
                PixelRect(step: line).fill(shadow).offset(x: line + 1, y: line + 1)
            }
            PixelRect(step: line).fill(fill)
            PixelRect(step: line).strokeBorder(border, lineWidth: line)
        }
    }
}

/// Многоцветная пиксельная картинка из строк; символ → цвет по палитре
struct PixelArt: View {
    let rows: [String]
    let palette: [Character: Color]

    var body: some View {
        Canvas { c, size in
            let height = rows.count
            let width = rows.map(\.count).max() ?? 1
            let cell = min(size.width / CGFloat(width), size.height / CGFloat(height))
            let ox = (size.width - cell * CGFloat(width)) / 2
            let oy = (size.height - cell * CGFloat(height)) / 2
            for (y, row) in rows.enumerated() {
                for (x, ch) in row.enumerated() {
                    guard let color = palette[ch] else { continue }
                    c.fill(Path(CGRect(x: ox + CGFloat(x) * cell, y: oy + CGFloat(y) * cell,
                                       width: cell + 0.3, height: cell + 0.3)),
                           with: .color(color))
                }
            }
        }
    }
}

enum PxArt {
    static let palette: [Character: Color] = [
        "K": Px.ink, "N": Px.navy, "P": Px.pink, "L": Px.pinkLight, "Y": Px.gold,
        "W": .white, "B": Px.sky, "V": Px.lavender, "R": Color(hex: 0xE8323C),
    ]

    static let moon = [
        "....KKKK....",
        "..KKYYYYK...",
        ".KYYYYKK....",
        ".KYYYK......",
        "KYYYK.......",
        "KYYYK.......",
        "KYYYK.......",
        "KYYYK.......",
        ".KYYYK......",
        ".KYYYYKK....",
        "..KKYYYYK...",
        "....KKKK....",
    ]
    static let heart = [
        ".KKK...KKK.",
        "KPLPK.KPPPK",
        "KLPPPKPPPPK",
        "KPPPPPPPPPK",
        "KPPPPPPPPPK",
        ".KPPPPPPPK.",
        "..KPPPPPK..",
        "...KPPPK...",
        "....KPK....",
        ".....K.....",
    ]
    static let brooch = [
        "..KKK...KKK..",
        ".KPLPK.KPPPK.",
        "KPLPPPKPPPPPK",
        "KPPPPYYYPPPPK",
        "KPPPYKKKYPPPK",
        "KPPPYK.KYPPPK",
        ".KPPPYYYPPPK.",
        "..KPPPPPPPK..",
        "...KPPPPPK...",
        "....KPPPK....",
        ".....KPK.....",
        "......K......",
    ]
    static let cat = [
        "N.......N...",
        "NN.....NN...",
        "NNN...NNN...",
        "NNNNYNNNN...",
        "NNNYYNNNN...",
        "NRNNNNNRN...",
        "NNNNPNNNN...",
        ".NNNNNNN....",
        ".NNNNNNNN...",
        "NNNNNNNNNN..",
        "NNNNNNNNNNN.",
        "NNNNNNNNNNNN",
    ]
    static let sparkle = [
        "..W..",
        "..W..",
        "WWWWW",
        "..W..",
        "..W..",
    ]
}

// MARK: - Окно с заголовком «◉◉◉ TITLE»

struct PixelWindow<Content: View>: View {
    let title: String
    var trailing: AnyView? = nil
    let content: Content

    init(title: String, trailing: AnyView? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.trailing = trailing
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                HStack(spacing: 3) {
                    ForEach(0..<3, id: \.self) { _ in
                        ZStack {
                            Circle().fill(Px.pink)
                            Circle().fill(Px.pinkLight).frame(width: 4, height: 4).offset(x: -1.5, y: -1.5)
                            Circle().stroke(Px.ink, lineWidth: 2)
                        }
                        .frame(width: 12, height: 12)
                    }
                }
                Text(title)
                    .font(Px.title(10))
                    .foregroundStyle(Px.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Spacer(minLength: 2)
                trailing
            }
            .padding(.horizontal, 10)
            .frame(height: 34)
            .background(Color.white)
            Rectangle().fill(Px.ink).frame(height: 3)
            content
        }
        .background(Px.paper)
        .clipShape(PixelRect(step: 3))
        .overlay(PixelRect(step: 3).strokeBorder(Px.ink, lineWidth: 3))
    }
}

struct PixelButtonStyle: ButtonStyle {
    var fill = Px.pink
    var text = Color.white

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Px.title(9))
            .foregroundStyle(text)
            .padding(.horizontal, 10)
            .frame(minHeight: 42)
            .background(PixelPanel(fill: configuration.isPressed ? Px.navy : fill, shadow: configuration.isPressed ? nil : Px.navy))
            .offset(x: configuration.isPressed ? 2 : 0, y: configuration.isPressed ? 2 : 0)
    }
}

// MARK: - Полоска как HP / MP

struct PixelBar: View {
    let value: Double
    var fill = Px.pinkSoft

    var body: some View {
        GeometryReader { g in
            ZStack(alignment: .leading) {
                PixelRect(step: 2).fill(Color.white)
                PixelRect(step: 2).fill(fill)
                    .frame(width: max(g.size.width * min(max(value, 0), 1), 0))
                PixelRect(step: 2).strokeBorder(Px.ink, lineWidth: 2)
                HStack(spacing: 0) {
                    ForEach(0..<10, id: \.self) { i in
                        Spacer()
                        if i < 9 { Rectangle().fill(Px.ink.opacity(0.35)).frame(width: 1, height: 4) }
                    }
                }
                .frame(maxHeight: .infinity, alignment: .bottom)
                .padding(.bottom, 3)
            }
        }
    }
}

// MARK: - Вспышка искр («Лунная призма»)

struct SparkleBurst: View {
    let start: Date
    var text: String? = nil
    var big = false

    var body: some View {
        TimelineView(.animation) { context in
            let duration = big ? 2.2 : 1.0
            let p = min(context.date.timeIntervalSince(start) / duration, 1)
            ZStack {
                Canvas { c, size in
                    guard p < 1 else { return }
                    let center = CGPoint(x: size.width / 2, y: size.height / 2)
                    let count = big ? 36 : 14
                    let colors = [Px.pink, Px.gold, Px.sky, Px.lavender, .white]
                    for i in 0..<count {
                        let angle = Double(i) / Double(count) * 2 * .pi + p * (big ? 2 : 1)
                        let radius = CGFloat(p) * (big ? 220 : 90) * (i % 2 == 0 ? 1 : 0.7)
                        let s: CGFloat = big ? 8 : 5
                        let x = center.x + CGFloat(cos(angle)) * radius
                        let y = center.y + CGFloat(sin(angle)) * radius
                        let color = colors[i % colors.count].opacity(1 - p)
                        c.fill(Path(CGRect(x: x - s / 2, y: y - s * 1.5, width: s, height: s * 3)), with: .color(color))
                        c.fill(Path(CGRect(x: x - s * 1.5, y: y - s / 2, width: s * 3, height: s)), with: .color(color))
                    }
                }
                if let text, p < 1 {
                    Text(text)
                        .font(Px.title(big ? 14 : 11))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white)
                        .shadow(color: Px.pink, radius: 0, x: 2, y: 2)
                        .shadow(color: Px.ink, radius: 0, x: -1, y: -1)
                        .padding(.horizontal, 20)
                        .scaleEffect(0.6 + min(p * 3, 1) * 0.4)
                        .opacity(p > 0.8 ? (1 - p) * 5 : 1)
                }
            }
        }
        .allowsHitTesting(false)
    }
}
