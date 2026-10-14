import SwiftUI

/// Окно плейлиста — сам список покупок
struct PlaylistWindow: View {
    @EnvironmentObject var store: ShopStore
    /// Масштаб скина (ширина экрана / 1200)
    let k: CGFloat

    private var fontSize: CGFloat { max(40 * k, 18) }

    var body: some View {
        VStack(spacing: 0) {
            Scaled(k: k, size: CGSize(width: 1200, height: 42)) {
                TitleBar(title: "WINAMP PLAYLIST", showIcon: false, buttons: [.shade, .close]) {
                    store.state.showPlaylist = false
                }
            }

            HStack(spacing: 0) {
                list
                scrollbar
                    .frame(width: max(26 * k, 10))
            }
            .background(Color.black)
            .overlay(Rectangle().strokeBorder(Winamp.frameDark, lineWidth: 2))
            .padding(.horizontal, 12 * k)
            .padding(.top, 2 * k)

            bottomBar
        }
        .background(WindowBody(line: 6 * k).ignoresSafeArea(edges: .bottom))
    }

    // MARK: Список

    private var list: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(store.displayItems.enumerated()), id: \.element.id) { index, item in
                        row(index: index, item: item)
                            .id(item.id)
                    }
                    if store.state.items.isEmpty {
                        Text("Список пуст — нажмите ADD")
                            .foregroundStyle(Winamp.listBought)
                            .padding(.horizontal, 8 * k + 4)
                            .frame(height: fontSize * 1.4)
                    }
                    if store.state.autoSuggest, !store.dueSuggestions.isEmpty {
                        Text("—— КУПИТЬ СНОВА ——")
                            .foregroundStyle(Winamp.listDue)
                            .font(.custom("Arial", size: fontSize * 0.75))
                            .padding(.horizontal, 8 * k + 4)
                            .padding(.top, fontSize * 0.5)
                        ForEach(store.dueSuggestions, id: \.name) { memory in
                            dueRow(memory)
                        }
                    }
                }
                .font(.custom("Arial", size: fontSize))
                .padding(.vertical, 6 * k)
            }
            .onChange(of: store.selectedID) { id in
                guard let id else { return }
                withAnimation(.easeOut(duration: 0.2)) { proxy.scrollTo(id) }
            }
        }
    }

    private func row(index: Int, item: ShopItem) -> some View {
        let selected = item.id == store.selectedID
        let color: Color = selected ? Winamp.white : (item.bought ? Winamp.listBought : Winamp.listGreen)
        return HStack(spacing: 8) {
            Text("\(index + 1). \(item.name)")
                .strikethrough(item.bought, color: color.opacity(0.7))
                .lineLimit(1)
            Spacer(minLength: 8)
            Text(item.bought ? "✓" + (store.cost(item).map { " " + ShopStore.rub($0) } ?? "") : store.qtyText(item))
                .font(.custom("Arial", size: fontSize * 0.8))
        }
        .foregroundStyle(color)
        .padding(.horizontal, 8 * k + 4)
        .frame(height: max(fontSize * 1.38, 44))
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
            Haptics.tap()
            store.selectedID = item.id
            store.toggleBought(item.id)
        }
        .onTapGesture {
            store.tapItem(item.id)
        }
        .onLongPressGesture { store.openItemMenu(item.id) }
    }

    private func dueRow(_ memory: ItemMemory) -> some View {
        HStack(spacing: 8) {
            Text("+ \(memory.name)").lineLimit(1)
            Spacer(minLength: 8)
            if let interval = memory.interval {
                Text("раз в \(Int(interval.rounded())) дн")
                    .font(.custom("Arial", size: fontSize * 0.8))
            }
        }
        .foregroundStyle(Winamp.listDue)
        .padding(.horizontal, 8 * k + 4)
        .frame(height: max(fontSize * 1.38, 44))
        .contentShape(Rectangle())
        .pressable(.winamp) {
            Haptics.tap()
            store.add(memory.name)
        }
    }

    private var scrollbar: some View {
        GeometryReader { g in
            let thumbH = max(34 * k, 14)
            let list = store.displayItems
            let index = list.firstIndex { $0.id == store.selectedID } ?? 0
            let fraction = list.count > 1 ? CGFloat(index) / CGFloat(list.count - 1) : 0
            ZStack(alignment: .top) {
                Rectangle().fill(Color(hex: 0x0B0D26))
                Bevel(edge: max(2 * k, 1), top: Winamp.goldTop, bottom: Winamp.goldBottom)
                    .frame(width: g.size.width * 0.6, height: thumbH)
                    .offset(y: 4 + (g.size.height - thumbH - 8) * fraction)
                    .animation(.easeOut(duration: 0.2), value: fraction)
            }
        }
    }

    // MARK: Нижняя панель — крупные кнопки под палец (высота 44 pt)

    private var bottomBar: some View {
        VStack(spacing: 6) {
            HStack {
                Text("\(store.boughtCount)/\(store.totalCount) КУПЛЕНО")
                Spacer()
                Text(store.hasPrices ? "КОРЗИНА \(Int(store.cartTotal.rounded()))/" + ShopStore.total(store.listTotal) : "ОСТАЛОСЬ \(store.leftCount)")
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .font(.system(size: 13, weight: .bold, design: .monospaced))
            .foregroundStyle(Winamp.listGreen)
            .padding(.horizontal, 8)
            .frame(height: 24)
            .background(Color.black)
            .overlay(Rectangle().strokeBorder(Winamp.frameDark, lineWidth: 1.5))
            HStack(spacing: 6) {
                barButton("ADD") { store.isEditingMemory = true }
                    .assistAnchor("add")
                barButton("REM") { store.remove(store.selectedID) }
                    .assistAnchor("rem")
                barButton("EDIT") { store.edit(store.selectedID) }
                    .assistAnchor("edit")
                barButton("MISC") { store.openMainMenu() }
                    .assistAnchor("misc")
                barButton("?") { store.showHelp = true }
                    .assistAnchor("help")
            }
        }
        .padding(.horizontal, 12 * k + 2)
        .padding(.top, 6)
        .padding(.bottom, 8)
    }

    private func barButton(_ text: String, action: @escaping () -> Void) -> some View {
        SkinButton(edge: 1.5, action: action) {
            Text(text)
                .font(.system(size: 14, weight: .black, design: .monospaced))
                .foregroundStyle(Winamp.ink)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 44)
    }
}
