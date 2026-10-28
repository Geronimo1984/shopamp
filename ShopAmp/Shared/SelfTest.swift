#if DEBUG
import Foundation

/// Проверка расчётов: запуск с флагом -selftest, результат — в консоль. В сборку для телефона не попадает
@MainActor
enum SelfTest {
    static func run() {
        var failed = 0
        func check(_ name: String, _ ok: Bool, _ detail: @autoclosure () -> String = "") {
            print((ok ? "PASS " : "FAIL ") + name + (ok ? "" : " — " + detail()))
            if !ok { failed += 1 }
        }
        let store = ShopStore(fileURL: nil)
        store.state = SavedState()
        store.state.catalogSeeded = true

        // цены и суммы
        check("parsePrice 89,90", ShopStore.parsePrice("89,90") == 89.9)
        check("parsePrice 1 500", ShopStore.parsePrice("1 500") == 1500)
        check("parsePrice пусто", ShopStore.parsePrice("") == nil)
        check("parsePrice 0", ShopStore.parsePrice("0") == nil)
        store.add("Бананы", qty: 6)
        store.add("Сыр")
        store.add("Вода", qty: 2)
        store.add("Огурцы")
        store.setPrice("Бананы", 25)
        store.setPrice("Сыр", 459)
        store.setPrice("Вода", 45)
        let bananas = store.state.items.first { $0.name == "Бананы" }!
        check("стоимость позиции 6×25", store.cost(bananas) == 150, "\(String(describing: store.cost(bananas)))")
        check("сумма списка", store.listTotal == 150 + 459 + 90, "\(store.listTotal)")
        check("без цены 1", store.unpricedCount == 1, "\(store.unpricedCount)")
        store.add("Бананы", qty: 2)
        check("повторное добавление суммирует количество", store.state.items.first { $0.name == "Бананы" }?.qty == 8)
        check("сумма после +2 бананов", store.listTotal == 200 + 459 + 90, "\(store.listTotal)")

        // корзина
        store.setBought(store.state.items.first { $0.name == "Сыр" }?.id, true)
        check("корзина = сыр", store.cartTotal == 459, "\(store.cartTotal)")
        check("вопрос «почём?» появился", store.pricePrompt?.name == "Сыр")
        check("покупка записана в историю", store.state.memory[ShopStore.key("Сыр")]?.purchases.count == 1)
        store.setBought(store.state.items.first { $0.name == "Сыр" }?.id, false)
        check("отмена покупки снимает запись", store.state.memory[ShopStore.key("Сыр")]?.purchases.isEmpty == true)
        check("отмена покупки убирает «почём?»", store.pricePrompt == nil)
        check("корзина пуста после отмены", store.cartTotal == 0)

        // бюджет
        check("без бюджета", store.budgetVerdict == .none)
        store.setBudget(1000)
        check("уложимся, запас 251", store.budgetVerdict == .fits(left: 251), "\(store.budgetVerdict)")
        store.setBudget(500)
        check("перебор 249", store.budgetVerdict == .over(by: 249), "\(store.budgetVerdict)")
        let cuts = store.budgetCuts.map(\.name)
        check("отложить: сначала самое дорогое (сыр)", cuts == ["Сыр"], "\(cuts)")
        store.setBudget(0)
        check("бюджет 0 = не задан", store.state.tripBudget == nil)
        store.setBudget(1499.6)
        check("бюджет округляется", store.state.tripBudget == 1500)

        // блюда в приоритете при подсказке «что отложить»
        store.state.dishes = [Dish(name: "Салат", ingredients: ["Сыр", "Огурцы"])]
        store.setBudget(400)
        let cutsDish = store.budgetCuts.map(\.name)
        check("отложить: сначала не из блюд", cutsDish.first == "Бананы", "\(cutsDish)")

        // цена на кассе и история
        store.confirmPrice("Бананы", 27)
        store.confirmPrice("Бананы", 28)
        let history = store.state.memory[ShopStore.key("Бананы")]?.priceHistory ?? []
        check("одна запись истории в день", history.count == 1 && history.first?.price == 28, "\(history)")
        check("подтверждённая цена — цена карточки", store.price("Бананы") == 28)
        let day = 86_400.0
        store.state.memory[ShopStore.key("Бананы")]?.priceHistory = [
            PricePoint(date: Date().addingTimeInterval(-200 * day), price: 20),
            PricePoint(date: Date(), price: 25),
        ]
        let trend = store.priceTrend("Бананы") ?? ""
        check("тренд +25%", trend.contains("+25%"), trend)
        check("тренд за 6 мес.", trend.contains("за 6 мес."), trend)
        store.state.memory[ShopStore.key("Бананы")]?.priceHistory = [
            PricePoint(date: Date().addingTimeInterval(-40 * day), price: 30),
            PricePoint(date: Date(), price: 24),
        ]
        check("тренд снижения −20%", (store.priceTrend("Бананы") ?? "").contains("−20%"), store.priceTrend("Бананы") ?? "nil")
        check("тренд из одной цены — нет", store.priceTrend("Вода") == nil)

        // блюдо целиком в корзину
        let dishID = store.state.dishes[0].id
        store.state.dishes[0].ingredients.append("Фета")
        store.putDishInCart(dishID)
        let dish = store.state.dishes[0]
        check("все продукты блюда куплены", dish.ingredients.allSatisfy { store.status(ofIngredient: $0) == .bought })
        check("недостающая фета добавлена в список", store.state.items.contains { $0.name == "Фета" && $0.bought })
        check("после «всё в корзину» «почём?» не спрашивает", store.pricePrompt == nil)
        store.putDishInCart(dishID)
        check("повтор «всё в корзину» ничего не дублирует", store.state.items.filter { $0.name == "Фета" }.count == 1)

        // совмещение
        store.addIngredient("Вода", to: dishID)
        store.addIngredient("Вода", to: dishID)
        check("продукт в блюдо добавляется один раз", store.state.dishes[0].ingredients.filter { $0 == "Вода" }.count == 1)
        store.combine("Бананы", onto: ShopStore.key("Сыр"))
        let titles = store.menu?.actions.map(\.title) ?? []
        check("совмещение предлагает дополнить блюдо", titles.contains { $0.contains("Добавить «Бананы» в «Салат»") }, "\(titles)")
        check("совмещение предлагает новое блюдо", titles.contains("Новое блюдо из этих продуктов"))
        store.menu = nil

        // порядок списка по блюдам
        store.state.groupByDish = true
        let order = store.displayItems.map(\.name)
        let dishPart = order.prefix { store.dish(containing: $0) != nil }
        check("по блюдам: продукты блюда идут первыми", Set(dishPart) == Set(["Сыр", "Огурцы", "Фета", "Вода"]), "\(order)")
        store.state.groupByDish = false

        // удаление сохраняет выбор
        let ids = store.displayItems.map(\.id)
        store.selectedID = ids[1]
        store.remove(ids[1])
        check("после удаления выбран соседний товар", store.selectedID != nil && store.state.items.contains { $0.id == store.selectedID })

        // переименование сохраняет отдел
        store.setCategory("Огурцы", .canned)
        if let id = store.state.items.first(where: { $0.name == "Огурцы" })?.id {
            store.update(id, name: "Огурцы маринованные", qty: 1)
        }
        check("переименование сохраняет отдел", store.category("Огурцы маринованные") == .canned, "\(store.category("Огурцы маринованные"))")

        print(failed == 0 ? "SELFTEST OK" : "SELFTEST FAILED: \(failed)")
    }

    /// Шаги раз в 1.5 с: отметить купленным → «почём?» → сообщение → снять отметку → окно бюджета → закрыть
    static func animationScript(_ store: ShopStore) {
        let steps: [() -> Void] = [
            { store.selectedID = store.displayItems.first?.id },
            { store.setBought(store.displayItems.first { !$0.bought }?.id, true) },
            { store.notify("Проверка: сообщение над полоской «почём?»") },
            { store.selectNext(); store.setBought(store.selectedID, true) },
            { store.setBought(store.state.items.first { $0.bought }?.id, false) },
            { store.pricePrompt = nil; store.openBudget() },
            { store.isEditingBudget = false; store.toggle(\.sortBought) },
            { store.toggle(\.sortBought) },
        ]
        for (i, step) in steps.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2 + Double(i) * 1.5) { step() }
        }
    }
}
#endif
