import SwiftUI

/// Скин «Pixel Moon»: пастельный пиксельный инвентарь и лунная магия
struct PixelSkinView: View {
    @EnvironmentObject var store: ShopStore

    enum Tab: String, CaseIterable {
        case all = "ВСЁ", buy = "КУПИТЬ", cart = "КОРЗИНА", due = "СНОВА"
    }

    @State private var tab: Tab = .all
    @State private var burst: (date: Date, text: String, big: Bool)?
    @State private var doneDisc: Date?

    var body: some View {
        ZStack {
            floor.ignoresSafeArea()
            ScrollViewReader { assistProxy in
ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 14) {
                    PixelWindow(title: "SHOPAMP'S LIL' BAG") {
                        MoonScene(onPlanet: magic, onCrane: craneGrab)
                            .frame(height: 252)
                    }
                    toolbar
                    inventory
                    detailPanel
                    tipBubble
                    levelBar
                }
                .padding(.horizontal, 14)
                .padding(.top, 6)
                .padding(.bottom, 44)
            }
.scrollsToAssistTarget(assistProxy, store.assistantTarget)
}
        }
        .overlay {
            if let burst {
                SparkleBurst(start: burst.date, text: burst.text, big: burst.big)
                    .id(burst.date)
            }
        }
        .overlay(alignment: .bottomTrailing) {
            if let doneDisc {
                DoneKirbyDisc(start: doneDisc)
                    .padding(.trailing, 10)
                    .padding(.bottom, 30)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .overlay {
            if store.isAdding || store.editingID != nil {
                PixelAddItemDialog()
            } else if store.isChoosingSkin {
                PixelSkinBrowser()
            }
        }
        .onChange(of: store.boughtCount) { [old = store.boughtCount] new in
            guard new > old else { return }
            if store.leftCount == 0 {
                fire("ЛУННАЯ ПРИЗМА,\nДАЙ МНЕ СИЛУ!\n✦ ВСЁ КУПЛЕНО ✦", big: true)
            } else {
                fire("+1 В РЮКЗАК!", big: false)
            }
            let start = Date()
            withAnimation { doneDisc = start }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                if doneDisc == start { withAnimation { doneDisc = nil } }
            }
        }
    }

    private func fire(_ text: String, big: Bool) {
        burst = (Date(), text, big)
    }

    /// Планета — просто волшебная вспышка
    private func magic() {
        Haptics.tap()
        fire("ЛУННАЯ ПРИЗМА,\nДАЙ МНЕ СИЛУ!", big: true)
    }

    /// Автомат с клешнёй достаёт из памяти то, что пора купить снова
    private func craneGrab() {
        let count = store.addDue()
        if count > 0 { fire("+\(count) КУПИТЬ СНОВА", big: false) }
    }

    // MARK: Панель кнопок — у каждой иконка и подпись

    private var toolbar: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
            toolButton("plus", "ДОБАВИТЬ") { store.isAdding = true }
                .assistAnchor("add")
            toolButton("pencil", "ИЗМЕНИТЬ") { store.edit(store.selectedID) }
                .assistAnchor("edit")
            toolButton("arrow.clockwise", "КУПИТЬ СНОВА") { store.isEditingMemory = true }
                .assistAnchor("again")
            toolButton("paintpalette.fill", "СКИН") { store.isChoosingSkin = true }
                .assistAnchor("skin")
            toolButton("questionmark", "СПРАВКА") { store.showHelp = true }
                .assistAnchor("help")
            toolButton("line.3.horizontal", "МЕНЮ") { store.openMainMenu() }
                .assistAnchor("menu")
        }
    }

    private func toolButton(_ symbol: String, _ title: String, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: symbol).font(.system(size: 12, weight: .black))
                Text(title).font(Px.title(9)).lineLimit(1).minimumScaleFactor(0.6)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PixelButtonStyle(fill: .white, text: Px.ink))
    }

    // MARK: Фон — розовый пол с пиксельной травкой

    private var floor: some View {
        Canvas { c, size in
            c.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Px.blush))
            var rng = SeededRandom(seed: 11)
            for _ in 0..<70 {
                let x = rng.next() * size.width, y = rng.next() * size.height
                let s: CGFloat = 3
                c.fill(Path(CGRect(x: x, y: y, width: s, height: s)), with: .color(Px.pinkSoft.opacity(0.7)))
                c.fill(Path(CGRect(x: x + s, y: y - s, width: s, height: s)), with: .color(Px.pinkSoft.opacity(0.7)))
                c.fill(Path(CGRect(x: x + s * 2, y: y, width: s, height: s)), with: .color(Px.pinkSoft.opacity(0.7)))
            }
        }
    }

    // MARK: ITEM INVENTORY

    private var tabItems: [ShopItem] {
        switch tab {
        case .all: return store.displayItems
        case .buy: return store.displayItems.filter { !$0.bought }
        case .cart: return store.displayItems.filter(\.bought)
        case .due: return []
        }
    }

    private var inventory: some View {
        VStack(spacing: 0) {
            HStack {
                Text("ITEM INVENTORY").font(Px.title(9))
                Spacer()
                Text("\(String(format: "%02d", store.totalCount))/99").font(Px.title(8))
                    .padding(.horizontal, 4)
                    .padding(.vertical, 3)
                    .background(PixelRect(step: 2).fill(Px.lavenderLight))
            }
            .foregroundStyle(Px.ink)
            .padding(.horizontal, 8)
            .frame(height: 28)
            HStack(spacing: 3) {
                ForEach(Tab.allCases, id: \.self) { t in
                    Text(t.rawValue)
                        .font(Px.title(9))
                        .foregroundStyle(t == tab ? .white : Px.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(PixelRect(step: 2).fill(t == tab ? Px.pink : Color.white))
                        .overlay(PixelRect(step: 2).strokeBorder(Px.ink, lineWidth: 2))
                        .pressable(.pixel) {
                            Haptics.tap()
                            tab = t
                        }
                }
            }
            .padding(.horizontal, 6)
            .padding(.bottom, 6)
            .assistAnchor("tabs")

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 5), spacing: 6) {
                if tab == .due {
                    ForEach(store.dueSuggestions, id: \.name) { memory in
                        dueSlot(memory)
                    }
                } else {
                    ForEach(tabItems) { item in
                        slot(item)
                    }
                }
                ForEach(0..<max(10 - slotCount, (5 - slotCount % 5) % 5), id: \.self) { _ in
                    emptySlot
                }
            }
            .padding(.horizontal, 8)
            .assistAnchor("inventory")

            if tab == .due {
                Button("НАСТРОИТЬ «КУПИТЬ СНОВА»") {
                    Haptics.tap()
                    store.isEditingMemory = true
                }
                .buttonStyle(PixelButtonStyle(fill: .white, text: Px.ink))
                .padding(.top, 8)
            }

            HStack(spacing: 6) {
                Circle().fill(Px.pink).overlay(Circle().stroke(Px.ink, lineWidth: 2)).frame(width: 16, height: 16)
                HStack {
                    Spacer()
                    Text("В КОРЗИНЕ \(store.boughtCount)/\(store.totalCount)")
                        .font(Px.title(8))
                        .foregroundStyle(Px.ink)
                }
                .padding(.horizontal, 6)
                .frame(height: 22)
                .background(PixelRect(step: 2).fill(.white))
                .overlay(PixelRect(step: 2).strokeBorder(Px.ink, lineWidth: 2))
            }
            .padding(8)
        }
        .background(PixelPanel(fill: Px.lavenderLight))
    }

    private var slotCount: Int {
        tab == .due ? store.dueSuggestions.count : tabItems.count
    }

    private func slot(_ item: ShopItem) -> some View {
        let selected = item.id == store.selectedID
        return ZStack(alignment: .bottomTrailing) {
            PixelRect(step: 3).fill(selected ? Px.pinkLight : Color.white)
            ProductImage(name: item.name, size: 40, pixelated: true)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .opacity(item.bought ? 0.35 : 1)
            if item.bought {
                Text("✓")
                    .font(Px.title(10))
                    .foregroundStyle(Px.pink)
                    .padding(4)
            } else if item.qty > 1 {
                Text("\(item.qty)")
                    .font(Px.title(7))
                    .foregroundStyle(.white)
                    .padding(3)
                    .background(PixelRect(step: 1).fill(Px.ink))
                    .padding(3)
            }
            PixelRect(step: 3).strokeBorder(selected ? Px.pink : Px.ink, lineWidth: selected ? 3 : 2)
        }
        .aspectRatio(1, contentMode: .fit)
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
            Haptics.tap()
            store.toggleBought(item.id)
        }
        .onTapGesture {
            Haptics.tap()
            store.tapItem(item.id)
        }
        .onLongPressGesture { store.openItemMenu(item.id) }
    }

    private func dueSlot(_ memory: ItemMemory) -> some View {
        ZStack(alignment: .topTrailing) {
            PixelRect(step: 3).fill(Color.white)
            ProductImage(name: memory.name, size: 40, pixelated: true)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            Text("+")
                .font(Px.title(9))
                .foregroundStyle(.white)
                .frame(width: 16, height: 16)
                .background(PixelRect(step: 1).fill(Px.pink))
                .padding(3)
            PixelRect(step: 3).strokeBorder(Px.ink, style: StrokeStyle(lineWidth: 2, dash: [4, 3]))
        }
        .aspectRatio(1, contentMode: .fit)
        .contentShape(Rectangle())
        .pressable(.pixel) {
            Haptics.tap()
            store.add(memory.name)
            fire("+ \(memory.name.uppercased())", big: false)
        }
    }

    private var emptySlot: some View {
        PixelRect(step: 3)
            .fill(Color.white.opacity(0.55))
            .overlay(PixelRect(step: 3).strokeBorder(Px.ink.opacity(0.5), lineWidth: 2))
            .aspectRatio(1, contentMode: .fit)
    }

    // MARK: Описание предмета (как «Ramen — Recovers 1000 HP»)

    private var detailPanel: some View {
        let item = store.selectedItem
        let memory = item.flatMap { store.state.memory[ShopStore.key($0.name)] }
        return HStack(alignment: .top, spacing: 10) {
            VStack(spacing: 6) {
                ZStack {
                    PixelRect(step: 3).fill(Px.sky.opacity(0.5))
                    ProductImage(name: item?.name ?? "", size: 46, pixelated: true)
                    PixelRect(step: 3).strokeBorder(Px.pinkLight, lineWidth: 3)
                }
                .frame(width: 62, height: 62)
                HStack(spacing: 4) {
                    smallPixelButton("−") { if let item { store.setQty(item.id, item.qty - 1) } }
                    smallPixelButton("+") { if let item { store.setQty(item.id, item.qty + 1) } }
                }
            }
            VStack(alignment: .leading, spacing: 5) {
                Text("• " + (item?.name ?? "Выберите предмет"))
                    .font(Px.body(18, .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(flavor(item, memory))
                    .font(Px.body(14))
                    .foregroundStyle(Px.pinkLight)
                Text(item.map { "Восстанавливает \($0.qty * 100) HP" } ?? "")
                    .font(Px.body(14))
                    .foregroundStyle(.white)
                HStack(spacing: 8) {
                    Button(item?.bought == true ? "ВЕРНУТЬ" : "В РЮКЗАК") {
                        Haptics.tap()
                        store.toggleBought(item?.id)
                    }
                    .buttonStyle(PixelButtonStyle())
                    .assistAnchor("backpack")
                    Button {
                        Haptics.tap()
                        store.edit(item?.id)
                    } label: {
                        Image(systemName: "pencil").font(.system(size: 13, weight: .bold))
                    }
                    .buttonStyle(PixelButtonStyle(fill: .white, text: Px.ink))
                    Button {
                        Haptics.tap()
                        store.remove(item?.id)
                    } label: {
                        Image(systemName: "trash.fill").font(.system(size: 13))
                    }
                    .buttonStyle(PixelButtonStyle(fill: Px.sky, text: Px.ink))
                }
                .padding(.top, 2)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(PixelPanel(fill: Px.navy, border: Px.ink, shadow: Px.pinkSoft))
        .opacity(item == nil ? 0.7 : 1)
    }

    private func flavor(_ item: ShopItem?, _ memory: ItemMemory?) -> String {
        guard let item else { return "Нажмите на ячейку, чтобы посмотреть предмет." }
        var parts = ["x\(item.qty)"]
        if let interval = memory?.interval {
            parts.append("покупаешь раз в \(Int(interval.rounded())) дн")
        } else {
            parts.append("новый предмет")
        }
        if item.bought { parts.append("уже в рюкзаке") }
        return parts.joined(separator: " · ")
    }

    private func smallPixelButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            Text(title)
                .font(Px.title(13))
                .foregroundStyle(Px.ink)
                .frame(width: 44, height: 40)
                .background(PixelRect(step: 2).fill(.white))
                .overlay(PixelRect(step: 2).strokeBorder(Px.pinkLight, lineWidth: 2))
        }
        .buttonStyle(PressScaleStyle())
    }

    // MARK: Розовое облачко-подсказка

    private var tipBubble: some View {
        let due = store.dueSuggestions.map(\.name)
        let text: String
        if store.totalCount == 0 {
            text = "Рюкзак пуст. Нажми ☰ или брошь, чтобы наполнить его."
        } else if store.leftCount == 0 {
            text = "Ты купил(а) всё! Мы советуем сделать перерыв ✦"
        } else if let first = due.first {
            text = "Куплено \(store.boughtCount) из \(store.totalCount). Не забудь: \(first)!"
        } else {
            text = "Куплено \(store.boughtCount) из \(store.totalCount). Ещё \(store.leftCount) — и готово!"
        }
        return HStack(spacing: 10) {
            Text(text)
                .font(Px.body(16, .bold))
                .foregroundStyle(Px.navy)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button("ADD") {
                Haptics.tap()
                store.isAdding = true
            }
            .buttonStyle(PixelButtonStyle(fill: .white, text: Px.pink))
        }
        .padding(12)
        .background(PixelPanel(fill: Px.pinkSoft, border: Px.ink, shadow: nil))
        .overlay(alignment: .topLeading) {
            PixelArt(rows: ["KKKKKK", "KPPPPK", ".KPPK.", "..KK.."].reversed(), palette: ["K": Px.ink, "P": Px.pinkSoft])
                .frame(width: 18, height: 12)
                .offset(x: 30, y: -10)
        }
    }

    // MARK: LV / HP / MP / EXP

    private var levelBar: some View {
        let totalPurchases = store.state.memory.values.reduce(0) { $0 + $1.purchases.count }
        let level = totalPurchases / 5 + 1
        let exp = Double(totalPurchases % 5) / 5
        let hp = store.totalCount == 0 ? 0 : Double(store.boughtCount) / Double(store.totalCount)
        let mp = store.regulars.isEmpty ? 0 : Double(store.dueSuggestions.count) / Double(store.regulars.count)
        return HStack(spacing: 8) {
            HStack(spacing: 4) {
                Text("LV.").font(Px.title(10)).foregroundStyle(.white)
                Text("\(level)")
                    .font(Px.title(11))
                    .foregroundStyle(.white)
                    .padding(4)
                    .background(PixelRect(step: 2).fill(Px.pink))
            }
            .padding(8)
            .background(PixelRect(step: 3).fill(Px.navy))
            VStack(alignment: .leading, spacing: 4) {
                statBar("HP[\(store.boughtCount)/\(store.totalCount)]", hp)
                statBar("MP[\(store.dueSuggestions.count)]", mp)
                statBar("EXP.\(totalPurchases)[\(Int(exp * 100))%]", exp)
            }
        }
        .padding(8)
        .background(PixelPanel(fill: Px.lavenderLight))
        .assistAnchor("level")
    }

    private func statBar(_ title: String, _ value: Double) -> some View {
        HStack(spacing: 6) {
            Text(title)
                .font(Px.title(8))
                .foregroundStyle(Px.navy)
                .frame(width: 120, alignment: .leading)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            PixelBar(value: value)
                .frame(height: 12)
        }
    }
}

// MARK: - Сцена: стена, окно с луной, Луна-кошка, звёзды и сердечки

struct MoonScene: View {
    let onPlanet: () -> Void
    let onCrane: () -> Void

    @EnvironmentObject private var store: ShopStore

    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            let floorY = h - 22
            ZStack(alignment: .topLeading) {
                TimelineView(.animation(minimumInterval: 1 / 20)) { context in
                    let t = context.date.timeIntervalSinceReferenceDate
                    ZStack(alignment: .topLeading) {
                        bricks(t: t)
                        // окно с ночным небом и луной
                        ZStack {
                            Rectangle().fill(Px.navy)
                            PixelArt(rows: PxArt.moon, palette: PxArt.palette)
                                .frame(width: 30, height: 30)
                                .offset(x: 12, y: CGFloat(sin(t * 1.5)) * 4 - 6)
                            shootingStar(t: t, width: w * 0.3)
                            Rectangle().fill(Px.lavender).frame(width: 4)
                            Rectangle().fill(Px.lavender).frame(height: 4)
                            Rectangle().stroke(Px.pink, lineWidth: 5)
                        }
                        .frame(width: w * 0.17, height: h * 0.5)
                        .offset(x: w * 0.435, y: h * 0.1)
                        curtain.frame(width: 10, height: h * 0.54).offset(x: w * 0.435 - 8, y: h * 0.08)
                        curtain.frame(width: 10, height: h * 0.54).offset(x: w * 0.605 - 2, y: h * 0.08)
                        Rectangle().fill(Px.pink).frame(width: w * 0.23, height: 7).offset(x: w * 0.405, y: h * 0.6)
                        // пол
                        Rectangle().fill(Px.pinkLight).frame(width: w, height: h - floorY).offset(y: floorY)
                        hearts(t: t, w: w, h: floorY)
                    }
                }
                // ночная панель слева: планета сверху, Кирби на радуге снизу
                VStack(spacing: 0) {
                    RingPlanet(fast: store.leftCount > 0)
                        .frame(height: 104)
                        .contentShape(Rectangle())
                        .pressable(.pixel, action: onPlanet)
                    KirbyRider(lively: store.leftCount > 0)
                        .frame(height: 92)
                }
                .frame(width: w * 0.36)
                // фон в форме панели, а содержимое не обрезается — звёздочки Кирби могут вылетать за край
                .background(
                    PixelRect(step: 3).fill(
                        LinearGradient(colors: [Px.nightTop, Px.navy], startPoint: .top, endPoint: .bottom)
                    )
                )
                .overlay(PixelRect(step: 3).strokeBorder(Px.pink, lineWidth: 3))
                .overlay(PixelRect(step: 3).strokeBorder(Px.ink, lineWidth: 1.5).padding(-2))
                .background(PixelRect(step: 3).fill(Px.navy).offset(x: 4, y: 4))
                .assistAnchor("planet")
                .padding(.leading, 8)
                .padding(.top, 8)
                .frame(width: w, height: h, alignment: .topLeading)
                // Луна сидит на полу под окном — она же помощник
                LunaCat()
                    .scaleEffect(1.18, anchor: .bottom)
                    .frame(width: 91, height: 92)
                    .frame(width: 91 * 1.18, height: 92 * 1.18, alignment: .bottom)
                    .assistAnchor("luna")
                    .padding(.leading, w * 0.52 - 91 * 1.18 / 2)
                    .padding(.top, floorY + 6 - 92 * 1.18)
                    .frame(width: w, height: h, alignment: .topLeading)
                // автомат с клешнёй — достаёт «Купить снова»
                VStack(spacing: 2) {
                    CraneMachine(onTap: onCrane)
                        .scaleEffect(0.92, anchor: .topLeading)
                        .frame(width: 130 * 0.92, height: 215 * 0.92, alignment: .topLeading)
                        .overlay(PixelRect(step: 3).strokeBorder(Px.pink, lineWidth: 3))
                        .overlay(PixelRect(step: 3).strokeBorder(Px.ink, lineWidth: 1.5).padding(-2))
                        .background(PixelRect(step: 3).fill(Px.navy).offset(x: 4, y: 4))
                    Text("КУПИТЬ СНОВА: \(store.dueSuggestions.count)")
                        .font(Px.title(6))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 3)
                        .background(PixelRect(step: 1).fill(Px.ink))
                }
                .assistAnchor("crane")
                .padding(.leading, w - 130 * 0.92 - 10)
                .padding(.top, 8)
                .frame(width: w, height: h, alignment: .topLeading)
                // Кирби на звезде летит по полу
            }
        }
        .clipped()
    }

    private func bricks(t: Double) -> some View {
        Canvas { c, size in
            c.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Px.lavender))
            let bw: CGFloat = 40, bh: CGFloat = 18
            var row = 0
            var y: CGFloat = 0
            while y < size.height {
                var x: CGFloat = row % 2 == 0 ? 0 : -bw / 2
                while x < size.width {
                    c.stroke(Path(CGRect(x: x, y: y, width: bw, height: bh)), with: .color(Px.mortar), lineWidth: 2)
                    x += bw
                }
                y += bh
                row += 1
            }
            var rng = SeededRandom(seed: 3)
            for i in 0..<16 {
                let x = rng.next() * size.width, y = rng.next() * size.height * 0.75
                let twinkle = (sin(t * 2.5 + Double(i) * 1.7) + 1) / 2
                let s: CGFloat = i % 3 == 0 ? 3 : 2
                let color = Color.white.opacity(0.3 + twinkle * 0.7)
                c.fill(Path(CGRect(x: x - s / 2, y: y - s * 1.5, width: s, height: s * 3)), with: .color(color))
                c.fill(Path(CGRect(x: x - s * 1.5, y: y - s / 2, width: s * 3, height: s)), with: .color(color))
            }
        }
    }

    private var curtain: some View {
        Canvas { c, size in
            c.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Px.sky))
            var y: CGFloat = 2
            var row = 0
            while y < size.height {
                var x: CGFloat = row % 2 == 0 ? 2 : 6
                while x < size.width {
                    c.fill(Path(CGRect(x: x, y: y, width: 2, height: 2)), with: .color(.white))
                    x += 8
                }
                y += 4
                row += 1
            }
            c.stroke(Path(CGRect(origin: .zero, size: size)), with: .color(Px.ink), lineWidth: 2)
        }
    }

    private func shootingStar(t: Double, width: CGFloat) -> some View {
        let cycle = t.truncatingRemainder(dividingBy: 6) / 1.2
        return Group {
            if cycle < 1 {
                HStack(spacing: 0) {
                    ForEach(0..<4, id: \.self) { i in
                        Rectangle().fill(Color.white.opacity(Double(i + 1) / 4)).frame(width: 4, height: 2)
                    }
                    Rectangle().fill(Px.gold).frame(width: 4, height: 4)
                }
                .rotationEffect(.degrees(25))
                .offset(x: -width / 2 + CGFloat(cycle) * width, y: -20 + CGFloat(cycle) * 30)
            }
        }
    }

    private func hearts(t: Double, w: CGFloat, h: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            ForEach(0..<4, id: \.self) { i in
                let period = 5.0 + Double(i)
                let p = ((t + Double(i) * 1.7).truncatingRemainder(dividingBy: period)) / period
                PixelArt(rows: PxArt.heart, palette: PxArt.palette)
                    .frame(width: 14, height: 13)
                    .opacity(p < 0.85 ? 1 : (1 - p) / 0.15)
                    .offset(x: w * (0.12 + CGFloat(i) * 0.24) + CGFloat(sin(t * 2 + Double(i))) * 6,
                            y: h * (1 - CGFloat(p)) - 10)
            }
        }
    }
}
