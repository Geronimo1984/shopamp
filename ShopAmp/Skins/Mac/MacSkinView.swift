import SwiftUI

/// Скин Macintosh: 1-битный монитор, рабочий стол, Finder-список и Control Panel
struct MacSkinView: View {
    @EnvironmentObject var store: ShopStore
    @State private var openBuy = true
    @State private var openCart = true
    @State private var openDue = false
    @State private var showLegend = false

    var body: some View {
        ZStack {
            Mac.bezel.ignoresSafeArea()
            VStack(spacing: 2) {
                screen
                bezelBottom
            }
            .padding(.horizontal, 5)
            .padding(.top, 2)
            // нижняя полоса корпуса занимает половину зоны полоски «домой»: монитору больше высоты,
            // а кнопки не попадают в скруглённые углы экрана
            .padding(.bottom, max(KeyboardWatcher.insets.bottom * 0.5, 4))
            .ignoresSafeArea(.container, edges: .bottom)
        }
        .overlay {
            if store.isAdding || store.editingID != nil {
                MacAddItemDialog()
            } else if store.isChoosingSkin {
                MacSkinBrowser()
            }
        }
        .onChange(of: store.leftCount) { left in
            if left == 0, store.totalCount > 0 {
                withAnimation(.easeOut(duration: 0.2)) { showLegend = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                    withAnimation { showLegend = false }
                }
            }
        }
    }

    // MARK: Монитор

    private var screen: some View {
        VStack(spacing: 6) {
            // иконки — своей высоты, список не должен их сжимать
            desktopIcons.fixedSize(horizontal: false, vertical: true)
            // своя высота по содержимому: при жёсткой высоте окно вылезало вверх и закрывало подписи иконок
            controlPanel
                .fixedSize(horizontal: false, vertical: true)
                .assistAnchor("controlPanel")
            finderWindow
                .frame(maxHeight: .infinity)
            statusBar
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 7)
        .background(Mac.screen)
        .overlay(alignment: .center) {
            if showLegend {
                legendToast
                    .padding(20)
                    .transition(.scale(scale: 0.9).combined(with: .opacity))
                    .onTapGesture { withAnimation { showLegend = false } }
            }
        }
        .padding(4)
        .background(Dither(a: Mac.ink, b: Mac.bezel, cell: 1.5))
        .overlay(Rectangle().stroke(Mac.ink, lineWidth: 3))
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Mac.bezel)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Mac.ink, lineWidth: 3))
        )
    }

    /// Низ корпуса: кнопка скина слева, решётка справа — на ней стоит скрепка
    private var bezelBottom: some View {
        HStack {
            Button {
                Haptics.tap()
                store.isChoosingSkin = true
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 4).stroke(Mac.ink, lineWidth: 3)
                    RoundedRectangle(cornerRadius: 2).fill(Mac.ink).padding(6)
                }
                .frame(width: 26, height: 26)
            }
            .buttonStyle(MacInvertStyle())
            .assistAnchor("power")
            Text("◂ скин")
                .font(Mac.font(13, .semibold))
                .foregroundStyle(Mac.ink)
            Spacer()
            VStack(spacing: 3) {
                ForEach(0..<5, id: \.self) { _ in
                    Rectangle().fill(Mac.ink).frame(width: 70, height: 2)
                }
            }
        }
        // отступ от скруглённых углов экрана
        .padding(.horizontal, 22)
        .frame(height: 30)
        // место скрепки: стоит на решётке справа, не закрывая сумму в строке состояния
        .overlay(alignment: .bottomTrailing) {
            Color.clear
                .frame(width: 104, height: 78)
                .padding(.trailing, 16)
                .padding(.bottom, 6)
                .assistAnchor("clippy")
                .allowsHitTesting(false)
        }
    }

    // MARK: Иконки рабочего стола

    private var desktopIcons: some View {
        HStack(alignment: .top, spacing: 4) {
            desktopIcon(MacIcons.mail, "Добавить") { store.isEditingMemory = true }
                .assistAnchor("add")
            desktopIcon(MacIcons.card, "Снова (\(store.dueSuggestions.count))") { store.addDue() }
                .assistAnchor("again")
            desktopIcon(MacIcons.folder, "Карточки") { store.isEditingMemory = true }
                .assistAnchor("cards")
            desktopIcon(MacIcons.help, "Справка") { store.showHelp = true }
                .assistAnchor("help")
            Button {
                Haptics.tap()
                store.openMainMenu()
            } label: {
                iconLabel(MacIcons.gear, "Меню")
            }
            .buttonStyle(MacInvertStyle())
            .assistAnchor("menu")
        }
        .padding(.horizontal, 4)
    }

    private func desktopIcon(_ bitmap: [String], _ title: String, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            iconLabel(bitmap, title)
        }
        .buttonStyle(MacInvertStyle())
    }

    private func iconLabel(_ bitmap: [String], _ title: String) -> some View {
        VStack(spacing: 3) {
            PixelBitmap(rows: bitmap, ink: Mac.paper, paper: Mac.ink)
                .frame(width: 36, height: 28)
            Text(title)
                .font(Mac.font(12))
                .foregroundStyle(Mac.paper)
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity)
        }
    }

    // MARK: Control Panel

    private var controlPanel: some View {
        MacWindow(title: "Control Panel") {
            HStack(spacing: 0) {
                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        MacGroupBox {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Подсказки").font(Mac.font(13, .semibold))
                                radioRow("Вкл", on: store.state.autoSuggest) { if !store.state.autoSuggest { store.toggle(\.autoSuggest) } }
                                radioRow("Выкл", on: !store.state.autoSuggest) { if store.state.autoSuggest { store.toggle(\.autoSuggest) } }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        MacGroupBox {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Купленное").font(Mac.font(13, .semibold))
                                radioRow("На месте", on: !store.state.sortBought) { if store.state.sortBought { store.toggle(\.sortBought) } }
                                radioRow("В конец", on: store.state.sortBought) { if !store.state.sortBought { store.toggle(\.sortBought) } }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    MacGroupBox {
                        HStack(spacing: 8) {
                            Text("В корзине").font(Mac.font(13, .semibold)).lineLimit(1).fixedSize()
                            progressBar
                            Text("\(store.boughtCount)/\(store.totalCount)")
                                .font(Mac.font(14, .bold))
                        }
                    }
                }
                MacGroupBox {
                    qtySlider
                }
                .assistAnchor("qty")
                .frame(width: 74)
            }
            .foregroundStyle(Mac.ink)
        }
    }

    private func radioRow(_ title: String, on: Bool, action: @escaping () -> Void) -> some View {
        HStack(spacing: 6) {
            MacRadio(on: on)
            Text(title).font(Mac.font(14)).lineLimit(1).minimumScaleFactor(0.7)
        }
        .frame(minHeight: 27)
        .contentShape(Rectangle())
        .pressable(.mac) {
            Haptics.tap()
            action()
        }
    }

    private var progressBar: some View {
        GeometryReader { g in
            let progress = store.totalCount == 0 ? 0 : CGFloat(store.boughtCount) / CGFloat(store.totalCount)
            ZStack(alignment: .leading) {
                Rectangle().fill(Mac.paper)
                Dither(a: Mac.ink, b: Mac.paper, cell: 1.5)
                    .frame(width: g.size.width * progress)
                Rectangle().stroke(Mac.ink, lineWidth: 2)
            }
        }
        .frame(height: 14)
    }

    /// «Speaker Volume» — количество выбранного товара
    private var qtySlider: some View {
        let qty = store.selectedItem?.qty ?? 0
        return VStack(spacing: 2) {
            HStack(alignment: .center, spacing: 4) {
                VStack(spacing: 0) {
                    ForEach((1...10).reversed(), id: \.self) { n in
                        Text(n % 3 == 1 || n == 10 ? "\(n)" : "·")
                            .font(Mac.font(9))
                            .frame(height: 8)
                    }
                }
                GeometryReader { g in
                    let value = CGFloat(max(qty - 1, 0)) / 9
                    ZStack(alignment: .top) {
                        Rectangle().fill(Mac.ink).frame(width: 4)
                        Rectangle()
                            .fill(Mac.paper)
                            .overlay(Rectangle().stroke(Mac.ink, lineWidth: 2))
                            .overlay(Rectangle().fill(Mac.ink).frame(height: 2).padding(.horizontal, 4))
                            .frame(width: 22, height: 12)
                            .offset(y: (g.size.height - 12) * (1 - value))
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0).onChanged { drag in
                            let v = 1 - min(max(drag.location.y / g.size.height, 0), 1)
                            store.setQty(store.selectedID, 1 + Int((v * 9).rounded()))
                        }
                    )
                }
            }
            Text("Кол-во").font(Mac.font(12, .semibold))
        }
    }

    // MARK: Finder

    private var finderWindow: some View {
        let buy = store.displayItems.filter { !$0.bought }
        let cart = store.displayItems.filter(\.bought)
        let due = store.state.autoSuggest ? store.dueSuggestions : []
        return MacWindow(title: "Список покупок") {
            VStack(spacing: 0) {
                HStack {
                    Text("\(store.totalCount) предм.")
                    Spacer()
                    Text("\(store.boughtCount) в корзине")
                    Spacer()
                    Text("\(store.leftCount) осталось")
                }
                .font(Mac.font(13))
                .padding(.horizontal, 8)
                .frame(height: 24)
                Rectangle().fill(Mac.ink).frame(height: 1)
                HStack {
                    Text("Название").underline()
                    Spacer()
                    Text("Кол-во")
                }
                .font(Mac.font(13, .semibold))
                .padding(.horizontal, 8)
                .frame(height: 22)
                Rectangle().fill(Mac.ink).frame(height: 2)

                HStack(spacing: 0) {
                    ScrollViewReader { assistProxy in
ScrollView(.vertical, showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 0) {
                            folderRow("Купить", count: buy.count, open: $openBuy)
                            if openBuy {
                                ForEach(Array(buy.enumerated()), id: \.element.id) { index, item in
                                    if let cat = store.sectionHeader(buy, at: index) {
                                        CategoryHeader(skin: .mac, section: cat).padding(.leading, 24)
                                    }
                                    itemRow(item)
                                }
                            }
                            folderRow("В корзине", count: cart.count, open: $openCart)
                            if openCart {
                                ForEach(cart) { itemRow($0) }
                            }
                            folderRow("Купить снова", count: due.count, open: $openDue)
                            if openDue {
                                ForEach(due, id: \.name) { dueRow($0) }
                                memorySettingsRow
                            }
                        }
                        .padding(.vertical, 4)
                    }
.scrollsToAssistTarget(assistProxy, store.assistantTarget)
}
                    macScrollbar
                }
                Rectangle().fill(Mac.ink).frame(height: 2)
                HStack(spacing: 8) {
                    Button("Добавить") { store.isEditingMemory = true }
                        .buttonStyle(MacButtonStyle(isDefault: true))
                    Button("Изменить") { store.edit(store.selectedID) }
                        .buttonStyle(MacButtonStyle())
                        .assistAnchor("edit")
                    Button("Готово") { store.finishShopping() }
                        .buttonStyle(MacButtonStyle())
                        .assistAnchor("done")
                    Spacer(minLength: 0)
                }
                .padding(8)
            }
            .foregroundStyle(Mac.ink)
        }
    }

    private func folderRow(_ title: String, count: Int, open: Binding<Bool>) -> some View {
        HStack(spacing: 8) {
            DisclosureTriangle(open: open.wrappedValue)
                .assistAnchor("folders", when: title == "Купить")
            PixelBitmap(rows: MacIcons.folder).frame(width: 22, height: 16)
            Text("\(title) (\(count))").font(Mac.font(16, .semibold))
            Spacer()
        }
        .padding(.horizontal, 8)
        .frame(height: 42)
        .contentShape(Rectangle())
        .pressable(.mac) {
            Haptics.tap()
            open.wrappedValue.toggle()
        }
    }

    private func itemRow(_ item: ShopItem) -> some View {
        let selected = item.id == store.selectedID
        let fg = selected ? Mac.paper : Mac.ink
        return HStack(spacing: 8) {
            MacCheckbox(checked: item.bought, size: 20)
                .frame(width: 36, height: 36)
                .contentShape(Rectangle())
                .assistAnchor("checkbox", when: item.id == store.displayItems.first?.id)
                .pressable(.mac) {
                    Haptics.tap()
                    store.toggleBought(item.id)
                }
            PixelBitmap(rows: MacIcons.bag, ink: fg, paper: selected ? Mac.ink : Mac.paper)
                .frame(width: 16, height: 15)
            Text(item.name)
                .font(Mac.font(17))
                .minimumScaleFactor(0.75)
                .strikethrough(item.bought, color: fg)
                .lineLimit(1)
                .layoutPriority(1)
            Spacer(minLength: 4)
            // количество и цена — узким столбиком в две строки, чтобы название помещалось
            VStack(alignment: .trailing, spacing: 0) {
                Text("\(item.qty) шт").font(Mac.font(13))
                if let cost = store.cost(item) {
                    Text(ShopStore.rub(cost)).font(Mac.font(12))
                }
            }
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .fixedSize()
        }
        .foregroundStyle(fg)
        .padding(.leading, 30)
        .padding(.trailing, 8)
        .frame(height: 42)
        .background(selected ? Mac.ink : Color.clear)
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
            Haptics.tap()
            store.toggleBought(item.id)
        }
        .assistAnchor("list", when: item.id == store.displayItems.first?.id)
        .onTapGesture { store.tapItem(item.id) }
        .combinable(item.name) { store.openItemMenu(item.id) }
    }

    private var memorySettingsRow: some View {
        HStack(spacing: 8) {
            PixelBitmap(rows: MacIcons.gear).frame(width: 16, height: 16)
            Text("Настроить «Купить снова»…").font(Mac.font(16)).underline()
            Spacer()
        }
        .padding(.leading, 30)
        .frame(height: 42)
        .contentShape(Rectangle())
        .pressable(.mac) {
            Haptics.tap()
            store.isEditingMemory = true
        }
    }

    private func dueRow(_ memory: ItemMemory) -> some View {
        HStack(spacing: 8) {
            Text("+").font(Mac.font(18, .bold)).frame(width: 16)
            PixelBitmap(rows: MacIcons.bag).frame(width: 16, height: 15)
            Text(memory.name).font(Mac.font(16)).lineLimit(1)
            Spacer(minLength: 4)
            if let interval = memory.interval {
                Text("раз в \(Int(interval.rounded())) дн").font(Mac.font(13))
            }
        }
        .padding(.leading, 30)
        .padding(.trailing, 8)
        .frame(height: 42)
        .contentShape(Rectangle())
        .pressable(.mac) {
            Haptics.tap()
            store.add(memory.name)
        }
    }

    private var macScrollbar: some View {
        VStack(spacing: 0) {
            scrollArrow(up: true)
            GeometryReader { g in
                let list = store.displayItems
                let index = list.firstIndex { $0.id == store.selectedID } ?? 0
                let fraction = list.count > 1 ? CGFloat(index) / CGFloat(list.count - 1) : 0
                ZStack(alignment: .top) {
                    Dither(a: Mac.ink, b: Mac.paper, cell: 1.5)
                    Rectangle()
                        .fill(Mac.paper)
                        .overlay(Rectangle().stroke(Mac.ink, lineWidth: 2))
                        .frame(height: 18)
                        .offset(y: (g.size.height - 18) * fraction)
                }
            }
            scrollArrow(up: false)
        }
        .frame(width: 30)
        .overlay(Rectangle().stroke(Mac.ink, lineWidth: 2))
    }

    private func scrollArrow(up: Bool) -> some View {
        Button {
            Haptics.tap()
            up ? store.selectPrev() : store.selectNext()
        } label: {
            Image(systemName: up ? "arrowtriangle.up" : "arrowtriangle.down")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(Mac.ink)
                .frame(width: 30, height: 30)
                .background(Mac.paper)
                .overlay(Rectangle().stroke(Mac.ink, lineWidth: 2))
        }
        .buttonStyle(MacInvertStyle())
    }

    // MARK: Строка статуса

    private var statusBar: some View {
        HStack(spacing: 8) {
            HStack(spacing: 6) {
                PixelBitmap(rows: MacIcons.smile, ink: Mac.paper, paper: Mac.ink).frame(width: 16, height: 14)
                Text("\(store.boughtCount)/\(store.totalCount)").font(Mac.font(15, .bold))
            }
            .padding(.horizontal, 6)
            .frame(height: 26)
            .background(Mac.ink)
            .foregroundStyle(Mac.paper)
            HStack(spacing: 5) {
                PixelBitmap(rows: MacIcons.cart).frame(width: 16, height: 12)
                Text(store.hasPrices ? "\(Int(store.cartTotal.rounded()))/" + ShopStore.total(store.listTotal) : "\(store.leftCount)")
                    .font(Mac.font(15, .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                // бюджет: при переборе — инверсная метка, как предупреждение в Mac OS
                if let tag = store.budgetTag {
                    Text(tag)
                        .font(Mac.font(13, .bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .padding(.horizontal, 4)
                        .foregroundStyle(store.isOverBudget ? Mac.paper : Mac.ink)
                        .background(store.isOverBudget ? Mac.ink : Color.clear)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { store.openBudget() }
            // справа — место для скрепки
            Spacer()
        }
        .foregroundStyle(Mac.ink)
        .padding(.horizontal, 6)
        .frame(height: 30)
        .background(Mac.paper)
        .overlay(Rectangle().stroke(Mac.paper, lineWidth: 2))
    }

    // MARK: «Legend of the Inbox»

    private var legendToast: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Легенда магазина")
                .font(Mac.font(22, .bold))
            Text("Вы купили всё. Достигнут уровень GODMODE.")
                .font(Mac.font(16))
        }
        .foregroundStyle(Mac.paper)
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 8).fill(Mac.ink))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Mac.paper, lineWidth: 3))
        .background(RoundedRectangle(cornerRadius: 8).fill(Mac.paper).offset(x: 5, y: 5))
    }
}
