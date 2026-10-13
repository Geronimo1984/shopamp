import SwiftUI

/// Окно эквалайзера — «память» покупок.
/// Каждый ползунок — регулярный товар: чем выше, тем сильнее «пора купить».
struct EqualizerWindow: View {
    @EnvironmentObject var store: ShopStore

    private let sliderTop: CGFloat = 158
    private let sliderHeight: CGFloat = 196

    var body: some View {
        let regulars = store.regulars
        ZStack(alignment: .topLeading) {
            WindowBody()

            TitleBar(title: "WINAMP EQUALIZER", showIcon: false, buttons: [.shade, .close]) {
                store.state.showEqualizer = false
            }
            .place(0, 0, 1200, 42)

            SkinButton {
                store.toggle(\.autoSuggest)
            } label: {
                LedLabel(on: store.state.autoSuggest, ledSize: CGSize(width: 22, height: 15), inset: 12) { skinText("ON", 36) }
            }
            .place(30, 56, 150, 84)

            SkinButton {
                store.toggle(\.autoAdd)
            } label: {
                LedLabel(on: store.state.autoAdd, ledSize: CGSize(width: 22, height: 15), inset: 12) { skinText("AUTO", 36) }
            }
            .place(190, 56, 190, 84)

            graph(regulars)
                .place(395, 56, 400, 84)

            SkinButton {
                store.isEditingMemory = true
            } label: {
                skinText("PRESETS", 36)
            }
            .place(810, 56, 360, 84, anchor: "presets")

            EQSlider(ratio: 0.5, active: false)
                .place(44, sliderTop, 56, sliderHeight)
            Text("PREAMP")
                .font(.system(size: 26, weight: .heavy, design: .monospaced))
                .foregroundStyle(Winamp.label)
                .place(10, sliderTop + sliderHeight + 8, 124, 40)

            VStack(alignment: .leading) {
                Text("ПОРА")
                Spacer()
                Text("НОРМ")
                Spacer()
                Text("РАНО")
            }
            .font(.system(size: 26, weight: .heavy, design: .monospaced))
            .foregroundStyle(Winamp.label)
            .place(118, sliderTop - 4, 90, sliderHeight + 8)

            ForEach(0..<10, id: \.self) { i in
                let x = 228 + CGFloat(i) * 94
                let memory = i < regulars.count ? regulars[i] : nil
                // кнопка до .place: иначе её зона нажатия растягивается на всё окно и перекрывает PRESETS
                EQSlider(ratio: memory?.dueRatio() ?? 0, active: memory != nil)
                    .frame(width: 56, height: sliderHeight)
                    .pressable(.winamp) {
                        if let memory {
                            Haptics.tap()
                            store.add(memory.name)
                        }
                    }
                    .place(x, sliderTop, 56, sliderHeight)
                Text(memory.map { String($0.name.uppercased().prefix(4)) } ?? "--")
                    .font(.system(size: 30, weight: .heavy, design: .monospaced))
                    .foregroundStyle(Winamp.label)
                    .lineLimit(1)
                    .place(x - 22, sliderTop + sliderHeight + 8, 100, 40)
            }
        }
        .frame(width: 1200, height: 430)
    }

    private func graph(_ regulars: [ItemMemory]) -> some View {
        LCDBox(alignment: .center, line: 3) {
            if regulars.isEmpty {
                Text("КУПИТЕ ТОВАР 2 РАЗА")
                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                    .foregroundStyle(Winamp.greenDim)
            } else {
                Canvas { c, size in
                    var mid = Path()
                    mid.move(to: CGPoint(x: 0, y: size.height / 2))
                    mid.addLine(to: CGPoint(x: size.width, y: size.height / 2))
                    c.stroke(mid, with: .color(Winamp.lcdDot), style: StrokeStyle(lineWidth: 2, dash: [3, 5]))

                    var line = Path()
                    for i in 0..<10 {
                        let ratio = i < regulars.count ? (regulars[i].dueRatio() ?? 0) : 0
                        let value = min(max(ratio / 1.2, 0), 1)
                        let point = CGPoint(x: 10 + CGFloat(i) * (size.width - 20) / 9,
                                            y: size.height - 6 - CGFloat(value) * (size.height - 12))
                        if i == 0 { line.move(to: point) } else { line.addLine(to: point) }
                    }
                    c.stroke(line,
                             with: .linearGradient(Gradient(colors: [Color(hex: 0xEF3B1E), Color(hex: 0xF0C42A), Winamp.green]),
                                                   startPoint: .zero, endPoint: CGPoint(x: 0, y: size.height)),
                             lineWidth: 3)
                }
                .padding(4)
            }
        }
    }
}

/// Вертикальный ползунок эквалайзера
struct EQSlider: View {
    let ratio: Double
    let active: Bool

    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            let thumbH: CGFloat = 26
            let value = CGFloat(min(max(ratio / 1.2, 0), 1))
            let y = (h - thumbH) * (1 - value)
            ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(hex: 0x111433))
                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(Winamp.frameDark, lineWidth: 3))
                    .frame(width: 16)
                if active {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(LinearGradient(colors: [Color(hex: 0xEF3B1E), Color(hex: 0xF0C42A), Color(hex: 0x2EC22E)],
                                             startPoint: .top, endPoint: .bottom))
                        .frame(width: 10, height: max(h - y - thumbH / 2, 0))
                        .offset(y: y + thumbH / 2)
                }
                Bevel(edge: 3)
                    .overlay(
                        Rectangle().fill(Winamp.ink).frame(width: w * 0.5, height: 3)
                    )
                    .frame(width: w * 0.8, height: thumbH)
                    .offset(y: y)
                    .opacity(active ? 1 : 0.55)
            }
            .frame(width: w, height: h, alignment: .top)
        }
    }
}
