import SwiftUI

/// Скин «Симс»: страница thesims2.ea.com (2010) на оригинальной графике сайта
struct SimsSkinView: View {
    @EnvironmentObject var store: ShopStore

    /// Размер картинок по бокам баннера: на узких экранах меньше
    private var bannerSide: CGFloat {
        #if canImport(UIKit)
        let w = UIScreen.main.bounds.width
        return min(60, max(30, (w - 16 - 114 - 28 - 140) / 2))
        #else
        return 60
        #endif
    }

    private var mood: Double {
        store.totalCount == 0 ? 1 : Double(store.boughtCount) / Double(store.totalCount)
    }

    var body: some View {
        GeometryReader { screen in
        ZStack {
            Sims.pageNavy.ignoresSafeArea()
            ScrollViewReader { assistProxy in
ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 8) {
                    navBar
                    HStack(alignment: .top, spacing: 6) {
                        sidebar.frame(width: 108)
                        banner
                    }
                    .frame(height: 290)
                    duePoster
                    joinPanel
                    newsPanel
                    HStack(alignment: .top, spacing: 6) {
                        collectionPod
                        recordsPod
                    }
                    footer
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 30)
                // ширина страницы = ширина экрана: ничего не выталкивает её за края на узких iPhone
                .frame(width: screen.size.width)
            }
.scrollsToAssistTarget(assistProxy, store.assistantTarget)
}
        }
        }
        .overlay {
            if store.isAdding || store.editingID != nil {
                SimsAddItemDialog()
            } else if store.isChoosingSkin {
                SimsSkinBrowser()
            }
        }
    }

    // MARK: Меню — оригинальные плитки сайта с русскими подписями

    private struct NavTile {
        let image: String
        let width: CGFloat
        let title: String
        var anchor = ""
        let action: () -> Void
    }

    /// Плитки идут подряд, как на сайте (nav3…nav8), — тогда изогнутая полоса сверху непрерывна.
    /// Ширины — в пикселях оригинала, высота у всех 57 без подписи.
    private var tiles: [NavTile] {
        [
            NavTile(image: "sims_nav3", width: 73, title: "Порядок", anchor: "order") { store.toggle(\.sortBought) },
            NavTile(image: "sims_nav4", width: 83, title: "Добавить", anchor: "add") { store.isEditingMemory = true },
            NavTile(image: "sims_nav5", width: 74, title: "Снова", anchor: "again") { store.addDue() },
            NavTile(image: "sims_nav6", width: 84, title: "Карточки", anchor: "memory") { store.isEditingMemory = true },
            NavTile(image: "sims_nav7", width: 83, title: "Скины", anchor: "skins") { store.isChoosingSkin = true },
            NavTile(image: "sims_nav8", width: 62, title: "Справка", anchor: "help") { store.showHelp = true },
        ]
    }

    private var navBar: some View {
        GeometryReader { g in
            let total = tiles.reduce(0) { $0 + $1.width }
            let k = g.size.width / total
            // плитки перекрываются на 1 pt, чтобы при дробном масштабе не было шва
            HStack(spacing: -1) {
                ForEach(Array(tiles.enumerated()), id: \.offset) { index, tile in
                    Button {
                        Haptics.tap()
                        tile.action()
                    } label: {
                        VStack(spacing: 0) {
                            SimsNavTileImage(image: tile.image, index: index)
                                .frame(width: tile.width * k + 1, height: 57 * k)
                            labelStrip(tile.title).frame(width: tile.width * k + 1, height: 20 * k)
                        }
                    }
                    .buttonStyle(SimsTilePressStyle())
                    .assistAnchor(tile.anchor)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Sims.tileEdge, lineWidth: 2))
        }
        .aspectRatio(459 / 77, contentMode: .fit)
    }

    /// Нижняя часть плитки: родной синий фон и белая подпись Arial Bold с тенью
    private func labelStrip(_ text: String) -> some View {
        ZStack {
            Sims.tileBlue
            Text(text)
                .font(.custom("Arial", size: 10).weight(.bold))
                .foregroundStyle(.white)
                .shadow(color: Color(hex: 0x10285C), radius: 0, x: 1, y: 1)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .overlay(alignment: .bottom) { Sims.tileEdge.frame(height: 2) }
    }

    // MARK: Колонка слева с логотипом-шайбой

    private var sidebar: some View {
        VStack(spacing: 6) {
            AnimatedSimsLogo(size: 104)
                .padding(.top, -4)
            Image("sims_question")
                .resizable()
                .interpolation(.high)
                .frame(width: 34, height: 37)
                .pressable(.sims) {
                    Haptics.tap()
                    store.showHelp = true
                }
            Text("Вы в\nмагазине.")
                .font(Sims.verdana(12, .bold))
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)
            VStack(alignment: .leading, spacing: 3) {
                sideLink("Добавить") { store.isEditingMemory = true }
                sideLink("Изменить") { store.edit(store.selectedID) }
                sideLink("Справка") { store.showHelp = true }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 10)
            Spacer(minLength: 0)
            HStack(spacing: 4) {
                Image("sims_icon_globe").resizable().interpolation(.high).frame(width: 26, height: 26)
                Text("Осталось\n\(store.leftCount) шт")
                    .font(Sims.verdana(11, .bold))
                    .fixedSize(horizontal: false, vertical: true)
                    .minimumScaleFactor(0.8)
                    .foregroundStyle(.white)
            }
            .padding(.bottom, 8)
        }
        .frame(maxHeight: .infinity)
        .background(
            Image("sims_sidebar")
                .resizable()
                .interpolation(.high)
                .padding(.top, 70)
        )
    }

    private func sideLink(_ text: String, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            HStack(spacing: 3) {
                Text("::").foregroundStyle(Color(hex: 0x9DC3FF))
                Text(text).foregroundStyle(.white)
            }
            .font(Sims.verdana(12, .bold))
        }
        .buttonStyle(PressScaleStyle())
    }

    // MARK: Баннер в оригинальной рамке

    private var banner: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 4)
            Text("ПОРА ЗА ПОКУПКАМИ!")
                .font(.custom("Arial", size: 22).weight(.black))
                .italic()
                .foregroundStyle(.white)
                .shadow(color: Color(hex: 0x10285C), radius: 0, x: 2, y: 2)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Spacer(minLength: 6)
            HStack(spacing: 4) {
                ProductImage(name: store.selectedItem?.name ?? "", size: bannerSide)
                VStack(spacing: 6) {
                    Plumbob(mood: mood).frame(width: 26, height: 42)
                    Text("Shop").font(.custom("Arial", size: 22).weight(.black)).italic().foregroundStyle(Color(hex: 0x10285C))
                    Button {
                        Haptics.tap()
                        store.isEditingMemory = true
                    } label: {
                        HStack(spacing: 4) {
                            Text("ADD")
                            Image(systemName: "play.circle.fill").foregroundStyle(Sims.plumbobGreen)
                            Text("NOW")
                        }
                        .fixedSize()
                        .font(.custom("Arial", size: 13).weight(.black))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Color(hex: 0x4A4F5C)))
                    }
                    .buttonStyle(PressScaleStyle())
                    .assistAnchor("addNow")
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(LinearGradient(colors: [.white, Color(hex: 0xD6DCE6)], startPoint: .top, endPoint: .bottom))
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color(hex: 0x6B7380), lineWidth: 4))
                )
                .layoutPriority(1)
                ProductImage(name: store.dueSuggestions.first?.name ?? "кофе", size: bannerSide)
            }
            Spacer(minLength: 6)
            Text(store.selectedItem.map { "\($0.name) · \($0.qty) шт" } ?? "Выберите товар в списке")
                .font(Sims.verdana(13, .bold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Spacer(minLength: 6)
            HStack(spacing: 6) {
                ForEach(1...4, id: \.self) { i in
                    Text("\(i)")
                        .font(Sims.verdana(12, .bold))
                        .foregroundStyle(i == 1 ? Color(hex: 0x10285C) : .white)
                        .frame(width: 20, height: 20)
                        .background(i == 1 ? Color(hex: 0xF5C83A) : .clear)
                }
                Spacer()
            }
            Spacer(minLength: 4)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Image("sims_banner_frame").resizable().interpolation(.high))
    }

    // MARK: Витрина готовых блюд из The Sims — «Купить снова»

    private var duePoster: some View {
        let due = store.state.autoSuggest ? store.dueSuggestions : []
        return Button {
            Haptics.tap()
            if due.isEmpty {
                store.isEditingMemory = true
            } else {
                store.addDue()
            }
        } label: {
            VStack(spacing: 2) {
                HStack {
                    Image("sims_trophy").resizable().interpolation(.high).frame(width: 22, height: 24)
                    Text("Купить снова")
                        .font(.custom("Arial", size: 15).weight(.bold))
                        .foregroundStyle(.white)
                        .shadow(color: Color(hex: 0x10285C), radius: 0, x: 1, y: 1)
                    Spacer()
                    Text(due.isEmpty ? "настроить ›" : "добавить \(due.count) ›")
                        .font(Sims.verdana(11, .bold))
                        .foregroundStyle(Color(hex: 0xFFF59A))
                        .shadow(color: Color(hex: 0x10285C), radius: 0, x: 1, y: 1)
                }
                SimsDishShow()
                    .frame(height: 132)
                Text(due.isEmpty
                     ? "Ничего не заканчивается. Нажмите, чтобы задать, как часто покупаете товары."
                     : "Заканчиваются: " + due.map(\.name).joined(separator: ", ") + ". Нажмите — добавим в список.")
                    .font(Sims.verdana(12, .bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(
                Image("sims_pod_teal_bg")
                    .resizable(capInsets: EdgeInsets(top: 14, leading: 14, bottom: 14, trailing: 14), resizingMode: .stretch)
                    .interpolation(.high)
            )
            .overlay(alignment: .top) {
                Image("sims_pod_teal_top").resizable().interpolation(.high).frame(height: 7)
            }
        }
        .buttonStyle(PressScaleStyle())
        .assistAnchor("dishes")
    }

    // MARK: «Join Now!» — список

    private var joinPanel: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(alignment: .center, spacing: 6) {
                Image("sims_icon_people").resizable().interpolation(.high).frame(width: 30, height: 31)
                Text("Список покупок")
                    .font(.custom("Arial", size: 15).weight(.bold))
                    .foregroundStyle(.white)
                    .shadow(color: Color(hex: 0x10285C), radius: 0, x: 1, y: 1)
                Spacer()
                StrokedText(text: store.hasPrices ? "Корзина: \(ShopStore.total(store.cartTotal))!" : "В корзине: \(store.boughtCount)!", font: .custom("Georgia", size: 14).weight(.black).italic(),
                            fill: AnyShapeStyle(Color(hex: 0xE8231A)), stroke: .white, width: 1.3)
                    .rotationEffect(.degrees(-8))
            }
            Text("Нажмите на товар, затем ещё раз — откроется его карточка. ✎ — изменить, ✓ — куплено.")
                .font(Sims.verdana(12, .bold))
                .foregroundStyle(Sims.ink)
            if store.state.items.isEmpty {
                Text("* Пока пусто — нажмите «Добавить» в меню")
                    .font(Sims.verdana(11, .bold))
                    .foregroundStyle(Sims.ink)
            }
            let items = store.displayItems
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                if let cat = store.sectionHeader(items, at: index) { CategoryHeader(skin: .sims, section: cat) }
                itemRow(item).assistAnchor("list", when: item.id == items.first?.id)
            }
            HStack {
                linkYellow("+ Добавить из карточек") { store.isEditingMemory = true }
                Spacer()
                linkYellow("Закончить покупки") { store.finishShopping() }
            }
            .padding(.top, 4)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            Image("sims_pod_join")
                .resizable(capInsets: EdgeInsets(top: 40, leading: 40, bottom: 40, trailing: 40), resizingMode: .stretch)
                .interpolation(.high)
        )
    }

    private func linkYellow(_ text: String, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            Text(text)
                .font(Sims.verdana(11, .bold))
                .foregroundStyle(Color(hex: 0xFFF59A))
                .shadow(color: Color(hex: 0x10285C), radius: 0, x: 1, y: 1)
        }
        .buttonStyle(PressScaleStyle())
    }

    private func itemRow(_ item: ShopItem) -> some View {
        let selected = item.id == store.selectedID
        return HStack(spacing: 6) {
            Text("*").font(Sims.verdana(12, .bold)).foregroundStyle(Sims.ink)
            ProductImage(name: item.name, size: 24)
            Text(item.name)
                .font(Sims.verdana(15, .bold))
                .strikethrough(item.bought, color: Sims.ink)
                .foregroundStyle(item.bought ? Sims.ink.opacity(0.5) : (selected ? .white : Sims.ink))
                .lineLimit(1)
            Spacer(minLength: 4)
            Text(item.bought ? "✓" : store.qtyText(item))
                .font(Sims.verdana(11, .bold))
                .foregroundStyle(selected ? .white : Sims.ink)
            Button {
                Haptics.tap()
                store.edit(item.id)
            } label: {
                Image(systemName: "pencil.circle.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(.white, Color(hex: 0x2A54B0))
            }
            .buttonStyle(PressScaleStyle())
            Button {
                Haptics.tap()
                store.toggleBought(item.id)
            } label: {
                Image(systemName: item.bought ? "arrow.uturn.backward.circle.fill" : "checkmark.circle.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(.white, item.bought ? Color(hex: 0x8A93B0) : Color(hex: 0x2E9E2A))
            }
            .buttonStyle(PressScaleStyle())
        }
        .padding(.horizontal, 6)
        .frame(height: 46)
        .background(RoundedRectangle(cornerRadius: 6).fill(selected ? Color(hex: 0x2A54B0).opacity(0.75) : .clear))
        .contentShape(Rectangle())
        .onTapGesture { store.tapItem(item.id) }
        .onLongPressGesture { store.openItemMenu(item.id) }
    }

    // MARK: News

    private var recentPurchases: [ItemMemory] {
        Array(store.state.memory.values
            .filter { $0.lastPurchase != nil }
            .sorted { ($0.lastPurchase ?? .distantPast) > ($1.lastPurchase ?? .distantPast) }
            .prefix(4))
    }

    private var newsPanel: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 6) {
                    Image("sims_icon_typewriter").resizable().interpolation(.high).frame(width: 30, height: 29)
                    Text("Новости")
                        .font(.custom("Arial", size: 15).weight(.bold))
                        .foregroundStyle(Sims.ink)
                }
                Text(Date(), format: .dateTime.weekday(.wide).day().month(.wide).year())
                    .font(Sims.verdana(12, .bold))
                    .foregroundStyle(Sims.ink)
                Text("Куплено \(store.boughtCount) из \(store.totalCount)" + (store.hasPrices ? " · " + store.budgetText : ""))
                    .font(Sims.verdana(11, .bold))
                    .foregroundStyle(Sims.ink)
                Text("Осталось \(store.leftCount). Купить снова: \(store.dueSuggestions.count). Как часто покупать товары — настраивается в «Памяти».")
                    .font(Sims.verdana(12))
                    .foregroundStyle(Sims.ink)
                linkYellow("Открыть «Память»") { store.isEditingMemory = true }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            VStack(alignment: .leading, spacing: 4) {
                Text("Недавно куплено:")
                    .font(Sims.verdana(12, .bold))
                    .foregroundStyle(Sims.ink)
                if recentPurchases.isEmpty {
                    Text("пока ничего").font(Sims.verdana(12)).foregroundStyle(Sims.ink)
                }
                ForEach(recentPurchases, id: \.name) { memory in
                    Button {
                        Haptics.tap()
                        store.add(memory.name)
                    } label: {
                        HStack(alignment: .firstTextBaseline, spacing: 3) {
                            Text("::").foregroundStyle(Sims.ink)
                            Text(memory.name).foregroundStyle(Color(hex: 0xFFF59A))
                                .shadow(color: Color(hex: 0x3A3C8A), radius: 0, x: 1, y: 1)
                        }
                        .font(Sims.verdana(12, .bold))
                    }
                    .buttonStyle(PressScaleStyle())
                }
                Spacer(minLength: 2)
                HStack(spacing: 4) {
                    Image("sims_xml").resizable().interpolation(.high).frame(width: 30, height: 12)
                    Text("Скины").font(Sims.verdana(12, .bold)).foregroundStyle(Sims.ink)
                }
                .pressable(.sims) { store.isChoosingSkin = true }
            }
            .frame(width: 118, alignment: .leading)
        }
        .padding(.leading, 18)
        .padding(.trailing, 12)
        .padding(.vertical, 12)
        .background(
            Image("sims_pod_news")
                .resizable(capInsets: EdgeInsets(top: 40, leading: 40, bottom: 40, trailing: 170), resizingMode: .stretch)
                .interpolation(.high)
        )
    }

    // MARK: Нижние «поды»

    private func pod<Content: View>(_ color: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            Image("sims_pod_\(color)_top").resizable().interpolation(.high).frame(height: 7)
            content()
                .padding(.horizontal, 10)
                .padding(.bottom, 12)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .background(
                    Image("sims_pod_\(color)_bg")
                        .resizable(capInsets: EdgeInsets(top: 0, leading: 12, bottom: 14, trailing: 12), resizingMode: .stretch)
                        .interpolation(.high)
                )
        }
    }

    private var collectionPod: some View {
        let top = Array(store.state.memory.values.sorted { $0.purchases.count > $1.purchases.count }.prefix(3))
        return pod("purp") {
            VStack(spacing: 6) {
                VStack(spacing: 2) {
                    Text("The Shop 2").font(.custom("Arial", size: 12).weight(.black)).italic().foregroundStyle(.white)
                    Text("ЛЮБИМОЕ").font(.custom("Arial", size: 15).weight(.black)).foregroundStyle(Color(hex: 0xFFE14A))
                        .shadow(color: Color(hex: 0xB0120A), radius: 0, x: 1, y: 1)
                    HStack(spacing: 2) {
                        ForEach(top, id: \.name) { ProductImage(name: $0.name, size: 30) }
                    }
                    Text("INCLUDES ALL \(top.count)!").font(Sims.verdana(7, .black)).foregroundStyle(.white)
                }
                .padding(8)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 3)
                        .fill(LinearGradient(colors: [Color(hex: 0x3FA0F0), Color(hex: 0x1C55B8)], startPoint: .top, endPoint: .bottom))
                        .overlay(RoundedRectangle(cornerRadius: 3).stroke(.white, lineWidth: 2))
                )
                Button {
                    Haptics.tap()
                    top.forEach { store.add($0.name) }
                } label: {
                    Text("Добавить в список!")
                        .font(Sims.verdana(12, .bold))
                        .underline()
                        .foregroundStyle(.white)
                }
                .buttonStyle(PressScaleStyle())
            }
            .padding(.top, 6)
        }
    }

    private var recordsPod: some View {
        let favorite = store.state.memory.values.max { $0.purchases.count < $1.purchases.count }
        let total = store.state.memory.values.reduce(0) { $0 + $1.purchases.count }
        return pod("blue") {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image("sims_trophy").resizable().interpolation(.high).frame(width: 24, height: 26)
                    Text("Рекорды")
                        .font(.custom("Arial", size: 14).weight(.bold))
                        .foregroundStyle(.white)
                }
                Text("Всего покупок: \(total)")
                if let favorite, !favorite.purchases.isEmpty {
                    Text("Чаще всего: \(favorite.name) (\(favorite.purchases.count))")
                }
                Text("Регулярных: \(store.regulars.count)")
            }
            .font(Sims.verdana(12, .bold))
            .foregroundStyle(.white)
            .padding(.top, 6)
        }
    }

    // MARK: Подвал — оригинальные логотипы

    private var footer: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                ForEach(["scs", "mysims", "animals", "thesims3", "ea", "esrb"], id: \.self) { name in
                    Image("sims_footer_\(name)")
                        .resizable()
                        .interpolation(.high)
                        .scaledToFit()
                        .frame(maxHeight: 30)
                }
            }
            .padding(.horizontal, 4)
            Text("Этот сайт требует ShopAmp 1.0\n©2026 ShopAmp. Все покупки защищены.")
                .font(Sims.verdana(8))
                .foregroundStyle(.white.opacity(0.55))
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
    }
}
