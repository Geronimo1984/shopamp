import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// Кадры Скрепыша (оригинальный лист clippy_map + clippy_anims.json) и общие формы облачка помощника.

// MARK: - Кадры анимации

final class ClippySprites {
    static let shared = ClippySprites()

    let frameSize = CGSize(width: 124, height: 93)
    /// Анимация → [(длительность мс, левый верхний угол кадра на листе)]
    private(set) var animations: [String: [(Int, CGPoint)]] = [:]
    private var sheet: CGImage?
    private var cache: [CGPoint: CGImage] = [:]

    private init() {
        #if canImport(UIKit)
        sheet = UIImage(named: "clippy_map")?.cgImage
        #endif
        guard let url = Bundle.main.url(forResource: "clippy_anims", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let anims = json["animations"] as? [String: [[Any]]] else { return }
        for (name, frames) in anims {
            var last = CGPoint.zero
            animations[name] = frames.map { frame in
                let duration = frame[0] as? Int ?? 100
                if let xy = frame[1] as? [Int], xy.count == 2 {
                    last = CGPoint(x: xy[0], y: xy[1])
                }
                return (duration, last)
            }
        }
    }

    func image(at origin: CGPoint) -> CGImage? {
        if let cached = cache[origin] { return cached }
        let rect = CGRect(origin: origin, size: frameSize)
        guard let img = sheet?.cropping(to: rect) else { return nil }
        cache[origin] = img
        return img
    }

    func duration(of name: String) -> Double {
        Double(animations[name]?.reduce(0) { $0 + $1.0 } ?? 0) / 1000
    }

    /// Кадр анимации в момент `elapsed`; после конца — последний кадр
    func origin(_ name: String, elapsed: Double) -> CGPoint {
        guard let frames = animations[name], !frames.isEmpty else { return .zero }
        var t = Int(elapsed * 1000)
        for frame in frames {
            if t < frame.0 { return frame.1 }
            t -= frame.0
        }
        return frames.last!.1
    }
}

extension CGPoint: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(x)
        hasher.combine(y)
    }
}

struct ClippyView: View {
    let animation: String
    let start: Date

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30)) { context in
            let origin = ClippySprites.shared.origin(animation, elapsed: context.date.timeIntervalSince(start))
            if let img = ClippySprites.shared.image(at: origin) {
                Image(decorative: img, scale: 1)
                    .resizable()
                    .interpolation(.high)
            } else {
                Color.clear
            }
        }
        .aspectRatio(124 / 93, contentMode: .fit)
    }
}

struct Triangle: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.midX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}

/// Скруглённое облачко с хвостиком вниз в точке tailX
struct BalloonShape: Shape {
    var tailX: CGFloat
    var tailUp = false

    func path(in r: CGRect) -> Path {
        if tailUp {
            // то же облачко, отражённое по вертикали: хвостик сверху
            let flipped = BalloonShape(tailX: tailX).path(in: CGRect(x: r.minX, y: r.minY, width: r.width, height: r.height))
            return flipped.applying(CGAffineTransform(translationX: 0, y: r.minY + r.maxY).scaledBy(x: 1, y: -1))
        }
        let radius: CGFloat = 10
        let tx = min(max(tailX, r.minX + 24), r.maxX - 24)
        var p = Path()
        p.move(to: CGPoint(x: r.minX + radius, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX - radius, y: r.minY))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.minY + radius), control: CGPoint(x: r.maxX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY - radius))
        p.addQuadCurve(to: CGPoint(x: r.maxX - radius, y: r.maxY), control: CGPoint(x: r.maxX, y: r.maxY))
        p.addLine(to: CGPoint(x: tx + 8, y: r.maxY))
        p.addLine(to: CGPoint(x: tx, y: r.maxY + 14))
        p.addLine(to: CGPoint(x: tx - 4, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX + radius, y: r.maxY))
        p.addQuadCurve(to: CGPoint(x: r.minX, y: r.maxY - radius), control: CGPoint(x: r.minX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.minY + radius))
        p.addQuadCurve(to: CGPoint(x: r.minX + radius, y: r.minY), control: CGPoint(x: r.minX, y: r.minY))
        p.closeSubpath()
        return p
    }
}

/// «Бегущие муравьи» — пунктирная рамка выделения
struct MarchingAnts: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 15)) { context in
            let phase = CGFloat(context.date.timeIntervalSinceReferenceDate * 16).truncatingRemainder(dividingBy: 8)
            ZStack {
                Rectangle().stroke(Mac.paper, lineWidth: 3)
                Rectangle().stroke(Mac.ink, style: StrokeStyle(lineWidth: 3, dash: [4, 4], dashPhase: phase))
            }
        }
    }
}
