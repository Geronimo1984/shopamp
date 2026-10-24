import SwiftUI

/// Список скинов. Новый скин: добавить case, название, значок и ветку в ContentView.
enum SkinID: String, Codable, CaseIterable, Identifiable {
    case winamp
    case aero
    case mac
    case sims
    case pixel

    var id: String { rawValue }

    var title: String {
        switch self {
        case .winamp: return "Winamp"
        case .aero: return "Frutiger Aero"
        case .mac: return "Macintosh"
        case .sims: return "Симс"
        case .pixel: return "Pixel Moon"
        }
    }

    /// Светлый скин — тёмный текст статус-бара
    var isLight: Bool {
        self == .mac || self == .pixel
    }

    var subtitle: String {
        switch self {
        case .winamp: return "классический плеер 2000-х"
        case .aero: return "небо, пузыри и Windows XP"
        case .mac: return "1-битная классика 90-х"
        case .sims: return "сайт The Sims 2 и пламбоб"
        case .pixel: return "пастельный пиксель и лунная магия"
        }
    }
}

/// Мини-значок скина для списка выбора
struct SkinBadge: View {
    let skin: SkinID

    var body: some View {
        switch skin {
        case .winamp:
            ZStack {
                RoundedRectangle(cornerRadius: 5)
                    .fill(LinearGradient(colors: [Winamp.bodyTop, Winamp.bodyBottom],
                                         startPoint: .top, endPoint: .bottom))
                RoundedRectangle(cornerRadius: 5)
                    .stroke(Winamp.frameDark, lineWidth: 1.5)
                BoltShape()
                    .fill(LinearGradient(colors: [Winamp.goldTop, Color(hex: 0xD98A2B)],
                                         startPoint: .top, endPoint: .bottom))
                    .padding(6)
            }
        case .aero:
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(LinearGradient(colors: [Aero.skyTop, Aero.skyBottom, Aero.grassLight, Aero.grassDark],
                                         startPoint: .top, endPoint: .bottom))
                Circle()
                    .stroke(.white.opacity(0.9), lineWidth: 1.2)
                    .background(Circle().fill(.white.opacity(0.25)))
                    .padding(7)
                Ellipse().fill(.white.opacity(0.9)).frame(width: 7, height: 4).offset(x: -4, y: -6)
                RoundedRectangle(cornerRadius: 6).stroke(Color.white, lineWidth: 1.5)
            }
        case .mac:
            ZStack {
                Rectangle().fill(Mac.paper)
                PixelBitmap(rows: MacIcons.smile).padding(6)
                Rectangle().stroke(Mac.ink, lineWidth: 2)
            }
        case .sims:
            Image("sims_logo_puck").resizable().interpolation(.high)
        case .pixel:
            ZStack {
                PixelRect(step: 3).fill(Px.lavender)
                PixelArt(rows: PxArt.moon, palette: PxArt.palette).padding(6)
                PixelRect(step: 3).strokeBorder(Px.ink, lineWidth: 2)
            }
        }
    }
}

/// Корневой экран: показывает выбранный скин. Данные и логика общие для всех скинов.
struct ContentView: View {
    @EnvironmentObject var store: ShopStore
    @StateObject private var keyboard = KeyboardWatcher()

    var body: some View {
        skinView
            .preferredColorScheme(store.state.skin.isLight ? .light : .dark)
            .overlayPreferenceValue(AssistAnchorKey.self) { anchors in
                GeometryReader { proxy in
                    AssistantLayer(anchors: anchors.mapValues { proxy[$0] }, size: proxy.size)
                }
            }
            .overlay {
                if store.showHelp {
                    HelpView(skin: store.state.skin)
                } else if let dish = store.editingDish {
                    DishEditorView(skin: store.state.skin, draft: dish).id(dish.id)
                } else if store.isViewingDishes {
                    DishesView(skin: store.state.skin)
                } else if store.isEditingMemory {
                    MemoryView(skin: store.state.skin)
                }
            }
            .overlay {
                if let menu = store.menu {
                    SkinMenuView(menu: menu, skin: store.state.skin)
                }
            }
            .overlay {
                if let name = store.iconPickerName {
                    IconPickerView(skin: store.state.skin, name: name)
                }
            }
            .overlay {
                // у цифровой клавиатуры и поля рецепта нет кнопки «Ввод» — закрыть клавиатуру можно здесь
                if keyboard.height > 0 {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            SkinChip(title: "Готово ⌄", style: SkinStyle.of(store.state.skin), filled: true) { KeyboardWatcher.hide() }
                        }
                        .padding(.horizontal, 10)
                        .padding(.bottom, keyboard.height + 6)
                    }
                    .ignoresSafeArea()
                    .transition(.opacity)
                }
            }
            // сообщения — поверх всех окон (иначе их закрывает затемнение открытого окна)
            .overlay {
                VStack {
                    Spacer()
                    if let toast = store.toast {
                        ToastView(text: toast, skin: store.state.skin)
                            .padding(.horizontal, 20)
                            .padding(.bottom, keyboard.height > 0 ? keyboard.height + 60 : 70)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            .onTapGesture { store.toast = nil }
                    }
                }
                // отступ от клавиатуры считается вручную
                .ignoresSafeArea(.keyboard)
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: store.toast)
            .onAppear {
                if !store.state.seenHelp { store.showHelp = true }
            }
            // окна (SkinChrome) подстраиваются под клавиатуру
            .environmentObject(keyboard)
    }

    @ViewBuilder
    private var skinView: some View {
        switch store.state.skin {
        case .winamp:
            WinampSkinView()
        case .aero:
            AeroSkinView()
        case .mac:
            MacSkinView()
        case .sims:
            SimsSkinView()
        case .pixel:
            PixelSkinView()
        }
    }
}
