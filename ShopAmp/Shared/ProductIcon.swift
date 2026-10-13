import SwiftUI

/// Картинка товара по названию. Иконки — Microsoft Fluent Emoji 3D (MIT), в каталоге ресурсов как «food_<имя>»;
/// если картинки нет, рисуется обычный эмодзи.
enum ProductIcon {
    struct Entry {
        let keys: [String]
        let emoji: String
        /// Папка в репозитории microsoft/fluentui-emoji
        let fluent: String
    }

    static func entry(for name: String) -> Entry? {
        let lowered = name.lowercased()
        return table.first { e in e.keys.contains { lowered.contains($0) } }
    }

    static func emoji(for name: String) -> String {
        entry(for: name)?.emoji ?? "🛒"
    }

    /// Имя картинки в каталоге ресурсов
    static func asset(for name: String) -> String {
        assetName(entry(for: name)?.fluent ?? "Shopping cart")
    }

    static func assetName(_ fluent: String) -> String {
        "food_" + fluent.lowercased().replacingOccurrences(of: " ", with: "_").replacingOccurrences(of: "-", with: "_")
    }

    /// Стабильный номер для цвета плитки (одинаковый между запусками)
    static func colorIndex(for name: String, count: Int) -> Int {
        let sum = name.lowercased().unicodeScalars.reduce(0) { $0 + Int($1.value) }
        return sum % max(count, 1)
    }

    /// Порядок важен: более точные слова — раньше («кокосовое молоко» до «молока», «зубная паста» до «пасты»)
    static let table: [Entry] = [
        Entry(keys: ["зубн", "щетк"], emoji: "🪥", fluent: "Toothbrush"),
        Entry(keys: ["туалетн", "бумажн", "полотенц", "салфет", "бумаг"], emoji: "🧻", fluent: "Roll of paper"),
        Entry(keys: ["губк", "тряпк"], emoji: "🧽", fluent: "Sponge"),
        Entry(keys: ["кокос"], emoji: "🥥", fluent: "Coconut"),
        Entry(keys: ["заменитель сахара", "сахар", "подсласт"], emoji: "🧂", fluent: "Salt"),
        Entry(keys: ["какао"], emoji: "🍫", fluent: "Chocolate bar"),
        Entry(keys: ["кофе"], emoji: "☕", fluent: "Hot beverage"),
        Entry(keys: ["бразильск", "грецк", "фундук", "миндал"], emoji: "🌰", fluent: "Chestnut"),
        Entry(keys: ["макадами", "арахис", "семечк", "орех"], emoji: "🥜", fluent: "Peanuts"),
        Entry(keys: ["соус"], emoji: "🥫", fluent: "Canned food"),
        Entry(keys: ["горчиц", "кетчуп", "майонез"], emoji: "🌭", fluent: "Hot dog"),
        Entry(keys: ["кола", "газиров", "лимонад"], emoji: "🥤", fluent: "Cup with straw"),
        Entry(keys: ["корица", "специ", "приправ"], emoji: "🪵", fluent: "Wood"),
        Entry(keys: ["маслин", "оливк"], emoji: "🫒", fluent: "Olive"),
        Entry(keys: ["икра"], emoji: "🫙", fluent: "Jar"),
        Entry(keys: ["кревет", "краб"], emoji: "🦐", fluent: "Shrimp"),
        Entry(keys: ["мидии", "мидия", "устриц"], emoji: "🦪", fluent: "Oyster"),
        Entry(keys: ["фасол", "горох", "горошек"], emoji: "🫛", fluent: "Pea pod"),
        Entry(keys: ["рыб", "лосос", "семг", "форел", "тунец", "сельд", "селед", "скумбри", "тилапи"], emoji: "🐟", fluent: "Fish"),
        Entry(keys: ["бекон"], emoji: "🥓", fluent: "Bacon"),
        Entry(keys: ["кур", "филе", "индейк", "крыл", "окорок"], emoji: "🍗", fluent: "Poultry leg"),
        Entry(keys: ["мяс", "говядин", "свинин", "фарш", "стейк", "баранин"], emoji: "🥩", fluent: "Cut of meat"),
        Entry(keys: ["колбас", "сосиск", "сардельк", "ветчин"], emoji: "🌭", fluent: "Hot dog"),
        Entry(keys: ["сливк", "молок", "кефир", "ряженк"], emoji: "🥛", fluent: "Glass of milk"),
        Entry(keys: ["сметан", "йогурт", "творог"], emoji: "🥣", fluent: "Bowl with spoon"),
        Entry(keys: ["сыр", "фета", "гойя"], emoji: "🧀", fluent: "Cheese wedge"),
        Entry(keys: ["масло"], emoji: "🧈", fluent: "Butter"),
        Entry(keys: ["яйц"], emoji: "🥚", fluent: "Egg"),
        Entry(keys: ["хлеб", "батон", "булк", "багет", "лаваш"], emoji: "🍞", fluent: "Bread"),
        Entry(keys: ["круассан", "выпечк"], emoji: "🥐", fluent: "Croissant"),
        Entry(keys: ["банан"], emoji: "🍌", fluent: "Banana"),
        Entry(keys: ["яблок"], emoji: "🍎", fluent: "Red apple"),
        Entry(keys: ["груш"], emoji: "🍐", fluent: "Pear"),
        Entry(keys: ["апельсин", "мандарин"], emoji: "🍊", fluent: "Tangerine"),
        Entry(keys: ["лимон"], emoji: "🍋", fluent: "Lemon"),
        Entry(keys: ["виноград"], emoji: "🍇", fluent: "Grapes"),
        Entry(keys: ["клубник", "ягод", "малин"], emoji: "🍓", fluent: "Strawberry"),
        Entry(keys: ["арбуз"], emoji: "🍉", fluent: "Watermelon"),
        Entry(keys: ["персик"], emoji: "🍑", fluent: "Peach"),
        Entry(keys: ["помидор", "томат", "черри"], emoji: "🍅", fluent: "Tomato"),
        Entry(keys: ["огур"], emoji: "🥒", fluent: "Cucumber"),
        Entry(keys: ["картоф", "картош"], emoji: "🥔", fluent: "Potato"),
        Entry(keys: ["морков"], emoji: "🥕", fluent: "Carrot"),
        Entry(keys: ["чеснок"], emoji: "🧄", fluent: "Garlic"),
        Entry(keys: ["лук"], emoji: "🧅", fluent: "Onion"),
        Entry(keys: ["капуст", "салат", "зелен", "укроп", "петрушк"], emoji: "🥬", fluent: "Leafy green"),
        Entry(keys: ["перец"], emoji: "🫑", fluent: "Bell pepper"),
        Entry(keys: ["гриб", "шампиньон"], emoji: "🍄", fluent: "Mushroom"),
        Entry(keys: ["авокадо"], emoji: "🥑", fluent: "Avocado"),
        Entry(keys: ["кукуруз"], emoji: "🌽", fluent: "Ear of corn"),
        Entry(keys: ["греч", "рис", "круп", "овсян", "мук"], emoji: "🌾", fluent: "Sheaf of rice"),
        Entry(keys: ["макарон", "спагет", "лапш"], emoji: "🍝", fluent: "Spaghetti"),
        Entry(keys: ["шоколад", "конфет"], emoji: "🍫", fluent: "Chocolate bar"),
        Entry(keys: ["печень", "крекер"], emoji: "🍪", fluent: "Cookie"),
        Entry(keys: ["торт", "пирож"], emoji: "🍰", fluent: "Shortcake"),
        Entry(keys: ["морожен"], emoji: "🍦", fluent: "Soft ice cream"),
        Entry(keys: ["мёд", "мед "], emoji: "🍯", fluent: "Honey pot"),
        Entry(keys: ["чай"], emoji: "🍵", fluent: "Teacup without handle"),
        Entry(keys: ["сок"], emoji: "🧃", fluent: "Beverage box"),
        Entry(keys: ["пив"], emoji: "🍺", fluent: "Beer mug"),
        Entry(keys: ["вин"], emoji: "🍷", fluent: "Wine glass"),
        Entry(keys: ["вод", "минерал"], emoji: "💧", fluent: "Droplet"),
        Entry(keys: ["мыло", "шампун", "гель"], emoji: "🧴", fluent: "Lotion bottle"),
        Entry(keys: ["порош", "стир", "моющ", "чистящ"], emoji: "🧼", fluent: "Soap"),
        Entry(keys: ["корм"], emoji: "🐾", fluent: "Paw prints"),
        Entry(keys: ["батарейк"], emoji: "🔋", fluent: "Battery"),
        Entry(keys: ["лекарств", "таблет", "витамин"], emoji: "💊", fluent: "Pill"),
        Entry(keys: ["цвет", "букет"], emoji: "💐", fluent: "Bouquet"),
    ]
}

/// Картинка товара; pixelated — для пиксельных скинов (уменьшается до 24 px и рисуется без сглаживания)
struct ProductImage: View {
    @EnvironmentObject private var store: ShopStore
    let name: String
    var size: CGFloat = 32
    var pixelated = false
    /// Показать конкретную картинку (в окне выбора иконки)
    var asset: String? = nil

    var body: some View {
        let asset = self.asset ?? store.icon(for: name)
        #if canImport(UIKit)
        if let image = UIImage(named: asset) {
            if pixelated, let small = Self.pixelate(image, asset: asset) {
                Image(uiImage: small).resizable().interpolation(.none).frame(width: size, height: size)
            } else {
                Image(uiImage: image).resizable().interpolation(.high).frame(width: size, height: size)
            }
        } else {
            Text(ProductIcon.emoji(for: name)).font(.system(size: size * 0.8))
        }
        #else
        Text(ProductIcon.emoji(for: name)).font(.system(size: size * 0.8))
        #endif
    }

    #if canImport(UIKit)
    private static var cache: [String: UIImage] = [:]

    private static func pixelate(_ image: UIImage, asset: String) -> UIImage? {
        if let hit = cache[asset] { return hit }
        let side: CGFloat = 24
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let small = UIGraphicsImageRenderer(size: CGSize(width: side, height: side), format: format).image { _ in
            image.draw(in: CGRect(x: 0, y: 0, width: side, height: side))
        }
        cache[asset] = small
        return small
    }
    #endif
}
