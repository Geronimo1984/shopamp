import SwiftUI

/// Шрифты и цвета содержимого окон для каждого скина
struct SkinStyle {
    let font: (CGFloat, Font.Weight) -> Font
    let text: Color
    let secondary: Color
    let accent: Color
    let rowFill: Color
    let rowStroke: Color
    /// Цвет текста на заливке акцентом (по умолчанию — цвет фона строки)
    var onAccent: Color? = nil

    static func of(_ skin: SkinID) -> SkinStyle {
        switch skin {
        case .winamp:
            return SkinStyle(font: { .custom("Arial", size: $0).weight($1) }, text: Winamp.listGreen,
                             secondary: Winamp.listDue, accent: Winamp.white,
                             rowFill: Color(hex: 0x0A0C1E), rowStroke: Winamp.frameLight)
        case .aero:
            return SkinStyle(font: { .system(size: $0, weight: $1) }, text: .black,
                             secondary: Color(hex: 0x5A6470), accent: Aero.xpSelect,
                             rowFill: .white, rowStroke: Aero.xpField)
        case .mac:
            return SkinStyle(font: { Mac.font($0, $1) }, text: Mac.ink,
                             secondary: Mac.ink.opacity(0.65), accent: Mac.ink,
                             rowFill: Mac.paper, rowStroke: Mac.ink)
        case .sims:
            return SkinStyle(font: { Sims.font($0 - 2, $1) }, text: .white,
                             secondary: Color(hex: 0x1F3C78), accent: Sims.link,
                             rowFill: Color.white.opacity(0.12), rowStroke: Sims.panelBorder, onAccent: Sims.ink)
        case .pixel:
            return SkinStyle(font: { Px.body($0, $1) }, text: Px.navy,
                             secondary: Px.ink, accent: Px.pink,
                             rowFill: .white, rowStroke: Px.ink)
        }
    }
}

/// Рамка окна в стиле скина: заголовок, кнопка закрытия, содержимое
struct SkinChrome<Content: View>: View {
    let title: String
    let skin: SkinID
    let onClose: () -> Void
    let content: Content

    init(title: String, skin: SkinID, onClose: @escaping () -> Void, @ViewBuilder content: () -> Content) {
        self.title = title
        self.skin = skin
        self.onClose = onClose
        self.content = content()
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture(perform: onClose)
            window
                .frame(maxWidth: 400)
                .padding(.horizontal, 14)
                .padding(.vertical, 40)
        }
    }

    @ViewBuilder
    private var window: some View {
        switch skin {
        case .winamp:
            VStack(spacing: 0) {
                TitleBar(title: title.uppercased(), showIcon: false, buttons: [.close], onClose: onClose)
                    .frame(height: 26)
                content
                    .padding(10)
                    .background(Color.black)
                    .overlay(Rectangle().strokeBorder(Winamp.frameDark, lineWidth: 2))
                    .padding(10)
            }
            .background(WindowBody(line: 3))
        case .aero:
            XPWindow(title: title, onClose: onClose) { content }
        case .mac:
            MacWindow(title: title, onClose: onClose) { content.padding(10) }
        case .sims:
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Plumbob(mood: 1).frame(width: 16, height: 26)
                    Text(title)
                        .font(Sims.title(18))
                        .foregroundStyle(.white)
                        .shadow(color: Sims.panelBorder, radius: 0, x: 1, y: 1)
                    Spacer()
                    SimsRoundButton(symbol: "xmark", colors: [Color(hex: 0xFF9A8A), Color(hex: 0xC8261A)], size: 32, action: onClose)
                }
                content
            }
            .padding(14)
            .background(SimsPanel(fill: [Color(hex: 0xB5D3FF), Sims.panel], radius: 18))
        case .pixel:
            VStack(spacing: 0) {
                HStack {
                    Text(title.uppercased()).font(Px.title(10)).foregroundStyle(Px.ink).lineLimit(1)
                    Spacer()
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 11, weight: .black))
                            .foregroundStyle(.white)
                            .frame(width: 32, height: 32)
                            .background(PixelRect(step: 2).fill(Px.pink))
                            .overlay(PixelRect(step: 2).strokeBorder(Px.ink, lineWidth: 2))
                    }
                    .buttonStyle(PressScaleStyle())
                }
                .padding(.horizontal, 10)
                .frame(height: 36)
                .background(Color.white)
                Rectangle().fill(Px.ink).frame(height: 3)
                content.padding(12)
            }
            .background(PixelPanel(fill: Px.lavenderLight))
        }
    }
}

/// Маленькая кнопка в стиле скина для окон справки и памяти
struct SkinChip: View {
    let title: String
    let style: SkinStyle
    var filled = false
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            Text(title)
                .font(style.font(14, .semibold))
                .foregroundStyle(filled ? (style.onAccent ?? style.rowFill) : style.text)
                .padding(.horizontal, 9)
                .frame(minWidth: 40, minHeight: 38)
                .background(RoundedRectangle(cornerRadius: 4).fill(filled ? style.accent : style.rowFill))
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(style.rowStroke, lineWidth: 1.5))
        }
        .buttonStyle(PressScaleStyle())
    }
}

// MARK: - Справка

struct HelpView: View {
    @EnvironmentObject var store: ShopStore
    let skin: SkinID

    var body: some View {
        let style = SkinStyle.of(skin)
        SkinChrome(title: "Справка · \(skin.title)", skin: skin, onClose: close) {
            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(Array(HelpContent.entries(for: skin).enumerated()), id: \.offset) { _, entry in
                        HStack(alignment: .top, spacing: 10) {
                            Text(entry.0)
                                .font(style.font(15, .bold))
                                .foregroundStyle(style.accent)
                                .frame(width: 86, alignment: .leading)
                            Text(entry.1)
                                .font(style.font(15, .regular))
                                .foregroundStyle(style.text)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    Text("Общее для всех скинов")
                        .font(style.font(16, .bold))
                        .foregroundStyle(style.accent)
                        .padding(.top, 6)
                    ForEach(Array(HelpContent.common.enumerated()), id: \.offset) { _, line in
                        Text("• " + line)
                            .font(style.font(14, .regular))
                            .foregroundStyle(style.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(4)
            }
            .frame(maxHeight: 520)
        }
    }

    private func close() {
        store.showHelp = false
        store.state.seenHelp = true
    }
}

enum HelpContent {
    static let common = [
        "Карточки товаров — постоянный каталог: базовые товары, ваш список и всё, что вы заведёте сами. Список покупок — только текущий поход в магазин.",
        "По умолчанию список покупок наполняется тем, что пора купить по срокам. Остальное отметьте ☑ в «Карточках». «Новый поход» — список заново по срокам, «Очистить список» — пустой список; карточки при этом не теряются.",
        "Добавить в список — кнопка «Добавить» (ADD, ⏏, конверт, человечек — в зависимости от скина): откроются карточки товаров, отметьте ☑ нужное. Нового товара нет в карточках — «+ Новая карточка» там же.",
        "Изменить товар — нажмите на товар, потом нажмите на него ещё раз: откроется карточка с названием, количеством, «Куплено» и «Удалить». Или кнопка «Изменить» / ✎.",
        "Долгое нажатие на товар — короткое меню товара.",
        "Отделы: у каждого товара есть отдел магазина («Овощи и фрукты», «Молочка и сыры», «Орехи и снеки»…) — он подбирается по названию, сменить можно в карточке или в окне товара. Список покупок идёт по отделам, удобно набирать корзину, проходя магазин. Выключить — меню → «Не группировать по отделам».",
        "Блюда и рецепты (меню → «Блюда и рецепты…» или «🍲 Блюда» в карточках): соберите блюдо из карточек или из списка покупок, добавьте заметку или рецепт. У каждого продукта видно: ✓ — в корзине, • — в списке, + — не хватает; «+ В список» добавит недостающее в список, «🛒 Всё в корзину» — сразу отметит все продукты блюда купленными. Меню → «Список по блюдам» — список и корзина разложены по блюдам, нажатие на заголовок блюда открывает рецепт.",
        "Ориентировочная цена за штуку задаётся в карточке товара или в окне товара («Цена ~»). Сумма корзины — купленное в этом походе, рядом — сколько стоит весь список. Цена запоминается в карточке и подставляется в следующие походы.",
        "Купленное никогда не удаляется само: оно зачёркнуто и остаётся в списке. Снять все отметки — меню → «Новый поход». Удалить товар — только кнопкой «Удалить».",
        "«Купить снова» — товары, которые вы покупаете регулярно и которые, по расчёту, уже заканчиваются. Для каждого товара можно задать «раз в N дней» в окне «Купить снова» (меню → «Настроить «Купить снова»…»). Без настройки интервал считается сам после покупок в 2 разных дня.",
    ]

    static func entries(for skin: SkinID) -> [(String, String)] {
        switch skin {
        case .winamp:
            return [
                ("?", "эта справка (кнопка в заголовке окна)"),
                ("молния", "смена скина (и значок слева в заголовке)"),
                ("02:53", "куплено : всего. Нажмите — покажет, сколько осталось"),
                ("строка", "выбранный товар и что пора купить снова"),
                ("шт / снова", "сколько осталось купить и сколько товаров в «Купить снова»"),
                ("ручн / авто", "выключить или включить подсказки «Купить снова»"),
                ("оранжевый", "ползунок количества выбранного товара (1–10)"),
                ("EQ / PL", "показать окно «Купить снова» (эквалайзер) и список"),
                ("⏮ ⏭", "предыдущий / следующий товар"),
                ("▶ / ❚❚", "отметить купленным (и перейти дальше) / снять отметку"),
                ("■", "закончить покупки — купленное остаётся в списке зачёркнутым"),
                ("⏏ / ADD", "добавить из карточек товаров"),
                ("REM / EDIT", "удалить / изменить выбранный товар"),
                ("SHUFFLE", "купленное — в конец списка"),
                ("🔁", "добавить всё из «Купить снова» (лампочка — есть что добавить)"),
                ("эквалайзер", "ползунок = регулярный товар, чем выше — тем скорее закончится. Нажатие добавляет его. PRESETS — настроить интервалы"),
                ("MISC", "меню; LIST OPTS — купленное в конец"),
            ]
        case .aero:
            return [
                ("search", "поиск по списку"),
                ("? ✎ ← →", "справка / изменить выбранный товар / предыдущий / следующий"),
                ("▶ в плеере", "СТАРТ — режим покупок (экран входа Windows XP)"),
                ("добавить", "подобрать товары из карточек (человечек)"),
                ("снова", "добавить всё из «Купить снова» (диск)"),
                ("Карточки", "каталог товаров: что взять в поход, сроки, иконки, новые карточки"),
                ("меню", "все действия (облачка)"),
                ("список", "нажатие — выбрать, ещё нажатие — карточка товара, двойное — куплено"),
                ("пузыри", "заканчивается: нажмите на пузырь, чтобы добавить; ⚙ — настроить «Купить снова»"),
                ("сменить скин", "кнопка внизу экрана"),
                ("Покупки", "барабан крутится свайпом вверх-вниз; свайп товара вправо — в корзину, влево — вернуть; зелёная стрелка — тоже в корзину; оранжевая кнопка — закончить"),
            ]
        case .mac:
            return [
                ("Добавить", "иконка-конверт: подобрать товары из карточек"),
                ("Купить снова", "иконка-карточка: добавить всё, что заканчивается"),
                ("Карточки", "папка: каталог товаров — отметьте, что взять в поход"),
                ("Справка", "эта справка; «Меню» — все действия"),
                ("Control P.", "подсказки вкл/выкл, купленное в конец, прогресс; ползунок справа — количество выбранного товара"),
                ("☐", "чекбокс у товара — куплено"),
                ("▽ папки", "свернуть/развернуть «Купить», «В корзине», «Купить снова»"),
                ("Изменить", "карточка выбранного товара; «Готово» — закончить покупки, купленное останется зачёркнутым"),
                ("скин ▸ ■", "кнопка на корпусе — смена скина"),
                ("скрепка", "нажмите на помощника — он подскажет, что делает каждая кнопка"),
            ]
        case .sims:
            return [
                ("меню", "Добавить, Купить снова, Порядок (купленное в конец), Карточки (каталог товаров и сроки), Скины, Справка"),
                ("?", "жёлтый значок слева — эта справка"),
                ("пламбоб", "цвет — прогресс покупок: красный, жёлтый, зелёный"),
                ("ADD ▶ NOW", "добавить из карточек товаров"),
                ("КУПИТЬ СНОВА!", "красный блок: добавить всё, что заканчивается"),
                ("✎ / ✓", "у каждого товара: изменить / отметить купленным"),
                ("Новости", "недавние покупки — нажмите, чтобы добавить снова"),
            ]
        case .pixel:
            return [
                ("ДОБАВИТЬ", "подобрать предметы из карточек"),
                ("ИЗМЕНИТЬ", "карточка выбранного предмета: название, количество, удалить"),
                ("КАРТОЧКИ", "каталог товаров: что взять в поход, сроки, иконки"),
                ("СКИН / СПРАВКА / МЕНЮ", "смена скина, эта справка, все действия"),
                ("автомат", "клешня достаёт в рюкзак всё, что пора купить снова"),
                ("ячейка", "нажатие — выбрать, ещё нажатие — карточка, двойное — в рюкзак (куплено)"),
                ("В РЮКЗАК", "отметить купленным; − + — количество"),
                ("Кирби, брошь", "просто для настроения — нажмите на них"),
                ("HP / MP", "HP — сколько куплено, MP — сколько купить снова, EXP — все покупки"),
            ]
        }
    }
}

// MARK: - Карточки товаров

/// Карточки товаров: постоянный каталог. Отсюда товары попадают в список покупок (текущий поход),
/// здесь же — сроки «купить снова», иконка, новые карточки и удаление
struct MemoryView: View {
    @EnvironmentObject var store: ShopStore
    let skin: SkinID
    @State private var search = ""
    @State private var expanded: String?
    @State private var showDueOnly = false
    @State private var priceDrafts: [String: String] = [:]
    @FocusState private var searchFocused: Bool

    var body: some View {
        let style = SkinStyle.of(skin)
        let query = search.trimmingCharacters(in: .whitespaces).lowercased()
        let cards = store.cards.filter {
            (query.isEmpty || $0.name.lowercased().contains(query)) && (!showDueOnly || ($0.daysLeft() ?? 1) == 0)
        }
        let exists = store.state.memory[ShopStore.key(search)] != nil
        SkinChrome(title: "Карточки товаров", skin: skin, onClose: { store.isEditingMemory = false }) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Отметьте ☑, что взять в этот поход. Нажмите на карточку — цена, сроки, иконка, удаление. Нет нужного товара — «+ Новая карточка».")
                    .font(style.font(13, .regular))
                    .foregroundStyle(style.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 6) {
                    TextField("", text: $search, prompt: Text("Найти или новая карточка").foregroundColor(style.secondary))
                        .font(style.font(15, .regular))
                        .foregroundStyle(style.text)
                        .padding(.horizontal, 8)
                        .frame(height: 38)
                        .background(RoundedRectangle(cornerRadius: 4).fill(style.rowFill))
                        .overlay(RoundedRectangle(cornerRadius: 4).stroke(style.rowStroke, lineWidth: 1.5))
                        .focused($searchFocused)
                        .submitLabel(.done)
                        .onAppear {
                            // для скриншота клавиатуры: -kbd
                            if ProcessInfo.processInfo.arguments.contains("-kbd") {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { searchFocused = true }
                            }
                        }
                        .onSubmit { if !query.isEmpty && !exists { createCard() } }
                }
                // создание новой карточки: из того, что введено в поле, или фокус на поле
                HStack(spacing: 6) {
                SkinChip(title: !query.isEmpty && !exists ? "+ Новая карточка «\(search.trimmingCharacters(in: .whitespaces))»" : "+ Новая карточка",
                         style: style, filled: true) {
                    if !query.isEmpty && !exists {
                        createCard()
                    } else {
                        search = ""
                        searchFocused = true
                        store.notify("Введите название новой карточки в поле поиска")
                    }
                }
                .layoutPriority(1)
                SkinChip(title: "🍲 Блюда (\(store.state.dishes.count))", style: style) { store.openDishes() }
                Spacer(minLength: 0)
                }
                HStack(spacing: 6) {
                    SkinChip(title: "Все (\(store.cards.count))", style: style, filled: !showDueOnly) { showDueOnly = false }
                    SkinChip(title: "Пора купить (\(store.cards.filter { ($0.daysLeft() ?? 1) == 0 }.count))", style: style, filled: showDueOnly) { showDueOnly = true }
                    Spacer(minLength: 0)
                }
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(spacing: 6) {
                        ForEach(cards, id: \.name) { memory in
                            row(memory, style)
                        }
                        if cards.isEmpty {
                            Text(query.isEmpty ? "Карточек нет" : "Не найдено — нажмите «+ Новая карточка»")
                                .font(style.font(14, .regular))
                                .foregroundStyle(style.secondary)
                                .padding(8)
                        }
                    }
                }
                .frame(maxHeight: 420)
                HStack(spacing: 6) {
                    SkinChip(title: "Новый поход", style: style) { store.startNewTrip() }
                    SkinChip(title: "Очистить список", style: style) {
                        store.clearAll()
                        store.notify("Список покупок очищен. Карточки на месте")
                    }
                    Spacer(minLength: 0)
                    SkinChip(title: "Готово", style: style, filled: true) { store.isEditingMemory = false }
                }
            }
        }
    }

    private func createCard() {
        let name = search.trimmingCharacters(in: .whitespacesAndNewlines)
        guard store.addCard(name) else { return }
        store.toggleInList(name)
        store.notify("Карточка «\(name)» создана и добавлена в список")
        search = ""
        searchFocused = false
    }

    private func row(_ memory: ItemMemory, _ style: SkinStyle) -> some View {
        let inList = store.isInList(memory.name)
        let open = expanded == memory.name
        return VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                // в список / из списка
                Button {
                    Haptics.tap()
                    store.toggleInList(memory.name)
                } label: {
                    Image(systemName: inList ? "checkmark.square.fill" : "square")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(inList ? style.accent : style.secondary)
                        .frame(width: 36, height: 36)
                        .contentShape(Rectangle())
                }
                .buttonStyle(SkinPressStyle(skin: skin))
                ProductImage(name: memory.name, size: 28)
                VStack(alignment: .leading, spacing: 1) {
                    Text(memory.name)
                        .font(style.font(15, .bold))
                        .foregroundStyle(style.text)
                        .lineLimit(1)
                    Text(shortStatus(memory))
                        .font(style.font(11, .regular))
                        .foregroundStyle(style.secondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 2)
                Image(systemName: open ? "chevron.up" : "chevron.down")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(style.secondary)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.easeOut(duration: 0.15)) { expanded = open ? nil : memory.name }
            }
            if open {
                Text(status(memory))
                    .font(style.font(12, .regular))
                    .foregroundStyle(style.secondary)
                HStack(spacing: 6) {
                    Text("раз в").font(style.font(14, .regular)).foregroundStyle(style.text)
                    SkinChip(title: "−", style: style) { change(memory, by: -1) }
                    Text(memory.interval.map { "\(Int($0.rounded())) дн" } ?? "— дн")
                        .font(style.font(15, .bold))
                        .foregroundStyle(style.text)
                        .frame(minWidth: 48)
                    SkinChip(title: "+", style: style) { change(memory, by: 1) }
                    SkinChip(title: "авто", style: style, filled: memory.customInterval == nil) {
                        store.setInterval(memory.name, days: nil)
                    }
                    Spacer(minLength: 0)
                }
                CategoryChip(skin: skin, name: memory.name)
                PriceField(skin: skin, text: Binding(
                    get: { priceDrafts[memory.name] ?? ShopStore.priceText(memory.price) },
                    set: { value in
                        priceDrafts[memory.name] = value
                        store.setPrice(memory.name, ShopStore.parsePrice(value))
                    }))
                HStack(spacing: 6) {
                    SkinChip(title: memory.remind ? "🔔 напоминать" : "🔕 не напоминать", style: style, filled: memory.remind) {
                        store.toggleRemind(memory.name)
                    }
                    SkinChip(title: "Иконка", style: style) { store.iconPickerName = memory.name }
                    Spacer(minLength: 0)
                    SkinChip(title: "Удалить", style: style) {
                        store.deleteCard(memory.name)
                        expanded = nil
                    }
                }
                if memory.interval != nil, memory.lastPurchase == nil {
                    SkinChip(title: "Купил сегодня — начать отсчёт", style: style) {
                        store.markPurchasedToday(memory.name)
                    }
                }
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(RoundedRectangle(cornerRadius: 4).fill(style.rowFill))
        .overlay(RoundedRectangle(cornerRadius: 4).stroke(inList ? style.accent : style.rowStroke, lineWidth: inList ? 2 : 1.5))
    }

    private func shortStatus(_ memory: ItemMemory) -> String {
        let price = " · " + store.category(memory.name).emoji + (memory.price.map { " · ~" + ShopStore.rub($0) } ?? "")
        if !memory.remind { return "без напоминаний" + price }
        if let days = memory.daysLeft() { return (days == 0 ? "пора купить!" : "через \(days) дн") + price }
        if let i = memory.interval { return "раз в \(Int(i.rounded())) дн" + price }
        return "срок не задан" + price
    }

    private func change(_ memory: ItemMemory, by step: Double) {
        let current = memory.interval ?? 7
        store.setInterval(memory.name, days: (current.rounded() + step))
    }

    private func status(_ memory: ItemMemory) -> String {
        var parts: [String] = []
        if let last = memory.lastPurchase {
            parts.append("последняя покупка: " + last.formatted(.dateTime.day().month(.abbreviated)))
        } else {
            parts.append("ещё не покупали")
        }
        if !memory.remind {
            parts.append("не напоминать")
        } else if let days = memory.daysLeft() {
            parts.append(days == 0 ? "пора купить!" : "купить через \(days) дн")
        } else if memory.interval == nil {
            parts.append("интервал не задан")
        } else {
            parts.append("отсчёт после первой покупки")
        }
        return parts.joined(separator: " · ")
    }
}

// MARK: - Выбор иконки товара

struct IconPickerView: View {
    @EnvironmentObject var store: ShopStore
    let skin: SkinID
    let name: String

    var body: some View {
        let style = SkinStyle.of(skin)
        let current = store.state.iconOverrides[ShopStore.key(name)]
        SkinChrome(title: "Иконка · \(name)", skin: skin, onClose: { store.iconPickerName = nil }) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Выберите картинку для товара. «Авто» — подбор по названию.")
                    .font(style.font(13, .regular))
                    .foregroundStyle(style.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                ScrollView(.vertical, showsIndicators: true) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 5), spacing: 8) {
                        cell(asset: ProductIcon.asset(for: name), selected: current == nil, label: "Авто") {
                            store.setIcon(nil, for: name)
                        }
                        ForEach(ProductIcon.catalog, id: \.self) { asset in
                            cell(asset: asset, selected: current == asset, label: nil) {
                                store.setIcon(asset, for: name)
                            }
                        }
                    }
                    .padding(4)
                }
                .frame(maxHeight: 440)
            }
        }
    }

    private func cell(asset: String, selected: Bool, label: String?, action: @escaping () -> Void) -> some View {
        let style = SkinStyle.of(skin)
        return Button {
            Haptics.tap()
            action()
            store.iconPickerName = nil
        } label: {
            ZStack(alignment: .bottom) {
                SkinTileBackground(skin: skin, selected: selected)
                ProductImage(name: name, size: 40, pixelated: skin == .pixel, asset: asset)
                    .grayscale(skin == .mac ? 1 : 0)
                    .contrast(skin == .mac ? 1.4 : 1)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                if let label {
                    Text(label)
                        .font(style.font(10, .bold))
                        .foregroundStyle(selected ? style.rowFill : style.text)
                        .padding(.horizontal, 4)
                        .background(selected ? style.accent : style.rowFill)
                        .padding(.bottom, 2)
                }
            }
            .aspectRatio(1, contentMode: .fit)
        }
        .buttonStyle(SkinPressStyle(skin: skin))
    }

}

/// Фон плитки выбора (иконка товара, картинка блюда, продукт) в стиле скина
struct SkinTileBackground: View {
    let skin: SkinID
    let selected: Bool

    var body: some View {
        switch skin {
        case .pixel:
            ZStack {
                PixelRect(step: 3).fill(selected ? Px.pinkLight : .white)
                PixelRect(step: 3).strokeBorder(selected ? Px.pink : Px.ink, lineWidth: selected ? 3 : 2)
            }
        case .mac:
            Rectangle().fill(Mac.paper)
                .overlay(Rectangle().stroke(Mac.ink, lineWidth: selected ? 3 : 1.5))
        case .winamp:
            Rectangle().fill(Color.black)
                .overlay(Rectangle().stroke(selected ? Winamp.green : Winamp.frameLight, lineWidth: selected ? 3 : 1))
        case .aero:
            RoundedRectangle(cornerRadius: 8)
                .fill(LinearGradient(colors: selected ? [Color(hex: 0xFFE7A8), Color(hex: 0xF5B94A)] : [.white, Color(hex: 0xE3ECF7)],
                                     startPoint: .top, endPoint: .bottom))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(selected ? Color(hex: 0xE08A12) : Aero.xpField, lineWidth: selected ? 2.5 : 1))
        case .sims:
            RoundedRectangle(cornerRadius: 10)
                .fill(selected ? Sims.panelBorder.opacity(0.7) : .white.opacity(0.18))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(selected ? Sims.link : .white.opacity(0.4), lineWidth: selected ? 2.5 : 1))
        }
    }
}

/// Кнопка «Иконка» для окна добавления/изменения товара
struct IconChooserButton: View {
    @EnvironmentObject var store: ShopStore
    let skin: SkinID
    let name: String

    var body: some View {
        let style = SkinStyle.of(skin)
        Button {
            Haptics.tap()
            guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
                store.notify("Сначала введите название товара")
                return
            }
            store.iconPickerName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        } label: {
            HStack(spacing: 8) {
                ProductImage(name: name.isEmpty ? "?" : name, size: 30, pixelated: skin == .pixel)
                    .grayscale(skin == .mac ? 1 : 0)
                Text("Иконка: выбрать…")
                    .font(style.font(14, .semibold))
                    .foregroundStyle(style.text)
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(style.secondary)
            }
            .padding(.horizontal, 10)
            .frame(height: 44)
            .background(RoundedRectangle(cornerRadius: skin == .mac || skin == .winamp ? 0 : 6).fill(style.rowFill))
            .overlay(RoundedRectangle(cornerRadius: skin == .mac || skin == .winamp ? 0 : 6).stroke(style.rowStroke, lineWidth: 1.5))
        }
        .buttonStyle(SkinPressStyle(skin: skin))
    }
}

// MARK: - Поле цены

/// Ввод ориентировочной цены за штуку в стиле скина
struct PriceField: View {
    let skin: SkinID
    @Binding var text: String
    var qty: Int = 1

    var body: some View {
        let style = SkinStyle.of(skin)
        HStack(spacing: 6) {
            Text("Цена ~").font(style.font(14, .regular)).foregroundStyle(style.text)
            TextField("", text: $text, prompt: Text("0").foregroundColor(style.secondary))
                .font(style.font(15, .bold))
                .foregroundStyle(style.text)
                .multilineTextAlignment(.trailing)
                #if os(iOS)
                .keyboardType(.decimalPad)
                #endif
                .padding(.horizontal, 6)
                .frame(width: 84, height: 36)
                .background(RoundedRectangle(cornerRadius: 4).fill(style.rowFill))
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(style.rowStroke, lineWidth: 1.5))
            Text("₽ за шт").font(style.font(13, .regular)).foregroundStyle(style.secondary)
            if let v = ShopStore.parsePrice(text), qty > 1 {
                Text("= " + ShopStore.rub(v * Double(qty))).font(style.font(13, .bold)).foregroundStyle(style.accent)
            }
            Spacer(minLength: 0)
        }
    }
}
