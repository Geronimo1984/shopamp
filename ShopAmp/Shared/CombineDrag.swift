import SwiftUI

/// Перетаскивание товара на товар: «совместить» их в блюдо.
/// Удержание без движения — как раньше, короткое меню товара; удержание и перетаскивание — совмещение.
@MainActor
final class CombineDrag: ObservableObject {
    static let shared = CombineDrag()

    /// Что тащат (название товара) и откуда (список покупок или карточки)
    @Published private(set) var name: String?
    /// Над чем сейчас палец — подсвечивается
    @Published private(set) var target: String?
    /// Палец удерживает товар — прокрутка списков на это время выключена, иначе перетаскивание листало бы список
    var holding: Bool {
        get { CombineScrollState.shared.locked }
        set { if CombineScrollState.shared.locked != newValue { CombineScrollState.shared.locked = newValue } }
    }
    private(set) var scope = ""

    /// Где на экране цели: ключ цели → рамка в глобальных координатах. Не публикуется — меняется при прокрутке
    private var frames: [String: (scope: String, rect: CGRect, owner: UUID)] = [:]

    func register(_ key: String, scope: String, rect: CGRect, owner: UUID) { frames[key] = (scope, rect, owner) }
    /// Убрать только свою запись: у строки бывает вторая (скрытая) копия, её исчезновение не должно стирать цель
    func unregister(_ key: String, owner: UUID) {
        if frames[key]?.owner == owner { frames[key] = nil }
    }

    func begin(_ name: String, scope: String) {
        self.scope = scope
        self.name = name
        Haptics.tap()
    }

    func move(to point: CGPoint) {
        CombineDragPosition.shared.point = point
        let hit = targetKey(at: point)
        if hit != target {
            target = hit
            if hit != nil { Haptics.tap() }
        }
    }

    /// Отпустили: совместить с целью (товар или заголовок блюда)
    func end(at point: CGPoint, store: ShopStore) {
        defer {
            name = nil
            target = nil
        }
        guard let dragged = name, let key = targetKey(at: point) else { return }
        if key.hasPrefix(Self.dishPrefix), let id = UUID(uuidString: String(key.dropFirst(Self.dishPrefix.count))) {
            store.addIngredient(dragged, to: id)
        } else {
            store.combine(dragged, onto: key)
        }
    }

    static let dishPrefix = "dish:"

    /// Центр цели на экране (для проверочного запуска -dragdemo)
    func center(of key: String) -> CGPoint? {
        frames[key].map { CGPoint(x: $0.rect.midX, y: $0.rect.midY) }
    }

    private func targetKey(at point: CGPoint) -> String? {
        guard let dragged = name else { return nil }
        let own = ShopStore.key(dragged)
        return frames.first { key, value in
            value.scope == scope && key != own && value.rect.contains(point)
        }?.key
    }
}

/// Положение пальца — отдельно, чтобы при движении перерисовывалась только картинка под пальцем
@MainActor
final class CombineDragPosition: ObservableObject {
    static let shared = CombineDragPosition()
    @Published var point: CGPoint = .zero
}

// MARK: - Предложения при совмещении

extension ShopStore {
    /// Перетащили «dragged» на «target»: предложить имеющийся рецепт или создать новый
    func combine(_ dragged: String, onto targetKey: String) {
        guard let target = displayName(forKey: targetKey) else { return }
        let a = Self.key(dragged), b = Self.key(target)
        guard a != b else { return }
        func has(_ dish: Dish, _ key: String) -> Bool { dish.ingredients.contains { Self.key($0) == key } }

        var actions: [MenuAction] = []
        // уже есть блюда с обоими продуктами — открыть рецепт
        for dish in state.dishes where has(dish, a) && has(dish, b) {
            actions.append(MenuAction(title: "Открыть «\(dish.name)»", emoji: dish.emoji) { [weak self] in
                self?.openDishes(dish.id)
            })
        }
        // блюда с одним из них — дополнить вторым
        for dish in state.dishes where has(dish, a) != has(dish, b) {
            let missing = has(dish, a) ? target : dragged
            actions.append(MenuAction(title: "Добавить «\(missing)» в «\(dish.name)»", emoji: dish.emoji) { [weak self] in
                self?.addIngredient(missing, to: dish.id)
            })
        }
        actions = Array(actions.prefix(6))
        actions.append(MenuAction(title: "Новое блюдо из этих продуктов", emoji: "➕") { [weak self] in
            self?.editingDish = Dish(name: "", ingredients: [target, dragged])
        })
        actions.append(MenuAction(title: "Отмена") {})
        menu = SkinMenu(title: "\(target) + \(dragged)", actions: actions)
    }

    /// Добавить продукт в блюдо
    func addIngredient(_ name: String, to id: UUID) {
        guard let i = state.dishes.firstIndex(where: { $0.id == id }) else { return }
        let dish = state.dishes[i]
        guard !dish.ingredients.contains(where: { Self.key($0) == Self.key(name) }) else {
            notify("«\(name)» уже есть в «\(dish.name)»")
            return
        }
        var s = state
        s.dishes[i].ingredients.append(name)
        if s.memory[Self.key(name)] == nil { s.memory[Self.key(name)] = ItemMemory(name: name) }
        state = s
        notify("«\(name)» добавлен в «\(dish.name)»")
    }

    /// Название товара по ключу: из списка покупок или из карточек
    private func displayName(forKey key: String) -> String? {
        state.items.first { Self.key($0.name) == key }?.name ?? state.memory[key]?.name
    }
}

// MARK: - Модификаторы для строк

extension View {
    /// Товар можно перетащить на другой товар. Удержание без движения — onHold (меню товара)
    func combinable(_ name: String, scope: String = "list", onHold: (() -> Void)? = nil) -> some View {
        modifier(CombinableModifier(name: name, scope: scope, onHold: onHold))
    }

    /// Сюда можно бросить товар (заголовок блюда); nil — не цель
    @ViewBuilder
    func combineTarget(_ key: String?, scope: String = "list") -> some View {
        if let key {
            modifier(CombineTargetModifier(key: key, scope: scope))
        } else {
            self
        }
    }
}

private struct CombinableModifier: ViewModifier {
    @EnvironmentObject var store: ShopStore
    @ObservedObject private var drag = CombineDrag.shared
    let name: String
    let scope: String
    let onHold: (() -> Void)?
    @State private var held = false
    @State private var dragging = false

    func body(content: Content) -> some View {
        let key = ShopStore.key(name)
        let isTarget = drag.target == key
        content
            .scaleEffect(held && !dragging ? 1.03 : 1)
            .opacity(dragging ? 0.45 : 1)
            .overlay {
                if isTarget {
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(SkinStyle.of(store.state.skin).accent, style: StrokeStyle(lineWidth: 3, dash: [6, 4]))
                        .overlay(alignment: .trailing) {
                            Text("+").font(.system(size: 20, weight: .heavy))
                                .foregroundStyle(SkinStyle.of(store.state.skin).accent)
                                .padding(.trailing, 8)
                        }
                        .allowsHitTesting(false)
                }
            }
            .animation(.easeOut(duration: 0.12), value: held)
            .background(FrameReporter(key: key, scope: scope))
            // одновременный жест: обычный свайп по-прежнему листает список (обычный .gesture перехватывал касание)
            .simultaneousGesture(
                LongPressGesture(minimumDuration: 0.45)
                    .sequenced(before: DragGesture(minimumDistance: 0, coordinateSpace: .global))
                    .onChanged { value in
                        guard case .second(true, let move) = value else { return }
                        if !held {
                            held = true
                            drag.holding = true
                            Haptics.tap()
                        }
                        guard let move else { return }
                        if !dragging, hypot(move.translation.width, move.translation.height) > 8 {
                            dragging = true
                            drag.begin(name, scope: scope)
                        }
                        if dragging { drag.move(to: move.location) }
                    }
                    .onEnded { value in
                        defer {
                            held = false
                            dragging = false
                            drag.holding = false
                        }
                        if dragging, case .second(true, let move?) = value {
                            drag.end(at: move.location, store: store)
                        } else if dragging {
                            drag.end(at: .init(x: -1, y: -1), store: store)
                        } else {
                            onHold?()
                        }
                    }
            )
    }
}

private struct CombineTargetModifier: ViewModifier {
    @EnvironmentObject var store: ShopStore
    @ObservedObject private var drag = CombineDrag.shared
    let key: String
    let scope: String

    func body(content: Content) -> some View {
        content
            .overlay {
                if drag.target == key {
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(SkinStyle.of(store.state.skin).accent, style: StrokeStyle(lineWidth: 3, dash: [6, 4]))
                        .allowsHitTesting(false)
                }
            }
            .background(FrameReporter(key: key, scope: scope))
    }
}

/// Пока товар удерживают, списки не прокручиваются (scrollDisabled действует на все вложенные ScrollView)
struct CombineScrollLock: ViewModifier {
    @ObservedObject private var scroll = CombineScrollState.shared

    func body(content: Content) -> some View {
        content.scrollDisabled(scroll.locked)
    }
}

/// Только флаг блокировки прокрутки: корень экрана следит за ним, а не за всем перетаскиванием
@MainActor
final class CombineScrollState: ObservableObject {
    static let shared = CombineScrollState()
    @Published var locked = false
}

/// Сообщает рамку цели на экране
private struct FrameReporter: View {
    let key: String
    let scope: String
    @State private var owner = UUID()

    var body: some View {
        GeometryReader { geo in
            Color.clear
                .onAppear { CombineDrag.shared.register(key, scope: scope, rect: geo.frame(in: .global), owner: owner) }
                .onChange(of: geo.frame(in: .global)) { CombineDrag.shared.register(key, scope: scope, rect: $0, owner: owner) }
                .onDisappear { CombineDrag.shared.unregister(key, owner: owner) }
        }
    }
}

/// Картинка товара под пальцем во время перетаскивания
struct CombineDragOverlay: View {
    @EnvironmentObject var store: ShopStore
    @ObservedObject private var drag = CombineDrag.shared
    @ObservedObject private var position = CombineDragPosition.shared

    var body: some View {
        if let name = drag.name {
            let style = SkinStyle.of(store.state.skin)
            HStack(spacing: 6) {
                Image(store.icon(for: name)).resizable().interpolation(store.state.skin == .pixel ? .none : .high)
                    .frame(width: 30, height: 30)
                    .grayscale(store.state.skin == .mac ? 1 : 0)
                Text(drag.target == nil ? name : "\(name)  +")
                    .font(style.font(14, .bold))
                    .foregroundStyle(style.text)
                    .lineLimit(1)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(RoundedRectangle(cornerRadius: 8).fill(style.rowFill.opacity(1)))
            .background(RoundedRectangle(cornerRadius: 8).fill(skinBackdrop))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(style.accent, lineWidth: 2))
            .shadow(color: .black.opacity(0.35), radius: 6, y: 3)
            .fixedSize()
            // над пальцем, но не за краем экрана
            .position(x: min(max(position.point.x, 90), UIScreen.main.bounds.width - 90), y: max(position.point.y - 44, 60))
            .allowsHitTesting(false)
        }
    }

    /// Подложка, чтобы полупрозрачная заливка строки Симс не просвечивала
    private var skinBackdrop: Color {
        switch store.state.skin {
        case .sims: return Sims.panel
        case .winamp: return .black
        default: return .white
        }
    }
}
