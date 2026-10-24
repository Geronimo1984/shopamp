import Foundation
import SwiftUI

struct ShopItem: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var qty: Int = 1
    var bought = false
    /// Дата покупки, которую эта отметка записала в память (чтобы снять её при отмене)
    var recordedPurchase: Date? = nil
}

/// Что приложение помнит о товаре: когда его покупали и как часто напоминать
struct ItemMemory: Codable, Equatable {
    var name: String
    var purchases: [Date] = []
    /// Интервал, заданный вручную (дней); nil — считать по истории
    var customInterval: Double? = nil
    /// Показывать ли товар в «Пора купить»
    var remind = true
    /// Ориентировочная цена за штуку, ₽ (nil — не задана)
    var price: Double? = nil
    /// Отдел магазина, выбранный вручную (nil — по названию)
    var category: String? = nil

    init(name: String, purchases: [Date] = []) {
        self.name = name
        self.purchases = purchases
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = try c.decode(String.self, forKey: .name)
        purchases = try c.decodeIfPresent([Date].self, forKey: .purchases) ?? []
        customInterval = try c.decodeIfPresent(Double.self, forKey: .customInterval)
        remind = try c.decodeIfPresent(Bool.self, forKey: .remind) ?? true
        price = try c.decodeIfPresent(Double.self, forKey: .price)
        category = try c.decodeIfPresent(String.self, forKey: .category)
    }

    var lastPurchase: Date? { purchases.max() }

    /// Средний интервал между покупками по истории, в днях
    var averageInterval: Double? {
        guard purchases.count >= 2 else { return nil }
        let sorted = purchases.sorted()
        let days = sorted.last!.timeIntervalSince(sorted.first!) / 86_400
        return max(days / Double(sorted.count - 1), 1)
    }

    /// Действующий интервал: ручной или по истории
    var interval: Double? { customInterval ?? averageInterval }

    /// 1.0 — пора покупать, меньше — ещё рано
    func dueRatio(at now: Date = Date()) -> Double? {
        guard let interval, let last = lastPurchase else { return nil }
        return now.timeIntervalSince(last) / 86_400 / interval
    }

    /// Через сколько дней пора (0 — уже пора), nil — неизвестно
    func daysLeft(at now: Date = Date()) -> Int? {
        guard let interval, let ratio = dueRatio(at: now) else { return nil }
        return max(Int((interval * (1 - ratio)).rounded(.up)), 0)
    }
}

/// Пункт меню, которое каждый скин рисует в своём стиле
struct MenuAction: Identifiable {
    let id = UUID()
    let title: String
    var destructive = false
    /// Картинка пункта (эмодзи) — рисуется в своём столбце, чтобы строки шли ровно
    var emoji: String? = nil
    /// Текущий выбор — галочка справа
    var checked = false
    let action: () -> Void
}

struct SkinMenu {
    let title: String
    let actions: [MenuAction]
}

struct SavedState: Codable {
    var items: [ShopItem] = []
    var memory: [String: ItemMemory] = [:]
    var autoSuggest = true
    var autoAdd = false
    var sortBought = false
    /// Список сгруппирован по отделам магазина
    var groupByCategory = true
    /// Список сгруппирован по блюдам (важнее отделов)
    var groupByDish = false
    /// Готовые блюда из карточек товаров
    var dishes: [Dish] = []
    var showEqualizer = false
    var showPlaylist = true
    var skin: SkinID = .winamp
    var seenHelp = false
    /// Список пользователя уже добавлен (один раз)
    var addedUserList = false
    /// Каталог карточек заполнен базовыми товарами, список покупок переведён на «текущий поход»
    var catalogSeeded = false
    /// Иконка, выбранная вручную: ключ названия товара → имя картинки
    var iconOverrides: [String: String] = [:]

    init() {}

    /// Поля, которых нет в старом файле, получают значения по умолчанию — данные не теряются
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        items = try c.decodeIfPresent([ShopItem].self, forKey: .items) ?? []
        memory = try c.decodeIfPresent([String: ItemMemory].self, forKey: .memory) ?? [:]
        autoSuggest = try c.decodeIfPresent(Bool.self, forKey: .autoSuggest) ?? true
        autoAdd = try c.decodeIfPresent(Bool.self, forKey: .autoAdd) ?? false
        sortBought = try c.decodeIfPresent(Bool.self, forKey: .sortBought) ?? false
        groupByCategory = try c.decodeIfPresent(Bool.self, forKey: .groupByCategory) ?? true
        groupByDish = try c.decodeIfPresent(Bool.self, forKey: .groupByDish) ?? false
        dishes = try c.decodeIfPresent([Dish].self, forKey: .dishes) ?? []
        showEqualizer = try c.decodeIfPresent(Bool.self, forKey: .showEqualizer) ?? false
        showPlaylist = try c.decodeIfPresent(Bool.self, forKey: .showPlaylist) ?? true
        skin = (try? c.decodeIfPresent(SkinID.self, forKey: .skin)) ?? .winamp
        seenHelp = try c.decodeIfPresent(Bool.self, forKey: .seenHelp) ?? false
        addedUserList = try c.decodeIfPresent(Bool.self, forKey: .addedUserList) ?? false
        catalogSeeded = try c.decodeIfPresent(Bool.self, forKey: .catalogSeeded) ?? false
        iconOverrides = try c.decodeIfPresent([String: String].self, forKey: .iconOverrides) ?? [:]
    }
}

@MainActor
final class ShopStore: ObservableObject {
    @Published var state: SavedState { didSet { save() } }
    @Published var selectedID: UUID?
    @Published var showRemaining = false
    @Published var isAdding = false
    @Published var isChoosingSkin = false
    /// Идёт режим покупок (в скинах, где он есть)
    @Published var isShopping = false
    /// Товар, открытый в редакторе
    @Published var editingID: UUID?
    /// Короткое всплывающее сообщение
    @Published var toast: String?
    /// Открытое меню (рисуется в стиле скина)
    @Published var menu: SkinMenu?
    @Published var showHelp = false
    /// Нажали на персонажа-помощника, который живёт внутри сцены (Луна)
    @Published var assistantPing = 0
    /// Когда помощник последний раз заговорил — персонаж может подпрыгнуть
    @Published var assistantTalking = Date.distantPast
    /// Пасхалка Winamp: бегущая строка с подписью разработчика до этого момента
    @Published var marqueeEasterUntil = Date.distantPast
    /// Пасхалка Aero: всплывающее окно MSN
    @Published var msnPopup = false
    /// Открыт выбор иконки для товара с этим названием
    @Published var iconPickerName: String?
    /// Элемент, о котором сейчас рассказывает помощник (страница прокручивается к нему)
    @Published var assistantTarget: String?
    @Published var isEditingMemory = false
    /// Окно «Блюда и рецепты»
    @Published var isViewingDishes = false
    /// Блюдо в редакторе (черновик)
    @Published var editingDish: Dish?
    /// Раскрытое блюдо в окне «Блюда и рецепты»
    @Published var openDishID: UUID?
    private var toastToken = UUID()

    private let fileURL: URL?

    nonisolated static let defaultURL: URL? = FileManager.default
        .urls(for: .documentDirectory, in: .userDomainMask).first?
        .appendingPathComponent("shopamp.json")

    init(fileURL: URL? = ShopStore.defaultURL) {
        self.fileURL = fileURL
        if let url = fileURL,
           let data = try? Data(contentsOf: url),
           let saved = try? JSONDecoder().decode(SavedState.self, from: data) {
            state = saved
        } else {
            state = SavedState()
        }
        selectedID = state.items.first?.id
        seedCatalogOnce()
    }

    /// Базовые карточки, которые были в приложении с самого начала
    static let baseCards = [
        "Хлеб бородинский", "Сыр", "Бананы", "Куриное филе", "Помидоры черри", "Гречка",
        "Зубная паста", "Сок апельсиновый", "Шоколад", "Молоко", "Хлеб", "Вода",
    ]

    /// Список пользователя (присланный 14.10.2026) — добавляется к уже созданным товарам один раз, без дублей
    static let userList = [
        "Кофе", "Заменитель сахара", "Какао", "Авокадо", "Кокосовое молоко", "Бумажные полотенца",
        "Бразильский орех", "Грецкий орех", "Яйца", "Тыквенные семечки", "Бекон", "Китайский соус / устричный соус",
        "Горчица", "Кола", "Сыр Гойя", "Корица", "Макадамия", "Фета", "Маслины", "Огурцы", "Икра", "Креветки",
        "Мидии", "Стручковая фасоль", "Тилапия, рыбное филе", "Кокосовое масло", "Сливки 33%", "Селёдка",
        "Курица", "Сметана", "Чеснок", "Туалетная бумага", "Губки, тряпки",
    ]

    /// Иконка товара: выбранная вручную или подобранная по названию
    func icon(for name: String) -> String {
        state.iconOverrides[Self.key(name)] ?? ProductIcon.asset(for: name)
    }

    /// nil — вернуть автоматический подбор
    func setIcon(_ asset: String?, for name: String) {
        let key = Self.key(name)
        guard !key.isEmpty else { return }
        state.iconOverrides[key] = asset
    }

    /// Один раз: все базовые товары и список пользователя становятся карточками,
    /// а список покупок — текущим походом: остаются только свои товары пользователя и то, что пора купить
    func seedCatalogOnce() {
        guard !state.catalogSeeded else { return }
        var s = state
        let seeded = Set((Self.baseCards + Self.userList).map(Self.key))
        for name in Self.baseCards + Self.userList where s.memory[Self.key(name)] == nil {
            s.memory[Self.key(name)] = ItemMemory(name: name)
        }
        for item in s.items where s.memory[Self.key(item.name)] == nil {
            s.memory[Self.key(item.name)] = ItemMemory(name: item.name)
        }
        // в списке оставляем только то, что пользователь завёл сам (не из стартовых наборов)
        s.items.removeAll { seeded.contains(Self.key($0.name)) }
        s.catalogSeeded = true
        s.addedUserList = true
        state = s
        addDue(silent: true)
        selectedID = state.items.first?.id
    }

    // MARK: - Карточки товаров

    /// Все карточки по алфавиту
    var cards: [ItemMemory] {
        state.memory.values.sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
    }

    func isInList(_ name: String) -> Bool {
        state.items.contains { !$0.bought && Self.key($0.name) == Self.key(name) }
    }

    /// Карточка в списке покупок ↔ нет
    func toggleInList(_ name: String) {
        let key = Self.key(name)
        if let item = state.items.first(where: { !$0.bought && Self.key($0.name) == key }) {
            remove(item.id)
        } else {
            add(name)
        }
    }

    /// Новая карточка (без добавления в список)
    @discardableResult
    func addCard(_ rawName: String) -> Bool {
        let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, state.memory[Self.key(name)] == nil else { return false }
        state.memory[Self.key(name)] = ItemMemory(name: name)
        return true
    }

    /// Удалить карточку из каталога (список покупок не трогаем)
    func deleteCard(_ name: String) {
        let key = Self.key(name)
        var s = state
        s.memory[key] = nil
        s.iconOverrides[key] = nil
        state = s
    }

    private func save() {
        guard let url = fileURL, let data = try? JSONEncoder().encode(state) else { return }
        try? data.write(to: url, options: .atomic)
    }

    static func key(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    // MARK: - Чтение

    /// Порядок списка: по блюдам или по отделам магазина (если включено),
    /// внутри — купленное в конец (если включено), иначе как добавляли
    var displayItems: [ShopItem] {
        let indexed = Array(state.items.enumerated())
        let group = isGrouped, bought = state.sortBought
        guard group || bought else { return state.items }
        var orders: [UUID: (Int, Int)] = [:]
        if group {
            for item in state.items { orders[item.id] = sectionOrder(for: item.name) }
        }
        return indexed.sorted { a, b in
            if group, let oa = orders[a.element.id], let ob = orders[b.element.id] {
                if oa.0 != ob.0 { return oa.0 < ob.0 }
                if bought, a.element.bought != b.element.bought { return !a.element.bought }
                if oa.1 != ob.1 { return oa.1 < ob.1 }
            } else if bought, a.element.bought != b.element.bought {
                return !a.element.bought
            }
            return a.offset < b.offset
        }.map(\.element)
    }

    var boughtCount: Int { state.items.filter(\.bought).count }
    var totalCount: Int { state.items.count }
    var leftCount: Int { totalCount - boughtCount }

    var selectedItem: ShopItem? { state.items.first { $0.id == selectedID } }
    var editingItem: ShopItem? { state.items.first { $0.id == editingID } }

    var selectedNumber: Int? {
        displayItems.firstIndex { $0.id == selectedID }.map { $0 + 1 }
    }

    /// Товары, которые по истории пора купить и которых нет в списке
    var dueSuggestions: [ItemMemory] {
        let inList = Set(state.items.filter { !$0.bought }.map { Self.key($0.name) })
        return state.memory.values
            .filter { $0.remind && !inList.contains(Self.key($0.name)) && ($0.dueRatio() ?? 0) >= 0.9 }
            .sorted { ($0.dueRatio() ?? 0) > ($1.dueRatio() ?? 0) }
    }

    /// Регулярные покупки для эквалайзера (самые «созревшие» первыми)
    var regulars: [ItemMemory] {
        Array(state.memory.values
            .filter { $0.remind && $0.interval != nil }
            .sorted { ($0.dueRatio() ?? 0) > ($1.dueRatio() ?? 0) }
            .prefix(10))
    }

    func suggestions(for text: String) -> [String] {
        let query = Self.key(text)
        let names = state.memory.values.map(\.name)
        guard !query.isEmpty else {
            return dueSuggestions.map(\.name).prefix(4).map { $0 }
        }
        return names
            .filter { Self.key($0).hasPrefix(query) && Self.key($0) != query }
            .sorted()
            .prefix(4)
            .map { $0 }
    }

    var marqueeText: String {
        if Date() < marqueeEasterUntil {
            return "НАКОДИЛ GERONIMO *** ЭТОТ ПЛЕЕР ДЕЛАЕТ ТОЛЬКО СПИСКИ, МУЗЫКИ НЕ БУДЕТ"
        }
        var text: String
        if let item = selectedItem, let number = selectedNumber {
            text = "\(number). \(item.name) (\(item.qty) шт)"
            if item.bought { text += " [куплено]" }
        } else if state.items.isEmpty {
            text = "ShopAmp - список покупок пуст"
        } else {
            text = "ShopAmp - выберите товар"
        }
        if state.autoSuggest, !dueSuggestions.isEmpty {
            text += " *** купить снова: " + dueSuggestions.map(\.name).joined(separator: ", ")
        }
        return text.uppercased()
    }

    // MARK: - Изменения

    func add(_ rawName: String, qty: Int = 1) {
        let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        let key = Self.key(name)
        var s = state
        if let i = s.items.firstIndex(where: { !$0.bought && Self.key($0.name) == key }) {
            s.items[i].qty = min(s.items[i].qty + qty, 99)
            selectedID = s.items[i].id
        } else {
            let item = ShopItem(name: name, qty: min(qty, 99))
            s.items.append(item)
            selectedID = item.id
        }
        if s.memory[key] == nil {
            s.memory[key] = ItemMemory(name: name)
        }
        state = s
    }

    /// Добавляет всё, что пора купить, и сообщает, что произошло
    @discardableResult
    func addDue(silent: Bool = false) -> Int {
        let names = dueSuggestions.map(\.name)
        for name in names {
            add(name)
        }
        guard !silent else { return names.count }
        if !names.isEmpty {
            notify("Добавлено из «Купить снова»: " + names.joined(separator: ", "))
        } else if let next = regulars.first, let days = next.daysLeft() {
            notify("Пока ничего не заканчивается. Ближайшее: \(next.name) через \(max(days, 1)) дн")
        } else {
            notify("«Купить снова» пока пуст. Задайте товарам, как часто вы их покупаете: меню → «Купить снова»")
        }
        return names.count
    }

    func openMainMenu() {
        menu = SkinMenu(title: "Меню", actions: [
            MenuAction(title: "Изменить выбранный товар…") { [weak self] in self?.edit(self?.selectedID) },
            MenuAction(title: "Подобрать из карточек товаров…") { [weak self] in self?.isEditingMemory = true },
            MenuAction(title: "Блюда и рецепты…") { [weak self] in self?.openDishes() },
            MenuAction(title: "Добавить всё, что пора купить") { [weak self] in self?.addDue() },
            MenuAction(title: "Новый поход (список по срокам)") { [weak self] in self?.startNewTrip() },
            MenuAction(title: state.sortBought ? "Не сортировать купленное" : "Купленное — в конец") { [weak self] in
                self?.toggle(\.sortBought)
            },
            MenuAction(title: state.groupByDish ? "Список по отделам (не по блюдам)" : "Список по блюдам") { [weak self] in
                self?.toggleGroupByDish()
            },
            MenuAction(title: state.groupByCategory ? "Не группировать по отделам" : "Группировать по отделам") { [weak self] in
                self?.toggle(\.groupByCategory)
            },
            MenuAction(title: "Сменить скин…") { [weak self] in self?.isChoosingSkin = true },
            MenuAction(title: "Справка") { [weak self] in self?.showHelp = true },
            MenuAction(title: "Очистить список", destructive: true) { [weak self] in self?.clearAll() },
        ])
    }

    // MARK: Память

    /// Все запомненные товары: сначала те, что пора купить
    var memoryList: [ItemMemory] {
        state.memory.values.sorted {
            let a = $0.dueRatio() ?? -1, b = $1.dueRatio() ?? -1
            return a == b ? $0.name < $1.name : a > b
        }
    }

    func setInterval(_ name: String, days: Double?) {
        let key = Self.key(name)
        guard state.memory[key] != nil else { return }
        state.memory[key]?.customInterval = days.map { min(max($0, 1), 365) }
    }

    func toggleRemind(_ name: String) {
        let key = Self.key(name)
        state.memory[key]?.remind.toggle()
    }

    /// Отметить покупку сегодня — запускает отсчёт до «пора»
    func markPurchasedToday(_ name: String) {
        let key = Self.key(name)
        guard var memory = state.memory[key] else { return }
        let now = Date()
        if !memory.purchases.contains(where: { Calendar.current.isDate($0, inSameDayAs: now) }) {
            memory.purchases.append(now)
        }
        state.memory[key] = memory
    }

    func forget(_ name: String) {
        state.memory[Self.key(name)] = nil
    }

    func openItemMenu(_ id: UUID) {
        guard let item = state.items.first(where: { $0.id == id }) else { return }
        selectedID = id
        menu = SkinMenu(title: item.name, actions: [
            MenuAction(title: "Изменить…") { [weak self] in self?.edit(id) },
            MenuAction(title: item.bought ? "Не куплено" : "Куплено") { [weak self] in self?.toggleBought(id) },
            MenuAction(title: "+1 шт") { [weak self] in self?.setQty(id, item.qty + 1) },
            MenuAction(title: "−1 шт") { [weak self] in self?.setQty(id, item.qty - 1) },
            MenuAction(title: "Убрать из списка (карточка останется)", destructive: true) { [weak self] in self?.remove(id) },
        ])
    }

    func runMenu(_ action: MenuAction) {
        menu = nil
        action.action()
    }

    func notify(_ text: String) {
        let token = UUID()
        toastToken = token
        toast = text
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.2) { [weak self] in
            if self?.toastToken == token { self?.toast = nil }
        }
    }

    /// Нажатие на товар: первое выбирает, повторное открывает редактор
    func tapItem(_ id: UUID) {
        if selectedID == id {
            editingID = id
        } else {
            selectedID = id
        }
    }

    func edit(_ id: UUID?) {
        guard let id, state.items.contains(where: { $0.id == id }) else {
            notify("Сначала выберите товар в списке")
            return
        }
        selectedID = id
        editingID = id
    }

    /// Сохранить изменения названия и количества
    func update(_ id: UUID?, name rawName: String, qty: Int) {
        let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, let i = state.items.firstIndex(where: { $0.id == id }) else { return }
        var s = state
        let oldKey = Self.key(s.items[i].name)
        if let icon = s.iconOverrides[oldKey], s.iconOverrides[Self.key(name)] == nil {
            s.iconOverrides[Self.key(name)] = icon
        }
        s.items[i].name = name
        s.items[i].qty = min(max(qty, 1), 99)
        let key = Self.key(name)
        if s.memory[key] == nil {
            // переименование: новая карточка получает отдел, выбранный у старой
            var memory = ItemMemory(name: name)
            memory.category = s.memory[oldKey]?.category
            s.memory[key] = memory
        }
        state = s
    }

    func toggleBought(_ id: UUID?) {
        guard let item = state.items.first(where: { $0.id == id }) else { return }
        setBought(item.id, !item.bought)
    }

    func setBought(_ id: UUID?, _ value: Bool) {
        guard let i = state.items.firstIndex(where: { $0.id == id }),
              state.items[i].bought != value else { return }
        var s = state
        var item = s.items[i]
        let key = Self.key(item.name)
        var memory = s.memory[key] ?? ItemMemory(name: item.name)
        if value {
            let now = Date()
            if memory.purchases.contains(where: { Calendar.current.isDate($0, inSameDayAs: now) }) {
                item.recordedPurchase = nil
            } else {
                memory.purchases.append(now)
                item.recordedPurchase = now
            }
        } else if let recorded = item.recordedPurchase {
            memory.purchases.removeAll { $0 == recorded }
            item.recordedPurchase = nil
        }
        item.bought = value
        s.items[i] = item
        s.memory[key] = memory
        state = s
    }

    func setQty(_ id: UUID?, _ qty: Int) {
        guard let i = state.items.firstIndex(where: { $0.id == id }) else { return }
        let value = min(max(qty, 1), 99)
        if state.items[i].qty != value {
            state.items[i].qty = value
        }
    }

    func remove(_ id: UUID?) {
        guard let id else { return }
        let list = displayItems
        let position = list.firstIndex { $0.id == id }
        state.items.removeAll { $0.id == id }
        if let position {
            let rest = displayItems
            selectedID = rest.isEmpty ? nil : rest[min(position, rest.count - 1)].id
        }
    }

    /// Покупки закончены: ничего не удаляется — купленное остаётся в списке зачёркнутым
    func finishShopping() {
        let bought = boughtCount
        notify(bought == 0
               ? "Покупки закончены. Пока ничего не отмечено купленным"
               : "Покупки закончены: в корзине \(bought) из \(totalCount). Купленное осталось в списке зачёркнутым")
    }

    /// Новый поход в магазин: список очищается и заполняется тем, что пора купить по срокам.
    /// Карточки и история покупок не трогаются
    func startNewTrip() {
        state.items.removeAll()
        let count = addDue(silent: true)
        selectedID = state.items.first?.id
        notify(count > 0
               ? "Новый поход: в списке \(count) — то, что пора купить по срокам. Остальное — из карточек"
               : "Новый поход: по срокам пока ничего. Наберите список из карточек")
    }

    func clearAll() {
        state.items.removeAll()
        selectedID = nil
    }

    func selectNext() { moveSelection(by: 1) }
    func selectPrev() { moveSelection(by: -1) }

    private func moveSelection(by step: Int) {
        let list = displayItems
        guard !list.isEmpty else { return }
        guard let current = list.firstIndex(where: { $0.id == selectedID }) else {
            selectedID = list.first?.id
            return
        }
        let next = (current + step + list.count) % list.count
        selectedID = list[next].id
    }

    func toggle(_ flag: WritableKeyPath<SavedState, Bool>) {
        state[keyPath: flag].toggle()
    }

    func appBecameActive() {
        // по умолчанию пустой список сам наполняется тем, что пора купить
        if state.autoAdd || state.items.isEmpty {
            addDue(silent: true)
        }
    }
}

// MARK: - Демо-данные для превью

extension ShopStore {
    static func demo() -> ShopStore {
        let store = ShopStore(fileURL: nil)
        let now = Date()
        func history(_ name: String, every: Double, times: Int, lastDaysAgo: Double) -> ItemMemory {
            ItemMemory(name: name, purchases: (0..<times).map {
                now.addingTimeInterval(-(lastDaysAgo + Double($0) * every) * 86_400)
            })
        }
        var s = SavedState()
        let memories = [
            history("Молоко", every: 4, times: 6, lastDaysAgo: 4),
            history("Хлеб", every: 2, times: 8, lastDaysAgo: 1),
            history("Яйца", every: 7, times: 4, lastDaysAgo: 8),
            history("Кофе", every: 14, times: 3, lastDaysAgo: 5),
            history("Бананы", every: 5, times: 4, lastDaysAgo: 3),
            history("Сыр", every: 6, times: 3, lastDaysAgo: 2),
            history("Вода", every: 3, times: 5, lastDaysAgo: 3),
        ]
        for memory in memories {
            s.memory[key(memory.name)] = memory
        }
        s.items = [
            ShopItem(name: "Хлеб бородинский", qty: 1),
            ShopItem(name: "Сыр", qty: 1, bought: true),
            ShopItem(name: "Бананы", qty: 6),
            ShopItem(name: "Куриное филе", qty: 2),
            ShopItem(name: "Помидоры черри", qty: 1),
            ShopItem(name: "Гречка", qty: 2, bought: true),
            ShopItem(name: "Зубная паста", qty: 1),
            ShopItem(name: "Сок апельсиновый", qty: 2),
            ShopItem(name: "Шоколад", qty: 3),
        ]
        s.showEqualizer = true
        s.seenHelp = true
        store.state = s
        store.seedCatalogOnce()
        // для демо в походе ещё пара товаров, один уже куплен
        store.add("Бананы", qty: 6)
        store.add("Куриное филе", qty: 2)
        store.add("Сыр")
        store.setBought(store.state.items.first { $0.name == "Сыр" }?.id, true)
        // ориентировочные цены для демо (часть товаров без цены)
        for (name, price) in [("Бананы", 25.0), ("Куриное филе", 389), ("Сыр", 459), ("Молоко", 89.9), ("Хлеб", 55),
                              ("Яйца", 129), ("Кофе", 690), ("Вода", 45), ("Гречка", 99)] {
            store.setPrice(name, price)
        }
        // блюда для демо
        store.state.dishes = [
            Dish(name: "Салат с фетой", emoji: "🥗", ingredients: ["Огурцы", "Помидоры черри", "Фета", "Маслины"],
                 note: "Нарезать огурцы и черри, добавить фету кубиками и маслины. Заправить оливковым маслом, щепотка орегано."),
            Dish(name: "Гречка с курицей", emoji: "🍲", ingredients: ["Гречка", "Куриное филе", "Сметана", "Чеснок"],
                 note: "Филе обжарить с чесноком, потушить в сметане 10 минут, подать с гречкой."),
            Dish(name: "Завтрак", emoji: "🍳", ingredients: ["Яйца", "Хлеб бородинский", "Бекон", "Кофе"]),
        ]
        store.selectedID = store.state.items.first { $0.name == "Бананы" }?.id
        return store
    }
}

// MARK: - Ориентировочная стоимость

extension ShopStore {
    /// Цена за штуку из карточки товара
    func price(_ name: String) -> Double? { state.memory[Self.key(name)]?.price }

    func setPrice(_ name: String, _ value: Double?) {
        let clean = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        let key = Self.key(clean)
        var s = state
        if s.memory[key] == nil { s.memory[key] = ItemMemory(name: clean) }
        s.memory[key]?.price = value.flatMap { $0 > 0 ? ($0 * 100).rounded() / 100 : nil }
        state = s
    }

    /// Стоимость позиции: цена × количество
    func cost(_ item: ShopItem) -> Double? { price(item.name).map { $0 * Double(item.qty) } }

    /// Сумма купленного в этом походе
    var cartTotal: Double { state.items.filter(\.bought).compactMap(cost).reduce(0, +) }
    /// Сколько стоит весь список
    var listTotal: Double { state.items.compactMap(cost).reduce(0, +) }
    /// Осталось потратить на некупленное
    var leftTotal: Double { listTotal - cartTotal }
    /// Товаров в списке без цены
    var unpricedCount: Int { state.items.filter { price($0.name) == nil }.count }
    var hasPrices: Bool { state.items.contains { price($0.name) != nil } }

    /// «89,9 ₽» — цена позиции (с копейками, если они есть)
    static func rub(_ value: Double) -> String { format(value, kopecks: true) }

    /// «1 651 ₽» — итоги округляются до рубля, чтобы помещаться в табло
    static func total(_ value: Double) -> String { format(value, kopecks: false) }

    private static func format(_ value: Double, kopecks: Bool) -> String {
        let f = NumberFormatter()
        f.locale = Locale(identifier: "ru_RU")
        f.numberStyle = .decimal
        f.groupingSeparator = "\u{00A0}"
        f.maximumFractionDigits = kopecks ? 2 : 0
        f.minimumFractionDigits = 0
        return (f.string(from: NSNumber(value: value)) ?? "\(Int(value))") + "\u{00A0}₽"
    }

    /// «1 240 ₽ из ~2 860 ₽»
    var budgetText: String {
        guard hasPrices else { return "цены не заданы" }
        var text = Self.total(cartTotal) + " из ~" + Self.total(listTotal)
        if unpricedCount > 0 { text += " (без цены: \(unpricedCount))" }
        return text
    }

    /// Подпись позиции: «2 шт · 180 ₽»
    func qtyText(_ item: ShopItem) -> String {
        let q = "\(item.qty) шт"
        guard let c = cost(item) else { return q }
        return q + " · " + Self.rub(c)
    }

    /// Разбор цены из поля ввода: «89,90» → 89.9
    static func parsePrice(_ text: String) -> Double? {
        let t = text.replacingOccurrences(of: ",", with: ".").filter { $0.isNumber || $0 == "." }
        guard let v = Double(t), v > 0 else { return nil }
        return v
    }

    static func priceText(_ value: Double?) -> String {
        guard let value else { return "" }
        return value.rounded() == value ? String(Int(value)) : String(format: "%.2f", value).replacingOccurrences(of: ".", with: ",")
    }
}
