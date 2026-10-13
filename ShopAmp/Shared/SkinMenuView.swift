import SwiftUI

/// Меню, нарисованное в стиле текущего скина (вместо системного)
struct SkinMenuView: View {
    @EnvironmentObject var store: ShopStore
    let menu: SkinMenu
    let skin: SkinID

    var body: some View {
        ZStack {
            Color.black.opacity(skin == .sims ? 0.72 : 0.3)
                .ignoresSafeArea()
                .onTapGesture { store.menu = nil }
            content
                .padding(.horizontal, 24)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch skin {
        case .winamp: winamp
        case .aero: aero
        case .mac: mac
        case .sims: simsPie
        case .pixel: pixel
        }
    }

    private func run(_ action: MenuAction) {
        Haptics.tap()
        store.runMenu(action)
    }

    // MARK: Winamp — окно с зелёными строками как в плейлисте

    private var winamp: some View {
        VStack(spacing: 0) {
            TitleBar(title: menu.title.uppercased(), showIcon: false, buttons: [.close]) { store.menu = nil }
                .frame(height: 26)
            VStack(alignment: .leading, spacing: 0) {
                ForEach(menu.actions) { action in
                    Text(action.title)
                        .font(.custom("Arial", size: 17))
                        .foregroundStyle(action.destructive ? Color(hex: 0xFF6A4A) : Winamp.listGreen)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 12)
                        .frame(height: 44)
                        .contentShape(Rectangle())
                        .pressable(skin) { run(action) }
                }
            }
            .padding(.vertical, 4)
            .background(Color.black)
            .overlay(Rectangle().strokeBorder(Winamp.frameDark, lineWidth: 2))
            .padding(10)
        }
        .background(WindowBody(line: 3))
        .frame(maxWidth: 360)
    }

    // MARK: Aero — контекстное меню Windows XP

    private var aero: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                XPFlag().frame(width: 16, height: 14)
                Text(menu.title)
                    .font(Aero.xp(15, .bold))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.4), radius: 0, x: 1, y: 1)
                    .lineLimit(1)
                Spacer()
                Button { store.menu = nil } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(LinearGradient(colors: [Color(hex: 0xEE9277), Color(hex: 0xC8391B)], startPoint: .top, endPoint: .bottom))
                        RoundedRectangle(cornerRadius: 4).stroke(.white, lineWidth: 1)
                        Image(systemName: "xmark").font(.system(size: 13, weight: .heavy)).foregroundStyle(.white)
                    }
                    .frame(width: 32, height: 32)
                }
                .buttonStyle(PressScaleStyle())
            }
            .padding(.leading, 10)
            .padding(.trailing, 6)
            .frame(height: 42)
            .background(LinearGradient(colors: Aero.lunaTitle, startPoint: .top, endPoint: .bottom))

            VStack(spacing: 0) {
                ForEach(Array(menu.actions.enumerated()), id: \.element.id) { index, action in
                    if index > 0 {
                        Rectangle().fill(Color(hex: 0xD5DCE8)).frame(height: 1).padding(.leading, 44)
                    }
                    HStack(spacing: 0) {
                        Image(systemName: aeroIcon(action.title))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(action.destructive ? Color(hex: 0xC8391B) : Color(hex: 0x2A5CCB))
                            .frame(width: 44)
                        Text(action.title)
                            .font(Aero.xp(16))
                            .foregroundStyle(action.destructive ? Color(hex: 0xC8261A) : .black)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .padding(.leading, 8)
                        Spacer(minLength: 8)
                    }
                    .frame(height: 44)
                    .background(alignment: .leading) {
                        LinearGradient(colors: [Color(hex: 0xE3ECFA), Color(hex: 0xCBDAF3)], startPoint: .leading, endPoint: .trailing)
                            .frame(width: 36)
                    }
                    .contentShape(Rectangle())
                    .pressable(skin) { run(action) }
                }
            }
            .padding(.vertical, 4)
            .background(Color.white)
        }
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Aero.xpBorder, lineWidth: 1.5))
        .background(RoundedRectangle(cornerRadius: 6).fill(.white).shadow(color: .black.opacity(0.35), radius: 8, x: 3, y: 5))
        .frame(maxWidth: 340)
        .environment(\.colorScheme, .light)
    }

    private func aeroIcon(_ title: String) -> String {
        let t = title.lowercased()
        if t.contains("изменить") { return "pencil" }
        if t.contains("добавить") { return "arrow.clockwise" }
        if t.contains("настроить") { return "gearshape" }
        if t.contains("закончить") { return "power" }
        if t.contains("купленное") || t.contains("сортир") { return "arrow.up.arrow.down" }
        if t.contains("скин") { return "paintpalette" }
        if t.contains("справка") { return "questionmark.circle" }
        if t.contains("очистить") || t.contains("удалить") { return "trash" }
        if t.contains("куплено") { return "checkmark" }
        if t.contains("+1") { return "plus" }
        if t.contains("−1") { return "minus" }
        return "circle"
    }

    // MARK: Mac — 1-битное выпадающее меню

    private var mac: some View {
        MacWindow(title: menu.title, onClose: { store.menu = nil }) {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(menu.actions.enumerated()), id: \.element.id) { index, action in
                    if index > 0 {
                        Dither(a: Mac.ink, b: Mac.paper, cell: 1).frame(height: 2).padding(.horizontal, 6)
                    }
                    Text(action.title + (action.destructive ? "  ⚠" : ""))
                        .font(Mac.font(18))
                        .foregroundStyle(Mac.ink)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 12)
                        .frame(height: 44)
                        .contentShape(Rectangle())
                        .pressable(skin) { run(action) }
                }
            }
            .padding(.vertical, 4)
        }
        .frame(maxWidth: 360)
    }

    // MARK: Sims — круговое пай-меню вокруг пламбоба

    private var simsPie: some View {
        let count = menu.actions.count
        let radius: CGFloat = 118
        return ZStack {
            Circle()
                .fill(RadialGradient(colors: [Color(hex: 0x6E9BEA).opacity(0.5), .clear], center: .center, startRadius: 10, endRadius: 150))
                .frame(width: 300, height: 300)
            VStack(spacing: 4) {
                Plumbob(mood: 1).frame(width: 26, height: 42)
                Text(menu.title)
                    .font(Sims.font(12, .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .frame(maxWidth: 120)
            }
            ForEach(Array(menu.actions.enumerated()), id: \.element.id) { index, action in
                let angle = -Double.pi / 2 + Double(index) / Double(count) * 2 * .pi
                Text(action.title)
                    .font(Sims.font(12, .bold))
                    .foregroundStyle(action.destructive ? Color(hex: 0xFFD0C8) : .white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(maxWidth: 130)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(LinearGradient(colors: action.destructive ? [Color(hex: 0xE86A5A), Color(hex: 0xA8201A)] : [Sims.panelLight, Sims.panelBorder],
                                                 startPoint: .top, endPoint: .bottom))
                            .overlay(Capsule().stroke(.white.opacity(0.8), lineWidth: 1.5))
                    )
                    .shadow(color: .black.opacity(0.4), radius: 3, y: 2)
                    .pressable(skin) { run(action) }
                    .offset(x: CGFloat(cos(angle)) * radius, y: CGFloat(sin(angle)) * radius * 0.95)
            }
        }
        .frame(height: 320)
    }

    // MARK: Pixel — розовые слоты как в рюкзаке

    private var pixel: some View {
        VStack(spacing: 0) {
            HStack {
                Text(menu.title.uppercased()).font(Px.title(10)).foregroundStyle(Px.ink).lineLimit(1)
                Spacer()
                Button { store.menu = nil } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .black))
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(PixelRect(step: 2).fill(Px.pink))
                        .overlay(PixelRect(step: 2).strokeBorder(Px.ink, lineWidth: 2))
                }
                .buttonStyle(PressScaleStyle())
            }
            .padding(.horizontal, 10)
            .frame(height: 36)
            .background(Color.white)
            Rectangle().fill(Px.ink).frame(height: 3)
            VStack(spacing: 6) {
                ForEach(menu.actions) { action in
                    Text(action.title)
                        .font(Px.body(16, .bold))
                        .foregroundStyle(action.destructive ? .white : Px.navy)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(PixelRect(step: 2).fill(action.destructive ? Px.pink : Px.pinkSoft.opacity(0.55)))
                        .overlay(PixelRect(step: 2).strokeBorder(Px.ink, lineWidth: 2))
                        .contentShape(Rectangle())
                        .pressable(skin) { run(action) }
                }
            }
            .padding(12)
        }
        .background(PixelPanel(fill: Px.lavenderLight))
        .frame(maxWidth: 360)
    }
}
