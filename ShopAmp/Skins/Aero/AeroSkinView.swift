import SwiftUI

/// Скин Frutiger Aero: меню и режим покупок в стиле экрана приветствия Windows XP
struct AeroSkinView: View {
    @EnvironmentObject var store: ShopStore
    @State private var search = ""

    var body: some View {
        ZStack {
            XPWelcomeBackground().ignoresSafeArea()
            if store.isShopping {
                AeroShoppingView()
                    .transition(.move(edge: .top).combined(with: .opacity))
            } else {
                menu
                    .transition(.opacity)
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.86), value: store.isShopping)
        .overlay(alignment: .bottomTrailing) {
            if store.msnPopup {
                MSNPopup()
                    .padding(.trailing, 10)
                    .padding(.bottom, 74)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .onTapGesture { withAnimation { store.msnPopup = false } }
            }
        }
        .overlay {
            if store.isAdding || store.editingID != nil {
                AeroAddItemDialog()
            } else if store.isChoosingSkin {
                AeroSkinBrowser()
            }
        }
    }

    // MARK: Меню

    private var menu: some View {
        VStack(spacing: 0) {
            XPTopBand {
                HStack(spacing: 8) {
                    XPFlag().frame(width: 24, height: 22)
                    Text("ShopAmp")
                        .font(Aero.xp(22, .bold, italic: true))
                        .foregroundStyle(.white)
                    Spacer()
                    XPSquareButton(symbol: "questionmark", colors: [Color(hex: 0x6CA6F5), Color(hex: 0x2A5CCB)], size: 38) {
                        store.showHelp = true
                    }
                    .assistAnchor("help")
                    XPSquareButton(symbol: "line.3.horizontal", colors: [Color(hex: 0x6CA6F5), Color(hex: 0x2A5CCB)], size: 38) {
                        store.openMainMenu()
                    }
                    .assistAnchor("menu")
                }
                .padding(.horizontal, 14)
            }
            ScrollViewReader { assistProxy in
ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 12) {
                    welcomeHeader
                    searchRow
                    HStack(alignment: .top, spacing: 8) {
                        playerWidget.assistAnchor("player")
                        aboutBox
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    actionsRow
                    listPanel.assistAnchor("list")
                    duePanel
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 14)
            }
.scrollsToAssistTarget(assistProxy, store.assistantTarget)
}
            XPBottomBand {
                HStack {
                    XPStartButton(title: "начать покупки") { startShopping() }
                        .assistAnchor("start")
                    Spacer(minLength: 8)
                    Button {
                        Haptics.tap()
                        store.isChoosingSkin = true
                    } label: {
                        (Text("Чтобы сменить оформление,\nнажмите ") + Text("здесь").underline())
                            .font(Aero.xp(11))
                            .multilineTextAlignment(.trailing)
                            .foregroundStyle(.white)
                            .minimumScaleFactor(0.7)
                    }
                    .buttonStyle(PressScaleStyle())
                }
            }
        }
    }

    private var welcomeHeader: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("welcome")
                    .font(Aero.xp(34, .bold, italic: true))
                    .foregroundStyle(.white)
                    .shadow(color: Color(hex: 0x1E3E9A).opacity(0.6), radius: 1, x: 1, y: 1)
                Text("Выберите товар, чтобы начать")
                    .font(Aero.xp(13))
                    .foregroundStyle(.white.opacity(0.95))
            }
            Spacer()
            // место помощника: человечка MSN рисует слой помощника по этому якорю
            Color.clear
                .frame(width: 64, height: 76)
                .assistAnchor("buddy")
        }
    }

    private var searchRow: some View {
        HStack(spacing: 8) {
            TextField("", text: $search, prompt: Text("Найти товар").foregroundColor(Color(hex: 0x7A8494)))
                .font(Aero.xp(15))
                .foregroundStyle(.black)
                .padding(.horizontal, 8)
                .frame(height: 42)
                .background(RoundedRectangle(cornerRadius: 3).fill(.white))
                .overlay(RoundedRectangle(cornerRadius: 3).stroke(Aero.xpField, lineWidth: 1))
                .environment(\.colorScheme, .light)
                .assistAnchor("search")
            HStack(spacing: 8) {
                XPSquareButton(symbol: "pencil", size: 42) { store.edit(store.selectedID) }
                XPSquareButton(symbol: "arrow.left", colors: [Color(hex: 0x6CA6F5), Color(hex: 0x2A5CCB)], size: 42) { store.selectPrev() }
                XPSquareButton(symbol: "arrow.right", colors: [Color(hex: 0x6CA6F5), Color(hex: 0x2A5CCB)], size: 42) { store.selectNext() }
            }
            .assistAnchor("editbar")
        }
    }

    // MARK: Windows Media Player

    private var playerWidget: some View {
        let progress = store.totalCount == 0 ? 0 : Double(store.boughtCount) / Double(store.totalCount)
        let caption = store.selectedItem.map { "\($0.name) - \($0.qty) шт" } ?? "Список - пуст"
        return VStack(spacing: 8) {
            HStack(spacing: 4) {
                XPFlag().frame(width: 14, height: 13)
                Text("Windows Media Player")
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: 0x2B4A78))
                    .lineLimit(1)
                Spacer(minLength: 2)
                Text("▾ _ □ ✕")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color(hex: 0x2B4A78))
            }
            HStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [.white, Color(hex: 0xB7C9DE)], startPoint: .top, endPoint: .bottom))
                        .overlay(Circle().stroke(Color(hex: 0x8EA9C8), lineWidth: 1))
                    HStack {
                        Button { Haptics.tap(); store.selectPrev() } label: {
                            Image(systemName: "backward.end.fill").font(.system(size: 13)).frame(width: 22, height: 40).contentShape(Rectangle())
                        }
                        Spacer()
                        Button { Haptics.tap(); store.selectNext() } label: {
                            Image(systemName: "forward.end.fill").font(.system(size: 13)).frame(width: 22, height: 40).contentShape(Rectangle())
                        }
                    }
                    .foregroundStyle(Color(hex: 0x3A5A8A))
                    .padding(.horizontal, 5)
                    OrbButton(symbol: "play.fill", size: 46) { startShopping() }
                }
                .frame(width: 84, height: 84)

                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text("▶ PLAYING").font(.system(size: 9, weight: .bold))
                        Spacer()
                        Text("✱ ☰").font(.system(size: 9, weight: .bold))
                    }
                    Text(String(format: "%02d:%02d", min(store.boughtCount, 99), min(store.totalCount, 99)))
                        .font(.system(size: 34, weight: .medium, design: .rounded))
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .frame(maxWidth: .infinity, alignment: .center)
                    Text(caption)
                        .font(.system(size: 11))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .opacity(0.9)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
                .frame(maxHeight: .infinity)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(LinearGradient(colors: [Color(hex: 0x6AA6F2), Color(hex: 0x1A4FB5), Color(hex: 0x2C66CC)],
                                                 startPoint: .top, endPoint: .bottom))
                        RoundedRectangle(cornerRadius: 14)
                            .fill(LinearGradient(colors: [.white.opacity(0.4), .clear], startPoint: .top, endPoint: .center))
                            .padding(2)
                        RoundedRectangle(cornerRadius: 14).stroke(Color(hex: 0x0E3A8A), lineWidth: 1)
                    }
                )
            }
            HStack(spacing: 6) {
                GeometryReader { g in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color(hex: 0xDCE7F2)).overlay(Capsule().stroke(Color(hex: 0x8EA9C8), lineWidth: 1))
                        Capsule()
                            .fill(LinearGradient(colors: [Color(hex: 0xB6F27A), Color(hex: 0x4DB82A)], startPoint: .top, endPoint: .bottom))
                            .frame(width: max(g.size.width * progress, 6))
                    }
                }
                .frame(height: 10)
                Image(systemName: "speaker.wave.2.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: 0x3A5A8A))
                    .padding(.horizontal, 6)
                    .background(GlossCapsule())
            }
        }
        .padding(10)
        .frame(maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(LinearGradient(colors: [Color(hex: 0xF6F9FD), Color(hex: 0xC3D5EA)], startPoint: .top, endPoint: .bottom))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: 0x8EA9C8), lineWidth: 1.2))
        )
        .padding(4)
        .background(AeroBox(radius: 18, fill: [Color(hex: 0xD9EEFB), Color(hex: 0xA9D4F0)]))
        .frame(maxWidth: .infinity)
        .layoutPriority(1)
    }

    // MARK: Сводка

    private var aboutBox: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Сводка")
                .font(Aero.xp(14, .bold))
                .foregroundStyle(.white)
            XPDivider(vertical: false).frame(height: 1.5)
            summaryRow("в списке", "\(store.totalCount)")
            summaryRow("куплено", "\(store.boughtCount)")
            summaryRow("осталось", "\(store.leftCount)")
            if store.hasPrices {
                summaryRow("корзина", ShopStore.total(store.cartTotal))
                summaryRow("список", "~" + ShopStore.total(store.listTotal))
            }
            if let budget = store.state.tripBudget {
                summaryRow(store.isOverBudget ? "перебор" : "бюджет",
                           store.isOverBudget ? "+" + ShopStore.total(store.listTotal - budget) : ShopStore.total(budget))
                    .foregroundStyle(store.isOverBudget ? Color(hex: 0xFFD27A) : .white)
            }
            summaryRow("купить снова", "\(store.dueSuggestions.count)")
            Spacer(minLength: 0)
            XPProgressBar(value: store.totalCount == 0 ? 0 : Double(store.boughtCount) / Double(store.totalCount))
                .frame(height: 16)
        }
        .padding(10)
        .frame(width: 136)
        .contentShape(Rectangle())
        .onTapGesture { store.openBudget() }
        .frame(maxHeight: .infinity, alignment: .top)
        .background(XPPanel())
    }

    private func summaryRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title).font(Aero.xp(13)).foregroundStyle(Aero.welcomeSub)
            Spacer()
            Text(value).font(Aero.xp(14, .bold)).foregroundStyle(.white)
        }
    }

    // MARK: Действия — плитки с иконками и подписями

    private var actionsRow: some View {
        HStack(spacing: 8) {
            actionTile("Добавить", icon: AnyView(MSNBuddy().frame(width: 32, height: 34).overlay(alignment: .bottomTrailing) { Image(systemName: "plus.circle.fill").font(.system(size: 14)).foregroundStyle(.white, Aero.limeStroke) })) { store.isEditingMemory = true }
                .assistAnchor("add")
            actionTile("Купить снова", icon: AnyView(MusicDiscIcon().frame(width: 34, height: 34))) { store.addDue() }
                .assistAnchor("again")
            actionTile("Карточки", icon: AnyView(Image("food_shopping_bags").resizable().frame(width: 34, height: 34))) { store.isEditingMemory = true }
                .assistAnchor("cards")
            actionTile("Меню", icon: AnyView(ChatBubblesIcon().frame(width: 36, height: 34))) { store.openMainMenu() }
        }
    }

    private func actionTile(_ title: String, icon: AnyView, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            VStack(spacing: 4) {
                icon
                Text(title)
                    .font(Aero.xp(13, .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(XPPanel())
        }
        .buttonStyle(PressScaleStyle())
    }

    // MARK: Список — строки как учётные записи XP

    private var filteredItems: [ShopItem] {
        let query = search.trimmingCharacters(in: .whitespaces).lowercased()
        guard !query.isEmpty else { return store.displayItems }
        return store.displayItems.filter { $0.name.lowercased().contains(query) }
    }

    private var listPanel: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Мой список")
                    .font(Aero.xp(17, .bold))
                    .foregroundStyle(.white)
                Spacer()
                Text("нажмите ещё раз — карточка товара")
                    .font(Aero.xp(10))
                    .foregroundStyle(Aero.welcomeSub)
            }
            .padding(.horizontal, 4)
            if store.state.items.isEmpty {
                Text("Список пуст — нажмите «Добавить»")
                    .font(Aero.xp(14))
                    .foregroundStyle(.white)
                    .padding(8)
            }
            let items = filteredItems
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                if let cat = store.sectionHeader(items, at: index) { CategoryHeader(skin: .aero, section: cat) }
                listRow(item)
            }
        }
        .padding(8)
        .background(XPPanel())
    }

    private func listRow(_ item: ShopItem) -> some View {
        let selected = item.id == store.selectedID
        return HStack(spacing: 10) {
            ProductTile(name: item.name, size: 38, dimmed: item.bought)
            VStack(alignment: .leading, spacing: 1) {
                Text(item.name)
                    .font(Aero.xp(17))
                    .foregroundStyle(.white)
                    .strikethrough(item.bought, color: .white)
                    .lineLimit(1)
                Text(item.bought ? "в корзине ✓" + (store.cost(item).map { " · " + ShopStore.rub($0) } ?? "") : store.qtyText(item))
                    .font(Aero.xp(11, .bold))
                    .foregroundStyle(Aero.welcomeSub)
            }
            Spacer(minLength: 4)
            if selected {
                XPSquareButton(symbol: item.bought ? "arrow.uturn.backward" : "checkmark", size: 40) {
                    store.toggleBought(item.id)
                }
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 5)
        .background(Group { if selected { XPPanel(highlighted: true, radius: 8) } })
        .opacity(item.bought ? 0.65 : 1)
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
            Haptics.tap()
            store.toggleBought(item.id)
        }
        .onTapGesture { store.tapItem(item.id) }
        .combinable(item.name) { store.openItemMenu(item.id) }
    }

    // MARK: Купить снова

    private var duePanel: some View {
        let due = store.state.autoSuggest ? store.dueSuggestions : []
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Купить снова")
                    .font(Aero.xp(17, .bold))
                    .foregroundStyle(.white)
                Spacer()
                XPSquareButton(symbol: "gearshape.fill", colors: [Color(hex: 0x6CA6F5), Color(hex: 0x2A5CCB)], size: 40) {
                    store.isEditingMemory = true
                }
                .assistAnchor("memory")
            }
            if due.isEmpty {
                Text("Сейчас ничего не заканчивается. ⚙ — задать, как часто вы покупаете товары.")
                    .font(Aero.xp(13))
                    .foregroundStyle(Aero.welcomeSub)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(due, id: \.name) { memory in
                            Button {
                                Haptics.tap()
                                store.add(memory.name)
                            } label: {
                                VStack(spacing: 4) {
                                    ProductTile(name: memory.name, size: 46)
                                    Text(memory.name)
                                        .font(Aero.xp(12, .bold))
                                        .foregroundStyle(.white)
                                        .lineLimit(1)
                                    Text("+ добавить")
                                        .font(Aero.xp(10))
                                        .foregroundStyle(Aero.welcomeSub)
                                }
                                .frame(width: 74)
                            }
                            .buttonStyle(PressScaleStyle())
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .padding(10)
        .background(XPPanel())
    }

    private func startShopping() {
        Haptics.tap()
        if store.selectedItem?.bought != false {
            store.selectedID = store.displayItems.first { !$0.bought }?.id ?? store.displayItems.first?.id
        }
        store.isShopping = true
    }
}

// MARK: - Иконки в духе MSN / iTunes

struct BuddyIcon: View {
    var body: some View {
        let gradient = LinearGradient(colors: [Color(hex: 0x9AD9FF), Color(hex: 0x1767D6)], startPoint: .top, endPoint: .bottom)
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            ZStack {
                Ellipse().fill(gradient)
                    .frame(width: w, height: h * 0.55)
                    .offset(y: h * 0.22)
                Circle().fill(gradient)
                    .frame(width: w * 0.62, height: w * 0.62)
                    .offset(y: -h * 0.2)
                Ellipse().fill(.white.opacity(0.75))
                    .frame(width: w * 0.3, height: w * 0.16)
                    .offset(x: -w * 0.08, y: -h * 0.32)
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: w * 0.38))
                    .foregroundStyle(.white, Aero.limeStroke)
                    .offset(x: w * 0.36, y: h * 0.32)
            }
            .frame(width: w, height: h)
            .shadow(color: Color(hex: 0x0D3E91).opacity(0.4), radius: 1, y: 1)
        }
    }
}

struct MusicDiscIcon: View {
    var body: some View {
        ZStack {
            Circle().fill(AngularGradient(colors: [Color(hex: 0xBFF3FF), Color(hex: 0xF6C8FF), Color(hex: 0xC8FFC0),
                                                   Color(hex: 0xFFF3B0), Color(hex: 0xBFF3FF)], center: .center))
            Circle().stroke(Color(hex: 0x7C9AB0), lineWidth: 1)
            Circle().fill(Color.white).frame(width: 10, height: 10)
            Circle().stroke(Color(hex: 0x7C9AB0), lineWidth: 1).frame(width: 10, height: 10)
            Image(systemName: "music.note")
                .font(.system(size: 20, weight: .heavy))
                .foregroundStyle(LinearGradient(colors: [Color(hex: 0x6EE36E), Color(hex: 0x1C8F3A)], startPoint: .top, endPoint: .bottom))
                .shadow(color: .white, radius: 1)
                .offset(x: 6, y: -4)
        }
    }
}

struct ChatBubblesIcon: View {
    var body: some View {
        ZStack {
            Image(systemName: "bubble.left.fill")
                .resizable()
                .foregroundStyle(LinearGradient(colors: [Color(hex: 0xE6FBFF), Color(hex: 0x7CD3F5)], startPoint: .top, endPoint: .bottom))
                .frame(width: 28, height: 24)
                .offset(x: -6, y: -6)
            Image(systemName: "bubble.right.fill")
                .resizable()
                .foregroundStyle(LinearGradient(colors: [Color(hex: 0xBDEBFF), Color(hex: 0x3BA6E8)], startPoint: .top, endPoint: .bottom))
                .frame(width: 28, height: 24)
                .offset(x: 7, y: 6)
            Text("•••")
                .font(.system(size: 9, weight: .black))
                .foregroundStyle(.white)
                .offset(x: 7, y: 5)
        }
        .shadow(color: Color(hex: 0x0D3E91).opacity(0.35), radius: 1, y: 1)
    }
}

/// Всплывающее уведомление MSN Messenger (пасхалка)
struct MSNPopup: View {
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                MSNBuddy().frame(width: 14, height: 16)
                Text("MSN Messenger")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
                Spacer()
                Image(systemName: "xmark").font(.system(size: 9, weight: .bold)).foregroundStyle(.white.opacity(0.9))
            }
            .padding(.horizontal, 8)
            .frame(height: 22)
            .background(LinearGradient(colors: [Color(hex: 0x6E9FE8), Color(hex: 0x2E63C8)], startPoint: .top, endPoint: .bottom))
            HStack(alignment: .top, spacing: 10) {
                MSNBuddy().frame(width: 34, height: 40)
                VStack(alignment: .leading, spacing: 3) {
                    Text("geronimo сейчас:")
                        .font(Aero.xp(13, .bold))
                        .foregroundStyle(Color(hex: 0x1C3F7A))
                    Text("Не в сети (ушёл за хлебом в 2001-м)")
                        .font(Aero.xp(13))
                        .foregroundStyle(.black)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(LinearGradient(colors: [.white, Color(hex: 0xDCE9FA)], startPoint: .top, endPoint: .bottom))
        }
        .frame(width: 240)
        .clipShape(RoundedRectangle(cornerRadius: 5))
        .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color(hex: 0x2E63C8), lineWidth: 1))
        .shadow(color: .black.opacity(0.35), radius: 6, y: 3)
        .environment(\.colorScheme, .light)
    }
}
