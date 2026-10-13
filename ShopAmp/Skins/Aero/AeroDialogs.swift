import SwiftUI

/// «Добавить товар» — окно Windows XP
struct AeroAddItemDialog: View {
    @EnvironmentObject var store: ShopStore
    @State private var name = ""
    @State private var qty = 1
    @FocusState private var focused: Bool

    var body: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture { close() }

            XPWindow(title: editing == nil ? "Добавить товар" : "Изменить товар", onClose: close) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 10) {
                        ProductTile(name: name.isEmpty ? "?" : name, size: 44)
                        Text("Введите название товара. Картинка подберётся сама.")
                            .font(.system(size: 12))
                    }
                    Text("Название:").font(.system(size: 12))
                    TextField("например, молоко", text: $name)
                        .font(.system(size: 15))
                        .focused($focused)
                        .submitLabel(.next)
                        .onSubmit(addAndContinue)
                        #if os(iOS)
                        .textInputAutocapitalization(.sentences)
                        #endif
                        .padding(.horizontal, 6)
                        .frame(height: 40)
                        .background(Color.white)
                        .overlay(Rectangle().stroke(Aero.xpField, lineWidth: 1))

                    IconChooserButton(skin: .aero, name: name)

                    let matches = store.suggestions(for: name)
                    if !matches.isEmpty {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(matches, id: \.self) { match in
                                HStack(spacing: 8) {
                                    ProductTile(name: match, size: 22)
                                    Text(match).font(.system(size: 14))
                                    Spacer()
                                }
                                .padding(.horizontal, 6)
                                .frame(height: 42)
                                .contentShape(Rectangle())
                                .pressable(.aero) { name = match }
                            }
                        }
                        .background(Color.white)
                        .overlay(Rectangle().stroke(Aero.xpField, lineWidth: 1))
                    }

                    HStack(spacing: 6) {
                        Text("Количество:").font(.system(size: 12))
                        Button("−") { qty = max(qty - 1, 1) }
                            .buttonStyle(XPButtonStyle())
                        Text("\(qty)")
                            .font(.system(size: 14))
                            .frame(width: 40, height: 28)
                            .background(Color.white)
                            .overlay(Rectangle().stroke(Aero.xpField, lineWidth: 1))
                        Button("+") { qty = min(qty + 1, 99) }
                            .buttonStyle(XPButtonStyle())
                    }

                    if let item = editing {
                        HStack(spacing: 8) {
                            Button(item.bought ? "Не куплено" : "Куплено") { toggleBoughtAndClose() }
                                .buttonStyle(XPButtonStyle())
                            Button("Удалить") { deleteAndClose() }
                                .buttonStyle(XPButtonStyle())
                        }
                    }
                    HStack(spacing: 8) {
                        Spacer()
                        Button("OK") { addAndClose() }
                            .buttonStyle(XPButtonStyle(isDefault: true))
                        Button("Отмена") { close() }
                            .buttonStyle(XPButtonStyle())
                    }
                    .padding(.top, 4)
                }
                .foregroundStyle(.black)
            }
            .frame(maxWidth: 370)
            .padding(.horizontal, 16)
        }
        .onAppear {
            if let item = store.editingItem {
                name = item.name
                qty = item.qty
            } else {
                focused = true
            }
        }
    }

    private func addAndContinue() {
        if editing != nil { return addAndClose() }
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return close() }
        store.add(name, qty: qty)
        name = ""
        qty = 1
        focused = true
    }

    private func addAndClose() {
        if let item = editing {
            store.update(item.id, name: name, qty: qty)
        } else {
            store.add(name, qty: qty)
        }
        close()
    }

    private func close() {
        focused = false
        store.isAdding = false
        store.editingID = nil
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

/// «Выбор скина» — окно Windows XP
struct AeroSkinBrowser: View {
    @EnvironmentObject var store: ShopStore

    var body: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture { store.isChoosingSkin = false }

            XPWindow(title: "Выбор скина", onClose: { store.isChoosingSkin = false }) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Выберите оформление:").font(.system(size: 12))
                    VStack(spacing: 0) {
                        ForEach(SkinID.allCases) { skin in
                            let current = skin == store.state.skin
                            HStack(spacing: 10) {
                                SkinBadge(skin: skin).frame(width: 32, height: 32)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(skin.title).font(.system(size: 15, weight: .semibold))
                                    Text(skin.subtitle).font(.system(size: 11)).opacity(0.8)
                                }
                                Spacer()
                            }
                            .foregroundStyle(current ? .white : .black)
                            .padding(.horizontal, 8)
                            .frame(height: 48)
                            .background(current ? Aero.xpSelect : Color.white)
                            .contentShape(Rectangle())
                            .pressable(.aero) {
                                Haptics.tap()
                                store.state.skin = skin
                                store.isChoosingSkin = false
                            }
                        }
                    }
                    .overlay(Rectangle().stroke(Aero.xpField, lineWidth: 1))

                    HStack {
                        Spacer()
                        Button("Закрыть") { store.isChoosingSkin = false }
                            .buttonStyle(XPButtonStyle(isDefault: true))
                    }
                }
                .foregroundStyle(.black)
            }
            .frame(maxWidth: 370)
            .padding(.horizontal, 16)
        }
    }
}
