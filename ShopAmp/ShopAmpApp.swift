import SwiftUI

@main
struct ShopAmpApp: App {
    /// Флаг запуска -demo: тестовый список без записи на диск (для скриншотов)
    @StateObject private var store = ProcessInfo.processInfo.arguments.contains("-demo")
        ? ShopStore.demo()
        : ShopStore()
    @Environment(\.scenePhase) private var scenePhase

    init() {
        FontRegistry.registerBundledFonts()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .onAppear {
                    // Флаги для скриншотов: -skins — сразу открыть выбор скина
                    let args = ProcessInfo.processInfo.arguments
                    if args.contains("-skins") { store.isChoosingSkin = true }
                    // -skin=<id>: открыть демо сразу в нужном скине; -shop: сразу режим покупок
                    if args.contains("-demo"), let arg = args.first(where: { $0.hasPrefix("-skin=") }),
                       let skin = SkinID(rawValue: String(arg.dropFirst(6))) {
                        store.state.skin = skin
                    }
                    if args.contains("-shop") { store.isShopping = true }
                    // окна для скриншотов: -help, -memory, -menu, -edit
                    if args.contains("-demo") {
                        if args.contains("-help") { store.showHelp = true }
                        if args.contains("-memory") { store.isEditingMemory = true }
                        // блюда: -dishes — окно блюд, -dishedit — редактор, -bydish — список по блюдам
                        if args.contains("-dishes") { store.openDishes(store.state.dishes.first?.id) }
                        if args.contains("-dishedit") { store.editingDish = store.state.dishes.first }
                        if args.contains("-dishnew") { store.newDish(fromList: true) }
                        // умная корзина: -budget — окно бюджета, -priceprompt — «почём?» для бананов
                        if args.contains("-budget") { store.openBudget() }
                        if args.contains("-priceprompt") { store.pricePrompt = PricePrompt(name: "Бананы", qty: 6) }
                        // совмещение товаров: -combine — меню «Огурцы + Фета», -combine2 — «Бананы + Яйца», -dragdemo — товар под пальцем
                        if args.contains("-combine") { store.combine("Огурцы", onto: ShopStore.key("Фета")) }
                        if args.contains("-combine2") { store.combine("Бананы", onto: ShopStore.key("Яйца")) }
                        if args.contains("-dragdemo") {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                let drag = CombineDrag.shared
                                drag.begin("Бананы", scope: "list")
                                if let point = drag.center(of: ShopStore.key("Яйца")) { drag.move(to: point) }
                            }
                        }
                        if args.contains("-bydish") { store.state.groupByDish = true }
                        if args.contains("-catmenu"), let name = store.selectedItem?.name { store.chooseCategory(for: name) }
                        if args.contains("-menu") { store.openMainMenu() }
                        if args.contains("-edit") { store.edit(store.selectedID) }
                        if args.contains("-icons") { store.iconPickerName = store.selectedItem?.name }
                        // пасхалки для скриншотов
                        if args.contains("-msn") { store.msnPopup = true }
                        if args.contains("-marquee") { store.marqueeEasterUntil = Date().addingTimeInterval(60) }
                    }
                }
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active {
                store.appBecameActive()
            }
        }
    }
}
