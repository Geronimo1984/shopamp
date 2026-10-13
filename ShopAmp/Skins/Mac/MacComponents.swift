import SwiftUI

/// Палитра 1-битного скина Macintosh (кремовый и графит)
enum Mac {
    static let paper = Color(hex: 0xEFEBD7)
    static let bezel = Color(hex: 0xE6E1CA)
    static let ink = Color(hex: 0x2E3036)
    static let screen = Color(hex: 0x2E3036)

    static func font(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        // Monocraft — пиксельный шрифт с полной кириллицей (OFL)
        Font.custom([.semibold, .bold, .heavy, .black].contains(weight) ? "Monocraft-Bold" : "Monocraft", size: size * 0.9)
    }
}

// MARK: - Пиксельные картинки

/// Рисует 1-битную картинку из строк: «#» — чернила, «o» — бумага, «.» — прозрачно
struct PixelBitmap: View {
    let rows: [String]
    var ink = Mac.ink
    var paper = Mac.paper

    var body: some View {
        Canvas { c, size in
            let height = rows.count
            let width = rows.map(\.count).max() ?? 1
            let cell = min(size.width / CGFloat(width), size.height / CGFloat(height))
            let ox = (size.width - cell * CGFloat(width)) / 2
            let oy = (size.height - cell * CGFloat(height)) / 2
            for (y, row) in rows.enumerated() {
                for (x, ch) in row.enumerated() where ch != "." {
                    let rect = CGRect(x: ox + CGFloat(x) * cell, y: oy + CGFloat(y) * cell,
                                      width: cell + 0.3, height: cell + 0.3)
                    c.fill(Path(rect), with: .color(ch == "#" ? ink : paper))
                }
            }
        }
    }
}

enum MacIcons {
    static let folder = [
        ".#####..........",
        "#ooooo#.........",
        "#oooooo########.",
        "################",
        "#oooooooooooooo#",
        "#oooooooooooooo#",
        "#oooooooooooooo#",
        "#oooooooooooooo#",
        "#oooooooooooooo#",
        "#oooooooooooooo#",
        "################",
    ]
    static let bag = [
        "....####....",
        "...#oooo#...",
        "...#o..o#...",
        "############",
        "#oooooooooo#",
        "#oo#oooo#oo#",
        "#oooooooooo#",
        "#oooooooooo#",
        "#ooo####ooo#",
        "#oooooooooo#",
        "############",
    ]
    static let mail = [
        "################",
        "##oooooooooooo##",
        "#o#oooooooooo#o#",
        "#oo#oooooooo#oo#",
        "#ooo#oooooo#ooo#",
        "#oooo######oooo#",
        "#oooooooooooooo#",
        "#oooooooooooooo#",
        "################",
    ]
    static let card = [
        "......####......",
        "################",
        "#oooooooooooooo#",
        "#o####oo######o#",
        "#o#oo#oooooooooo#",
        "#o####oo######o#",
        "#oooooooooooooo#",
        "#o####oo####ooo#",
        "#oooooooooooooo#",
        "################",
    ]
    static let gear = [
        "......####......",
        "...##.#oo#.##...",
        "..#oo##oo##oo#..",
        "...#oooooooo#...",
        ".###ooo##ooo###.",
        "#ooooo#..#ooooo#",
        "#ooooo#..#ooooo#",
        ".###ooo##ooo###.",
        "...#oooooooo#...",
        "..#oo##oo##oo#..",
        "...##.#oo#.##...",
        "......####......",
    ]
    static let help = [
        "...######...",
        "..#oooooo#..",
        ".#ooo##ooo#.",
        ".#oo#..#oo#.",
        ".....#ooo#..",
        "....#ooo#...",
        "....#oo#....",
        ".....##.....",
        "....#oo#....",
        ".....##.....",
    ]
    static let smile = [
        "..######..",
        ".#oooooo#.",
        "#oo#oo#oo#",
        "#oooooooo#",
        "#o#oooo#o#",
        "#oo####oo#",
        ".#oooooo#.",
        "..######..",
    ]
    static let cart = [
        "##..........",
        "o#########..",
        ".#ooooooo#..",
        ".#ooooooo#..",
        ".##########.",
        "..#.....#...",
        "..#.....#...",
    ]
}

// MARK: - Узоры

/// Шахматный узор 50% (дизеринг)
struct Dither: View {
    var a = Mac.ink
    var b = Mac.paper
    var cell: CGFloat = 1.5

    var body: some View {
        Canvas { c, size in
            c.fill(Path(CGRect(origin: .zero, size: size)), with: .color(b))
            var y: CGFloat = 0
            var row = 0
            while y < size.height {
                var x: CGFloat = row % 2 == 0 ? 0 : cell
                while x < size.width {
                    c.fill(Path(CGRect(x: x, y: y, width: cell, height: cell)), with: .color(a))
                    x += cell * 2
                }
                y += cell
                row += 1
            }
        }
    }
}

/// Горизонтальные полоски заголовка окна
struct TitleStripes: View {
    var body: some View {
        Canvas { c, size in
            var y: CGFloat = 2
            while y < size.height - 1 {
                c.fill(Path(CGRect(x: 0, y: y, width: size.width, height: 1.2)), with: .color(Mac.ink))
                y += 3
            }
        }
    }
}

// MARK: - Окно

struct MacWindow<Content: View>: View {
    let title: String
    var dark = false
    var onClose: (() -> Void)? = nil
    let content: Content

    init(title: String, dark: Bool = false, onClose: (() -> Void)? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.dark = dark
        self.onClose = onClose
        self.content = content()
    }

    private var fg: Color { dark ? Mac.paper : Mac.ink }
    private var bg: Color { dark ? Mac.ink : Mac.paper }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Text(title)
                    .font(Mac.font(17, .bold))
                    .foregroundStyle(fg)
                    .lineLimit(1)
                    .fixedSize()
                    .padding(.horizontal, 4)
                    .background(bg)
                TitleStripes()
                    .frame(height: 16)
                    .opacity(dark ? 0 : 1)
                if let onClose {
                    Button {
                        Haptics.tap()
                        onClose()
                    } label: {
                        ZStack {
                            Rectangle().fill(bg)
                            Rectangle().stroke(fg, lineWidth: 2)
                            Image(systemName: "xmark")
                                .font(.system(size: 10, weight: .black))
                                .foregroundStyle(fg)
                        }
                        .frame(width: 20, height: 20)
                    }
                    .buttonStyle(MacInvertStyle())
                }
            }
            .padding(.horizontal, 6)
            .frame(height: 30)
            Rectangle().fill(fg).frame(height: 2)
            content
        }
        .background(bg)
        .overlay(Rectangle().stroke(fg == Mac.ink ? Mac.ink : Mac.paper, lineWidth: 2))
        .background(Rectangle().fill(Mac.ink).offset(x: 4, y: 4))
    }
}

// MARK: - Элементы управления

struct MacButtonStyle: ButtonStyle {
    var isDefault = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Mac.font(16, .semibold))
            .foregroundStyle(configuration.isPressed ? Mac.paper : Mac.ink)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .padding(.horizontal, 8)
            .frame(minHeight: 42)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(configuration.isPressed ? Mac.ink : Mac.paper)
            )
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Mac.ink, lineWidth: 2))
            .padding(isDefault ? 4 : 0)
            .overlay(
                Group {
                    if isDefault {
                        RoundedRectangle(cornerRadius: 11).stroke(Mac.ink, lineWidth: 3)
                    }
                }
            )
    }
}

struct MacCheckbox: View {
    let checked: Bool
    var size: CGFloat = 16

    var body: some View {
        ZStack {
            Rectangle().fill(Mac.paper)
            Rectangle().stroke(Mac.ink, lineWidth: 2)
            if checked {
                Path { p in
                    p.move(to: CGPoint(x: 2, y: 2))
                    p.addLine(to: CGPoint(x: size - 2, y: size - 2))
                    p.move(to: CGPoint(x: size - 2, y: 2))
                    p.addLine(to: CGPoint(x: 2, y: size - 2))
                }
                .stroke(Mac.ink, lineWidth: 2)
            }
        }
        .frame(width: size, height: size)
    }
}

struct MacRadio: View {
    let on: Bool

    var body: some View {
        ZStack {
            Circle().fill(Mac.paper)
            Circle().stroke(Mac.ink, lineWidth: 2)
            if on {
                Circle().fill(Mac.ink).padding(4)
            }
        }
        .frame(width: 16, height: 16)
    }
}

struct DisclosureTriangle: View {
    let open: Bool

    var body: some View {
        Path { p in
            p.move(to: CGPoint(x: 0, y: 0))
            p.addLine(to: CGPoint(x: 10, y: 5))
            p.addLine(to: CGPoint(x: 0, y: 10))
            p.closeSubpath()
        }
        .stroke(Mac.ink, lineWidth: 1.5)
        .frame(width: 10, height: 10)
        .rotationEffect(.degrees(open ? 90 : 0))
        .animation(.easeOut(duration: 0.15), value: open)
    }
}

/// Рамка-группа как в Control Panel
struct MacGroupBox<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(6)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(Rectangle().stroke(Mac.ink, lineWidth: 2))
    }
}
