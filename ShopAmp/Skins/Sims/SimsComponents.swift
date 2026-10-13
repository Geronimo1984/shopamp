import SwiftUI

/// Палитра скина «Симс» (сайт The Sims 2)
enum Sims {
    static let page = Color(hex: 0x14347F)
    static let pageDark = Color(hex: 0x0D2563)
    static let panel = Color(hex: 0x5E8FE2)
    static let panelLight = Color(hex: 0x8DB4F2)
    static let panelBorder = Color(hex: 0x1D3F94)
    static let sidebar = Color(hex: 0x3366C8)
    static let lavender = Color(hex: 0xA6A8EC)
    static let lavenderDark = Color(hex: 0x7A7CD4)
    static let navTop = Color(hex: 0x9CC4FF)
    static let navBottom = Color(hex: 0x3F79DA)
    static let link = Color(hex: 0xFFF7A8)
    static let ink = Color(hex: 0x10245E)
    static let white = Color.white
    static let plumbobGreen = Color(hex: 0x3FD23C)
    /// Цвета, снятые пипеткой с оригинальной графики сайта
    static let pageNavy = Color(hex: 0x003062)
    static let tileBlue = Color(hex: 0x347CD2)
    static let tileEdge = Color(hex: 0x1C4283)

    static func verdana(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .custom("Verdana", size: size).weight(weight)
    }

    static func font(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .custom("Verdana", size: size).weight(weight)
    }

    static func title(_ size: CGFloat) -> Font {
        .custom("Arial", size: size).weight(.black)
    }
}

// MARK: - Пламбоб

/// Ромб-кристалл. Цвет — «настроение»: красный → жёлтый → зелёный по прогрессу покупок.
struct Plumbob: View {
    var mood: Double = 1
    var spinning = true

    private var color: Color {
        if mood < 0.34 { return Color(hex: 0xE8402A) }
        if mood < 0.75 { return Color(hex: 0xF2C53A) }
        return Sims.plumbobGreen
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30, paused: !spinning)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let turn = spinning ? cos(t * 1.8) : 1
            Canvas { c, size in
                let w = size.width, h = size.height
                let cx = w / 2
                let half = w / 2 * CGFloat(abs(turn))
                let mid = h * 0.42
                let shift = CGFloat(turn) * w * 0.12
                let top = CGPoint(x: cx, y: 0), bottom = CGPoint(x: cx, y: h)
                let left = CGPoint(x: cx - half, y: mid), right = CGPoint(x: cx + half, y: mid)
                let front = CGPoint(x: cx + shift, y: mid)
                func facet(_ pts: [CGPoint], _ brightness: Double) {
                    var p = Path()
                    p.move(to: pts[0])
                    for pt in pts.dropFirst() { p.addLine(to: pt) }
                    p.closeSubpath()
                    c.fill(p, with: .color(color.opacity(1)))
                    c.fill(p, with: .color(brightness > 0 ? .white.opacity(brightness) : .black.opacity(-brightness)))
                }
                facet([top, left, front], 0.45)
                facet([top, front, right], 0.05)
                facet([bottom, left, front], -0.1)
                facet([bottom, front, right], -0.35)
                var outline = Path()
                outline.move(to: top)
                outline.addLine(to: right)
                outline.addLine(to: bottom)
                outline.addLine(to: left)
                outline.closeSubpath()
                c.stroke(outline, with: .color(.black.opacity(0.35)), lineWidth: 1)
            }
            .offset(y: CGFloat(sin(t * 2)) * 2)
        }
        .shadow(color: color.opacity(0.7), radius: 4)
    }
}

// MARK: - Панели

/// Скруглённая панель сайта с рамкой и внутренним светом
struct SimsPanel: View {
    var fill: [Color] = [Sims.panelLight, Sims.panel]
    var radius: CGFloat = 12

    var body: some View {
        RoundedRectangle(cornerRadius: radius)
            .fill(LinearGradient(colors: fill, startPoint: .top, endPoint: .bottom))
            .overlay(
                RoundedRectangle(cornerRadius: radius)
                    .stroke(LinearGradient(colors: [.white.opacity(0.7), .white.opacity(0.1)], startPoint: .top, endPoint: .bottom),
                            lineWidth: 1.5)
                    .padding(2)
            )
            .overlay(RoundedRectangle(cornerRadius: radius).stroke(Sims.panelBorder, lineWidth: 3))
    }
}

struct SimsHeader: View {
    let icon: AnyView
    let title: String

    var body: some View {
        HStack(spacing: 8) {
            icon.frame(width: 30, height: 28)
            Text(title)
                .font(.custom("Arial", size: 17).weight(.bold))
                .foregroundStyle(.white)
                .shadow(color: Sims.ink, radius: 0, x: 1, y: 1)
            Spacer(minLength: 0)
        }
    }
}

/// Ссылка с «::» как на сайте
struct SimsLink: View {
    let text: String
    var color = Sims.link
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("::").font(Sims.font(11, .bold))
                Text(text).font(Sims.font(12, .bold)).multilineTextAlignment(.leading)
            }
            .foregroundStyle(color)
        }
        .buttonStyle(PressScaleStyle())
    }
}

/// Круглая кнопка Sims 2 (зелёная галочка / красный крестик)
struct SimsRoundButton: View {
    let symbol: String
    var colors = [Color(hex: 0x9CF07A), Color(hex: 0x2E9E2A)]
    var size: CGFloat = 44
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            ZStack {
                Circle().fill(LinearGradient(colors: [Color(hex: 0xEAF2FF), Color(hex: 0x8DA9D8)], startPoint: .top, endPoint: .bottom))
                Circle().fill(LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom)).padding(size * 0.1)
                Ellipse().fill(.white.opacity(0.6)).frame(width: size * 0.45, height: size * 0.2).offset(y: -size * 0.22)
                Image(systemName: symbol)
                    .font(.system(size: size * 0.38, weight: .black))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.4), radius: 1, y: 1)
                Circle().stroke(Sims.panelBorder, lineWidth: 1.5)
            }
            .frame(width: size, height: size)
        }
        .buttonStyle(PressScaleStyle())
    }
}

struct GlobeIcon: View {
    var body: some View {
        ZStack {
            Circle().fill(RadialGradient(colors: [Color(hex: 0xA9D4FF), Color(hex: 0x3A7FE0), Color(hex: 0x1A3E9A)],
                                         center: UnitPoint(x: 0.35, y: 0.3), startRadius: 1, endRadius: 16))
            Ellipse().stroke(.white.opacity(0.6), lineWidth: 1).padding(.horizontal, 7)
            Rectangle().fill(.white.opacity(0.6)).frame(height: 1)
            Ellipse().stroke(.white.opacity(0.4), lineWidth: 1).frame(height: 10)
            Circle().stroke(Color(hex: 0x0E2466), lineWidth: 1.2)
        }
    }
}

/// Текст с толстой обводкой (как буквы логотипа)
struct StrokedText: View {
    let text: String
    let font: Font
    var fill: AnyShapeStyle = AnyShapeStyle(Color.white)
    var stroke: Color = Color(hex: 0x1E4A9C)
    var width: CGFloat = 2

    var body: some View {
        let base = Text(text).font(font)
        ZStack {
            ForEach(0..<16, id: \.self) { i in
                let a = Double(i) / 16 * 2 * .pi
                base.foregroundStyle(stroke)
                    .offset(x: CGFloat(cos(a)) * width, y: CGFloat(sin(a)) * width)
            }
            base.foregroundStyle(fill)
        }
    }
}

/// Витрина блюд из The Sims: тарелки едут по кругу, над центральной поднимается пар
struct SimsDishShow: View {
    /// Канонические блюда из The Sims (порядок — как картинки sims_food_0…25)
    static let names = [
        "Блинчики", "Спагетти", "Чили", "Омлет", "Французские тосты", "Яичница-болтунья", "Сэндвич BLT",
        "Рыба с картошкой", "Клубничный торт", "Печенье с шоколадом", "Фрикадельки", "Рёбрышки «Корона»",
        "Тыквенный пирог", "Минестроне", "Индейка", "Хлопья", "Сырный тост", "Макароны с сыром",
        "Лобстер «Термидор»", "«Аляска»", "Амброзия", "Крокеты из лосося", "Сосиски с пюре",
        "Говядина «Веллингтон»", "Вафли с яблоком и беконом", "Вафли «Банана-сплит»",
    ]
    private var count: Int { Self.names.count }
    private let period = 2.2

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let step = t / period
            let index = Int(step)
            let frac = step - Double(index)
            let move = frac < 0.35 ? smooth(frac / 0.35) : 1
            ZStack {
                ForEach(-2...2, id: \.self) { k in
                    let pos = Double(k) - move + 1
                    let dish = ((index + k) % count + count) % count
                    let size = 104 - min(abs(pos), 2) * 30
                    Image("sims_food_\(dish)")
                        .resizable()
                        .interpolation(.high)
                        .frame(width: size, height: size)
                        .offset(x: CGFloat(pos) * 92, y: CGFloat(abs(pos)) * 6 + (abs(pos) < 0.3 ? CGFloat(sin(t * 3)) * 2 : 0))
                        .opacity(1 - min(abs(pos) / 2.3, 1))
                        .zIndex(-abs(pos))
                }
                steam(t: t)
                    .frame(width: 60, height: 46)
                    .offset(y: -50)
                    .opacity(move >= 1 ? 1 : 0)
                sparkles(t: t)
                // название блюда в центре появляется, когда тарелка встала на место
                Text(Self.names[(index % count + count) % count])
                    .font(Sims.verdana(10, .bold))
                    .foregroundStyle(.white)
                    .shadow(color: Color(hex: 0x10285C), radius: 0, x: 1, y: 1)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color(hex: 0x10285C).opacity(0.45)))
                    .offset(y: 52)
                    .opacity(move >= 1 ? 1 : 0)
            }
            .frame(maxWidth: .infinity)
        }
        .allowsHitTesting(false)
    }

    private func smooth(_ x: Double) -> Double { x * x * (3 - 2 * x) }

    /// Три волнистые струйки пара
    private func steam(t: Double) -> some View {
        Canvas { c, size in
            for j in 0..<3 {
                var p = Path()
                let x0 = size.width * (0.25 + CGFloat(j) * 0.25)
                for y in stride(from: size.height, through: 0, by: -2) {
                    let k = Double(size.height - y) / Double(size.height)
                    let x = x0 + CGFloat(sin(t * 3 + Double(j) * 2 + k * 6)) * 5 * CGFloat(k)
                    if y == size.height { p.move(to: CGPoint(x: x, y: y)) } else { p.addLine(to: CGPoint(x: x, y: y)) }
                }
                c.stroke(p, with: .linearGradient(Gradient(colors: [.white.opacity(0.75), .white.opacity(0)]),
                                                  startPoint: CGPoint(x: 0, y: size.height), endPoint: .zero),
                         style: StrokeStyle(lineWidth: 3, lineCap: .round))
            }
        }
    }

    private func sparkles(t: Double) -> some View {
        Canvas { c, size in
            let points: [CGPoint] = [CGPoint(x: 0.3, y: 0.2), CGPoint(x: 0.7, y: 0.25), CGPoint(x: 0.62, y: 0.75), CGPoint(x: 0.36, y: 0.7)]
            for (i, pt) in points.enumerated() {
                let a = (sin(t * 4 + Double(i) * 1.7) + 1) / 2
                let s: CGFloat = 2 + CGFloat(a) * 3
                let x = pt.x * size.width, y = pt.y * size.height
                c.fill(Path(CGRect(x: x - s / 4, y: y - s, width: s / 2, height: s * 2)), with: .color(.white.opacity(a)))
                c.fill(Path(CGRect(x: x - s, y: y - s / 4, width: s * 2, height: s / 2)), with: .color(.white.opacity(a)))
            }
        }
    }
}

/// Логотип-шайба The Sims 2: оригинальная картинка, пламбоб остаётся частью логотипа —
/// вокруг него пульсирует сияние и кружит искорка, по глянцу пробегает блик, шайба чуть «дышит»
struct AnimatedSimsLogo: View {
    var size: CGFloat = 104

    var body: some View {
        let s = size
        let plumbob = CGPoint(x: s * 0.448, y: s * 0.24)
        TimelineView(.animation(minimumInterval: 1 / 30)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let breathe = 1 + CGFloat(sin(t * 1.4)) * 0.012
            let pulse = (sin(t * 2.6) + 1) / 2
            let sweep = t.truncatingRemainder(dividingBy: 5) / 1.2
            ZStack(alignment: .topLeading) {
                Image("sims_logo_puck").resizable().interpolation(.high)
                    .frame(width: s, height: s)
                // сияние пламбоба — тот же жёлто-зелёный, что в логотипе
                Circle()
                    .fill(RadialGradient(colors: [Color(hex: 0xF4FF9C).opacity(0.25 + 0.35 * pulse), Color(hex: 0x9BE04A).opacity(0.15 * pulse), .clear],
                                         center: .center, startRadius: 0, endRadius: s * 0.09))
                    .frame(width: s * 0.18, height: s * 0.18)
                    .blendMode(.screen)
                    .position(plumbob)
                // искорка кружит вокруг пламбоба
                Image(systemName: "sparkle")
                    .font(.system(size: s * 0.06, weight: .bold))
                    .foregroundStyle(Color(hex: 0xF8FFD0))
                    .opacity(0.4 + 0.6 * pulse)
                    .position(x: plumbob.x + CGFloat(cos(t * 1.8)) * s * 0.07,
                              y: plumbob.y + CGFloat(sin(t * 1.8)) * s * 0.035)
                if sweep < 1 {
                    Rectangle()
                        .fill(LinearGradient(colors: [.clear, .white.opacity(0.45), .clear], startPoint: .leading, endPoint: .trailing))
                        .frame(width: s * 0.22, height: s * 1.4)
                        .rotationEffect(.degrees(25))
                        .offset(x: -s * 0.25 + CGFloat(sweep) * s * 1.3, y: -s * 0.2)
                        .blur(radius: s * 0.02)
                        .frame(width: s, height: s, alignment: .topLeading)
                        .mask(Circle().padding(s * 0.03))
                }
            }
            .frame(width: s, height: s, alignment: .topLeading)
            .scaleEffect(breathe)
        }
        .frame(width: s, height: s)
    }
}

/// Картинка плитки меню: по плиткам волной пробегает подсветка — иконка приподнимается, за ней свечение и искорка
struct SimsNavTileImage: View {
    let image: String
    let index: Int

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            // волна слева направо раз в 4.5 с, на каждую плитку ~0.6 с
            let phase = (t.truncatingRemainder(dividingBy: 4.5) - Double(index) * 0.32) / 0.6
            let p = phase >= 0 && phase < 1 ? sin(phase * .pi) : 0
            GeometryReader { g in
                let w = g.size.width, h = g.size.height
                ZStack(alignment: .topLeading) {
                    // плитка целиком — фон и изогнутая полоса неподвижны
                    Image(image).resizable().interpolation(.high)
                        .frame(width: w, height: h)
                    // мягкое свечение за иконкой
                    Ellipse()
                        .fill(RadialGradient(colors: [Color(hex: 0xDDEBFF).opacity(0.45 * p), .clear],
                                             center: .center, startRadius: 0, endRadius: w * 0.32))
                        .frame(width: w * 0.7, height: h * 0.6)
                        .position(x: w * 0.5, y: h * 0.66)
                    // сама иконка (вырезана из плитки по цвету фона): приподнимается и чуть растёт
                    Image(image + "_icon").resizable().interpolation(.high)
                        .frame(width: w, height: h)
                        .scaleEffect(1 + CGFloat(p) * 0.1, anchor: UnitPoint(x: 0.5, y: 0.9))
                        .offset(y: -CGFloat(p) * h * 0.05)
                        .shadow(color: .black.opacity(0.35 * p), radius: 2, y: 2)
                    if p > 0.3 {
                        Image(systemName: "sparkle")
                            .font(.system(size: h * 0.2, weight: .bold))
                            .foregroundStyle(.white)
                            .shadow(color: Color(hex: 0xFFF59A), radius: 3)
                            .opacity(p)
                            .rotationEffect(.degrees(phase * 90))
                            .position(x: w * 0.8, y: h * 0.45)
                    }
                }
                .frame(width: w, height: h)
                .clipped()
            }
        }
    }
}

/// Нажатие на плитку меню: вдавливается и светлеет
struct SimsTilePressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.93 : 1)
            .brightness(configuration.isPressed ? 0.12 : 0)
            .animation(configuration.isPressed ? .easeOut(duration: 0.08) : .spring(response: 0.3, dampingFraction: 0.45),
                       value: configuration.isPressed)
    }
}
