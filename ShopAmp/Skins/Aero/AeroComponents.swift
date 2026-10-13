import SwiftUI

/// Палитра скина Frutiger Aero / Windows XP
enum Aero {
    static let skyTop = Color(hex: 0x1E7FE0)
    static let skyBottom = Color(hex: 0xC4EAFF)
    static let grassLight = Color(hex: 0x9BE65A)
    static let grassDark = Color(hex: 0x2F8F1C)

    static let frameGreen = Color(hex: 0x7FD45C)
    static let frameBlue = Color(hex: 0xA7DCF7)
    static let panel = Color(hex: 0xF2FAFE)
    static let boxBorder = Color(hex: 0x7C9AB0)
    static let ink = Color(hex: 0x161616)

    static let aquaFill = Color(hex: 0x9ED8FF)
    static let aquaStroke = Color(hex: 0x1C68D3)
    static let limeFill = Color(hex: 0xB9F58C)
    static let limeStroke = Color(hex: 0x3BAA25)
    static let pillTop = Color(hex: 0xD4F7B8)
    static let pillBottom = Color(hex: 0x8FDA66)

    static let lunaTitle = [Color(hex: 0x3C8CF8), Color(hex: 0x0A5FE6), Color(hex: 0x0553DA), Color(hex: 0x0B5EE0)]
    static let xpBeige = Color(hex: 0xECE9D8)
    static let xpBorder = Color(hex: 0x0831D9)
    static let xpField = Color(hex: 0x7F9DB9)
    static let xpSelect = Color(hex: 0x316AC5)

    static let welcomeBg = Color(hex: 0x5A7EDC)
    static let welcomeGlow = Color(hex: 0x8DAEEE)
    static let welcomeBand = Color(hex: 0x00309C)
    static let welcomeOrange = Color(hex: 0xF0A23E)
    static let welcomeSub = Color(hex: 0xD6E4FF)

    static func mono(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        Font.custom("Courier New", size: size).weight(weight)
    }

    static let tilePalette: [[Color]] = [
        [Color(hex: 0xFFE27A), Color(hex: 0xF5A623)],
        [Color(hex: 0xA8E6FF), Color(hex: 0x3D9BE9)],
        [Color(hex: 0xC9F59B), Color(hex: 0x5CB82E)],
        [Color(hex: 0xFFC3D8), Color(hex: 0xE5598A)],
        [Color(hex: 0xE2D1FF), Color(hex: 0x8C67D9)],
        [Color(hex: 0xFFD3A8), Color(hex: 0xE5733B)],
    ]
}

/// Простой генератор случайных чисел с зерном — рисунок одинаковый при каждой перерисовке
struct SeededRandom {
    private var state: UInt64

    init(seed: UInt64) { state = seed &* 6364136223846793005 &+ 1 }

    mutating func next() -> CGFloat {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return CGFloat((state >> 33) % 10_000) / 10_000
    }
}

/// Нажатие: кнопка сжимается и чуть темнеет, при отпускании пружинит обратно
struct PressScaleStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
            .brightness(configuration.isPressed ? -0.08 : 0)
            .animation(configuration.isPressed ? .easeOut(duration: 0.08) : .spring(response: 0.3, dampingFraction: 0.45),
                       value: configuration.isPressed)
    }
}

/// Классическая Mac OS: нажатый элемент инвертируется
struct MacInvertStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        Group {
            if configuration.isPressed {
                configuration.label.colorInvert()
            } else {
                configuration.label
            }
        }
        .contentShape(Rectangle())
    }
}

/// Пиксельная кнопка: сдвиг на «пиксель» вниз-вправо и затемнение
struct PixelPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .offset(x: configuration.isPressed ? 2 : 0, y: configuration.isPressed ? 2 : 0)
            .brightness(configuration.isPressed ? -0.12 : 0)
            .animation(.linear(duration: 0.05), value: configuration.isPressed)
    }
}

// MARK: - Текст с обводкой («dm to ask about comms»)

struct OutlinedText: View {
    let text: String
    var size: CGFloat = 15
    var fill = Aero.aquaFill
    var stroke = Aero.aquaStroke

    var body: some View {
        let base = Text(text).font(Aero.mono(size, .bold))
        ZStack {
            ForEach(0..<8, id: \.self) { i in
                let angle = Double(i) * .pi / 4
                base.foregroundColor(stroke)
                    .offset(x: cos(angle) * 1.3, y: sin(angle) * 1.3)
            }
            base.foregroundColor(fill)
        }
    }
}

// MARK: - Глянцевые формы

struct GlossCapsule: View {
    var top = Color.white
    var bottom = Color(hex: 0xDCE5EE)
    var border = Color(hex: 0x8C9BA8)

    var body: some View {
        ZStack {
            Capsule().fill(LinearGradient(colors: [top, bottom], startPoint: .top, endPoint: .bottom))
            Capsule()
                .fill(LinearGradient(colors: [.white.opacity(0.9), .white.opacity(0)], startPoint: .top, endPoint: .bottom))
                .scaleEffect(x: 0.94, y: 0.48, anchor: .top)
                .padding(.top, 1.5)
            Capsule().stroke(border, lineWidth: 1.2)
        }
    }
}

struct AeroBox: View {
    var radius: CGFloat = 10
    var fill: [Color] = [Color.white, Color(hex: 0xEAF3F9)]

    var body: some View {
        RoundedRectangle(cornerRadius: radius)
            .fill(LinearGradient(colors: fill, startPoint: .top, endPoint: .bottom))
            .overlay(RoundedRectangle(cornerRadius: radius).stroke(Aero.boxBorder, lineWidth: 1.2))
    }
}

/// Круглая глянцевая кнопка (синие стрелки, кнопка воспроизведения)
struct OrbButton: View {
    let symbol: String
    var size: CGFloat = 30
    var colors = [Color(hex: 0x6CB8FF), Color(hex: 0x1557C9)]
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            Orb(colors: colors) {
                Image(systemName: symbol)
                    .font(.system(size: size * 0.45, weight: .heavy))
                    .foregroundStyle(.white)
                    .shadow(color: Color(hex: 0x0D3E91), radius: 1)
            }
            .frame(width: size, height: size)
        }
        .buttonStyle(PressScaleStyle())
    }
}

struct Orb<Content: View>: View {
    var colors = [Color(hex: 0x6CB8FF), Color(hex: 0x1557C9)]
    let content: Content

    init(colors: [Color] = [Color(hex: 0x6CB8FF), Color(hex: 0x1557C9)], @ViewBuilder content: () -> Content) {
        self.colors = colors
        self.content = content()
    }

    var body: some View {
        ZStack {
            Circle().fill(LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom))
            Circle().fill(RadialGradient(colors: [.white.opacity(0.45), .clear], center: .bottom,
                                         startRadius: 0, endRadius: 30))
            Ellipse()
                .fill(LinearGradient(colors: [.white.opacity(0.9), .white.opacity(0.05)], startPoint: .top, endPoint: .bottom))
                .scaleEffect(x: 0.72, y: 0.46, anchor: .top)
                .padding(.top, 1.5)
            Circle().stroke(Color(hex: 0x0D3E91).opacity(0.8), lineWidth: 1.2)
            content
        }
    }
}

// MARK: - Флажок «окон»

struct XPFlag: View {
    var body: some View {
        GeometryReader { g in
            let w = g.size.width / 2, h = g.size.height / 2, gap = g.size.width * 0.06
            ZStack(alignment: .topLeading) {
                tile(Color(hex: 0xF25022)).frame(width: w - gap, height: h - gap)
                tile(Color(hex: 0x7FBA00)).frame(width: w - gap, height: h - gap).offset(x: w)
                tile(Color(hex: 0x00A4EF)).frame(width: w - gap, height: h - gap).offset(y: h)
                tile(Color(hex: 0xFFB900)).frame(width: w - gap, height: h - gap).offset(x: w, y: h)
            }
            .rotation3DEffect(.degrees(18), axis: (x: 0.2, y: 1, z: 0.1), perspective: 0.6)
            .rotationEffect(.degrees(-6))
        }
    }

    private func tile(_ color: Color) -> some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(LinearGradient(colors: [color.opacity(0.85), color], startPoint: .topLeading, endPoint: .bottomTrailing))
    }
}

// MARK: - Плитка товара (как картинка пользователя в XP)

struct ProductTile: View {
    let name: String
    var size: CGFloat = 48
    var dimmed = false

    var body: some View {
        let colors = Aero.tilePalette[ProductIcon.colorIndex(for: name, count: Aero.tilePalette.count)]
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.14)
                .fill(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing))
            ProductImage(name: name, size: size * 0.74)
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.14))
        .overlay(RoundedRectangle(cornerRadius: size * 0.14).stroke(Color.white, lineWidth: size * 0.06))
        .shadow(color: .black.opacity(0.35), radius: 2, x: 1, y: 2)
        .saturation(dimmed ? 0 : 1)
        .opacity(dimmed ? 0.65 : 1)
    }
}

// MARK: - Фон: небо, облака, трава, пузыри

struct AeroBackground: View {
    var body: some View {
        Canvas { c, size in
            let w = size.width, h = size.height
            var rng = SeededRandom(seed: 7)
            c.fill(Path(CGRect(origin: .zero, size: size)),
                   with: .linearGradient(Gradient(colors: [Aero.skyTop, Aero.skyBottom]),
                                         startPoint: .zero, endPoint: CGPoint(x: 0, y: h * 0.7)))
            c.drawLayer { layer in
                layer.addFilter(.blur(radius: 16))
                for _ in 0..<10 {
                    let x = rng.next() * w, y = rng.next() * h * 0.5, r = 40 + rng.next() * 70
                    layer.fill(Path(ellipseIn: CGRect(x: x - r, y: y - r * 0.45, width: r * 2, height: r * 0.9)),
                               with: .color(.white.opacity(0.8)))
                }
            }
            let horizon = h * 0.64
            var hill = Path()
            hill.move(to: CGPoint(x: 0, y: horizon + 30))
            hill.addQuadCurve(to: CGPoint(x: w, y: horizon), control: CGPoint(x: w * 0.45, y: horizon - 60))
            hill.addLine(to: CGPoint(x: w, y: h))
            hill.addLine(to: CGPoint(x: 0, y: h))
            hill.closeSubpath()
            c.fill(hill, with: .linearGradient(Gradient(colors: [Aero.grassLight, Aero.grassDark]),
                                               startPoint: CGPoint(x: 0, y: horizon - 40), endPoint: CGPoint(x: 0, y: h)))
            for _ in 0..<160 {
                let x = rng.next() * w
                let height = 50 + rng.next() * h * 0.28
                let lean = (rng.next() - 0.5) * 70
                var blade = Path()
                blade.move(to: CGPoint(x: x - 3, y: h))
                blade.addQuadCurve(to: CGPoint(x: x + lean, y: h - height),
                                   control: CGPoint(x: x + lean * 0.2, y: h - height * 0.5))
                blade.addQuadCurve(to: CGPoint(x: x + 3, y: h),
                                   control: CGPoint(x: x + lean * 0.2 + 4, y: h - height * 0.5))
                c.fill(blade, with: .color(Color(hue: 0.25 + Double(rng.next()) * 0.07, saturation: 0.75,
                                                 brightness: 0.5 + Double(rng.next()) * 0.45).opacity(0.85)))
            }
            for _ in 0..<12 {
                drawBubble(in: &c, center: CGPoint(x: rng.next() * w, y: rng.next() * h), radius: 6 + rng.next() * 22)
            }
        }
    }
}

func drawBubble(in c: inout GraphicsContext, center: CGPoint, radius r: CGFloat) {
    let rect = CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2)
    c.fill(Path(ellipseIn: rect),
           with: .radialGradient(Gradient(colors: [.white.opacity(0.05), .white.opacity(0.35)]),
                                 center: center, startRadius: 0, endRadius: r))
    c.stroke(Path(ellipseIn: rect), with: .color(.white.opacity(0.75)), lineWidth: max(r * 0.06, 0.8))
    c.fill(Path(ellipseIn: CGRect(x: center.x - r * 0.55, y: center.y - r * 0.7, width: r * 0.6, height: r * 0.35)),
           with: .color(.white.opacity(0.85)))
}

/// Баннер: небо, холмы, вода, пузыри и стеклянный город
struct AeroBanner: View {
    var body: some View {
        Canvas { c, size in
            let w = size.width, h = size.height
            var rng = SeededRandom(seed: 21)
            c.fill(Path(CGRect(origin: .zero, size: size)),
                   with: .linearGradient(Gradient(colors: [Color(hex: 0x3D9BEF), Color(hex: 0xD8F1FF)]),
                                         startPoint: .zero, endPoint: CGPoint(x: 0, y: h * 0.75)))
            c.drawLayer { layer in
                layer.addFilter(.blur(radius: 8))
                for _ in 0..<6 {
                    let x = rng.next() * w * 0.6, y = rng.next() * h * 0.45, r = 20 + rng.next() * 30
                    layer.fill(Path(ellipseIn: CGRect(x: x - r, y: y - r * 0.5, width: r * 2, height: r)),
                               with: .color(.white.opacity(0.9)))
                }
            }
            // стеклянный город справа
            var x = w * 0.55
            while x < w {
                let bw = 8 + rng.next() * 14
                let bh = h * (0.3 + rng.next() * 0.5)
                let rect = CGRect(x: x, y: h * 0.78 - bh, width: bw, height: bh)
                c.fill(Path(rect), with: .linearGradient(Gradient(colors: [Color(hex: 0xD9ECF8), Color(hex: 0x7EA6C4)]),
                                                         startPoint: CGPoint(x: rect.minX, y: 0),
                                                         endPoint: CGPoint(x: rect.maxX, y: 0)))
                x += bw + 2
            }
            // холмы
            var hill = Path()
            hill.move(to: CGPoint(x: 0, y: h * 0.72))
            hill.addQuadCurve(to: CGPoint(x: w, y: h * 0.7), control: CGPoint(x: w * 0.4, y: h * 0.52))
            hill.addLine(to: CGPoint(x: w, y: h))
            hill.addLine(to: CGPoint(x: 0, y: h))
            hill.closeSubpath()
            c.fill(hill, with: .linearGradient(Gradient(colors: [Color(hex: 0x9EEA4E), Color(hex: 0x3E9E22)]),
                                               startPoint: CGPoint(x: 0, y: h * 0.55), endPoint: CGPoint(x: 0, y: h)))
            // водяная волна
            var wave = Path()
            wave.move(to: CGPoint(x: -10, y: h * 0.35))
            wave.addCurve(to: CGPoint(x: w * 0.5, y: h * 0.1),
                          control1: CGPoint(x: w * 0.15, y: h * 0.75), control2: CGPoint(x: w * 0.3, y: -h * 0.2))
            wave.addCurve(to: CGPoint(x: -10, y: h * 0.55),
                          control1: CGPoint(x: w * 0.3, y: h * 0.1), control2: CGPoint(x: w * 0.12, y: h * 0.95))
            c.fill(wave, with: .linearGradient(Gradient(colors: [.white.opacity(0.85), Color(hex: 0x7CC8FF).opacity(0.5)]),
                                               startPoint: .zero, endPoint: CGPoint(x: w * 0.4, y: h)))
            for _ in 0..<9 {
                drawBubble(in: &c, center: CGPoint(x: rng.next() * w, y: rng.next() * h), radius: 3 + rng.next() * 12)
            }
        }
    }
}

/// Подводная сцена с лучами света
struct AquaScene: View {
    var body: some View {
        Canvas { c, size in
            let w = size.width, h = size.height
            var rng = SeededRandom(seed: 5)
            c.fill(Path(CGRect(origin: .zero, size: size)),
                   with: .linearGradient(Gradient(colors: [Color(hex: 0xC9F0FF), Color(hex: 0x48AEF2), Color(hex: 0x1665CC)]),
                                         startPoint: .zero, endPoint: CGPoint(x: 0, y: h)))
            for i in 0..<5 {
                var ray = Path()
                let x0 = w * (0.1 + CGFloat(i) * 0.2)
                ray.move(to: CGPoint(x: x0, y: 0))
                ray.addLine(to: CGPoint(x: x0 + 14, y: 0))
                ray.addLine(to: CGPoint(x: x0 + 50, y: h))
                ray.addLine(to: CGPoint(x: x0 + 18, y: h))
                ray.closeSubpath()
                c.fill(ray, with: .color(.white.opacity(0.12)))
            }
            var wave = Path()
            wave.move(to: CGPoint(x: 0, y: h * 0.85))
            wave.addCurve(to: CGPoint(x: w, y: h * 0.7),
                          control1: CGPoint(x: w * 0.3, y: h * 0.6), control2: CGPoint(x: w * 0.6, y: h * 1.0))
            wave.addLine(to: CGPoint(x: w, y: h))
            wave.addLine(to: CGPoint(x: 0, y: h))
            wave.closeSubpath()
            c.fill(wave, with: .color(.white.opacity(0.25)))
            for _ in 0..<16 {
                drawBubble(in: &c, center: CGPoint(x: rng.next() * w, y: rng.next() * h), radius: 3 + rng.next() * 10)
            }
        }
    }
}

// MARK: - Окно Windows XP (Luna)

struct XPWindow<Content: View>: View {
    let title: String
    let onClose: () -> Void
    let content: Content

    init(title: String, onClose: @escaping () -> Void, @ViewBuilder content: () -> Content) {
        self.title = title
        self.onClose = onClose
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                XPFlag().frame(width: 16, height: 14)
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.5), radius: 0, x: 1, y: 1)
                Spacer()
                Button(action: onClose) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(LinearGradient(colors: [Color(hex: 0xEE9277), Color(hex: 0xC8391B)],
                                                 startPoint: .top, endPoint: .bottom))
                        RoundedRectangle(cornerRadius: 4).stroke(.white, lineWidth: 1)
                        Image(systemName: "xmark")
                            .font(.system(size: 11, weight: .heavy))
                            .foregroundStyle(.white)
                    }
                    .frame(width: 32, height: 32)
                }
                .buttonStyle(PressScaleStyle())
            }
            .padding(.horizontal, 8)
            .frame(height: 32)
            .background(LinearGradient(colors: Aero.lunaTitle, startPoint: .top, endPoint: .bottom))

            content
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Aero.xpBeige)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Aero.xpBorder, lineWidth: 2))
        .shadow(color: .black.opacity(0.4), radius: 10, x: 0, y: 6)
        .environment(\.colorScheme, .light)
    }
}

struct XPButtonStyle: ButtonStyle {
    var isDefault = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16))
            .foregroundStyle(.black)
            .padding(.horizontal, 14)
            .frame(minWidth: 44, minHeight: 42)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(LinearGradient(colors: configuration.isPressed
                                         ? [Color(hex: 0xE3E3DB), .white] : [.white, Color(hex: 0xE3E3DB)],
                                         startPoint: .top, endPoint: .bottom))
            )
            .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color(hex: 0x003C74), lineWidth: 1))
            .overlay(
                Group {
                    if isDefault {
                        RoundedRectangle(cornerRadius: 3).stroke(Color(hex: 0x6D9EEC), lineWidth: 2).padding(2)
                    }
                }
            )
    }
}

// MARK: - Стиль экрана приветствия Windows XP (общий для меню и режима покупок)

extension Aero {
    /// Шрифт экрана входа XP: Trebuchet MS — ближайший к Franklin Gothic / Tahoma, что есть в iOS
    static func xp(_ size: CGFloat, _ weight: Font.Weight = .regular, italic: Bool = false) -> Font {
        let base = Font.custom("Trebuchet MS", size: size).weight(weight)
        return italic ? base.italic() : base
    }
}

/// Фон середины экрана приветствия: ровный синий со светлым пятном слева вверху
struct XPWelcomeBackground: View {
    var body: some View {
        ZStack {
            Aero.welcomeBg
            RadialGradient(colors: [Color(hex: 0x9AB6EE), Aero.welcomeBg.opacity(0)],
                           center: UnitPoint(x: 0.12, y: 0.18), startRadius: 4, endRadius: 420)
        }
    }
}

/// Верхняя тёмная полоса с тонкой светлой линией снизу
struct XPTopBand<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(Aero.welcomeBand.ignoresSafeArea(edges: .top))
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(LinearGradient(colors: [Color(hex: 0x3E6FD8), Color(hex: 0xA9C3F5), .white.opacity(0.9), Color(hex: 0x3E6FD8)],
                                         startPoint: .leading, endPoint: .trailing))
                    .frame(height: 2)
            }
    }
}

/// Нижняя тёмная полоса с оранжево-белой линией сверху
struct XPBottomBand<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .frame(height: 64)
            .background(Aero.welcomeBand.ignoresSafeArea(edges: .bottom))
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(LinearGradient(colors: [Color(hex: 0x3E6FD8), Aero.welcomeOrange, Color(hex: 0xFFE7B8), Color(hex: 0x3E6FD8)],
                                         startPoint: .leading, endPoint: .trailing))
                    .frame(height: 2)
            }
    }
}

/// Вертикальная белая линия-разделитель, гаснущая к концам
struct XPDivider: View {
    var vertical = true

    var body: some View {
        Rectangle()
            .fill(LinearGradient(colors: [.white.opacity(0), .white.opacity(0.85), .white.opacity(0)],
                                 startPoint: vertical ? .top : .leading, endPoint: vertical ? .bottom : .trailing))
            .frame(width: vertical ? 1.5 : nil, height: vertical ? nil : 1.5)
    }
}

/// Полупрозрачная панель, как выделенная учётная запись на экране входа
struct XPPanel: View {
    var highlighted = false
    var radius: CGFloat = 10

    var body: some View {
        RoundedRectangle(cornerRadius: radius)
            .fill(LinearGradient(colors: highlighted
                                 ? [Color(hex: 0x2A52B2), Color(hex: 0x3F67C6).opacity(0.35)]
                                 : [Color.white.opacity(0.16), Color.white.opacity(0.06)],
                                 startPoint: .leading, endPoint: .trailing))
            .overlay(
                RoundedRectangle(cornerRadius: radius)
                    .stroke(LinearGradient(colors: [.white.opacity(0.6), .white.opacity(0.12)], startPoint: .topLeading, endPoint: .bottomTrailing),
                            lineWidth: 1)
            )
    }
}

/// Квадратная кнопка экрана входа: зелёная стрелка, синий «?», оранжевое питание
struct XPSquareButton: View {
    let symbol: String
    var colors: [Color] = [Color(hex: 0x7BD86A), Color(hex: 0x2E9A2A)]
    var size: CGFloat = 26
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: size * 0.16)
                    .fill(LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom))
                RoundedRectangle(cornerRadius: size * 0.16)
                    .fill(LinearGradient(colors: [.white.opacity(0.45), .clear], startPoint: .top, endPoint: .center))
                    .padding(1.5)
                RoundedRectangle(cornerRadius: size * 0.16).stroke(.white, lineWidth: 1.2)
                Image(systemName: symbol)
                    .font(.system(size: size * 0.48, weight: .heavy))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.3), radius: 0.5, y: 0.5)
            }
            .frame(width: size, height: size)
        }
        .buttonStyle(PressScaleStyle())
    }
}

/// Зелёная кнопка «пуск» Windows XP
struct XPStartButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            HStack(spacing: 8) {
                XPFlag().frame(width: 22, height: 20)
                Text(title)
                    .font(Aero.xp(19, .bold, italic: true))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .fixedSize()
                    .shadow(color: .black.opacity(0.45), radius: 0, x: 1, y: 1)
            }
            .padding(.leading, 12)
            .padding(.trailing, 20)
            .frame(height: 40)
        }
        .buttonStyle(XPStartStyle())
    }
}

/// Кнопка «пуск» Windows XP: выпуклый глянец, мягкий диагональный блик раз в несколько секунд;
/// при нажатии темнеет и вдавливается
struct XPStartStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        return configuration.label
            .offset(y: pressed ? 1 : 0)
            .background(
                TimelineView(.animation(minimumInterval: 1 / 30)) { context in
                    let t = context.date.timeIntervalSinceReferenceDate
                    // блик проходит за 0.9 с, затем пауза; плавное ускорение и торможение
                    let raw = t.truncatingRemainder(dividingBy: 4) / 0.9
                    let sweep = raw < 1 ? raw * raw * (3 - 2 * raw) : -1
                    Canvas { c, size in
                        let w = size.width, h = size.height
                        let shape = UnevenRightCapsule().path(in: CGRect(origin: .zero, size: size))
                        // основа: зелёный выпуклый градиент XP
                        c.fill(shape, with: .linearGradient(
                            Gradient(stops: pressed
                                ? [.init(color: Color(hex: 0x2E7E24), location: 0), .init(color: Color(hex: 0x22701A), location: 0.5),
                                   .init(color: Color(hex: 0x2A8222), location: 1)]
                                : [.init(color: Color(hex: 0x79D467), location: 0), .init(color: Color(hex: 0x4BB23C), location: 0.18),
                                   .init(color: Color(hex: 0x379A2C), location: 0.55), .init(color: Color(hex: 0x2C8A24), location: 0.8),
                                   .init(color: Color(hex: 0x45A838), location: 1)]),
                            startPoint: .zero, endPoint: CGPoint(x: 0, y: h)))
                        c.drawLayer { l in
                            l.clip(to: shape)
                            // стеклянный блик верхней половины
                            if !pressed {
                                l.fill(Path(roundedRect: CGRect(x: 4, y: 2, width: w - h * 0.4, height: h * 0.42), cornerRadius: h * 0.2),
                                       with: .linearGradient(Gradient(colors: [.white.opacity(0.55), .white.opacity(0.08)]),
                                                             startPoint: CGPoint(x: 0, y: 2), endPoint: CGPoint(x: 0, y: h * 0.44)))
                            }
                            // мягкий диагональный блик
                            if !pressed && sweep >= 0 {
                                let bandW = w * 0.28
                                let x = -bandW + CGFloat(sweep) * (w + bandW * 2)
                                var band = Path()
                                band.move(to: CGPoint(x: x + h * 0.35, y: 0))
                                band.addLine(to: CGPoint(x: x + bandW + h * 0.35, y: 0))
                                band.addLine(to: CGPoint(x: x + bandW - h * 0.35, y: h))
                                band.addLine(to: CGPoint(x: x - h * 0.35, y: h))
                                band.closeSubpath()
                                l.addFilter(.blur(radius: 5))
                                l.fill(band, with: .linearGradient(
                                    Gradient(colors: [.white.opacity(0), .white.opacity(0.55), .white.opacity(0)]),
                                    startPoint: CGPoint(x: x, y: 0), endPoint: CGPoint(x: x + bandW, y: 0)))
                            }
                        }
                        // внутренняя тень при нажатии
                        if pressed {
                            c.drawLayer { l in
                                l.clip(to: shape)
                                l.addFilter(.blur(radius: 2.5))
                                l.stroke(shape, with: .color(.black.opacity(0.45)), lineWidth: 4)
                            }
                        }
                        c.stroke(shape, with: .color(Color(hex: 0x1B5214)), lineWidth: 1)
                    }
                }
            )
            .shadow(color: .black.opacity(pressed ? 0.15 : 0.4), radius: pressed ? 1 : 3, x: 1, y: pressed ? 1 : 2)
            .animation(.easeOut(duration: 0.08), value: pressed)
    }
}

/// Форма кнопки «пуск»: прямой левый край, скруглённый правый
struct UnevenRightCapsule: Shape {
    func path(in r: CGRect) -> Path {
        let rad = r.height / 2
        var p = Path()
        p.move(to: CGPoint(x: r.minX + 6, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX - rad, y: r.minY))
        p.addArc(center: CGPoint(x: r.maxX - rad, y: r.midY), radius: rad, startAngle: .degrees(-90), endAngle: .degrees(90), clockwise: false)
        p.addLine(to: CGPoint(x: r.minX + 6, y: r.maxY))
        p.addQuadCurve(to: CGPoint(x: r.minX, y: r.maxY - 6), control: CGPoint(x: r.minX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.minY + 6))
        p.addQuadCurve(to: CGPoint(x: r.minX + 6, y: r.minY), control: CGPoint(x: r.minX, y: r.minY))
        p.closeSubpath()
        return p
    }
}

/// Индикатор XP из зелёных квадратиков (как полоса загрузки)
struct XPProgressBar: View {
    let value: Double

    var body: some View {
        GeometryReader { g in
            let blocks = Int(g.size.width / 10)
            let filled = Int((Double(blocks) * min(max(value, 0), 1)).rounded())
            HStack(spacing: 2) {
                ForEach(0..<max(blocks, 1), id: \.self) { i in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(i < filled
                              ? LinearGradient(colors: [Color(hex: 0xA6F08C), Color(hex: 0x3BB52B), Color(hex: 0x2B9A20)], startPoint: .top, endPoint: .bottom)
                              : LinearGradient(colors: [.clear, .clear], startPoint: .top, endPoint: .bottom))
                        .frame(width: 8)
                }
            }
            .padding(3)
            .frame(width: g.size.width, height: g.size.height, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 4).fill(.white))
            .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color(hex: 0x7F9DB9), lineWidth: 1))
        }
    }
}
