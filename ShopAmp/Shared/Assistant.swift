import SwiftUI

// Помощник в каждом скине: Скрепыш (Mac), Луна (Pixel Moon), пламбоб (Sims), человечек MSN (Aero).
// Нажатие на персонажа — облачко с фактом из справки, нужная кнопка обводится «бегущими муравьями».

// MARK: - Якоря кнопок

struct AssistAnchorKey: PreferenceKey {
    static var defaultValue: [String: Anchor<CGRect>] = [:]

    static func reduce(value: inout [String: Anchor<CGRect>], nextValue: () -> [String: Anchor<CGRect>]) {
        value.merge(nextValue()) { $1 }
    }
}

extension View {
    /// Помечает элемент, на который помощник может показать
    func assistAnchor(_ id: String, when condition: Bool = true) -> some View {
        // transform, а не anchorPreference: вложенные якоря (чекбокс внутри строки) не затираются внешними
        transformAnchorPreference(key: AssistAnchorKey.self, value: .bounds) { value, anchor in
            if condition { value[id] = anchor }
        }
            // метка для ScrollViewReader: к элементу можно прокрутить страницу
            .background { if condition { Color.clear.id("assist-" + id) } }
    }

    /// Прокрутка страницы к элементу, о котором рассказывает помощник
    func scrollsToAssistTarget(_ proxy: ScrollViewProxy, _ target: String?) -> some View {
        onChange(of: target) { id in
            guard let id else { return }
            withAnimation(.easeInOut(duration: 0.35)) { proxy.scrollTo("assist-" + id, anchor: .center) }
        }
    }
}

// MARK: - Подсказки

struct AssistantTip {
    let target: String?
    let text: String
}

enum AssistantTips {
    static func tips(for skin: SkinID) -> [AssistantTip] {
        switch skin {
        case .mac:
            return [
                AssistantTip(target: nil, text: "Похоже, вы составляете список покупок. Хотите, покажу, что здесь к чему?"),
                AssistantTip(target: "add", text: "«Добавить» открывает карточки товаров: отметьте, что взять. Новую карточку можно завести там же."),
                AssistantTip(target: "again", text: "«Купить снова» добавляет всё, что по расчёту уже заканчивается."),
                AssistantTip(target: "checkbox", text: "Поставьте крестик — и товар куплен."),
                AssistantTip(target: "list", text: "Нажмите на товар, а потом ещё раз — откроется его карточка: название, количество, «Удалить»."),
                AssistantTip(target: "folders", text: "Треугольник сворачивает папку: «Купить», «В корзине», «Купить снова»."),
                AssistantTip(target: "qty", text: "Ползунок «Кол-во» меняет количество выбранного товара."),
                AssistantTip(target: "controlPanel", text: "Здесь включаются подсказки и порядок: купленное остаётся на месте или уходит в конец."),
                AssistantTip(target: "edit", text: "«Изменить» открывает карточку выбранного товара."),
                AssistantTip(target: "done", text: "«Готово» — закончить покупки. Купленное останется в списке зачёркнутым."),
                AssistantTip(target: "menu", text: "«Меню» — все действия: настроить «Купить снова», сменить скин, очистить список."),
                AssistantTip(target: "cards", text: "Папка «Карточки» — каталог всех товаров. Отметьте, что взять в этот поход."),
                AssistantTip(target: "help", text: "«Справка» — все подсказки сразу."),
                AssistantTip(target: "power", text: "Эта кнопка на корпусе меняет скин."),
                AssistantTip(target: nil, text: "Это всё. Кстати, меня тоже накодил geronimo, и он до сих пор боится, что я заговорю первым."),
            ]
        case .pixel:
            return [
                AssistantTip(target: nil, text: "Мяу! Я Луна. Нажимай на меня — расскажу, как тут всё устроено ✦"),
                AssistantTip(target: "add", text: "«Добавить» — открою все карточки, отметь, что положить в рюкзак-список. Новую карточку — там же."),
                AssistantTip(target: "edit", text: "«Изменить» открывает карточку выбранного предмета: название, количество, удалить."),
                AssistantTip(target: "crane", text: "Нажми на автомат — клешня достанет всё, что пора купить снова."),
                AssistantTip(target: "again", text: "«Карточки» — все твои товары. Отметь, что взять в поход, и задай сроки — тогда я напомню вовремя."),
                AssistantTip(target: "tabs", text: "Вкладки: все предметы, что купить, что уже в корзине и что пора купить снова."),
                AssistantTip(target: "inventory", text: "Нажми на ячейку — выберешь предмет. Ещё раз — карточка. Двойное нажатие — в рюкзак, то есть куплено."),
                AssistantTip(target: "backpack", text: "«В рюкзак» отмечает выбранный предмет купленным. − и + меняют количество."),
                AssistantTip(target: "planet", text: "Планета и Кирби — для настроения. Попробуй нажать на них!"),
                AssistantTip(target: "level", text: "HP — сколько куплено, MP — сколько купить снова, EXP — все твои покупки."),
                AssistantTip(target: "skin", text: "«Скин» меняет оформление приложения."),
                AssistantTip(target: "help", text: "«Справка» — все подсказки сразу."),
            ]
        case .sims:
            return [
                AssistantTip(target: nil, text: "Сул-сул! Я пламбоб. Нажимайте на меня — подскажу, что делает каждая кнопка."),
                AssistantTip(target: "add", text: "«Добавить» — подобрать товары из карточек. Новую карточку можно завести там же."),
                AssistantTip(target: "again", text: "«Снова» добавляет всё, что по расчёту уже заканчивается."),
                AssistantTip(target: "memory", text: "«Карточки» — каталог всех товаров. Отметьте, что взять в этот поход, задайте сроки — и нужное появится в списке само."),
                AssistantTip(target: "order", text: "«Порядок» переносит купленное в конец списка."),
                AssistantTip(target: "addNow", text: "ADD ▶ NOW — тоже подобрать товары из карточек."),
                AssistantTip(target: "dishes", text: "Это витрина «Купить снова». Нажмите — заканчивающиеся товары попадут в список."),
                AssistantTip(target: "list", text: "Нажмите на товар, потом ещё раз — откроется карточка. ✎ — изменить, ✓ — куплено."),
                AssistantTip(target: "skins", text: "«Скины» меняет оформление."),
                AssistantTip(target: "help", text: "«Справка» — все подсказки сразу."),
            ]
        case .aero:
            return [
                AssistantTip(target: nil, text: "Привет! Это я, твой контакт из MSN. Нажимай на меня — расскажу про кнопки :)"),
                AssistantTip(target: "start", text: "«начать покупки» открывает режим покупок: крути барабан вверх-вниз, а товар смахивай вправо — он в корзине."),
                AssistantTip(target: "search", text: "Поиск по списку."),
                AssistantTip(target: "editbar", text: "Зелёный карандаш — изменить выбранный товар, стрелки — выбрать предыдущий или следующий."),
                AssistantTip(target: "player", text: "▶ в плеере — тоже старт покупок. На экране — куплено : всего."),
                AssistantTip(target: "add", text: "«Добавить» — подобрать товары из карточек; новая карточка — там же."),
                AssistantTip(target: "again", text: "«Купить снова» добавляет всё, что заканчивается."),
                AssistantTip(target: "list", text: "Нажми на товар, потом ещё раз — откроется карточка. Двойное нажатие — куплено."),
                AssistantTip(target: "memory", text: "Шестерёнка — задать, как часто ты покупаешь товары."),
                AssistantTip(target: "cards", text: "«Карточки» — все твои товары. Отметь галочкой, что взять в этот поход."),
                AssistantTip(target: "menu", text: "Меню — все действия: новый поход, очистить список, сменить скин."),
                AssistantTip(target: "help", text: "«?» — все подсказки сразу."),
            ]
        case .winamp:
            return [
                AssistantTip(target: nil, text: "Хай. Я Kitty. Тыкни в меня ещё — расскажу, что тут за кнопки."),
                AssistantTip(target: "play", text: "Кнопка ▶ — товар куплен, и сразу выбирается следующий."),
                AssistantTip(target: "pause", text: "Кнопка ❚❚ — снять отметку «куплено»."),
                AssistantTip(target: "stop", text: "Кнопка ■ — закончить покупки. Купленное останется в списке зачёркнутым."),
                AssistantTip(target: "prev", text: "Крайние кнопки со стрелками — предыдущий и следующий товар."),
                AssistantTip(target: "eject", text: "Кнопка со стрелкой вверх (eject) — добавить товары из карточек."),
                AssistantTip(target: "lcd", text: "Цифры — куплено : всего. Нажми на них — покажу, сколько осталось."),
                AssistantTip(target: "qty", text: "Оранжевый ползунок — сколько штук выбранного товара."),
                AssistantTip(target: "again", text: "Кнопка с круговыми стрелками — добавить всё, что пора купить снова. Лампочка горит — есть что добавить."),
                AssistantTip(target: "shuffle", text: "SHUFFLE — купленное уезжает в конец списка."),
                AssistantTip(target: "eq", text: "EQ — окно «Купить снова»: чем выше ползунок, тем скорее товар закончится."),
                AssistantTip(target: "presets", text: "PRESETS — задать, как часто ты покупаешь каждый товар."),
                AssistantTip(target: "edit", text: "EDIT — карточка выбранного товара. Или нажми на товар в списке дважды подряд."),
                AssistantTip(target: "misc", text: "MISC — меню: сменить скин, очистить список и всё остальное."),
            ]
        }
    }
}

// MARK: - Слой помощника

struct AssistantLayer: View {
    @EnvironmentObject var store: ShopStore
    let anchors: [String: CGRect]
    let size: CGSize
    /// Скин берём из текущего состояния: замыкания таймеров не должны видеть устаревший
    private var skin: SkinID { store.state.skin }

    @State private var tipIndex: Int?
    @State private var nextTip = 0
    @State private var balloonHeight: CGFloat = 120
    @State private var clippyAnimation = "Greeting"
    @State private var clippyStart = Date()
    @State private var lean: Double = 0
    @State private var tapTimes: [Date] = []
    @State private var plumbobAngryUntil = Date.distantPast

    private var tips: [AssistantTip] { AssistantTips.tips(for: skin) }

    /// Где стоит персонаж (для Pixel Moon — Луна в сцене)
    private var characterFrame: CGRect? {
        switch skin {
        case .mac: return anchors["clippy"] ?? CGRect(x: size.width - 114, y: size.height - 60, width: 110, height: 82)
        case .sims: return CGRect(x: size.width - 66, y: size.height - 150, width: 50, height: 80)
        case .aero: return anchors["buddy"]
        case .pixel: return anchors["luna"]
        case .winamp: return anchors["kitty"]
        }
    }

    private var hidden: Bool {
        store.isAdding || store.editingID != nil || store.isChoosingSkin || store.showHelp
            || store.isEditingMemory || store.menu != nil || store.isViewingDishes || store.editingDish != nil
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            if !hidden, let index = tipIndex, index < tips.count, let target = tips[index].target, let rect = anchors[target] {
                TargetSpotlight(rect: rect.insetBy(dx: -6, dy: -6), skin: skin)
                    .allowsHitTesting(false)
            }
            if !hidden, let index = tipIndex, index < tips.count, let char = characterFrame {
                balloon(tips[index], character: char,
                        target: tips[index].target.flatMap { anchors[$0] })
            }
            // мигающий «?» — сразу видно, что персонаж кликабельный
            if !hidden, tipIndex == nil, let char = characterFrame {
                AttentionBadge(skin: skin)
                    .offset(x: min(char.maxX - 18, size.width - 40), y: max(char.minY - 20, 4))
                    .onTapGesture(perform: showNextTip)
            }
            if !hidden, let char = characterFrame, skin != .pixel, skin != .winamp {
                character
                    .frame(width: char.width, height: char.height)
                    .contentShape(Rectangle())
                    .onTapGesture(perform: characterTapped)
                    .simultaneousGesture(LongPressGesture(minimumDuration: 0.8).onEnded { _ in
                        // пасхалка Aero: долгое нажатие на человечка MSN
                        guard skin == .aero else { return }
                        Haptics.tap()
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) { store.msnPopup = true }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                            withAnimation(.easeIn(duration: 0.3)) { store.msnPopup = false }
                        }
                    })
                    .offset(x: char.minX, y: char.minY)
            }
        }
        .frame(width: size.width, height: size.height, alignment: .topLeading)
        .onPreferenceChange(BalloonHeightKey.self) { balloonHeight = $0 }
        .onChange(of: store.assistantPing) { _ in showNextTip() }
        .onChange(of: skin) { _ in
            store.assistantTarget = nil
            tipIndex = nil
            nextTip = 0
        }
        .onAppear {
            let args = ProcessInfo.processInfo.arguments
            if args.contains("-clippy") || args.contains("-assist") {
                // -tip=N: показать N-ю подсказку (для скриншотов)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    nextTip = args.first { $0.hasPrefix("-tip=") }.flatMap { Int($0.dropFirst(5)) } ?? 4
                    showNextTip()
                }
            }
        }
        .onReceive(Timer.publish(every: 7, on: .main, in: .common).autoconnect()) { _ in
            guard skin == .mac, tipIndex == nil else { return }
            // Скрепыш то стучит по экрану, то машет — привлекает внимание
            playClippy(["GetAttention", "Wave", "IdleEyeBrowRaise", "IdleSideToSide", "IdleHeadScratch"].randomElement()!)
        }
    }

    // MARK: Персонажи

    @ViewBuilder
    private var character: some View {
        switch skin {
        case .mac:
            ClippyView(animation: clippyAnimation, start: clippyStart)
        case .sims:
            FlyingPlumbob(lean: lean, angryUntil: plumbobAngryUntil)
        case .aero:
            MSNBuddy(animated: true, lean: lean, talking: store.assistantTalking)
        default:
            EmptyView()
        }
    }

    private func playClippy(_ name: String) {
        clippyAnimation = name
        clippyStart = Date()
    }

    /// Нажатие на персонажа: подсказка; в Sims три быстрых нажатия — пасхалка
    private func characterTapped() {
        if skin == .sims {
            let now = Date()
            tapTimes = tapTimes.filter { now.timeIntervalSince($0) < 1.2 } + [now]
            if tapTimes.count >= 3 {
                tapTimes = []
                close()
                Haptics.tap()
                plumbobAngryUntil = now.addingTimeInterval(4)
                store.notify("Настроение geronimo: −50 «Оскорбление чувств верующих»")
                return
            }
        }
        showNextTip()
    }

    private func showNextTip() {
        guard !tips.isEmpty else { return }
        Haptics.tap()
        let index = nextTip % tips.count
        nextTip += 1
        withAnimation(.easeOut(duration: 0.15)) { tipIndex = index }
        store.assistantTalking = Date()
        store.assistantTarget = tips[index].target
        if let target = tips[index].target, let rect = anchors[target], let char = characterFrame {
            let dir = direction(from: char, to: CGPoint(x: rect.midX, y: rect.midY))
            playClippy("Gesture" + dir)
            lean = dir == "Left" ? -14 : (dir == "Right" ? 14 : 0)
        } else {
            playClippy("Explain")
            lean = 0
        }
    }

    private func close() {
        withAnimation(.easeOut(duration: 0.15)) { tipIndex = nil }
        store.assistantTarget = nil
        playClippy("IdleEyeBrowRaise")
        lean = 0
    }

    private func direction(from char: CGRect, to point: CGPoint) -> String {
        let dx = point.x - char.midX, dy = point.y - char.midY
        if abs(dy) > abs(dx) * 0.8 { return dy < 0 ? "Up" : "Down" }
        return dx < 0 ? "Left" : "Right"
    }

    // MARK: Облачко в стиле скина

    private func balloon(_ tip: AssistantTip, character char: CGRect, target: CGRect?) -> some View {
        let width = min(size.width - 32, 300)
        let height = balloonHeight
        var x = max(16, min(char.midX - width * 0.7, size.width - width - 16))
        // персонаж в верхней половине экрана (Луна) — облачко под ним, иначе над ним
        var below = char.midY < size.height * 0.45 || char.minY < height + 40
        var y = below ? char.maxY + 14 : char.minY - height - 22
        var pointTo = char.midX
        // облачко никогда не закрывает элемент, о котором рассказывает: иначе ставим его над или под элементом
        if let target {
            let box = CGRect(x: x, y: y, width: width, height: height)
            if box.intersects(target.insetBy(dx: -10, dy: -10)) {
                let spaceAbove = target.minY - 20
                let spaceBelow = size.height - target.maxY - 20
                below = spaceBelow >= height || spaceBelow > spaceAbove
                y = below ? target.maxY + 18 : target.minY - height - 18
                x = max(16, min(target.midX - width / 2, size.width - width - 16))
                pointTo = target.midX
            }
        }
        y = max(8, min(y, size.height - height - 8))
        let tailX = pointTo - x
        return balloonBody(tip)
            .frame(width: width)
            .fixedSize(horizontal: false, vertical: true)
            .background(balloonShape(tailX: tailX, tailUp: below))
            .background(GeometryReader { g in Color.clear.preference(key: BalloonHeightKey.self, value: g.size.height) })
            .offset(x: x, y: y)
            .transition(.opacity)
    }

    private func balloonBody(_ tip: AssistantTip) -> some View {
        let style = BalloonStyle.of(skin)
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                style.icon
                Text(style.title).font(style.font(14, .bold))
            }
            Text(tip.text)
                .font(style.font(14, .regular))
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 8) {
                Spacer()
                balloonButton("Дальше", style, action: showNextTip)
                balloonButton("Закрыть", style, action: close)
            }
        }
        .foregroundStyle(style.text)
        .padding(12)
        .padding(.vertical, 2)
    }

    @ViewBuilder
    private func balloonShape(tailX: CGFloat, tailUp: Bool) -> some View {
        let style = BalloonStyle.of(skin)
        ZStack {
            BalloonShape(tailX: tailX, tailUp: tailUp).fill(style.fill)
            BalloonShape(tailX: tailX, tailUp: tailUp).stroke(style.stroke, lineWidth: style.lineWidth)
        }
        .shadow(color: .black.opacity(0.25), radius: 4, y: 2)
    }

    private func balloonButton(_ title: String, _ style: BalloonStyle, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(style.font(14, .regular))
                .foregroundStyle(style.buttonText)
                .padding(.horizontal, 12)
                .frame(minWidth: 76)
                .frame(height: 40)
                .background(RoundedRectangle(cornerRadius: style.buttonRadius).fill(style.buttonFill))
                .overlay(RoundedRectangle(cornerRadius: style.buttonRadius).stroke(style.stroke.opacity(0.7), lineWidth: 1))
        }
        .buttonStyle(PressScaleStyle())
    }
}

private struct BalloonHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 120
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

/// Цвета и шрифты облачка для каждого скина
struct BalloonStyle {
    let title: String
    let icon: AnyView
    let fill: Color
    let stroke: Color
    let lineWidth: CGFloat
    let text: Color
    let buttonFill: Color
    let buttonText: Color
    let buttonRadius: CGFloat
    let font: (CGFloat, Font.Weight) -> Font

    static func of(_ skin: SkinID) -> BalloonStyle {
        let warning = AnyView(
            ZStack {
                Triangle().fill(Color(hex: 0xFFE14A))
                Triangle().stroke(Color.black, lineWidth: 1)
                Text("!").font(.custom("Verdana", size: 13).weight(.heavy)).offset(y: 3)
            }
            .frame(width: 22, height: 20)
        )
        switch skin {
        case .aero:
            return BalloonStyle(
                title: "MSN Messenger",
                icon: AnyView(MSNBuddy().frame(width: 20, height: 22)),
                fill: Color(hex: 0xFFFFE1), stroke: .black, lineWidth: 1, text: .black,
                buttonFill: .white, buttonText: .black, buttonRadius: 4,
                font: { Aero.xp($0, $1) })
        case .sims:
            return BalloonStyle(
                title: "Подсказка",
                icon: AnyView(Plumbob(mood: 1, spinning: false).frame(width: 12, height: 20)),
                fill: Color(hex: 0x8DB4F2), stroke: Sims.panelBorder, lineWidth: 2.5, text: Sims.ink,
                buttonFill: Color(hex: 0xEAF2FF), buttonText: Sims.ink, buttonRadius: 12,
                font: { Sims.verdana($0, $1) })
        case .pixel:
            return BalloonStyle(
                title: "Луна",
                icon: AnyView(PixelArt(rows: PxArt.moon, palette: PxArt.palette).frame(width: 18, height: 18)),
                fill: Px.paper, stroke: Px.ink, lineWidth: 2.5, text: Px.navy,
                buttonFill: Px.pinkLight, buttonText: Px.navy, buttonRadius: 2,
                font: { Px.body($0, $1) })
        case .winamp:
            return BalloonStyle(
                title: "KITTY",
                icon: AnyView(Image("winamp_kitty").resizable().frame(width: 22, height: 22).clipShape(Rectangle())),
                fill: Color(hex: 0x0E1030), stroke: Color(hex: 0xE2D9A6), lineWidth: 2, text: Color(hex: 0x46D446),
                buttonFill: Color(hex: 0xC9D3EC), buttonText: Winamp.ink, buttonRadius: 2,
                font: { .system(size: $0, weight: $1, design: .monospaced) })
        default:
            return BalloonStyle(
                title: "ShopAmp",
                icon: warning,
                fill: Color(hex: 0xFFFFCC), stroke: .black, lineWidth: 1, text: .black,
                buttonFill: .white, buttonText: .black, buttonRadius: 4,
                font: { .custom("Verdana", size: $0).weight($1) })
        }
    }
}

// MARK: - Персонажи

/// Глянцевый человечек MSN Messenger. Цвета сняты с референса: бирюзовый на свету, тёмно-синий в тени,
/// почти белый блик, светлый отражённый свет снизу, серо-белая «наклейка» по контуру и тень.
/// animated: дышит, подпрыгивает с приплющиванием, по голове пробегает блик, кивает, когда говорит.
struct MSNBuddy: View {
    var animated = false
    var lean: Double = 0
    var talking: Date = .distantPast

    var body: some View {
        if animated {
            TimelineView(.animation(minimumInterval: 1 / 30)) { context in
                frame(t: context.date.timeIntervalSinceReferenceDate, now: context.date)
            }
        } else {
            frame(t: nil, now: Date())
        }
    }

    private func frame(t: Double?, now: Date) -> some View {
        Canvas { c, size in
            // холст шире рамки на `inset` со всех сторон — прыжок, тень и обводка не обрезаются
            let inset: CGFloat = 26
            let s = min((size.width - inset * 2) / 100, (size.height - inset * 2) / 118)
            let ox = (size.width - 100 * s) / 2
            let oy = size.height - inset - 118 * s
            // ---- параметры анимации
            var breathe: CGFloat = 0, lift: CGFloat = 0, squash: CGFloat = 0, nod: CGFloat = 0, glint: CGFloat = -1
            if let t {
                breathe = CGFloat(sin(t * 2.2)) * 0.02
                let hopT = t.truncatingRemainder(dividingBy: 4.2)
                if hopT < 0.12 { squash = CGFloat(hopT / 0.12) * 0.12 }                       // присел
                else if hopT < 0.62 {                                                           // в прыжке
                    let p = (hopT - 0.12) / 0.5
                    lift = CGFloat(sin(p * .pi)) * 14
                    squash = -CGFloat(sin(p * .pi)) * 0.06                                      // вытянулся
                } else if hopT < 0.78 { squash = CGFloat(sin((hopT - 0.62) / 0.16 * .pi)) * 0.1 } // приземлился
                let g = t.truncatingRemainder(dividingBy: 3.1)
                if g < 0.7 { glint = CGFloat(g / 0.7) }
                let talk = now.timeIntervalSince(talking)
                if talk < 0.8 { nod = CGFloat(sin(talk / 0.8 * .pi * 2)) * 3 }
            }
            let ground = CGPoint(x: ox + 50 * s, y: oy + 112 * s)
            // тень на «полу»
            let shadowW = (70 - lift * 1.6) * s
            c.fill(Path(ellipseIn: CGRect(x: ground.x - shadowW / 2, y: ground.y - 3 * s, width: shadowW, height: 8 * s)),
                   with: .color(.black.opacity(0.28 - Double(lift) * 0.01)))
            c.translateBy(x: 0, y: -lift * s)
            // приплющивание от земли
            c.translateBy(x: ground.x, y: ground.y)
            c.scaleBy(x: 1 + squash * 0.8 - breathe * 0.4, y: 1 - squash + breathe)
            c.rotate(by: .degrees(lean))
            c.translateBy(x: -ground.x, y: -ground.y)

            func P(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: ox + x * s, y: oy + y * s) }
            let headC = P(43, 31 + nod), headR = 28 * s
            let head = Path(ellipseIn: CGRect(x: headC.x - headR, y: headC.y - headR, width: headR * 2, height: headR * 2))
            var body = Path()
            body.move(to: P(4, 98))
            body.addCurve(to: P(48, 52), control1: P(0, 66), control2: P(18, 52))
            body.addCurve(to: P(96, 98), control1: P(80, 52), control2: P(100, 68))
            body.addCurve(to: P(78, 111), control1: P(96, 108), control2: P(90, 111))
            body.addLine(to: P(22, 111))
            body.addCurve(to: P(4, 98), control1: P(10, 111), control2: P(4, 108))
            body.closeSubpath()

            // ---- «наклейка»: серо-белый контур с мягкой тенью
            c.drawLayer { l in
                l.addFilter(.shadow(color: .black.opacity(0.35), radius: 3 * s, x: 1.5 * s, y: 2.5 * s))
                let stroke = StrokeStyle(lineWidth: 9 * s, lineJoin: .round)
                l.stroke(body, with: .color(Color(hex: 0xE9EDF2)), style: stroke)
                l.fill(body, with: .color(Color(hex: 0xE9EDF2)))
                l.stroke(head, with: .color(Color(hex: 0xE9EDF2)), style: stroke)
                l.fill(head, with: .color(Color(hex: 0xE9EDF2)))
            }
            c.stroke(body, with: .color(Color(hex: 0xBEC9D7)), lineWidth: 1.2 * s)

            // ---- тело
            c.fill(body, with: .linearGradient(
                Gradient(stops: [.init(color: Color(hex: 0x1989BE), location: 0), .init(color: Color(hex: 0x06C8DD), location: 0.2),
                                 .init(color: Color(hex: 0x07D3E7), location: 0.3), .init(color: Color(hex: 0x0898C9), location: 0.46),
                                 .init(color: Color(hex: 0x02539E), location: 0.66), .init(color: Color(hex: 0x0665B2), location: 0.78),
                                 .init(color: Color(hex: 0x03275F), location: 1)]),
                startPoint: P(5, 80), endPoint: P(95, 80)))
            c.drawLayer { l in
                l.clip(to: body)
                // низ темнее и отражённый свет по краю снизу
                l.fill(body, with: .linearGradient(Gradient(colors: [.clear, Color(hex: 0x0B4278).opacity(0.55)]),
                                                   startPoint: P(50, 70), endPoint: P(50, 110)))
                l.addFilter(.blur(radius: 3 * s))
                l.fill(Path(ellipseIn: CGRect(x: P(14, 101).x, y: P(14, 101).y, width: 70 * s, height: 14 * s)),
                       with: .color(Color(hex: 0xA8E1F0).opacity(0.75)))
                // вертикальный блик слева
                l.fill(Path(ellipseIn: CGRect(x: P(16, 58).x, y: P(16, 58).y, width: 16 * s, height: 42 * s)),
                       with: .color(.white.opacity(0.4)))
                // тень от головы
                l.fill(Path(ellipseIn: CGRect(x: P(18, 46 + nod).x, y: P(18, 46 + nod).y, width: 52 * s, height: 14 * s)),
                       with: .color(Color(hex: 0x002A55).opacity(0.55)))
            }

            // ---- голова
            c.fill(head, with: .radialGradient(
                Gradient(stops: [.init(color: Color(hex: 0xE6F8FA), location: 0), .init(color: Color(hex: 0x8FDDEC), location: 0.16),
                                 .init(color: Color(hex: 0x0D9EBF), location: 0.42), .init(color: Color(hex: 0x0A6EA8), location: 0.66),
                                 .init(color: Color(hex: 0x003B67), location: 1)]),
                center: P(30, 16 + nod), startRadius: 0, endRadius: 48 * s))
            c.drawLayer { l in
                l.clip(to: head)
                l.addFilter(.blur(radius: 2.5 * s))
                // отражённый свет внизу головы
                l.fill(Path(ellipseIn: CGRect(x: P(20, 48 + nod).x, y: P(20, 48 + nod).y, width: 44 * s, height: 15 * s)),
                       with: .color(Color(hex: 0x9DE4F3).opacity(0.85)))
                // пробегающий блик
                if glint >= 0 {
                    let gx = 14 + glint * 60
                    var band = Path()
                    band.move(to: P(gx, 4 + nod)); band.addLine(to: P(gx + 8, 4 + nod))
                    band.addLine(to: P(gx - 6, 56 + nod)); band.addLine(to: P(gx - 14, 56 + nod)); band.closeSubpath()
                    l.fill(band, with: .color(.white.opacity(0.45 * Double(sin(glint * .pi)))))
                }
            }
            // зеркальный блик
            c.drawLayer { l in
                l.addFilter(.blur(radius: 1.2 * s))
                l.fill(Path(ellipseIn: CGRect(x: P(22, 8 + nod).x, y: P(22, 8 + nod).y, width: 30 * s, height: 16 * s)),
                       with: .color(.white.opacity(0.9)))
            }
            c.stroke(head, with: .color(Color(hex: 0x002A55).opacity(0.5)), lineWidth: 0.8 * s)
        }
        .padding(-26)
        .aspectRatio(100 / 118, contentMode: .fit)
    }
}

/// Летающий зелёный пламбоб с сиянием и тенью
struct FlyingPlumbob: View {
    var lean: Double = 0
    /// До этого момента пламбоб красный (настроение испорчено)
    var angryUntil: Date = .distantPast

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let angry = context.date < angryUntil
            let lift = CGFloat(sin(t * (angry ? 9 : 1.8))) * (angry ? 3 : 6)
            let glowColor = angry ? Color(hex: 0xE8402A) : Sims.plumbobGreen
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(RadialGradient(colors: [glowColor.opacity(0.55), .clear], center: .center, startRadius: 2, endRadius: 30))
                        .frame(width: 60, height: 60)
                    Plumbob(mood: angry ? 0 : 1)
                        .frame(width: 30, height: 50)
                        .rotationEffect(.degrees(lean))
                }
                .offset(y: lift)
                Ellipse()
                    .fill(Color.black.opacity(0.25 - Double(lift) * 0.01))
                    .frame(width: 26 - lift, height: 6)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: lean)
    }
}

/// Пульсирующий значок «?» над помощником
struct AttentionBadge: View {
    let skin: SkinID

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let pulse = 1 + CGFloat(sin(t * 4)) * 0.12
            let bob = CGFloat(sin(t * 2.5)) * 2
            Text("?")
                .font(.system(size: 15, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 26, height: 26)
                .background(Circle().fill(color))
                .overlay(Circle().stroke(.white, lineWidth: 2))
                .shadow(color: color.opacity(0.7), radius: 4 + CGFloat(sin(t * 4)) * 2)
                .scaleEffect(pulse)
                .offset(y: bob)
        }
        .frame(width: 36, height: 36)
        .contentShape(Rectangle())
    }

    private var color: Color {
        switch skin {
        case .winamp: return Color(hex: 0xF0469A)
        case .aero: return Color(hex: 0x2A5CCB)
        case .mac: return Color(hex: 0x2E3036)
        case .sims: return Color(hex: 0x2E9E2A)
        case .pixel: return Px.pink
        }
    }
}

/// Подсветка элемента: экран затемнён, элемент «вырезан» и обведён пульсирующей рамкой в цвете скина
struct TargetSpotlight: View {
    let rect: CGRect
    let skin: SkinID

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let pulse = (sin(t * 5) + 1) / 2
            ZStack(alignment: .topLeading) {
                Canvas { c, size in
                    var p = Path(CGRect(origin: .zero, size: size))
                    p.addRoundedRect(in: rect, cornerSize: CGSize(width: 10, height: 10))
                    c.fill(p, with: .color(.black.opacity(0.42)), style: FillStyle(eoFill: true))
                }
                if skin == .mac {
                    MarchingAnts()
                        .frame(width: rect.width, height: rect.height)
                        .offset(x: rect.minX, y: rect.minY)
                } else {
                    let grow = CGFloat(pulse) * 4
                    RoundedRectangle(cornerRadius: 10 + grow)
                        .stroke(accent, lineWidth: 3.5)
                        .shadow(color: accent.opacity(0.9), radius: 6 + CGFloat(pulse) * 6)
                        .overlay(RoundedRectangle(cornerRadius: 10 + grow).stroke(.white.opacity(0.85), lineWidth: 1).padding(3))
                        .frame(width: rect.width + grow * 2, height: rect.height + grow * 2)
                        .offset(x: rect.minX - grow, y: rect.minY - grow)
                }
            }
        }
    }

    private var accent: Color {
        switch skin {
        case .winamp: return Color(hex: 0x46F046)
        case .aero: return Color(hex: 0xFFB23C)
        case .mac: return .black
        case .sims: return Color(hex: 0x6CF04E)
        case .pixel: return Color(hex: 0xFF5FB0)
        }
    }
}
