import SwiftUI

/// «Новый товар» — 1-битный диалог Mac
struct MacAddItemDialog: View {
    @EnvironmentObject var store: ShopStore
    @State private var name = ""
    @State private var qty = 1
    @State private var priceText = ""
    @FocusState private var focused: Bool

    var body: some View {
        ZStack {
            Dither(a: Mac.ink.opacity(0.55), b: .clear, cell: 1.5)
                .ignoresSafeArea()
                .onTapGesture { close() }

            MacWindow(title: editing == nil ? "Новый товар" : "Изменить товар", onClose: close) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Название:").font(Mac.font(15))
                    TextField("", text: $name, prompt: Text("молоко").foregroundColor(Mac.ink.opacity(0.4)))
                        .font(Mac.font(18))
                        .foregroundStyle(Mac.ink)
                        .tint(Mac.ink)
                        .focused($focused)
                        .submitLabel(.next)
                        .onSubmit(addAndContinue)
                        #if os(iOS)
                        .textInputAutocapitalization(.sentences)
                        #endif
                        .padding(.horizontal, 8)
                        .frame(height: 36)
                        .background(Mac.paper)
                        .overlay(Rectangle().stroke(Mac.ink, lineWidth: 2))

                    IconChooserButton(skin: .mac, name: name)

                    let matches = store.suggestions(for: name)
                    if !matches.isEmpty {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(matches, id: \.self) { match in
                                HStack(spacing: 8) {
                                    PixelBitmap(rows: MacIcons.bag).frame(width: 16, height: 15)
                                    Text(match).font(Mac.font(16))
                                    Spacer()
                                }
                                .padding(.horizontal, 8)
                                .frame(height: 42)
                                .contentShape(Rectangle())
                                .pressable(.mac) { name = match }
                            }
                        }
                        .overlay(Rectangle().stroke(Mac.ink, lineWidth: 2))
                    }

                    HStack(spacing: 8) {
                        Text("Кол-во").font(Mac.font(15))
                        Text("\(qty) шт")
                            .font(Mac.font(17, .bold))
                            .frame(width: 70, height: 32)
                            .overlay(Rectangle().stroke(Mac.ink, lineWidth: 2))
                        VStack(spacing: 0) {
                            stepper("arrowtriangle.up.fill") { qty = min(qty + 1, 99) }
                            stepper("arrowtriangle.down.fill") { qty = max(qty - 1, 1) }
                        }
                    }

                    PriceField(skin: .mac, text: $priceText, qty: qty)
                    if let item = editing {
                        HStack(spacing: 10) {
                            Button(item.bought ? "Не куплено" : "Куплено") { toggleBoughtAndClose() }
                                .buttonStyle(MacButtonStyle())
                            Button("Удалить") { deleteAndClose() }
                                .buttonStyle(MacButtonStyle())
                        }
                    }
                    HStack(spacing: 10) {
                        Spacer()
                        Button("Отмена") { close() }
                            .buttonStyle(MacButtonStyle())
                        Button("OK") { addAndClose() }
                            .buttonStyle(MacButtonStyle(isDefault: true))
                    }
                }
                .foregroundStyle(Mac.ink)
                .padding(14)
            }
            .frame(maxWidth: 360)
            .padding(.horizontal, 20)
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

    private func stepper(_ symbol: String, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 9))
                .foregroundStyle(Mac.ink)
                .frame(width: 22, height: 16)
                .overlay(Rectangle().stroke(Mac.ink, lineWidth: 2))
        }
        .buttonStyle(MacInvertStyle())
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

/// Выбор скина в стиле Extensions Manager
struct MacSkinBrowser: View {
    @EnvironmentObject var store: ShopStore

    var body: some View {
        ZStack {
            Dither(a: Mac.ink.opacity(0.55), b: .clear, cell: 1.5)
                .ignoresSafeArea()
                .onTapGesture { store.isChoosingSkin = false }

            MacWindow(title: "Менеджер скинов", onClose: { store.isChoosingSkin = false }) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        Text("Набор:").font(Mac.font(15))
                        Text("Мои скины  ▾")
                            .font(Mac.font(15, .semibold))
                            .padding(.horizontal, 8)
                            .frame(height: 26)
                            .overlay(Rectangle().stroke(Mac.ink, lineWidth: 2))
                            .background(Rectangle().fill(Mac.ink).offset(x: 2, y: 2))
                            .background(Mac.paper)
                    }
                    VStack(spacing: 0) {
                        HStack {
                            Text("Вкл").frame(width: 36, alignment: .leading)
                            Text("Название")
                            Spacer()
                            Text("Версия")
                        }
                        .font(Mac.font(13, .semibold))
                        .padding(.horizontal, 8)
                        .frame(height: 24)
                        Rectangle().fill(Mac.ink).frame(height: 2)
                        ForEach(SkinID.allCases) { skin in
                            let current = skin == store.state.skin
                            HStack(spacing: 8) {
                                MacCheckbox(checked: current)
                                    .frame(width: 28, alignment: .leading)
                                SkinBadge(skin: skin).frame(width: 26, height: 26)
                                VStack(alignment: .leading, spacing: 0) {
                                    Text(skin.title).font(Mac.font(16, .semibold))
                                    Text(skin.subtitle).font(Mac.font(12))
                                }
                                Spacer()
                                Text("1.0").font(Mac.font(14))
                            }
                            .padding(.horizontal, 8)
                            .frame(height: 46)
                            .contentShape(Rectangle())
                            .pressable(.mac) {
                                Haptics.tap()
                                store.state.skin = skin
                                store.isChoosingSkin = false
                            }
                            Rectangle().fill(Mac.ink.opacity(0.3)).frame(height: 1)
                        }
                    }
                    .overlay(Rectangle().stroke(Mac.ink, lineWidth: 2))

                    HStack {
                        Text("▷ Показать сведения").font(Mac.font(13))
                        Spacer()
                        Button("Продолжить") { store.isChoosingSkin = false }
                            .buttonStyle(MacButtonStyle(isDefault: true))
                    }
                }
                .foregroundStyle(Mac.ink)
                .padding(12)
            }
            .frame(maxWidth: 380)
            .padding(.horizontal, 16)
        }
    }
}
