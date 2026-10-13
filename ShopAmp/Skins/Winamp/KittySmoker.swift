import SwiftUI

/// Hello Kitty с сигаретой (картинка пользователя) — помощник скина Winamp.
/// Поверх картинки: моргание, тлеющий огонёк при затяжке, струйка и клубы дыма, лёгкое «дыхание».
struct KittySmoker: View {
    @EnvironmentObject private var store: ShopStore

    // Точки на картинке в долях её размера
    private let leftEye = CGRect(x: 0.285, y: 0.415, width: 0.06, height: 0.065)
    private let rightEye = CGRect(x: 0.635, y: 0.415, width: 0.06, height: 0.065)
    private let tip = CGPoint(x: 0.262, y: 0.688)

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 24)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let cycle = t.truncatingRemainder(dividingBy: 5)
            let inhale = cycle < 1.2 ? sin(cycle / 1.2 * .pi) : 0
            let blink = t.truncatingRemainder(dividingBy: 3.7) < 0.16
            let talk = context.date.timeIntervalSince(store.assistantTalking)
            let hop: CGFloat = talk < 0.4 ? -CGFloat(sin(talk / 0.4 * .pi)) * 6 : 0
            GeometryReader { g in
                let w = g.size.width, h = g.size.height
                ZStack(alignment: .topLeading) {
                    Image("winamp_kitty")
                        .resizable()
                        .interpolation(.high)
                        .frame(width: w, height: h)
                        .scaleEffect(x: 1, y: 1 + CGFloat(sin(t * 1.6)) * 0.012, anchor: .bottom)
                    Canvas { c, size in
                        // моргание: белое веко и чёрная чёрточка поверх глаз
                        if blink {
                            for eye in [leftEye, rightEye] {
                                let r = CGRect(x: eye.minX * w, y: eye.minY * h, width: eye.width * w, height: eye.height * h)
                                c.fill(Path(r.insetBy(dx: -1, dy: -1)), with: .color(.white))
                                c.fill(Path(CGRect(x: r.minX, y: r.midY, width: r.width, height: max(2, h * 0.015))), with: .color(.black))
                            }
                        }
                        // огонёк: разгорается при затяжке
                        let tp = CGPoint(x: tip.x * w, y: tip.y * h)
                        let glow = 0.25 + 0.75 * inhale
                        c.fill(Path(ellipseIn: CGRect(x: tp.x - w * 0.06, y: tp.y - h * 0.05, width: w * 0.12, height: h * 0.1)),
                               with: .radialGradient(Gradient(colors: [Color.orange.opacity(0.7 * glow), .clear]),
                                                     center: tp, startRadius: 0, endRadius: w * 0.06))
                        let s = w * 0.035
                        c.fill(Path(CGRect(x: tp.x - s / 2, y: tp.y - s / 2, width: s, height: s)),
                               with: .color(Color(red: 1, green: 0.25 + 0.6 * inhale, blue: 0.1)))
                        // струйка дыма — пиксельные клубы вверх
                        for i in 0..<9 {
                            let life = 2.8
                            let p = ((t * 0.9 + Double(i) * life / 9).truncatingRemainder(dividingBy: life)) / life
                            let x = tp.x - CGFloat(p) * w * 0.08 + CGFloat(sin(t * 2 + Double(i))) * w * 0.03
                            let y = tp.y - CGFloat(p) * h * 0.55
                            let sq = w * (0.02 + CGFloat(p) * 0.06)
                            c.fill(Path(CGRect(x: x - sq / 2, y: y - sq / 2, width: sq, height: sq)),
                                   with: .color(Color(hex: 0xEEF0F8).opacity((1 - p) * 0.6)))
                        }
                        // выдох после затяжки
                        if cycle > 1.2 && cycle < 3.4 {
                            let p = (cycle - 1.2) / 2.2
                            for k in 0..<6 {
                                let a = Double(k) * 1.1
                                let x = w * 0.42 - CGFloat(p) * w * 0.25 + CGFloat(cos(a)) * w * 0.05
                                let y = h * 0.6 - CGFloat(p) * h * 0.3 + CGFloat(sin(a)) * h * 0.035
                                let sz = w * (0.05 + CGFloat(p) * 0.08)
                                c.fill(Path(CGRect(x: x - sz / 2, y: y - sz / 2, width: sz, height: sz)),
                                       with: .color(Color.white.opacity((1 - p) * 0.55)))
                            }
                        }
                    }
                    .frame(width: w, height: h)
                    .allowsHitTesting(false)
                }
                .offset(y: hop)
            }
        }
    }
}
