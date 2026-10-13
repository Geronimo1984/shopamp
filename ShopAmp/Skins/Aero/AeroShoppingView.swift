import SwiftUI

/// Режим покупок — экран приветствия Windows XP.
/// Барабан крутится свайпом вверх-вниз; свайп товара вправо — в корзину, влево — обратно.
struct AeroShoppingView: View {
    @EnvironmentObject var store: ShopStore

    /// Положение барабана: дробный номер товара, стоящего по центру
    @State private var wheel: CGFloat = 0
    @State private var wheelStart: CGFloat?
    @State private var touchStart: Date?
    @State private var gestureMode: GestureMode = .undecided
    @State private var grabbed = false
    @State private var listHeight: CGFloat = 400
    @State private var appeared = false
    @State private var dragID: UUID?
    @State private var dragY: CGFloat = 0
    @State private var showHint = false

    private let rowHeight: CGFloat = 80
    private let swipeDistance: CGFloat = 30

    private enum GestureMode { case undecided, spin, swipe }

    var body: some View {
        VStack(spacing: 0) {
            topBand
            GeometryReader { geo in
                HStack(spacing: 0) {
                    welcomeColumn
                        .frame(width: geo.size.width * 0.31)
                    Rectangle()
                        .fill(LinearGradient(colors: [.white.opacity(0), .white.opacity(0.85), .white.opacity(0)],
                                             startPoint: .top, endPoint: .bottom))
                        .frame(width: 1.5)
                        .padding(.vertical, 24)
                    list
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
            .background(XPWelcomeBackground())
            bottomBand
        }
        .onAppear {
            if let i = store.displayItems.firstIndex(where: { $0.id == store.selectedID }) { wheel = CGFloat(i) }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                withAnimation(.spring(response: 0.55, dampingFraction: 0.8)) { appeared = true }
            }
        }
    }

    // MARK: Полосы сверху и снизу

    private var topBand: some View {
        XPTopBand { Color.clear }
    }

    private var bottomBand: some View {
        XPBottomBand {
            HStack(spacing: 10) {
                Button {
                    Haptics.tap()
                    store.finishShopping()
                    store.isShopping = false
                } label: {
                    HStack(spacing: 8) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 5)
                                .fill(LinearGradient(colors: [Color(hex: 0xF9C063), Color(hex: 0xE0670C)], startPoint: .top, endPoint: .bottom))
                            RoundedRectangle(cornerRadius: 5)
                                .fill(LinearGradient(colors: [.white.opacity(0.4), .clear], startPoint: .top, endPoint: .center))
                                .padding(1.5)
                            RoundedRectangle(cornerRadius: 5).stroke(.white, lineWidth: 1.5)
                            Image(systemName: "power")
                                .font(.system(size: 15, weight: .heavy))
                                .foregroundStyle(.white)
                        }
                        .frame(width: 30, height: 30)
                        Text("Закончить покупки")
                            .font(Aero.xp(16))
                            .foregroundStyle(.white)
                    }
                }
                .buttonStyle(PressScaleStyle())
                Spacer(minLength: 6)
                Button {
                    Haptics.tap()
                    store.isShopping = false
                } label: {
                    (Text("Чтобы добавить товар,\nвернитесь ") + Text("в меню").underline())
                        .font(Aero.xp(11))
                        .multilineTextAlignment(.trailing)
                        .foregroundStyle(.white)
                }
                .buttonStyle(PressScaleStyle())
            }
        }
    }

    // MARK: Левая колонка «welcome»

    private var welcomeColumn: some View {
        let done = store.totalCount > 0 && store.leftCount == 0
        return VStack(alignment: .trailing, spacing: 6) {
            Spacer()
            XPFlag().frame(width: 34, height: 30)
            Text(done ? "готово!" : "welcome")
                .font(Aero.xp(30, .bold, italic: true))
                .frame(maxWidth: .infinity, alignment: .trailing)
                .foregroundStyle(.white)
                .shadow(color: Color(hex: 0x1E3E9A).opacity(0.6), radius: 1, x: 1, y: 1)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(done ? "Всё в корзине.\nМожно на кассу" : "Крутите\nбарабан.\nВправо —\nв корзину,\nвлево — назад")
                .font(Aero.xp(12))
                .minimumScaleFactor(0.75)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .multilineTextAlignment(.trailing)
                .foregroundStyle(.white.opacity(0.95))
            Text("\(store.boughtCount) из \(store.totalCount) в корзине")
                .font(Aero.xp(11, .bold))
                .foregroundStyle(Aero.welcomeSub)
                .padding(.top, 4)
            Spacer()
        }
        .padding(.leading, 8)
        .padding(.trailing, 10)
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    // MARK: Список-барабан

    private var list: some View {
        let items = store.displayItems
        return GeometryReader { g in
            let center = g.size.height / 2
            ZStack(alignment: .topLeading) {
                // рамка-окошко выбора по центру барабана
                XPPanel(highlighted: true, radius: 12)
                    .frame(height: rowHeight - 8)
                    .padding(.horizontal, 2)
                    .offset(y: center - (rowHeight - 8) / 2)
                    .opacity(items.isEmpty ? 0 : 1)
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    let d = CGFloat(index) - wheel
                    if abs(d) < 4.5 {
                        row(item)
                            .frame(height: rowHeight)
                            .rotation3DEffect(.degrees(Double(-d) * 22), axis: (x: 1, y: 0, z: 0), perspective: 0.55)
                            .scaleEffect(1 - min(abs(d), 3) * 0.06)
                            .opacity(Double(1 - min(abs(d) / 3.6, 1) * 0.85))
                            .offset(y: center - rowHeight / 2 + wheelOffset(d))
                            .zIndex(-Double(abs(d)))
                    }
                }
                if items.isEmpty {
                    Text("Список пуст.\nВернитесь в меню и добавьте товары")
                        .font(Aero.xp(14))
                        .foregroundStyle(.white)
                        .padding(.top, 30)
                }
            }
            .frame(width: g.size.width, height: g.size.height, alignment: .topLeading)
            .offset(y: appeared ? 0 : -60)
            .opacity(appeared ? 1 : 0)
            .contentShape(Rectangle())
            .gesture(drumGesture(center: center))
            // затемнение к краям — как у настоящего барабана
            .overlay(
                LinearGradient(stops: [.init(color: Aero.welcomeBg.opacity(0.85), location: 0), .init(color: .clear, location: 0.3),
                                       .init(color: .clear, location: 0.7), .init(color: Aero.welcomeBg.opacity(0.85), location: 1)],
                               startPoint: .top, endPoint: .bottom)
                    .allowsHitTesting(false)
            )
            .overlay(alignment: .trailing) {
                // «взяли» барабан — по краям загораются засечки
                if grabbed {
                    VStack(spacing: 6) {
                        ForEach(0..<7, id: \.self) { _ in Capsule().fill(.white.opacity(0.7)).frame(width: 10, height: 2) }
                    }
                    .padding(.trailing, 6)
                    .transition(.opacity)
                }
            }
            .onAppear { listHeight = g.size.height }
        }
        .clipped()
        .overlay(alignment: .bottom) {
            if showHint {
                hintBalloon.padding(10).transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showHint)
        .animation(.easeOut(duration: 0.15), value: grabbed)
    }

    /// Вертикальный сдвиг строки на барабане: к краям строки «сжимаются», как на цилиндре
    private func wheelOffset(_ d: CGFloat) -> CGFloat {
        let angle = min(max(d * 0.38, -1.45), 1.45)
        return sin(angle) / 0.38 * rowHeight
    }

    /// Удержание + движение — крутим барабан; быстрый свайп — отметить товар; касание — выбрать
    private func drumGesture(center: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let items = store.displayItems
                guard !items.isEmpty else { return }
                if touchStart == nil {
                    touchStart = Date()
                    wheelStart = wheel
                    gestureMode = .undecided
                }
                // направление решает: по вертикали — крутим барабан, вбок — отмечаем товар
                let dx = abs(value.translation.width), dy = abs(value.translation.height)
                if gestureMode == .undecided && max(dx, dy) > 8 {
                    gestureMode = dy >= dx ? .spin : .swipe
                    if gestureMode == .spin { grabbed = true }
                }
                switch gestureMode {
                case .spin:
                    let target = (wheelStart ?? wheel) - value.translation.height / rowHeight
                    let clamped = rubberBand(target, max: CGFloat(items.count - 1))
                    let before = Int(wheel.rounded())
                    wheel = clamped
                    let now = Int(wheel.rounded())
                    if now != before, items.indices.contains(now) {
                        Haptics.tap()
                        store.selectedID = items[now].id
                    }
                case .swipe:
                    dragID = item(at: value.startLocation.y, center: center)?.id
                    dragY = max(min(value.translation.width * 0.5, 60), -60)
                case .undecided:
                    break
                }
            }
            .onEnded { value in
                let items = store.displayItems
                defer {
                    touchStart = nil
                    wheelStart = nil
                    gestureMode = .undecided
                    grabbed = false
                }
                guard !items.isEmpty else { return }
                switch gestureMode {
                case .spin:
                    // инерция броска и защёлкивание на ближайшем товаре
                    let fling = (value.predictedEndTranslation.height - value.translation.height) / rowHeight
                    let target = min(max((wheel - fling * 0.6).rounded(), 0), CGFloat(items.count - 1))
                    withAnimation(.spring(response: 0.55, dampingFraction: 0.82)) { wheel = target }
                    store.selectedID = items[Int(target)].id
                case .swipe:
                    if let item = item(at: value.startLocation.y, center: center) {
                        if value.translation.width > swipeDistance { mark(item, bought: true) }
                        else if value.translation.width < -swipeDistance { mark(item, bought: false) }
                    }
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { dragY = 0 }
                    dragID = nil
                case .undecided:
                    // простое касание — выбрать товар и повернуть барабан к нему
                    if let item = item(at: value.startLocation.y, center: center),
                       let index = items.firstIndex(where: { $0.id == item.id }) {
                        if item.id == store.selectedID {
                            store.tapItem(item.id)
                        } else {
                            store.selectedID = item.id
                            withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) { wheel = CGFloat(index) }
                        }
                    }
                }
            }
    }

    /// Товар под пальцем
    private func item(at y: CGFloat, center: CGFloat) -> ShopItem? {
        let items = store.displayItems
        var best: (Int, CGFloat)?
        for index in items.indices {
            let d = CGFloat(index) - wheel
            guard abs(d) < 4.5 else { continue }
            let dist = abs(center + wheelOffset(d) - y)
            if best == nil || dist < best!.1 { best = (index, dist) }
        }
        return best.map { items[$0.0] }
    }

    /// За краями списка барабан тянется с сопротивлением
    private func rubberBand(_ x: CGFloat, max upper: CGFloat) -> CGFloat {
        if x < 0 { return -pow(-x, 0.7) * 0.5 }
        if x > upper { return upper + pow(x - upper, 0.7) * 0.5 }
        return x
    }

    private func row(_ item: ShopItem) -> some View {
        let selected = item.id == store.selectedID
        return HStack(spacing: 10) {
            ProductTile(name: item.name, size: 46, dimmed: item.bought)
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(Aero.xp(19))
                    .foregroundStyle(.white)
                    .strikethrough(item.bought, color: .white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                if selected && !item.bought {
                    HStack(spacing: 5) {
                        Text("\(item.qty) шт")
                            .font(Aero.xp(13))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 6)
                            .frame(width: 62, height: 28, alignment: .leading)
                            .background(RoundedRectangle(cornerRadius: 3).fill(.white))
                            .overlay(RoundedRectangle(cornerRadius: 3).stroke(Color(hex: 0x8FA9D8), lineWidth: 1))
                        squareButton("arrow.right", colors: [Color(hex: 0x7BD86A), Color(hex: 0x2E9A2A)]) {
                            mark(item, bought: true)
                        }
                        squareButton("questionmark", colors: [Color(hex: 0x6CA6F5), Color(hex: 0x2A5CCB)]) {
                            showHint = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { showHint = false }
                        }
                    }
                } else {
                    Text(item.bought ? "в корзине ✓" : "\(item.qty) шт · смахните вправо")
                        .font(Aero.xp(11, .bold))
                        .foregroundStyle(Aero.welcomeSub)
                        .frame(height: 28, alignment: .leading)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        // смена выбранного товара не анимируется отдельно — строка двигается вместе с барабаном
        .transaction { $0.animation = nil }
        .opacity(item.bought ? 0.55 : 1)
        .offset(x: dragID == item.id ? dragY : 0)
    }

    private func squareButton(_ symbol: String, colors: [Color], action: @escaping () -> Void) -> some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 3)
                    .fill(LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom))
                RoundedRectangle(cornerRadius: 3).stroke(.white, lineWidth: 1)
                Image(systemName: symbol)
                    .font(.system(size: 15, weight: .heavy))
                    .foregroundStyle(.white)
            }
            .frame(width: 30, height: 28)
        }
        .buttonStyle(PressScaleStyle())
    }

    private func mark(_ item: ShopItem, bought: Bool) {
        guard item.bought != bought else { return }
        Haptics.tap()
        withAnimation(.easeInOut(duration: 0.25)) {
            store.setBought(item.id, bought)
            if bought, store.selectedID == item.id,
               let next = store.displayItems.first(where: { !$0.bought }) {
                store.selectedID = next.id
                ensureVisible(next.id)
            }
        }
    }

    /// Повернуть барабан к товару
    private func ensureVisible(_ id: UUID) {
        guard let index = store.displayItems.firstIndex(where: { $0.id == id }) else { return }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) { wheel = CGFloat(index) }
    }

}

extension AeroShoppingView {
    /// Жёлтая подсказка-«балун» как в Windows XP
    var hintBalloon: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 18))
                .foregroundStyle(.white, Color(hex: 0x2A5CCB))
            VStack(alignment: .leading, spacing: 2) {
                Text("Как отмечать покупки").font(.system(size: 12, weight: .bold))
                Text("Крутите барабан вверх-вниз. Смахните товар вправо — он в корзине,\nвлево — вернётся в список.\nЗелёная стрелка — тоже в корзину.")
                    .font(.system(size: 11))
            }
            .foregroundStyle(.black)
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color(hex: 0xFFFFE1)))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black.opacity(0.7), lineWidth: 1))
        .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
    }
}
