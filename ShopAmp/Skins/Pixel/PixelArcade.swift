import SwiftUI

// Анимации из пиксельного трекера (скин Moon): Кирби на звезде, автомат с клешнёй, планета с кольцом.
// Пиксельные картинки и тайминги перенесены один в один из task_quest_moon.py.

/// Один кадр трекера — 80 мс
private func trackerFrame(_ date: Date) -> Int {
    Int(date.timeIntervalSinceReferenceDate / 0.08)
}

private func hexColor(_ s: String) -> Color {
    Color(hex: UInt32(s.dropFirst(), radix: 16) ?? 0)
}

enum ArcadeArt {
    static let kirbyPalette: [Character: Color] = [
        "a": hexColor("#690322"), "b": hexColor("#da7591"), "c": hexColor("#dd9baa"), "d": hexColor("#9b0238"),
        "e": hexColor("#dfd0c4"), "f": hexColor("#da2261"), "g": hexColor("#db9a04"), "h": hexColor("#ddd702"),
        "i": hexColor("#4b9c15"), "j": hexColor("#026fc5"), "k": hexColor("#6a3175"), "z": hexColor("#010200"),
    ]

    static let kirby = [
        "...............aabbbbbaa.........",
        ".............abbcccccccbba.......",
        "............abcccccccccccbd......",
        "...........abcccccccccccccba.....",
        ".......aabbbbccccccccccccccb.....",
        "......abcccbbcccccccabccabcca....",
        "......acccccbcccccccezccezccbb...",
        "......bcccccbcccccccdzccdzccbca..",
        "......acccccbccccccczzcczzccbcb..",
        ".......bbbbbbccbbbbcbaccbaccbcb..",
        "........abbbbccffffcbbccbbffbcb..",
        "..........abbcccccccccccccccba...",
        "..........abbccccccccccaccbba....",
        ".........aabbcccccccccccccbb.....",
        ".........afdbbbcccccccccbbba.....",
        "........aeffdbbbbbbbbbbbbba......",
        "........affffdbbbbbbbbbbbaa......",
        "..aaaaa.afffddaddbbbbbdddddaa....",
        ".aggggggaaaaaaaaaaaaaddddffdaa...",
        "agghhhhgggggggggggggaddddfffdaa..",
        "agghhhhhhhgggggggggggaddddffdaga.",
        "hagghhhhhhhhggggggggggaddddddggga",
        "hhaagghhhhhhhhggggggggggaadagggga",
        "iiiiaagggghhhhhhhhhhhhhggggggggga",
        "iiiiiiaggghhhheehhhhhhhhhhhhhhga.",
        "jjjjjjjagghhhheehhhgghhhhhhhhhhga",
        "jjjjjjjagghhhhhhhhggggghhhhhhhhga",
        "kkkkkkkkagghhhggggaaaaagggghhhhga",
        "kkkkkkkkkaaaaaaaaakkkkkaaaaaaaaa.",
    ]

    static let kirbyBlink = Array(kirby[0..<6]) + [
        "......acccccbcccccccccccccccbb...",
        "......bcccccbcccccccdcccdcccbca..",
        "......acccccbcccccccaaccaaccbcb..",
    ] + Array(kirby[9...])

    /// Ряды радуги за звездой
    static let trail: [Int: Color] = [
        21: hexColor("#ddd702"), 22: hexColor("#ddd702"), 23: hexColor("#4b9c15"), 24: hexColor("#4b9c15"),
        25: hexColor("#026fc5"), 26: hexColor("#026fc5"), 27: hexColor("#6a3175"), 28: hexColor("#6a3175"),
    ]

    static let planet = [
        ".............................ddd.",
        ".............pppppp.......dddrrrr",
        "...........ppwwwwwwpp...dddrrrrrr",
        ".........ppwwwwwwwqwwppddddrrrrrr",
        "........pqwwwwwwwwsqwwwpdd..rrrr.",
        ".......pqwwwwwwwwwwswwlwp...rrrr.",
        "......pqwwwwwwlsswwwlwwwwp..rrrr.",
        "......pwwwqswwlqqslllllwwp.rrrr..",
        ".....pqwwqqswlsqqqqqqqslwwrrrr...",
        ".....pwwwqsllsqqppppppqlwrrrr....",
        "....pqwwwslllqqpqwwqqpqlrrrr.....",
        "....pqwwwllwsqppwwwwqllrrrrp.....",
        "....pqwwwllwsqppqwqqlwrrrrwp.....",
        "....pqwwwllqwlppqqppqrrrrwwp.....",
        "....pqwwwllsqqpppqpprrrrswwp.....",
        "....pqwwwwllsqqpppprrrrwlwwp.....",
        ".....pqwwwwllsqqprrrrrslwwp......",
        ".....pqwwwwllwlsrrrrrqslwwp......",
        "....ddpwwwwwwllrrrrlwlplwp.......",
        "...dddpqwwwwwrrrrrlwwllwwp.......",
        "..ddd..pqwwwrrrrrwwwlwwwp........",
        ".ddd....prrrrrrwwwwwwwwp.........",
        "dddr...rrrrrrwwwwwwwwpp..........",
        "ddrrrrrrrrrppqqqwwwpp............",
        "drrrrrrrrr...pppppp..............",
        "rrrrrrrrr........................",
        "rrrrrr...........................",
    ]

    static let planetPalette: [Character: Color] = [
        "w": hexColor("#facee2"), "l": hexColor("#fbadd0"), "s": hexColor("#f9799f"), "q": hexColor("#f46691"),
        "p": hexColor("#eb4371"), "r": hexColor("#b03f4f"), "d": hexColor("#97323d"),
    ]
    static let ringLight = hexColor("#d4627c")
    static let ringDark = hexColor("#74232e")

    static let planetStars: [[(Int, Int)]] = [
        [(2,4),(3,4),(4,4),(5,3),(5,4),(5,5),(6,0),(6,1),(6,2),(6,3),(6,4),(6,5),(6,6),(6,7),(6,8),(7,3),(7,4),(7,5),(8,4),(9,4),(10,4)],
        [(40,34),(41,33),(41,35),(42,32),(42,34),(42,36),(43,33),(43,35),(44,34)],
        [(2,36),(2,39),(3,37),(3,38),(4,37),(4,38),(5,36),(5,39)],
        [(22,42),(23,40),(23,41),(23,42),(23,43),(23,44),(24,42)],
        [(12,1),(13,0),(13,1),(13,2),(14,1)],
        [(44,6),(45,5),(45,6),(45,7),(46,6)],
        [(3,22),(4,21),(4,23),(5,22)],
        [(32,1)], [(40,1)], [(42,1)], [(44,1)], [(7,15)], [(47,27)], [(42,30)], [(30,34)], [(38,34)],
        [(46,34)], [(16,37)], [(42,38)],
    ]

    /// Звёздочка, как те, что лежат у автомата (16×10)
    static let pickStar = [
        ".......yd.......",
        "......wyyd......",
        ".....wyyydo.....",
        ".wyyyyyyyyyyyw..",
        "wyyyyyyyyyyyyyy.",
        ".dddyyyyyyydooo.",
        "..dyyyyyyyyyoo..",
        "...yyyyodyyyd...",
        "..wyyydoddyyy...",
        "..wydooo..oyw...",
    ]
    static let craneStarPalette: [Character: Color] = [
        "w": hexColor("#fffbe0"), "y": hexColor("#fffbb8"), "d": hexColor("#d8bd6a"), "o": hexColor("#b39547"),
    ]
    static let warpStarPalette: [Character: Color] = [
        "w": hexColor("#fff7a0"), "y": hexColor("#ddd702"), "d": hexColor("#db9a04"), "o": hexColor("#a86400"),
    ]
    static let craneStars: [(CGFloat, CGFloat)] = [(32, 172), (45, 170), (57, 175), (74, 180), (95, 172), (109, 171), (16, 186), (113, 40)]
}

/// Рисует пиксельную картинку в Canvas с левым верхним углом в точке и размером клетки
private func drawSprite(_ c: inout GraphicsContext, _ rows: [String], _ palette: [Character: Color],
                        at origin: CGPoint, cell: CGFloat, opacity: Double = 1) {
    for (y, row) in rows.enumerated() {
        for (x, ch) in row.enumerated() {
            guard let color = palette[ch] else { continue }
            c.fill(Path(CGRect(x: origin.x + CGFloat(x) * cell, y: origin.y + CGFloat(y) * cell,
                               width: cell + 0.2, height: cell + 0.2)),
                   with: .color(color.opacity(opacity)))
        }
    }
}

// MARK: - Всплывающие звёздочки (star_burst из трекера)

struct StarBurst: View {
    let start: Date
    let count: Int
    let palettes: [[Character: Color]]

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30)) { context in
            Canvas { c, size in
                let elapsed = context.date.timeIntervalSince(start) / 0.08
                var rng = SeededRandom(seed: UInt64(start.timeIntervalSinceReferenceDate * 1000) & 0xFFFF)
                for i in 0..<count {
                    let born = Double(i / 2)
                    let dx = (rng.next() - 0.5) * 52, dy = (rng.next() - 0.5) * 12
                    let vx = (rng.next() - 0.5) * 3.6, vy = -2.2 - rng.next() * 2
                    let life = 18 + Double(rng.next()) * 10
                    let scale = [1, 1.5, 1.5, 2][Int(rng.next() * 3.99)]
                    let phase = Double(rng.next()) * .pi * 2
                    let palette = palettes[Int(rng.next() * CGFloat(palettes.count - 1) + 0.5)]
                    let t = elapsed - born
                    guard t >= 0, t < life else { continue }
                    let x = size.width / 2 + dx + vx * CGFloat(t) + CGFloat(sin(t * 0.5 + phase)) * 3
                    let y = size.height / 2 + dy + vy * CGFloat(t)
                    let opacity = t > life - 6 ? (life - t) / 6 : 1
                    drawSprite(&c, ArcadeArt.pickStar, palette, at: CGPoint(x: x - 8 * scale, y: y - 5 * scale),
                               cell: scale, opacity: opacity)
                }
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Кирби на звезде

struct KirbyRider: View {
    @State private var hopStart = Date.distantPast
    @State private var burst: Date?
    var lively = false

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 25)) { context in
            let f = trackerFrame(context.date)
            let hop = context.date.timeIntervalSince(hopStart) / 0.08
            let hopping = hop < 18
            let fast = lively || hopping
            Canvas { c, size in
                let s: CGFloat = 2
                let w = CGFloat(ArcadeArt.kirby[0].count) * s, h = CGFloat(ArcadeArt.kirby.count) * s
                let bob = CGFloat(sin(Double(f) * (fast ? 0.45 : 0.15))) * (fast ? 3 : 2)
                let jump = hopping ? -CGFloat(sin(hop / 18 * .pi)) * 22 : 0
                let left = size.width - w - 8
                let base = size.height - h - 6
                let top = base + bob + jump
                // радуга от левого края до звезды, волна бежит назад
                let trailTop = base + bob
                let speed = fast ? 3 : 1
                var x: CGFloat = 0
                while x < left + 4 {
                    let wave = (CGFloat(sin(Double(x) / 14 + Double(f * speed) * 0.35)) * 4 / s).rounded() * s
                    let lift = (jump * pow(min(1, x / max(left, 1)), 1.6) / s).rounded() * s
                    for (row, color) in ArcadeArt.trail {
                        c.fill(Path(CGRect(x: x, y: trailTop + CGFloat(row) * s + wave + lift, width: min(4, left + 4 - x), height: s)),
                               with: .color(color))
                    }
                    x += 4
                }
                // встречные искры
                for i in 0..<5 {
                    let px = size.width - CGFloat((f * (fast ? 4 : 2) + i * 37) % Int(size.width + 20))
                    let py = CGFloat((i * 53) % Int(max(size.height - 10, 1))) + 5
                    let sp: CGFloat = 2
                    c.fill(Path(CGRect(x: px - sp / 2, y: py - sp * 1.5, width: sp, height: sp * 3)), with: .color(.white.opacity(0.8)))
                    c.fill(Path(CGRect(x: px - sp * 1.5, y: py - sp / 2, width: sp * 3, height: sp)), with: .color(.white.opacity(0.8)))
                }
                let closed = hopping || f % 40 < 2
                drawSprite(&c, closed ? ArcadeArt.kirbyBlink : ArcadeArt.kirby, ArcadeArt.kirbyPalette,
                           at: CGPoint(x: left, y: top), cell: s)
            }
        }
        .overlay {
            if let burst {
                StarBurst(start: burst, count: 10, palettes: [ArcadeArt.warpStarPalette, ArcadeArt.warpStarPalette, ArcadeArt.craneStarPalette])
                    .padding(-90)
                    .id(burst)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            Haptics.tap()
            hopStart = Date()
            burst = Date()
        }
    }
}

// MARK: - Автомат Kirby Crane Fever с клешнёй

struct CraneMachine: View {
    @State private var burst: Date?
    let onTap: () -> Void

    // координаты из трекера: клешня на картинке и середина зубцов
    private let clawAt = CGPoint(x: 61, y: 75)

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 25)) { context in
            let f = trackerFrame(context.date)
            let k = f % 90
            let (drop, grip): (CGFloat, CGFloat) = {
                if k < 20 { return (0, 0) }
                if k < 40 { return (CGFloat(k - 20) * 0.7, 0) }
                if k < 52 { return (14, CGFloat(min(2, (k - 40) / 3))) }
                if k < 72 { return (14 - CGFloat(k - 52) * 0.7, 2) }
                return (0, k < 80 ? 2 : 1)
            }()
            let sway: CGFloat = k < 20 ? CGFloat(sin(Double(f) * 0.15)).rounded() : 0
            ZStack(alignment: .topLeading) {
                Image("pixel_crane").interpolation(.none)
                if drop >= 1 {
                    Rectangle().fill(Color(hex: 0x9A96B8))
                        .frame(width: 2, height: drop.rounded() + 1)
                        .offset(x: clawAt.x + 8, y: clawAt.y)
                }
                // пасхалка: примерно в 1 попытке из 20 клешня вытаскивает табличку «geronimo»
                let attempt = f / 90
                let lucky = (attempt * 7919 + 13) % 20 == 0 || ProcessInfo.processInfo.arguments.contains("-geronimo")
                if lucky && k >= 46 && k < 80 {
                    Text("geronimo")
                        .font(Px.title(5))
                        .foregroundStyle(Px.navy)
                        .padding(.horizontal, 3)
                        .padding(.vertical, 2)
                        .background(Rectangle().fill(Color.white))
                        .overlay(Rectangle().stroke(Px.ink, lineWidth: 1))
                        .rotationEffect(.degrees(k < 72 ? sin(Double(k) * 0.6) * 6 : 0))
                        .fixedSize()
                        .offset(x: clawAt.x + sway - 14, y: clawAt.y + drop.rounded() + 22)
                }
                Group {
                    Image("pixel_claw_head").interpolation(.none)
                    Image("pixel_claw_left").interpolation(.none).offset(x: grip, y: 13)
                    Image("pixel_claw_right").interpolation(.none).offset(x: 9 - grip, y: 13)
                }
                .offset(x: clawAt.x + sway, y: clawAt.y + drop.rounded())
                Canvas { c, _ in
                    for (i, star) in ArcadeArt.craneStars.enumerated() where (f / 3 + i * 5) % 24 < 3 {
                        drawSprite(&c, PxArt.sparkle, ["W": .white], at: CGPoint(x: star.0 - 5, y: star.1 - 2), cell: 2)
                    }
                }
            }
            .frame(width: 130, height: 215, alignment: .topLeading)
        }
        .overlay(alignment: .top) {
            if let burst {
                StarBurst(start: burst, count: 12, palettes: [ArcadeArt.craneStarPalette, ArcadeArt.craneStarPalette, ArcadeArt.warpStarPalette])
                    .padding(-90)
                    .id(burst)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            Haptics.tap()
            burst = Date()
            onTap()
        }
    }
}

// MARK: - Планета с вращающимся кольцом

struct RingPlanet: View {
    var fast = false

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 25)) { context in
            let f = trackerFrame(context.date)
            let k = (fast ? f : f / 2) % 16
            Canvas { c, size in
                let cell = min(size.width / 50, size.height / 45)
                let ox = (size.width - cell * 50) / 2, oy = (size.height - cell * 45) / 2
                // кольцо: светлые и тёмные полосы бегут по кругу
                let center = CGPoint(x: 15.5, y: 13), axis = CGPoint(x: 0.79, y: -0.61)
                let a = 19.6, b = 4.0
                let phase = Double(k) / 16 * 2 * .pi
                for (y, row) in ArcadeArt.planet.enumerated() {
                    for (x, ch) in row.enumerated() {
                        guard var color = ArcadeArt.planetPalette[ch] else { continue }
                        if ch == "r" || ch == "d" {
                            let dx = Double(x) - center.x, dy = Double(y) - center.y
                            let t = atan2((dx * -axis.y + dy * axis.x) / b, (dx * axis.x + dy * axis.y) / a)
                            let band = sin(3 * t - phase)
                            if band > 0.55 {
                                color = ch == "d" ? ArcadeArt.planetPalette["r"]! : ArcadeArt.ringLight
                            } else if band < -0.55 {
                                color = ch == "r" ? ArcadeArt.planetPalette["d"]! : ArcadeArt.ringDark
                            }
                        }
                        c.fill(Path(CGRect(x: ox + CGFloat(x + 9) * cell, y: oy + CGFloat(y + 6) * cell,
                                           width: cell + 0.2, height: cell + 0.2)), with: .color(color))
                    }
                }
                // мерцающие звёзды
                for (i, star) in ArcadeArt.planetStars.enumerated() {
                    let phaseStar = (f / 3 + i * 7) % 20
                    guard phaseStar < 16 else { continue }
                    var cells = star
                    if phaseStar >= 13, cells.count > 4 {
                        cells = [cells[cells.count / 2]]
                    }
                    for (x, y) in cells {
                        c.fill(Path(CGRect(x: ox + CGFloat(x) * cell, y: oy + CGFloat(y) * cell, width: cell, height: cell)),
                               with: .color(ArcadeArt.planetPalette["w"]!))
                    }
                }
            }
        }
    }
}

// MARK: - «Готово»: диск Kirby Air Ride (30 кадров по 100 мс)

struct DoneKirbyDisc: View {
    let start: Date

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 20)) { context in
            let i = Int(context.date.timeIntervalSince(start) / 0.1) % 30
            Image("pixel_done_\(i)").interpolation(.none)
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Луна из «Сейлор Мун»: хвост покачивается, моргает, полумесяц блестит

struct LunaCat: View {
    @EnvironmentObject private var store: ShopStore
    @State private var meow: Date?

    var body: some View {
        TimelineView(.animation) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            // моргание: раз в ~4 с, иногда двойное
            let cycle = t.truncatingRemainder(dividingBy: 4.3)
            let blink = cycle < 0.14 || (Int(t / 4.3) % 3 == 0 && cycle > 0.3 && cycle < 0.42)
            let talk = context.date.timeIntervalSince(store.assistantTalking)
            let hop: CGFloat = talk < 0.4 ? -CGFloat(sin(talk / 0.4 * .pi)) * 8 : 0
            let glint = (sin(t * 2.4) + 1) / 2
            ZStack(alignment: .topLeading) {
                LunaTail(t: t)
                Image("luna_body").interpolation(.none)
                    .scaleEffect(x: 1, y: 1 + CGFloat(sin(t * 2.2)) * 0.008, anchor: .bottom)
                if blink {
                    Image("luna_lids").interpolation(.none)
                }
                // блик на полумесяце
                Canvas { c, _ in
                    let s: CGFloat = 1
                    let p = CGPoint(x: 55, y: 15)
                    let color = Color.white.opacity(glint)
                    c.fill(Path(CGRect(x: p.x, y: p.y - 2 * s, width: s, height: 5 * s)), with: .color(color))
                    c.fill(Path(CGRect(x: p.x - 2 * s, y: p.y, width: 5 * s, height: s)), with: .color(color))
                }
            }
            .frame(width: 91, height: 92, alignment: .topLeading)
            .offset(y: hop)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            store.assistantPing += 1
        }
    }
}

/// Хвост Луны: гибкий, изгибается волной от основания к кончику; рисуется по пиксельной сетке
struct LunaTail: View {
    let t: Double

    /// Осевая линия хвоста в пикселях спрайта 91×92: от основания у тела до загнутого кончика
    private static let spine: [CGPoint] = [
        CGPoint(x: 31, y: 79), CGPoint(x: 27, y: 80), CGPoint(x: 22, y: 79.5), CGPoint(x: 18.5, y: 77.5),
        CGPoint(x: 16.3, y: 73.5), CGPoint(x: 15.6, y: 68), CGPoint(x: 16, y: 62), CGPoint(x: 16.6, y: 56),
        CGPoint(x: 17.5, y: 50), CGPoint(x: 18.5, y: 44), CGPoint(x: 19.6, y: 38), CGPoint(x: 20.6, y: 32),
        CGPoint(x: 21, y: 27), CGPoint(x: 19.5, y: 22.5), CGPoint(x: 15.5, y: 20.8), CGPoint(x: 11.5, y: 21.3),
        CGPoint(x: 8.5, y: 23), CGPoint(x: 7.5, y: 25.5),
    ]
    private static let color = Color(hex: 0x212163)

    var body: some View {
        Canvas { c, _ in
            let pts = bentSpine()
            // все клетки собираются в один контур и заливаются разом — дёшево даже на 60 кадрах
            var cells = Set<Int>()
            // толщина: у основания 5 px, к кончику 3.5 px
            for i in 0..<(pts.count - 1) {
                let a = pts[i], b = pts[i + 1]
                let steps = max(Int(hypot(b.x - a.x, b.y - a.y) * 1.5), 1)
                for k in 0...steps {
                    let f = CGFloat(k) / CGFloat(steps)
                    let p = CGPoint(x: a.x + (b.x - a.x) * f, y: a.y + (b.y - a.y) * f)
                    let along = (CGFloat(i) + f) / CGFloat(pts.count - 1)
                    let r = 2.5 - along * 0.8
                    // заливка по клеткам 1 px — хвост остаётся пиксельным
                    let x0 = Int((p.x - r).rounded()), x1 = Int((p.x + r).rounded()) - 1
                    let y0 = Int((p.y - r).rounded()), y1 = Int((p.y + r).rounded()) - 1
                    guard x1 >= x0, y1 >= y0 else { continue }
                    for x in x0...x1 { for y in y0...y1 {
                        let dx = CGFloat(x) + 0.5 - p.x, dy = CGFloat(y) + 0.5 - p.y
                        if dx * dx + dy * dy <= r * r + 0.4 { cells.insert(y * 128 + x) }
                    } }
                }
            }
            var path = Path()
            for cell in cells {
                path.addRect(CGRect(x: cell % 128, y: cell / 128, width: 1, height: 1))
            }
            c.fill(path, with: .color(Self.color))
        }
        .frame(width: 91, height: 92)
    }

    /// Каждый сустав поворачивает остаток хвоста: волна бежит от основания к кончику, кончик гнётся сильнее
    private func bentSpine() -> [CGPoint] {
        let src = Self.spine
        let n = src.count
        // редкий резкий взмах раз в 7 с
        let cycle = t.truncatingRemainder(dividingBy: 7)
        let flick = cycle < 0.9 ? sin(cycle / 0.9 * .pi) : 0
        var out = [src[0]]
        var angle: Double = 0
        for i in 1..<n {
            let f = Double(i) / Double(n - 1)
            // плавная бегущая волна + общий наклон
            angle += (sin(t * 1.9 - f * 3.2) * 0.055 + flick * 0.05) * f
            let prevSrc = src[i - 1], curSrc = src[i]
            let dx = curSrc.x - prevSrc.x, dy = curSrc.y - prevSrc.y
            let ca = CGFloat(cos(angle)), sa = CGFloat(sin(angle))
            let last = out[i - 1]
            out.append(CGPoint(x: last.x + dx * ca - dy * sa, y: last.y + dx * sa + dy * ca))
        }
        return out
    }
}
