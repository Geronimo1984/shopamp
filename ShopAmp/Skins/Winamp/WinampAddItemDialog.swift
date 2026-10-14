import SwiftUI

/// Окно «ADD ITEM» в стиле Winamp
struct WinampAddItemDialog: View {
    @EnvironmentObject var store: ShopStore
    @State private var name = ""
    @State private var qty = 1
    @State private var priceText = ""
    @FocusState private var focused: Bool

    var body: some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()
                .onTapGesture { close() }

            VStack(spacing: 0) {
                TitleBar(title: editing == nil ? "ADD ITEM" : "EDIT ITEM", showIcon: false, buttons: [.close]) { close() }
                    .frame(height: 26)

                VStack(alignment: .leading, spacing: 10) {
                    caption("НАЗВАНИЕ")
                    TextField("", text: $name, prompt: Text("например, молоко").foregroundColor(Winamp.greenDim))
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundStyle(Winamp.green)
                        .tint(Winamp.green)
                        .focused($focused)
                        .submitLabel(.next)
                        .onSubmit(addAndContinue)
                        #if os(iOS)
                        .textInputAutocapitalization(.sentences)
                        #endif
                        .padding(.horizontal, 10)
                        .frame(height: 40)
                        .background(LCDBox(line: 2) { Color.clear })

                    IconChooserButton(skin: .winamp, name: name)

                    let matches = store.suggestions(for: name)
                    if !matches.isEmpty {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(matches, id: \.self) { match in
                                Text(match)
                                    .font(.custom("Arial", size: 17))
                                    .foregroundStyle(Winamp.listGreen)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 10)
                                    .frame(height: 40)
                                    .contentShape(Rectangle())
                                    .pressable(.winamp) { name = match }
                            }
                        }
                        .padding(.vertical, 4)
                        .background(Color.black)
                        .overlay(Rectangle().strokeBorder(Winamp.frameDark, lineWidth: 2))
                    }

                    HStack(spacing: 8) {
                        caption("КОЛ-ВО")
                        SkinButton(edge: 1.5) { qty = max(qty - 1, 1) } label: { skinText("−", 20) }
                            .frame(width: 36, height: 32)
                        LCDBox(alignment: .center, line: 2) {
                            Text("\(qty)")
                                .font(.system(size: 18, weight: .bold, design: .monospaced))
                                .foregroundStyle(Winamp.green)
                        }
                        .frame(width: 44, height: 32)
                        SkinButton(edge: 1.5) { qty = min(qty + 1, 99) } label: { skinText("+", 20) }
                            .frame(width: 36, height: 32)
                    }

                    PriceField(skin: .winamp, text: $priceText, qty: qty)
                    if let item = editing {
                        HStack(spacing: 10) {
                            SkinButton(edge: 1.5) { toggleBoughtAndClose() } label: {
                                skinText(item.bought ? "НЕ КУПЛЕНО" : "КУПЛЕНО", 13)
                            }
                            .frame(height: 44)
                            SkinButton(edge: 1.5) { deleteAndClose() } label: { skinText("УДАЛИТЬ", 13) }
                                .frame(height: 44)
                        }
                    }
                    HStack(spacing: 10) {
                        Spacer()
                        SkinButton(edge: 1.5) { addAndClose() } label: { skinText("OK", 15) }
                            .frame(width: 84, height: 34)
                        SkinButton(edge: 1.5) { close() } label: { skinText("CANCEL", 15) }
                            .frame(width: 96, height: 34)
                    }
                    .padding(.top, 4)
                }
                .padding(14)
            }
            .background(WindowBody(line: 3))
            .frame(maxWidth: 380)
            .padding(.horizontal, 16)
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

    private func caption(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .heavy, design: .monospaced))
            .foregroundStyle(Winamp.label)
    }

    /// Enter на клавиатуре — добавить и сразу вводить следующий товар
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
