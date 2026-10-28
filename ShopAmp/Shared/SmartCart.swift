import SwiftUI

/// Цена, которую подтвердили на кассе
struct PricePoint: Codable, Equatable {
    var date: Date
    var price: Double
}

/// Вопрос «почём?» после отметки товара купленным
struct PricePrompt: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let qty: Int
}

/// Итог сравнения списка с бюджетом похода
enum BudgetVerdict: Equatable {
    case none
    case fits(left: Double)
    case over(by: Double)
}

extension ShopStore {
    // MARK: - Бюджет похода

    var budgetVerdict: BudgetVerdict {
        guard let budget = state.tripBudget, budget > 0 else { return .none }
        let total = listTotal
        return total <= budget ? .fits(left: budget - total) : .over(by: total - budget)
    }

    /// «Уложитесь, запас ~800 ₽» / «Перебор ~600 ₽»; nil — бюджет не задан
    var budgetVerdictText: String? {
        switch budgetVerdict {
        case .none: return nil
        case .fits(let left): return "уложитесь, запас ~" + Self.total(left)
        case .over(let by): return "перебор ~" + Self.total(by)
        }
    }

    /// Короткая метка для строк состояния: «✓ 5 000» или «▲ +600»
    var budgetTag: String? {
        switch budgetVerdict {
        case .none: return nil
        case .fits: return "✓ " + Self.total(state.tripBudget ?? 0)
        case .over(let by): return "▲ +" + Self.total(by)
        }
    }

    var isOverBudget: Bool { if case .over = budgetVerdict { return true } else { return false } }

    func setBudget(_ value: Double?) {
        state.tripBudget = value.flatMap { $0 > 0 ? $0.rounded() : nil }
    }

    /// Что отложить, чтобы уложиться: сначала товары не из блюд, дорогие первыми, пока не хватит
    var budgetCuts: [ShopItem] {
        guard case .over(let by) = budgetVerdict else { return [] }
        let candidates = state.items.filter { !$0.bought && cost($0) != nil }
            .sorted { a, b in
                let da = dish(containing: a.name) != nil, db = dish(containing: b.name) != nil
                if da != db { return !da }
                return (cost(a) ?? 0) > (cost(b) ?? 0)
            }
        var saved = 0.0
        var result: [ShopItem] = []
        for item in candidates where saved < by {
            result.append(item)
            saved += cost(item) ?? 0
        }
        return result
    }

    func openBudget() { isEditingBudget = true }

    // MARK: - Цена на кассе

    /// Подтвердить цену за штуку: она становится ценой карточки и записывается в историю (одна запись в день)
    func confirmPrice(_ name: String, _ value: Double) {
        guard value > 0 else { return }
        setPrice(name, value)
        let key = Self.key(name)
        guard var memory = state.memory[key] else { return }
        let now = Date()
        memory.priceHistory.removeAll { Calendar.current.isDate($0.date, inSameDayAs: now) }
        memory.priceHistory.append(PricePoint(date: now, price: (value * 100).rounded() / 100))
        state.memory[key] = memory
    }

    /// «99 → 115 → 129 ₽ · +30% за 7 мес.»; nil — меньше двух цен в истории
    func priceTrend(_ name: String) -> String? {
        let history = (state.memory[Self.key(name)]?.priceHistory ?? []).sorted { $0.date < $1.date }
        guard history.count >= 2, let first = history.first, let last = history.last else { return nil }
        let chain = history.suffix(4).map { Self.priceText($0.price) }.joined(separator: " → ") + " ₽"
        let change = (last.price - first.price) / first.price * 100
        let sign = change > 0 ? "+" : (change < 0 ? "−" : "")
        let months = Calendar.current.dateComponents([.month], from: first.date, to: last.date).month ?? 0
        let period = months >= 1 ? "за \(months) мес." : "за месяц"
        return chain + " · \(sign)\(Int(abs(change).rounded()))% \(period)"
    }
}

// MARK: - Окно «Бюджет похода»

struct BudgetView: View {
    @EnvironmentObject var store: ShopStore
    let skin: SkinID
    @State private var text = ""

    var body: some View {
        let style = SkinStyle.of(skin)
        SkinChrome(title: "Бюджет похода", skin: skin, onClose: { store.isEditingBudget = false }) {
            VStack(alignment: .leading, spacing: 10) {
                summary(style)
                HStack(spacing: 6) {
                    Text("Бюджет").font(style.font(14, .regular)).foregroundStyle(style.text)
                    TextField("", text: $text, prompt: Text("не задан").foregroundColor(style.secondary))
                        .font(style.font(16, .bold))
                        .foregroundStyle(style.text)
                        .multilineTextAlignment(.trailing)
                        .keyboardType(.numberPad)
                        .padding(.horizontal, 8)
                        .frame(width: 120, height: 40)
                        .background(RoundedRectangle(cornerRadius: 4).fill(style.rowFill))
                        .overlay(RoundedRectangle(cornerRadius: 4).stroke(style.rowStroke, lineWidth: 1.5))
                        .onChange(of: text) { store.setBudget(ShopStore.parsePrice($0)) }
                    Text("₽").font(style.font(14, .regular)).foregroundStyle(style.secondary)
                    Spacer(minLength: 0)
                }
                FlowLayout(spacing: 6, lineSpacing: 6) {
                    ForEach([1000, 2000, 3000, 5000, 7000, 10000], id: \.self) { value in
                        SkinChip(title: ShopStore.total(Double(value)), style: style,
                                 filled: store.state.tripBudget == Double(value)) { set(Double(value)) }
                    }
                    SkinChip(title: "Без бюджета", style: style, filled: store.state.tripBudget == nil) { set(nil) }
                }
                cuts(style)
                Button {
                    Haptics.tap()
                    store.toggle(\.askPriceAtCheckout)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: store.state.askPriceAtCheckout ? "checkmark.square.fill" : "square")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(store.state.askPriceAtCheckout ? style.accent : style.secondary)
                        Text("Спрашивать цену, когда отмечаю купленным — так запоминаются цены и видно, как они растут")
                            .font(style.font(13, .regular))
                            .foregroundStyle(style.text)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .buttonStyle(SkinPressStyle(skin: skin))
                HStack {
                    Spacer()
                    SkinChip(title: "Готово", style: style, filled: true) { store.isEditingBudget = false }
                }
            }
        }
        .onAppear { text = store.state.tripBudget.map { String(Int($0)) } ?? "" }
    }

    private func set(_ value: Double?) {
        store.setBudget(value)
        text = value.map { String(Int($0)) } ?? ""
        KeyboardWatcher.hide()
    }

    @ViewBuilder
    private func summary(_ style: SkinStyle) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(store.hasPrices ? "Список выйдет ~" + ShopStore.total(store.listTotal) : "У товаров пока нет цен")
                .font(style.font(17, .bold))
                .foregroundStyle(style.text)
            Text("в корзине " + ShopStore.total(store.cartTotal)
                 + (store.unpricedCount > 0 ? " · без цены: \(store.unpricedCount)" : ""))
                .font(style.font(13, .regular))
                .foregroundStyle(style.secondary)
            if let verdict = store.budgetVerdictText {
                Text(store.isOverBudget ? "▲ " + verdict.capitalizedFirst : "✓ " + verdict.capitalizedFirst)
                    .font(style.font(15, .bold))
                    .foregroundStyle(store.isOverBudget ? Color(hex: 0xE0442A) : style.accent)
            }
        }
    }

    /// Что отложить при переборе
    @ViewBuilder
    private func cuts(_ style: SkinStyle) -> some View {
        let cuts = store.budgetCuts
        if !cuts.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                Text("Можно отложить на следующий раз:")
                    .font(style.font(13, .bold))
                    .foregroundStyle(style.text)
                ForEach(cuts) { item in
                    HStack(spacing: 8) {
                        ProductImage(name: item.name, size: 24, pixelated: skin == .pixel)
                            .grayscale(skin == .mac ? 1 : 0)
                        VStack(alignment: .leading, spacing: 0) {
                            Text(item.name).font(style.font(14, .semibold)).foregroundStyle(style.text).lineLimit(1)
                            Text(store.qtyText(item)).font(style.font(11, .regular)).foregroundStyle(style.secondary)
                        }
                        Spacer(minLength: 4)
                        SkinChip(title: "Убрать", style: style) {
                            store.remove(item.id)
                            store.notify("«\(item.name)» убран из списка, карточка осталась")
                        }
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(RoundedRectangle(cornerRadius: 4).fill(style.rowFill))
                }
            }
        }
    }
}

private extension String {
    var capitalizedFirst: String { prefix(1).uppercased() + dropFirst() }
}

// MARK: - «Почём?» на кассе

/// Полоска внизу экрана после отметки «куплено»: цена подставлена, ✓ — подтвердить, можно исправить
struct PricePromptBar: View {
    @EnvironmentObject var store: ShopStore
    let prompt: PricePrompt
    @State private var text = ""
    @FocusState private var focused: Bool

    var body: some View {
        let skin = store.state.skin
        let style = SkinStyle.of(skin)
        HStack(spacing: 8) {
            ProductImage(name: prompt.name, size: 30, pixelated: skin == .pixel)
                .grayscale(skin == .mac ? 1 : 0)
            VStack(alignment: .leading, spacing: 0) {
                Text(prompt.name).font(style.font(14, .bold)).foregroundStyle(style.text).lineLimit(1)
                Text(prompt.qty > 1 ? "почём за шт?" : "почём?")
                    .font(style.font(11, .regular)).foregroundStyle(style.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            Spacer(minLength: 4)
            TextField("", text: $text, prompt: Text("0").foregroundColor(style.secondary))
                .font(style.font(16, .bold))
                .foregroundStyle(style.text)
                .multilineTextAlignment(.trailing)
                .keyboardType(.decimalPad)
                .focused($focused)
                .padding(.horizontal, 6)
                .frame(width: 70, height: 38)
                .background(RoundedRectangle(cornerRadius: 4).fill(style.rowFill))
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(style.rowStroke, lineWidth: 1.5))
            Text("₽").font(style.font(14, .regular)).foregroundStyle(style.secondary)
            SkinChip(title: "✓", style: style, filled: true) { confirm() }
            Button {
                Haptics.tap()
                close()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(style.secondary)
                    .frame(width: 30, height: 38)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(RoundedRectangle(cornerRadius: 10).fill(style.rowFill))
        .background(RoundedRectangle(cornerRadius: 10).fill(backdrop(skin)))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(style.accent, lineWidth: 2))
        .shadow(color: .black.opacity(0.3), radius: 6, y: 3)
        .onAppear { text = ShopStore.priceText(store.price(prompt.name)) }
        // сама исчезает через 8 секунд, если её не трогают
        .task(id: prompt.id) {
            try? await Task.sleep(nanoseconds: 8_000_000_000)
            if !focused && store.pricePrompt == prompt { store.pricePrompt = nil }
        }
    }

    private func confirm() {
        if let value = ShopStore.parsePrice(text) {
            store.confirmPrice(prompt.name, value)
            store.notify("Цена «\(prompt.name)» запомнена: " + ShopStore.rub(value))
        }
        close()
    }

    private func close() {
        focused = false
        store.pricePrompt = nil
    }

    private func backdrop(_ skin: SkinID) -> Color {
        switch skin {
        case .sims: return Sims.panel
        case .winamp: return .black
        default: return .white
        }
    }
}
