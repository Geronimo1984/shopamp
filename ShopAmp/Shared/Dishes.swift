import SwiftUI

/// Готовое блюдо: набор карточек товаров и заметка или рецепт
struct Dish: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var emoji: String = "🍲"
    /// Названия карточек товаров
    var ingredients: [String] = []
    var note: String = ""

    static let emojis = ["🍲", "🥗", "🍝", "🍳", "🥘", "🍛", "🍜", "🥪", "🍕", "🌮", "🌯", "🥙", "🍔", "🌭", "🥞", "🧇",
                         "🍰", "🧁", "🥧", "🍪", "🍣", "🍱", "🥟", "🍤", "🍖", "🍗", "🥩", "🐟", "🥣", "🫕", "🥐", "🍹",
                         "🍚", "🍙", "🥡", "🦪", "🫔", "🧆", "🥨", "🥯", "🍿", "🍠", "🫓", "🍮", "🍨", "🍧", "🍩", "🍢",
                         "🍡", "🍷", "🍵", "☕"]
}

/// Раздел списка покупок: отдел магазина или блюдо
struct ListSection: Equatable, Hashable {
    let id: String
    let emoji: String
    let title: String
    var dishID: UUID? = nil
    /// Подпись раздела в режиме покупок: «отдел» или «блюдо»
    var kind: String { dishID == nil && id != Self.noDishID ? "отдел" : "блюдо" }

    static let noDishID = "dish:none"
    static let noDish = ListSection(id: noDishID, emoji: "🛒", title: "Без блюда")

    init(id: String, emoji: String, title: String, dishID: UUID? = nil) {
        self.id = id
        self.emoji = emoji
        self.title = title
        self.dishID = dishID
    }

    init(_ category: ShopCategory) {
        self.init(id: "cat:" + category.rawValue, emoji: category.emoji, title: category.title)
    }

    init(_ dish: Dish) {
        self.init(id: "dish:" + dish.id.uuidString, emoji: dish.emoji, title: dish.name, dishID: dish.id)
    }
}

extension ShopStore {
    // MARK: - Разделы списка

    /// Список разбит на разделы (по блюдам или по отделам)
    var isGrouped: Bool { state.groupByDish || state.groupByCategory }

    /// Первое блюдо, в которое входит товар
    func dish(containing name: String) -> Dish? {
        let key = Self.key(name)
        return state.dishes.first { $0.ingredients.contains { Self.key($0) == key } }
    }

    /// Раздел товара в текущем режиме: блюдо, «Без блюда» или отдел
    func section(for name: String) -> ListSection {
        if state.groupByDish {
            return dish(containing: name).map(ListSection.init) ?? .noDish
        }
        return ListSection(category(name))
    }

    /// Порядок раздела и место товара внутри него — для сортировки списка
    func sectionOrder(for name: String) -> (Int, Int) {
        let catOrder = category(name).order
        guard state.groupByDish else { return (catOrder, 0) }
        let key = Self.key(name)
        for (i, dish) in state.dishes.enumerated() {
            if let j = dish.ingredients.firstIndex(where: { Self.key($0) == key }) { return (i, j) }
        }
        // без блюда — в конце, по отделам (если они включены)
        return (state.dishes.count, state.groupByCategory ? catOrder : 0)
    }

    /// Нужен ли заголовок раздела перед строкой (список сгруппирован и раздел сменился)
    func sectionHeader(_ list: [ShopItem], at index: Int) -> ListSection? {
        guard isGrouped, index < list.count else { return nil }
        let current = section(for: list[index].name)
        if index == 0 { return current }
        return section(for: list[index - 1].name) == current ? nil : current
    }

    /// Товары, разложенные по разделам в порядке списка
    func sections(_ items: [ShopItem]) -> [(ListSection, [ShopItem])] {
        var result: [(ListSection, [ShopItem])] = []
        for item in items {
            let s = section(for: item.name)
            if let last = result.indices.last, result[last].0 == s {
                result[last].1.append(item)
            } else {
                result.append((s, [item]))
            }
        }
        return result
    }

    // MARK: - Блюда

    enum IngredientStatus { case bought, inList, missing }

    func status(ofIngredient name: String) -> IngredientStatus {
        let key = Self.key(name)
        if state.items.contains(where: { !$0.bought && Self.key($0.name) == key }) { return .inList }
        if state.items.contains(where: { $0.bought && Self.key($0.name) == key }) { return .bought }
        return .missing
    }

    func missingIngredients(_ dish: Dish) -> [String] {
        dish.ingredients.filter { status(ofIngredient: $0) == .missing }
    }

    /// Стоимость блюда по ценам карточек (только продукты с ценой)
    func dishCost(_ dish: Dish) -> Double? {
        let prices = dish.ingredients.compactMap { price($0) }
        return prices.isEmpty ? nil : prices.reduce(0, +)
    }

    func saveDish(_ draft: Dish) {
        var dish = draft
        dish.name = dish.name.trimmingCharacters(in: .whitespacesAndNewlines)
        dish.note = dish.note.trimmingCharacters(in: .whitespacesAndNewlines)
        var s = state
        // продукты блюда — это карточки: новых названий в каталоге быть не должно
        for name in dish.ingredients where s.memory[Self.key(name)] == nil {
            s.memory[Self.key(name)] = ItemMemory(name: name)
        }
        if let i = s.dishes.firstIndex(where: { $0.id == dish.id }) {
            s.dishes[i] = dish
        } else {
            s.dishes.append(dish)
        }
        state = s
        openDishID = dish.id
    }

    func deleteDish(_ id: UUID) {
        guard let dish = state.dishes.first(where: { $0.id == id }) else { return }
        menu = SkinMenu(title: "Удалить блюдо «\(dish.name)»?", actions: [
            MenuAction(title: "Удалить блюдо (карточки товаров останутся)", destructive: true) { [weak self] in
                self?.state.dishes.removeAll { $0.id == id }
                self?.notify("Блюдо «\(dish.name)» удалено")
            },
            MenuAction(title: "Отмена") {},
        ])
    }

    /// Добавить в список покупок всё, чего не хватает для блюда
    func addDishToList(_ id: UUID) {
        guard let dish = state.dishes.first(where: { $0.id == id }) else { return }
        let missing = missingIngredients(dish)
        guard !missing.isEmpty else {
            notify("Для «\(dish.name)» всё уже в списке или в корзине")
            return
        }
        for name in missing { add(name) }
        notify("В список добавлено для «\(dish.name)»: " + missing.joined(separator: ", "))
    }

    /// Все продукты блюда — сразу в корзину (купленными); недостающие сначала попадают в список
    func putDishInCart(_ id: UUID) {
        guard let dish = state.dishes.first(where: { $0.id == id }) else { return }
        var moved: [String] = []
        for name in dish.ingredients where status(ofIngredient: name) != .bought {
            let key = Self.key(name)
            if !state.items.contains(where: { !$0.bought && Self.key($0.name) == key }) { add(name) }
            if let item = state.items.first(where: { !$0.bought && Self.key($0.name) == key }) {
                setBought(item.id, true)
                moved.append(name)
            }
        }
        notify(moved.isEmpty
               ? "Для «\(dish.name)» всё уже в корзине"
               : "В корзину для «\(dish.name)»: " + moved.joined(separator: ", "))
    }

    func newDish(fromList: Bool = false) {
        let names = fromList ? state.items.filter { !$0.bought }.map(\.name) : []
        editingDish = Dish(name: "", ingredients: names)
    }

    func openDishes(_ id: UUID? = nil) {
        openDishID = id
        isViewingDishes = true
    }

    func toggleGroupByDish() {
        state.groupByDish.toggle()
        if state.groupByDish && state.dishes.isEmpty {
            notify("Блюд пока нет — создайте их в «Блюда и рецепты». Сейчас весь список в разделе «Без блюда»")
        } else {
            notify(state.groupByDish ? "Список по блюдам" : (state.groupByCategory ? "Список по отделам" : "Список без разделов"))
        }
    }
}

// MARK: - Окно «Блюда и рецепты»

struct DishesView: View {
    @EnvironmentObject var store: ShopStore
    let skin: SkinID

    var body: some View {
        let style = SkinStyle.of(skin)
        SkinChrome(title: "Блюда и рецепты", skin: skin, onClose: { store.isViewingDishes = false }) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Соберите блюдо из карточек или из списка покупок, добавьте заметку или рецепт. ✓ — в корзине, • — в списке, + — не хватает.")
                    .font(style.font(13, .regular))
                    .foregroundStyle(style.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                FlowLayout(spacing: 6, lineSpacing: 6) {
                    SkinChip(title: "+ Новое блюдо", style: style, filled: true) { store.newDish() }
                    SkinChip(title: "+ Из списка покупок", style: style) {
                        if store.state.items.contains(where: { !$0.bought }) {
                            store.newDish(fromList: true)
                        } else {
                            store.notify("В списке нет некупленных товаров — выберите продукты из карточек")
                            store.newDish()
                        }
                    }
                    SkinChip(title: store.state.groupByDish ? "☑ Список по блюдам" : "☐ Список по блюдам",
                             style: style, filled: store.state.groupByDish) { store.toggleGroupByDish() }
                }
                ScrollViewReader { proxy in
                    ScrollView(.vertical, showsIndicators: true) {
                        VStack(spacing: 6) {
                            ForEach(store.state.dishes) { dish in
                                DishRow(skin: skin, dish: dish).id(dish.id)
                            }
                            if store.state.dishes.isEmpty {
                                Text("Блюд пока нет. Нажмите «+ Новое блюдо» — например, «Салат с фетой»: огурцы, помидоры, фета, маслины.")
                                    .font(style.font(14, .regular))
                                    .foregroundStyle(style.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .padding(8)
                            }
                        }
                    }
                    .frame(maxHeight: 440)
                    .onAppear {
                        if let id = store.openDishID { proxy.scrollTo(id, anchor: .top) }
                    }
                }
                HStack {
                    Spacer()
                    SkinChip(title: "Готово", style: style, filled: true) { store.isViewingDishes = false }
                }
            }
        }
    }
}

/// Блюдо в окне «Блюда и рецепты»: заголовок, продукты со статусом, рецепт
private struct DishRow: View {
    @EnvironmentObject var store: ShopStore
    let skin: SkinID
    let dish: Dish

    var body: some View {
        let style = SkinStyle.of(skin)
        let open = store.openDishID == dish.id
        let missing = store.missingIngredients(dish).count
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(dish.emoji).font(.system(size: 26))
                VStack(alignment: .leading, spacing: 1) {
                    Text(dish.name)
                        .font(style.font(16, .bold))
                        .foregroundStyle(style.text)
                        .lineLimit(1)
                    Text(summary(missing: missing))
                        .font(style.font(11, .regular))
                        .foregroundStyle(style.secondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 2)
                if !dish.note.isEmpty { Text("📖").font(.system(size: 14)) }
                Image(systemName: open ? "chevron.up" : "chevron.down")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(style.secondary)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.easeOut(duration: 0.15)) { store.openDishID = open ? nil : dish.id }
            }
            if open {
                FlowLayout(spacing: 6, lineSpacing: 6) {
                    ForEach(dish.ingredients, id: \.self) { name in
                        ingredientChip(name, style)
                    }
                }
                if !dish.note.isEmpty {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Заметка / рецепт")
                            .font(style.font(12, .bold))
                            .foregroundStyle(style.accent)
                        Text(dish.note)
                            .font(style.font(14, .regular))
                            .foregroundStyle(style.text)
                            .fixedSize(horizontal: false, vertical: true)
                            .textSelection(.enabled)
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(style.rowStroke.opacity(0.6), style: StrokeStyle(lineWidth: 1, dash: [4, 3])))
                }
                let notInCart = dish.ingredients.filter { store.status(ofIngredient: $0) != .bought }.count
                FlowLayout(spacing: 6, lineSpacing: 6) {
                    SkinChip(title: notInCart > 0 ? "🛒 Всё в корзину (\(notInCart))" : "🛒 Всё в корзине ✓",
                             style: style, filled: notInCart > 0) { store.putDishInCart(dish.id) }
                    SkinChip(title: missing > 0 ? "+ В список (\(missing))" : "Всё в списке ✓",
                             style: style) { store.addDishToList(dish.id) }
                    SkinChip(title: "Изменить", style: style) { store.editingDish = dish }
                    SkinChip(title: "Удалить", style: style) { store.deleteDish(dish.id) }
                }
            }
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 4).fill(style.rowFill))
        .overlay(RoundedRectangle(cornerRadius: 4).stroke(open ? style.accent : style.rowStroke, lineWidth: open ? 2 : 1.5))
    }

    private func summary(missing: Int) -> String {
        var parts = ["\(dish.ingredients.count) прод."]
        let bought = dish.ingredients.filter { store.status(ofIngredient: $0) == .bought }.count
        if bought > 0 { parts.append("в корзине \(bought)") }
        parts.append(missing == 0 ? "всё есть в списке" : "не хватает \(missing)")
        if let cost = store.dishCost(dish) { parts.append("~" + ShopStore.total(cost)) }
        return parts.joined(separator: " · ")
    }

    /// Продукт блюда: нажатие добавляет в список / убирает из списка
    private func ingredientChip(_ name: String, _ style: SkinStyle) -> some View {
        let status = store.status(ofIngredient: name)
        let mark: String = { switch status { case .bought: return "✓"; case .inList: return "•"; case .missing: return "+" } }()
        return Button {
            Haptics.tap()
            switch status {
            case .missing: store.add(name)
            case .inList: store.toggleInList(name)
            case .bought: store.notify("«\(name)» уже в корзине")
            }
        } label: {
            HStack(spacing: 5) {
                Text(mark).font(style.font(13, .bold)).foregroundStyle(status == .missing ? style.secondary : style.accent)
                ProductImage(name: name, size: 20, pixelated: skin == .pixel)
                    .grayscale(skin == .mac ? 1 : 0)
                Text(name)
                    .font(style.font(13, .semibold))
                    .foregroundStyle(style.text)
                    .strikethrough(status == .bought, color: style.text)
                    .lineLimit(1)
            }
            .padding(.horizontal, 8)
            .frame(minHeight: 34)
            .background(RoundedRectangle(cornerRadius: 4).fill(style.rowFill))
            .overlay(RoundedRectangle(cornerRadius: 4).stroke(status == .missing ? style.rowStroke.opacity(0.5) : style.accent,
                                                              style: StrokeStyle(lineWidth: 1.5, dash: status == .missing ? [4, 3] : [])))
            .opacity(status == .bought ? 0.7 : 1)
        }
        .buttonStyle(SkinPressStyle(skin: skin))
    }
}

// MARK: - Редактор блюда

struct DishEditorView: View {
    @EnvironmentObject var store: ShopStore
    let skin: SkinID
    @State var draft: Dish
    @State private var fromList = true
    @State private var search = ""

    private var isNew: Bool { !store.state.dishes.contains { $0.id == draft.id } }

    var body: some View {
        let style = SkinStyle.of(skin)
        SkinChrome(title: isNew ? "Новое блюдо" : "Блюдо", skin: skin, onClose: { store.editingDish = nil }) {
            VStack(alignment: .leading, spacing: 8) {
                ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(alignment: .leading, spacing: 10) {
                        field(TextField("", text: $draft.name, prompt: Text("Название, например «Салат с фетой»").foregroundColor(style.secondary)), style)
                        Text("Картинка блюда")
                            .font(style.font(13, .bold))
                            .foregroundStyle(style.text)
                        // плитка картинок, выбранная — в рамке
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 8), spacing: 6) {
                            ForEach(Dish.emojis, id: \.self) { e in
                                Button {
                                    Haptics.tap()
                                    draft.emoji = e
                                } label: {
                                    ZStack {
                                        SkinTileBackground(skin: skin, selected: e == draft.emoji)
                                        Text(e).font(.system(size: 22))
                                    }
                                    .aspectRatio(1, contentMode: .fit)
                                }
                                .buttonStyle(SkinPressStyle(skin: skin))
                            }
                        }
                        .padding(2)
                        Text("Заметка или рецепт")
                            .font(style.font(13, .bold))
                            .foregroundStyle(style.text)
                        TextEditor(text: $draft.note)
                            .font(style.font(14, .regular))
                            .foregroundStyle(style.text)
                            .scrollContentBackground(.hidden)
                            .padding(4)
                            .frame(minHeight: 96, maxHeight: 160)
                            .background(RoundedRectangle(cornerRadius: 4).fill(style.rowFill))
                            .overlay(RoundedRectangle(cornerRadius: 4).stroke(style.rowStroke, lineWidth: 1.5))
                            .overlay(alignment: .topLeading) {
                                if draft.note.isEmpty {
                                    Text("Как готовить, на сколько порций, что взять дополнительно…")
                                        .font(style.font(13, .regular))
                                        .foregroundStyle(style.secondary)
                                        .padding(10)
                                        .allowsHitTesting(false)
                                }
                            }
                        Text("Продукты (\(draft.ingredients.count))" + (draft.ingredients.isEmpty ? "" : " — нажмите, чтобы убрать"))
                            .font(style.font(13, .bold))
                            .foregroundStyle(style.text)
                        if draft.ingredients.isEmpty {
                            Text("Выберите продукты ниже")
                                .font(style.font(13, .regular))
                                .foregroundStyle(style.secondary)
                        } else {
                            FlowLayout(spacing: 6, lineSpacing: 6) {
                                ForEach(draft.ingredients, id: \.self) { name in
                                    SkinChip(title: name + "  ✕", style: style, filled: true) { toggle(name) }
                                }
                            }
                        }
                        picker(style).id("picker")
                    }
                    .padding(2)
                }
                .frame(maxHeight: 520)
                .scrollDismissesKeyboard(.interactively)
                .onAppear {
                    // для скриншота плитки продуктов: -dishpick
                    if ProcessInfo.processInfo.arguments.contains("-dishpick") {
                        fromList = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { proxy.scrollTo("picker", anchor: .top) }
                    }
                }
                }
                HStack(spacing: 6) {
                    SkinChip(title: "Отмена", style: style) { store.editingDish = nil }
                    Spacer(minLength: 0)
                    SkinChip(title: "Сохранить", style: style, filled: true) { save() }
                }
            }
        }
    }

    private func field(_ textField: TextField<Text>, _ style: SkinStyle) -> some View {
        textField
            .font(style.font(15, .bold))
            .foregroundStyle(style.text)
            .padding(.horizontal, 8)
            .frame(height: 40)
            .background(RoundedRectangle(cornerRadius: 4).fill(style.rowFill))
            .overlay(RoundedRectangle(cornerRadius: 4).stroke(style.rowStroke, lineWidth: 1.5))
    }

    /// Откуда брать продукты: список покупок или все карточки
    @ViewBuilder
    private func picker(_ style: SkinStyle) -> some View {
        HStack(spacing: 6) {
            SkinChip(title: "Из списка (\(store.state.items.count))", style: style, filled: fromList) { fromList = true }
            SkinChip(title: "Все карточки", style: style, filled: !fromList) { fromList = false }
            Spacer(minLength: 0)
        }
        if !fromList {
            field(TextField("", text: $search, prompt: Text("Найти карточку").foregroundColor(style.secondary)), style)
        }
        let names = candidates
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 4), spacing: 6) {
            ForEach(names, id: \.self) { name in
                productTile(name, style)
            }
        }
        VStack {
            if names.isEmpty {
                Text(fromList ? "Список покупок пуст — выберите «Все карточки»" : "Не найдено")
                    .font(style.font(13, .regular))
                    .foregroundStyle(style.secondary)
                    .padding(6)
            }
        }
    }

    /// Плитка продукта: картинка, название, отметка ✓ у выбранного
    private func productTile(_ name: String, _ style: SkinStyle) -> some View {
        let on = contains(name)
        return Button {
            Haptics.tap()
            toggle(name)
        } label: {
            ZStack(alignment: .topTrailing) {
                SkinTileBackground(skin: skin, selected: on)
                VStack(spacing: 3) {
                    ProductImage(name: name, size: 34, pixelated: skin == .pixel)
                        .grayscale(skin == .mac ? 1 : 0)
                        .contrast(skin == .mac ? 1.4 : 1)
                    Text(name)
                        .font(style.font(10, .semibold))
                        .foregroundStyle(tileInk(style))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                        .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 3)
                .padding(.vertical, 6)
                if on {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white, style.accent)
                        .padding(3)
                }
            }
            .frame(height: 78)
        }
        .buttonStyle(SkinPressStyle(skin: skin))
    }

    /// Текст на плитке: фон плитки у части скинов светлый, у Winamp — чёрный
    private func tileInk(_ style: SkinStyle) -> Color {
        switch skin {
        case .aero: return .black
        case .winamp: return Winamp.listGreen
        case .sims: return .white
        default: return style.text
        }
    }

    private var candidates: [String] {
        if fromList {
            var seen = Set<String>()
            return store.displayItems.map(\.name).filter { seen.insert(ShopStore.key($0)).inserted }
        }
        let q = search.trimmingCharacters(in: .whitespaces).lowercased()
        return store.cards.map(\.name).filter { q.isEmpty || $0.lowercased().contains(q) }
    }

    private func contains(_ name: String) -> Bool {
        draft.ingredients.contains { ShopStore.key($0) == ShopStore.key(name) }
    }

    private func toggle(_ name: String) {
        if contains(name) {
            draft.ingredients.removeAll { ShopStore.key($0) == ShopStore.key(name) }
        } else {
            draft.ingredients.append(name)
        }
    }

    private func save() {
        guard !draft.name.trimmingCharacters(in: .whitespaces).isEmpty else {
            store.notify("Введите название блюда")
            return
        }
        guard !draft.ingredients.isEmpty else {
            store.notify("Выберите хотя бы один продукт")
            return
        }
        store.saveDish(draft)
        store.editingDish = nil
        store.isViewingDishes = true
        store.notify("Блюдо «\(draft.name.trimmingCharacters(in: .whitespaces))» сохранено")
    }
}
