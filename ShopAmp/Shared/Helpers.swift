import SwiftUI
import CoreText
#if canImport(UIKit)
import UIKit
#endif

extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: alpha)
    }
}

enum Haptics {
    static func tap() {
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }
}

extension View {
    /// Абсолютное размещение в координатах «скина» (как на исходной картинке)
    func place(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> some View {
        frame(width: w, height: h).position(x: x + w / 2, y: y + h / 2)
    }

    /// То же, но с якорем для помощника: якорь ставится до позиционирования, иначе он займёт весь родитель
    func place(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, anchor id: String) -> some View {
        frame(width: w, height: h).assistAnchor(id).position(x: x + w / 2, y: y + h / 2)
    }
}

/// Рисует содержимое в пиксельной сетке скина и масштабирует под ширину экрана
struct Scaled<Content: View>: View {
    let k: CGFloat
    let size: CGSize
    let content: Content

    init(k: CGFloat, size: CGSize, @ViewBuilder content: () -> Content) {
        self.k = k
        self.size = size
        self.content = content()
    }

    var body: some View {
        content
            .frame(width: size.width, height: size.height)
            .scaleEffect(k, anchor: .topLeading)
            .frame(width: size.width * k, height: size.height * k, alignment: .topLeading)
    }
}

/// Регистрирует шрифты из папки Fonts (пиксельные шрифты скинов)
enum FontRegistry {
    static func registerBundledFonts() {
        let urls = (Bundle.main.urls(forResourcesWithExtension: "ttf", subdirectory: nil) ?? [])
            + (Bundle.main.urls(forResourcesWithExtension: "ttf", subdirectory: "Fonts") ?? [])
        for url in urls {
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
}

/// Анимация нажатия в характере скина
struct SkinPressStyle: ButtonStyle {
    let skin: SkinID

    func makeBody(configuration: Configuration) -> some View {
        switch skin {
        case .mac: MacInvertStyle().makeBody(configuration: configuration)
        case .pixel: PixelPressStyle().makeBody(configuration: configuration)
        case .winamp:
            // Winamp: элемент «вдавливается» на пиксель и тускнеет
            configuration.label
                .offset(x: configuration.isPressed ? 1.5 : 0, y: configuration.isPressed ? 1.5 : 0)
                .brightness(configuration.isPressed ? -0.15 : 0)
                .animation(.linear(duration: 0.05), value: configuration.isPressed)
        default: PressScaleStyle().makeBody(configuration: configuration)
        }
    }
}

extension View {
    /// Делает элемент кнопкой с анимацией нажатия скина (вместо onTapGesture без отклика)
    func pressable(_ skin: SkinID, action: @escaping () -> Void) -> some View {
        Button(action: action) { self.contentShape(Rectangle()) }
            .buttonStyle(SkinPressStyle(skin: skin))
    }
}

// MARK: - Пауза украшений

private struct DecorPausedKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    /// Открыто окно поверх скина — фоновые анимации (персонажи, плитки, сцены) стоят, процессор не тратится
    var decorPaused: Bool {
        get { self[DecorPausedKey.self] }
        set { self[DecorPausedKey.self] = newValue }
    }
}
