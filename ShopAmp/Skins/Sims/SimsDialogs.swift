import SwiftUI

/// Окно в стиле интерфейса Sims 2: голубая панель с пламбобом и круглыми кнопками
struct SimsDialog<Content: View>: View {
    let title: String
    let onClose: () -> Void
    let onConfirm: (() -> Void)?
    let content: Content

    init(title: String, onClose: @escaping () -> Void, onConfirm: (() -> Void)? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.onClose = onClose
        self.onConfirm = onConfirm
        self.content = content()
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture(perform: onClose)
            VStack(spacing: 10) {
                HStack(spacing: 8) {
                    Plumbob(mood: 1).frame(width: 16, height: 26)
                    Text(title)
                        .font(Sims.title(18))
                        .foregroundStyle(.white)
                        .shadow(color: Sims.panelBorder, radius: 0, x: 1, y: 1)
                    Spacer()
                }
                content
                HStack(spacing: 14) {
                    Spacer()
                    if let onConfirm {
                        SimsRoundButton(symbol: "checkmark", action: onConfirm)
                    }
                    SimsRoundButton(symbol: "xmark", colors: [Color(hex: 0xFF9A8A), Color(hex: 0xC8261A)], action: onClose)
                }
            }
            .padding(14)
            .background(SimsPanel(fill: [Color(hex: 0xB5D3FF), Sims.panel], radius: 18))
            .shadow(color: .black.opacity(0.5), radius: 10, y: 6)
            .frame(maxWidth: 370)
            .padding(.horizontal, 18)
        }
    }
}

struct SimsAddItemDialog: View {
    @EnvironmentObject var store: ShopStore
    @State private var name = ""
    @State private var qty = 1
    @State private var priceText = ""
    @FocusState private var focused: Bool

    var body: some View {
        SimsDialog(title: editing == nil ? "Добавить товар" : "Изменить товар", onClose: close, onConfirm: addAndClose) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    ProductImage(name: name.isEmpty ? "?" : name, size: 42)
                        .frame(width: 52, height: 52)
                        .background(RoundedRectangle(cornerRadius: 10).fill(.white.opacity(0.3)))
                    TextField("", text: $name, prompt: Text("Название товара").foregroundColor(Sims.ink.opacity(0.45)))
                        .font(Sims.font(16, .bold))
                        .foregroundStyle(Sims.ink)
                        .focused($focused)
                        .submitLabel(.next)
                        .onSubmit(addAndContinue)
                        #if os(iOS)
                        .textInputAutocapitalization(.sentences)
                        #endif
                        .padding(.horizontal, 12)
                        .frame(height: 40)
                        .background(Capsule().fill(.white))
                        .overlay(Capsule().stroke(Sims.panelBorder, lineWidth: 2))
                }
                IconChooserButton(skin: .sims, name: name)
                let matches = store.suggestions(for: name)
                if !matches.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(matches, id: \.self) { match in
                            HStack(spacing: 4) {
                                ProductImage(name: match, size: 20)
                                Text(match)
                                    .font(Sims.font(12, .bold))
                                    .foregroundStyle(.white)
                                    .lineLimit(1)
                            }
                            .padding(.horizontal, 8)
                            .frame(height: 32)
                                .background(Capsule().fill(Sims.panelBorder.opacity(0.6)))
                                .pressable(.sims) { name = match }
                        }
                    }
                }
                HStack(spacing: 10) {
                    Text("Количество:").font(Sims.font(13, .bold)).foregroundStyle(.white)
                    SimsRoundButton(symbol: "minus", colors: [Color(hex: 0x9CC0FF), Color(hex: 0x2F62C8)], size: 40) { qty = max(qty - 1, 1) }
                    Text("\(qty)")
                        .font(Sims.title(20))
                        .foregroundStyle(.white)
                        .frame(width: 34)
                    SimsRoundButton(symbol: "plus", colors: [Color(hex: 0x9CC0FF), Color(hex: 0x2F62C8)], size: 40) { qty = min(qty + 1, 99) }
                }
                PriceField(skin: .sims, text: $priceText, qty: qty)
                CategoryChip(skin: .sims, name: name)
                if let item = editing {
                    HStack(spacing: 8) {
                        SimsLink(text: item.bought ? "Не куплено" : "Куплено", color: .white) { toggleBoughtAndClose() }
                        Spacer()
                        SimsLink(text: "Удалить", color: Color(hex: 0xFFD0C8)) { deleteAndClose() }
                    }
                    .padding(.top, 4)
                }
            }
        }
        .onAppear {
            if let item = store.editingItem {
                name = item.name
                qty = item.qty
                priceText = ShopStore.priceText(store.price(item.name))
            } else {
                focused = true
            }
        }
    }

    private func addAndContinue() {
        if editing != nil { return addAndClose() }
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return close() }
        store.add(name, qty: qty)
        savePrice()
        name = ""
        priceText = ""
        qty = 1
        focused = true
    }

    private func addAndClose() {
        if let item = editing {
            store.update(item.id, name: name, qty: qty)
        } else {
            store.add(name, qty: qty)
        }
        savePrice()
        close()
    }

    private func close() {
        focused = false
        store.isAdding = false
        store.editingID = nil
    }

    /// Цена хранится в карточке товара: пустое поле при правке убирает цену
    private func savePrice() {
        let clean = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        let value = ShopStore.parsePrice(priceText)
        if value != nil || editing != nil { store.setPrice(clean, value) }
    }

    private var editing: ShopItem? { store.editingItem }

    private func toggleBoughtAndClose() {
        store.toggleBought(editing?.id)
        close()
    }

    private func deleteAndClose() {
        store.remove(editing?.id)
        close()
    }

}

struct SimsSkinBrowser: View {
    @EnvironmentObject var store: ShopStore

    var body: some View {
        SimsDialog(title: "Выберите скин", onClose: { store.isChoosingSkin = false }) {
            VStack(spacing: 6) {
                ForEach(SkinID.allCases) { skin in
                    let current = skin == store.state.skin
                    HStack(spacing: 10) {
                        SkinBadge(skin: skin).frame(width: 34, height: 34)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(skin.title).font(Sims.font(14, .bold))
                            Text(skin.subtitle).font(Sims.font(10))
                        }
                        .foregroundStyle(current ? Sims.link : .white)
                        Spacer()
                        if current {
                            Plumbob(mood: 1).frame(width: 12, height: 20)
                        }
                    }
                    .padding(.horizontal, 10)
                    .frame(height: 50)
                    .background(RoundedRectangle(cornerRadius: 10).fill(current ? Sims.panelBorder.opacity(0.6) : .white.opacity(0.12)))
                    .contentShape(Rectangle())
                    .pressable(.sims) {
                        Haptics.tap()
                        store.state.skin = skin
                        store.isChoosingSkin = false
                    }
                }
            }
        }
    }
}
