import SwiftUI

/// Отделы супермаркета — в порядке обычного обхода магазина
enum ShopCategory: String, CaseIterable, Codable, Identifiable {
    case produce, bakery, dairy, meat, fish, grocery, nuts, canned, spices, drinksHot, sweets, drinks, frozen, household, hygiene, other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .produce: return "Овощи и фрукты"
        case .bakery: return "Хлеб и выпечка"
        case .dairy: return "Молочка и сыры"
        case .meat: return "Мясо и птица"
        case .fish: return "Рыба и морепродукты"
        case .grocery: return "Бакалея и крупы"
        case .nuts: return "Орехи и снеки"
        case .canned: return "Консервы и соусы"
        case .spices: return "Специи и приправы"
        case .drinksHot: return "Чай и кофе"
        case .sweets: return "Сладкое"
        case .drinks: return "Напитки"
        case .frozen: return "Заморозка"
        case .household: return "Бытовое"
        case .hygiene: return "Гигиена"
        case .other: return "Разное"
        }
    }

    var emoji: String {
        switch self {
        case .produce: return "🥬"
        case .bakery: return "🍞"
        case .dairy: return "🥛"
        case .meat: return "🥩"
        case .fish: return "🐟"
        case .grocery: return "🌾"
        case .nuts: return "🥜"
        case .canned: return "🥫"
        case .spices: return "🧂"
        case .drinksHot: return "☕"
        case .sweets: return "🍫"
        case .drinks: return "🧃"
        case .frozen: return "🧊"
        case .household: return "🧽"
        case .hygiene: return "🪥"
        case .other: return "🛒"
        }
    }

    var label: String { emoji + " " + title }
    var order: Int { Self.allCases.firstIndex(of: self) ?? 0 }

    /// Ключевые слова. Порядок проверки важен: точные сочетания раньше общих
    /// («кокосовое молоко» — бакалея, «зубная паста» — гигиена, «рыбное филе» — рыба)
    private static let rules: [(ShopCategory, [String])] = [
        (.hygiene, ["зубн", "шампун", "гель для душ", "мыло", "дезодор", "прокладк", "ватн", "бритв", "крем для"]),
        (.household, ["туалетн", "бумажн", "полотенц", "салфет", "губк", "тряпк", "порошок", "средство", "пакет", "фольг", "пленк", "плёнк", "батарейк", "лампочк", "мешки"]),
        (.frozen, ["морожен", "пельмен", "вареник", "заморож", "лёд", "лед "]),
        (.fish, ["рыб", "лосос", "сёмг", "семг", "форел", "тунец", "сельд", "селед", "селёд", "скумбри", "тилапи", "кревет", "краб", "мидии", "мидия", "кальмар", "устриц", "икра"]),
        (.meat, ["бекон", "кур", "филе", "индейк", "крыл", "окорок", "мяс", "говядин", "свинин", "фарш", "стейк", "баранин", "колбас", "сосиск", "ветчин", "печень"]),
        (.drinksHot, ["кофе", "чай", "какао", "цикори"]),
        (.nuts, ["орех", "миндал", "фундук", "кешью", "фисташ", "макадами", "арахис", "семечк", "чипс", "сухарик", "попкорн", "сухофрукт", "изюм", "курага", "чернослив"]),
        (.grocery, ["кокосовое молоко", "кокосовое масло", "гречк", "рис", "овсян", "хлопь", "макарон", "спагетти", "мука", "сахар", "заменитель", "масло подсолн", "оливковое масло", "растительное масло", "крупа", "булгур", "киноа", "чечевиц", "нут", "соль", "мёд", "мед ", "сода", "дрожж"]),
        (.canned, ["соус", "кетчуп", "майонез", "горчиц", "консерв", "тушёнк", "тушенк", "маслин", "оливк", "огурцы маринов", "томатн", "паст", "варень", "джем"]),
        (.spices, ["корица", "специ", "приправ", "перец молот", "паприк", "куркум", "ванил", "лавров", "имбирь молот"]),
        (.dairy, ["молок", "кефир", "ряженк", "йогурт", "творог", "сметан", "сливк", "сыр", "фета", "моцарел", "масло сливоч", "сливочное масло", "яйц", "яйца", "простокваш", "айран"]),
        (.bakery, ["хлеб", "батон", "булк", "лаваш", "лепёшк", "лепешк", "багет", "круассан", "пирог", "выпечк", "сушк", "пряник"]),
        (.sweets, ["шоколад", "конфет", "печень", "торт", "вафл", "зефир", "мармелад", "пастил", "сладк"]),
        (.drinks, ["вода", "сок", "кола", "газиров", "лимонад", "морс", "компот", "квас", "пиво", "вино", "напит"]),
        (.produce, ["помидор", "томат", "огур", "картоф", "морков", "лук", "чеснок", "капуст", "перец", "кабачк", "баклажан", "зелен", "укроп", "петрушк", "салат", "шпинат", "фасол", "горох", "горошек", "брокколи", "свёкл", "свекл", "редис", "тыкв", "авокадо", "банан", "яблок", "груш", "апельсин", "мандарин", "лимон", "лайм", "виноград", "ягод", "клубник", "малин", "черник", "киви", "манго", "ананас", "персик", "слив", "гриб", "имбир"]),
    ]

    static func guess(_ name: String) -> ShopCategory {
        let n = " " + name.lowercased() + " "
        for (cat, keys) in rules where keys.contains(where: { n.contains($0) }) { return cat }
        return .other
    }
}

extension ShopStore {
    /// Отдел товара: выбранный в карточке или определённый по названию
    func category(_ name: String) -> ShopCategory {
        state.memory[Self.key(name)]?.category.flatMap(ShopCategory.init(rawValue:)) ?? ShopCategory.guess(name)
    }

    func setCategory(_ name: String, _ category: ShopCategory?) {
        let clean = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        let key = Self.key(clean)
        var s = state
        if s.memory[key] == nil { s.memory[key] = ItemMemory(name: clean) }
        s.memory[key]?.category = category?.rawValue
        state = s
    }

    /// Выбор отдела — меню в стиле скина
    func chooseCategory(for name: String, onPick: ((ShopCategory) -> Void)? = nil) {
        let current = category(name)
        menu = SkinMenu(title: "Отдел: \(name)", actions: ShopCategory.allCases.map { cat in
            MenuAction(title: (cat == current ? "✓ " : "") + cat.label) { [weak self] in
                self?.setCategory(name, cat)
                onPick?(cat)
            }
        })
    }

    /// Нужен ли заголовок отдела перед строкой (список сгруппирован и отдел сменился)
    func categoryHeader(_ list: [ShopItem], at index: Int) -> ShopCategory? {
        guard state.groupByCategory, index < list.count else { return nil }
        let cat = category(list[index].name)
        if index == 0 { return cat }
        return category(list[index - 1].name) == cat ? nil : cat
    }
}

/// Заголовок отдела в списке — в стиле скина
struct CategoryHeader: View {
    let skin: SkinID
    let category: ShopCategory
    var count: Int? = nil

    var body: some View {
        let style = SkinStyle.of(skin)
        HStack(spacing: 6) {
            Text(category.emoji).font(.system(size: 14))
            Text(skin == .winamp ? category.title.uppercased() : category.title)
                .font(style.font(skin == .pixel ? 12 : 13, .bold))
                .foregroundStyle(headerInk(style))
                .lineLimit(1)
            if let count { Text("\(count)").font(style.font(11, .regular)).foregroundStyle(style.secondary) }
            Rectangle().fill(headerInk(style).opacity(0.35)).frame(height: 1)
        }
        .padding(.horizontal, 6)
        .padding(.top, 8)
        .padding(.bottom, 2)
        .accessibilityAddTraits(.isHeader)
    }

    private func headerInk(_ style: SkinStyle) -> Color {
        switch skin {
        case .winamp: return Winamp.listDue
        case .aero: return .white
        case .mac: return Mac.ink
        case .sims: return Color(hex: 0xFFF59A)
        case .pixel: return Px.ink
        }
    }
}

/// Кнопка «Отдел» для окна товара и карточки
struct CategoryChip: View {
    @EnvironmentObject var store: ShopStore
    let skin: SkinID
    let name: String

    var body: some View {
        let style = SkinStyle.of(skin)
        let cat = name.trimmingCharacters(in: .whitespaces).isEmpty ? ShopCategory.other : store.category(name)
        HStack(spacing: 6) {
            Text("Отдел").font(style.font(14, .regular)).foregroundStyle(style.text)
            SkinChip(title: cat.label + "  ▾", style: style) {
                guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
                    store.notify("Сначала введите название товара")
                    return
                }
                store.chooseCategory(for: name)
            }
            Spacer(minLength: 0)
        }
    }
}
