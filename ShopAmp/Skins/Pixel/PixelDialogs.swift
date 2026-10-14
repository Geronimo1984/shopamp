import SwiftUI

/// Окно «ITEM» в пиксельном стиле
struct PixelDialog<Content: View>: View {
    let title: String
    let onClose: () -> Void
    let content: Content

    init(title: String, onClose: @escaping () -> Void, @ViewBuilder content: () -> Content) {
        self.title = title
        self.onClose = onClose
        self.content = content()
    }

    var body: some View {
        ZStack {
            Px.navy.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture(perform: onClose)
            VStack(spacing: 0) {
                HStack {
                    Text(title).font(Px.title(10)).foregroundStyle(Px.ink)
                    Spacer()
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 11, weight: .black))
                            .foregroundStyle(.white)
                            .frame(width: 32, height: 32)
                            .background(PixelRect(step: 2).fill(Px.pink))
                            .overlay(PixelRect(step: 2).strokeBorder(Px.ink, lineWidth: 2))
                    }
                    .buttonStyle(PixelPressStyle())
                }
                .padding(.horizontal, 10)
                .frame(height: 36)
                .background(Color.white)
                Rectangle().fill(Px.ink).frame(height: 3)
                content
                    .padding(12)
            }
            .background(PixelPanel(fill: Px.lavenderLight))
            .frame(maxWidth: 370)
            .padding(.horizontal, 20)
        }
    }
}

struct PixelAddItemDialog: View {
    @EnvironmentObject var store: ShopStore
    @State private var name = ""
    @State private var qty = 1
    @State private var priceText = ""
    @FocusState private var focused: Bool

    var body: some View {
        PixelDialog(title: editing == nil ? "НОВЫЙ ПРЕДМЕТ" : "ПРЕДМЕТ", onClose: close) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    ZStack {
                        PixelRect(step: 3).fill(Px.sky.opacity(0.5))
                        ProductImage(name: name.isEmpty ? "?" : name, size: 36, pixelated: true)
                        PixelRect(step: 3).strokeBorder(Px.ink, lineWidth: 2)
                    }
                    .frame(width: 50, height: 50)
                    TextField("", text: $name, prompt: Text("название").foregroundColor(Px.ink.opacity(0.4)))
                        .font(Px.body(18, .semibold))
                        .foregroundStyle(Px.navy)
                        .tint(Px.pink)
                        .focused($focused)
                        .submitLabel(.next)
                        .onSubmit(addAndContinue)
                        #if os(iOS)
                        .textInputAutocapitalization(.sentences)
                        #endif
                        .padding(.horizontal, 10)
                        .frame(height: 40)
                        .background(PixelRect(step: 3).fill(Px.pinkLight))
                        .overlay(PixelRect(step: 3).strokeBorder(Px.ink, lineWidth: 2))
                }
                IconChooserButton(skin: .pixel, name: name)
                let matches = store.suggestions(for: name)
                if !matches.isEmpty {
                    VStack(spacing: 4) {
                        ForEach(matches, id: \.self) { match in
                            HStack {
                                ProductImage(name: match, size: 22, pixelated: true)
                                Text(match).font(Px.body(16))
                                Spacer()
                            }
                            .foregroundStyle(Px.navy)
                            .padding(.horizontal, 8)
                            .frame(height: 42)
                            .background(PixelRect(step: 2).fill(Px.pinkSoft.opacity(0.6)))
                            .overlay(PixelRect(step: 2).strokeBorder(Px.ink, lineWidth: 2))
                            .pressable(.pixel) { name = match }
                        }
                    }
                }
                HStack(spacing: 8) {
                    Text("КОЛ-ВО").font(Px.title(8)).foregroundStyle(Px.ink)
                    Button("−") { qty = max(qty - 1, 1) }.buttonStyle(PixelButtonStyle(fill: .white, text: Px.ink))
                    Text("x\(qty)").font(Px.title(11)).foregroundStyle(Px.navy).frame(width: 44)
                    Button("+") { qty = min(qty + 1, 99) }.buttonStyle(PixelButtonStyle(fill: .white, text: Px.ink))
                }
                PriceField(skin: .pixel, text: $priceText, qty: qty)
                if let item = editing {
                    HStack(spacing: 10) {
                        Button(item.bought ? "ВЕРНУТЬ" : "В РЮКЗАК ✓") { toggleBoughtAndClose() }
                            .buttonStyle(PixelButtonStyle(fill: Px.sky, text: Px.ink))
                        Button("УДАЛИТЬ") { deleteAndClose() }
                            .buttonStyle(PixelButtonStyle(fill: .white, text: Px.pink))
                    }
                }
                HStack(spacing: 10) {
                    Spacer()
                    Button("ОТМЕНА") { close() }.buttonStyle(PixelButtonStyle(fill: .white, text: Px.ink))
                    Button(editing == nil ? "В РЮКЗАК" : "СОХРАНИТЬ") { addAndClose() }.buttonStyle(PixelButtonStyle())
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

/// Выбор скина в стиле окна «SKILL»
struct PixelSkinBrowser: View {
    @EnvironmentObject var store: ShopStore

    var body: some View {
        PixelDialog(title: "SKIN", onClose: { store.isChoosingSkin = false }) {
            VStack(spacing: 6) {
                ForEach(SkinID.allCases) { skin in
                    let current = skin == store.state.skin
                    HStack(spacing: 10) {
                        SkinBadge(skin: skin)
                            .frame(width: 36, height: 36)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(skin.title).font(Px.body(17, .semibold))
                            Text(skin.subtitle).font(Px.body(12))
                        }
                        .foregroundStyle(Px.navy)
                        Spacer()
                        Text(current ? "✓" : "+")
                            .font(Px.title(10))
                            .foregroundStyle(.white)
                            .frame(width: 24, height: 24)
                            .background(PixelRect(step: 2).fill(current ? Px.ink : Px.pink))
                    }
                    .padding(.horizontal, 8)
                    .frame(height: 52)
                    .background(PixelRect(step: 3).fill(current ? Px.pinkLight : .white))
                    .overlay(PixelRect(step: 3).strokeBorder(Px.ink, lineWidth: 2))
                    .contentShape(Rectangle())
                    .pressable(.pixel) {
                        Haptics.tap()
                        store.state.skin = skin
                        store.isChoosingSkin = false
                    }
                }
                HStack {
                    Spacer()
                    Text("СКИНОВ").font(Px.title(7)).foregroundStyle(Px.ink)
                    Text("\(SkinID.allCases.count)")
                        .font(Px.title(8))
                        .foregroundStyle(Px.ink)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(PixelRect(step: 2).fill(.white))
                        .overlay(PixelRect(step: 2).strokeBorder(Px.ink, lineWidth: 2))
                }
                .padding(.top, 4)
            }
        }
    }
}
