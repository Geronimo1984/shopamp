import SwiftUI

/// Скин Winamp: главное окно, эквалайзер («память») и плейлист
struct WinampSkinView: View {
    @EnvironmentObject var store: ShopStore

    var body: some View {
        GeometryReader { geo in
            let k = geo.size.width / 1200
            VStack(spacing: 0) {
                Scaled(k: k, size: CGSize(width: 1200, height: 840)) {
                    MainWindow()
                }
                if store.state.showEqualizer {
                    Scaled(k: k, size: CGSize(width: 1200, height: 430)) {
                        EqualizerWindow()
                    }
                }
                if store.state.showPlaylist {
                    PlaylistWindow(k: k)
                } else {
                    Spacer(minLength: 0)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
        }
        .background(Winamp.screen.ignoresSafeArea())
        .overlay {
            if store.isAdding || store.editingID != nil {
                WinampAddItemDialog()
            } else if store.isChoosingSkin {
                WinampSkinBrowser()
            }
        }
    }
}

/// Выбор скина в стиле Winamp (Skin Browser)
struct WinampSkinBrowser: View {
    @EnvironmentObject var store: ShopStore

    var body: some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()
                .onTapGesture { store.isChoosingSkin = false }

            VStack(spacing: 0) {
                TitleBar(title: "SKIN BROWSER", showIcon: false, buttons: [.close]) {
                    store.isChoosingSkin = false
                }
                .frame(height: 26)

                VStack(alignment: .leading, spacing: 10) {
                    Text("ВЫБЕРИТЕ СКИН")
                        .font(.system(size: 13, weight: .heavy, design: .monospaced))
                        .foregroundStyle(Winamp.label)

                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(SkinID.allCases.enumerated()), id: \.element) { index, skin in
                            let current = skin == store.state.skin
                            HStack(spacing: 10) {
                                SkinBadge(skin: skin)
                                    .frame(width: 30, height: 30)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text("\(index + 1). \(skin.title)")
                                        .font(.custom("Arial", size: 18))
                                    Text(skin.subtitle)
                                        .font(.custom("Arial", size: 12))
                                        .opacity(0.7)
                                }
                                Spacer(minLength: 4)
                                if current {
                                    Text("✓").font(.custom("Arial", size: 18))
                                }
                            }
                            .foregroundStyle(current ? Winamp.white : Winamp.listGreen)
                            .padding(.horizontal, 10)
                            .frame(height: 48)
                            .contentShape(Rectangle())
                            .pressable(.winamp) {
                                Haptics.tap()
                                store.state.skin = skin
                                store.isChoosingSkin = false
                            }
                        }
                    }
                    .padding(.vertical, 4)
                    .background(Color.black)
                    .overlay(Rectangle().strokeBorder(Winamp.frameDark, lineWidth: 2))

                    HStack {
                        Spacer()
                        SkinButton(edge: 1.5) { store.isChoosingSkin = false } label: { skinText("CLOSE", 15) }
                            .frame(width: 96, height: 34)
                    }
                }
                .padding(14)
            }
            .background(WindowBody(line: 3))
            .frame(maxWidth: 380)
            .padding(.horizontal, 16)
        }
    }
}

struct WinampSkinView_Previews: PreviewProvider {
    static var previews: some View {
        WinampSkinView()
            .environmentObject(ShopStore.demo())
            .preferredColorScheme(.dark)
    }
}
