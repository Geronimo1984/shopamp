import SwiftUI

/// Главное окно «плеера». Координаты — в пикселях скина 1200×700: верх как в оригинале,
/// а кнопки управления увеличены и разложены в два ряда, чтобы по ним было удобно попадать пальцем.
struct MainWindow: View {
    @EnvironmentObject var store: ShopStore
    @State private var balance = 0.5

    private var playing: Bool { store.leftCount > 0 }

    var body: some View {
        ZStack(alignment: .topLeading) {
            WindowBody()

            TitleBar(title: "WINAMP", buttons: [.help, .minimize, .shade, .close],
                     onIcon: { store.isChoosingSkin = true }, onHelp: { store.showHelp = true },
                     onIconLong: {
                         store.marqueeEasterUntil = Date().addingTimeInterval(14)
                         DispatchQueue.main.asyncAfter(deadline: .now() + 14.1) { store.marqueeEasterUntil = .distantPast }
                     })
                .place(0, 0, 1200, 58)

            lcdPanel
                .place(45, 92, 412, 192, anchor: "lcd")

            LCDBox {
                Marquee(text: store.marqueeText, maxChars: 24, size: 44)
                    .padding(.leading, 18)
            }
            .place(470, 96, 695, 72, anchor: "marquee")

            infoRow

            HSkinSlider(
                value: Double((store.selectedItem?.qty ?? 1) - 1) / 9,
                track: [Color(hex: 0xF57B45), Color(hex: 0xE24A1E), Color(hex: 0xA8300F)],
                thumbWidth: 90
            ) { v in
                store.setQty(store.selectedID, 1 + Int((v * 9).rounded()))
            }
            .place(470, 266, 470, 64, anchor: "qty")

            HSkinSlider(
                value: balance,
                track: [Color(hex: 0x5BE05B), Color(hex: 0x2EA82E), Color(hex: 0x167016)]
            ) { v in
                balance = v
            } onEnd: {
                withAnimation(.spring(response: 0.3)) { balance = 0.5 }
            }
            .place(955, 266, 200, 64)

            seekBar
                .place(45, 350, 1110, 46)

            transport

        }
        .frame(width: 1200, height: 840)
    }

    // MARK: Табло

    private var lcdPanel: some View {
        ZStack(alignment: .topLeading) {
            LCDBox { Color.clear }

            VStack(spacing: 6) {
                ForEach(Array("OAIDV".enumerated()), id: \.offset) { item in
                    Text(String(item.element))
                        .font(.system(size: 22, weight: .heavy, design: .monospaced))
                        .foregroundStyle(item.element == "D" ? Winamp.labelDim : Winamp.clutter)
                }
            }
            .place(8, 14, 26, 168)

            VStack(spacing: 6) {
                Rectangle().fill(playing ? Winamp.green : Winamp.greenDim).frame(width: 14, height: 14)
                Rectangle().fill(Color(hex: playing ? 0x5A1410 : 0xD8301E)).frame(width: 14, height: 10)
            }
            .place(48, 26, 16, 34)

            playStateGlyph
                .place(76, 24, 32, 42)

            LCDDigits(
                minus: store.showRemaining,
                left: store.showRemaining ? store.leftCount : store.boughtCount,
                right: store.totalCount
            )
            .frame(width: 268, height: 66)
            .pressable(.winamp) {
                Haptics.tap()
                store.showRemaining.toggle()
            }
            .place(132, 16, 268, 66)

            Visualizer(playing: playing)
                .place(42, 96, 358, 84)
        }
    }

    @ViewBuilder
    private var playStateGlyph: some View {
        if store.totalCount == 0 {
            TransportGlyph(kind: .stop).fill(Winamp.green).padding(6)
        } else if playing {
            TransportGlyph(kind: .play).fill(Winamp.green)
                .shadow(color: Winamp.green.opacity(0.6), radius: 3)
        } else {
            TransportGlyph(kind: .pause).fill(Winamp.green).padding(4)
        }
    }

    // MARK: Строка «320 kbps 44 kHz mono stereo»

    private var infoRow: some View {
        ZStack(alignment: .topLeading) {
            LCDBox(alignment: .trailing) {
                lcdNumber(store.leftCount).padding(.trailing, 10)
            }
            .place(470, 182, 96, 62)
            skinLabel("шт.", 38, Winamp.label)
                .place(578, 182, 90, 62)

            LCDBox(alignment: .trailing) {
                lcdNumber(store.dueSuggestions.count).padding(.trailing, 10)
            }
            .place(680, 182, 80, 62)
            skinLabel("снова", 38, Winamp.label)
                .place(770, 182, 150, 62)

            HStack(spacing: 10) {
                skinLabel("ручн", 36, store.state.autoSuggest ? Winamp.labelDim : Winamp.green)
                skinLabel("авто", 36, store.state.autoSuggest ? Winamp.green : Winamp.labelDim)
                    .shadow(color: store.state.autoSuggest ? Winamp.green.opacity(0.6) : .clear, radius: 4)
            }
            .frame(width: 240, height: 62)
            .pressable(.winamp) {
                Haptics.tap()
                store.toggle(\.autoSuggest)
            }
            .place(925, 182, 240, 62)
        }
    }

    private func lcdNumber(_ n: Int) -> some View {
        Text("\(min(n, 999))")
            .font(.system(size: 42, weight: .bold, design: .monospaced))
            .foregroundStyle(Winamp.green)
    }

    private func skinLabel(_ text: String, _ size: CGFloat, _ color: Color) -> some View {
        Text(text)
            .font(.system(size: size, weight: .heavy, design: .monospaced))
            .foregroundStyle(color)
            .shadow(color: .black.opacity(0.7), radius: 0, x: 2, y: 2)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Полоса прогресса

    private var seekBar: some View {
        GeometryReader { g in
            let thumb: CGFloat = 122
            let progress = store.totalCount == 0 ? 0 : CGFloat(store.boughtCount) / CGFloat(store.totalCount)
            ZStack(alignment: .leading) {
                Rectangle().fill(Color(hex: 0x15183F))
                Rectangle().strokeBorder(Winamp.frameDark, lineWidth: 4)
                Rectangle()
                    .strokeBorder(Winamp.frameLight.opacity(0.4), lineWidth: 2)
                    .padding(-2)
                ZStack {
                    Bevel(edge: 3, top: Winamp.goldTop, bottom: Winamp.goldBottom)
                    Rectangle()
                        .strokeBorder(Color(hex: 0x6E5A22), lineWidth: 3)
                        .padding(12)
                }
                .frame(width: thumb, height: g.size.height - 4)
                .offset(x: (g.size.width - thumb) * progress)
                .animation(.easeInOut(duration: 0.25), value: progress)
            }
        }
    }

    // MARK: Кнопки управления

    private var transport: some View {
        ZStack(alignment: .topLeading) {
            transportButton(.prev, index: 0) { store.selectPrev() }
            transportButton(.play, index: 1) {
                if let item = store.selectedItem { store.notify("▶ Куплено: \(item.name)") }
                store.setBought(store.selectedID, true)
                store.selectNext()
            }
            transportButton(.pause, index: 2) {
                if let item = store.selectedItem { store.notify("❚❚ Снята отметка: \(item.name)") }
                store.setBought(store.selectedID, false)
            }
            transportButton(.stop, index: 3) {
                store.finishShopping()
            }
            transportButton(.next, index: 4) { store.selectNext() }
            transportButton(.eject, index: 5) { store.isAdding = true }

            // второй ряд: переключатели
            SkinButton {
                store.toggle(\.sortBought)
                store.notify(store.state.sortBought ? "SHUFFLE: купленное — в конец списка" : "SHUFFLE выкл: порядок как добавляли")
            } label: {
                bigLed(store.state.sortBought) { skinText("SHUFFLE", 42) }
            }
            .place(36, 556, 250, 124, anchor: "shuffle")

            SkinButton {
                store.addDue()
            } label: {
                bigLed(!store.dueSuggestions.isEmpty) {
                    Image(systemName: "repeat")
                        .font(.system(size: 44, weight: .black))
                        .foregroundStyle(Winamp.ink)
                }
            }
            .place(296, 556, 190, 124, anchor: "again")

            SkinButton {
                store.toggle(\.showEqualizer)
            } label: {
                bigLed(store.state.showEqualizer) { skinText("EQ", 46) }
            }
            .place(496, 556, 190, 124, anchor: "eq")

            SkinButton {
                store.toggle(\.showPlaylist)
            } label: {
                bigLed(store.state.showPlaylist) { skinText("PL", 46) }
            }
            .place(696, 556, 190, 124, anchor: "pl")

            // подсказка-бегущая строка про Kitty
            LCDBox(alignment: .leading) {
                Marquee(text: "НАЖМИ НА KITTY — ОНА ПОДСКАЖЕТ, ЧТО ДЕЛАЕТ КАЖДАЯ КНОПКА ***", maxChars: 26, size: 38)
                    .padding(.leading, 16)
            }
            .place(36, 700, 850, 104)

            // Hello Kitty — помощник скина
            KittySmoker()
                .clipShape(Rectangle())
                .overlay(Rectangle().strokeBorder(Winamp.frameDark, lineWidth: 6))
                .overlay(Rectangle().strokeBorder(Winamp.frameLight.opacity(0.5), lineWidth: 2).padding(6))
                .contentShape(Rectangle())
                .pressable(.winamp) { store.assistantPing += 1 }
                .place(904, 556, 260, 260, anchor: "kitty")
        }
    }

    private func bigLed<Content: View>(_ on: Bool, @ViewBuilder content: () -> Content) -> some View {
        LedLabel(on: on, ledSize: CGSize(width: 26, height: 17), inset: 14, content: content)
    }

    /// Шесть кнопок на всю ширину окна: ~180×130 px скина ≈ 60×43 pt на iPhone
    private func transportButton(_ kind: TransportGlyph.Kind, index: Int,
                                 action: @escaping () -> Void) -> some View {
        SkinButton(edge: 4, action: action) {
            TransportGlyph(kind: kind)
                .skinGlyph(line: 5)
                .frame(width: kind == .stop ? 50 : 60, height: kind == .stop ? 50 : 56)
        }
        .place(36 + CGFloat(index) * 188, 410, 180, 130, anchor: ["prev", "play", "pause", "stop", "next", "eject"][index])
    }
}

func skinText(_ text: String, _ size: CGFloat) -> some View {
    Text(text)
        .font(.system(size: size, weight: .black, design: .monospaced))
        .foregroundStyle(Winamp.ink)
        .lineLimit(1)
        .minimumScaleFactor(0.5)
}
