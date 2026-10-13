import SwiftUI

/// Короткое сообщение внизу экрана в стиле текущего скина
struct ToastView: View {
    let text: String
    let skin: SkinID

    var body: some View {
        switch skin {
        case .winamp:
            Text(text.uppercased())
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundStyle(Winamp.green)
                .padding(12)
                .background(Winamp.lcd)
                .overlay(Rectangle().strokeBorder(Winamp.frameLight, lineWidth: 2))
        case .aero:
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(.white, Color(hex: 0x2A5CCB))
                Text(text).font(.system(size: 14)).foregroundStyle(.black)
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color(hex: 0xFFFFE1)))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black.opacity(0.7), lineWidth: 1))
        case .mac:
            Text(text)
                .font(Mac.font(17))
                .foregroundStyle(Mac.ink)
                .padding(12)
                .background(Mac.paper)
                .overlay(Rectangle().stroke(Mac.ink, lineWidth: 2))
                .background(Rectangle().fill(Mac.ink).offset(x: 4, y: 4))
        case .sims:
            HStack(spacing: 8) {
                Plumbob(mood: 1).frame(width: 12, height: 20)
                Text(text).font(Sims.font(13, .bold)).foregroundStyle(.white)
            }
            .padding(12)
            .background(SimsPanel(fill: [Sims.panelLight, Sims.panel]))
        case .pixel:
            Text(text)
                .font(Px.body(17))
                .foregroundStyle(.white)
                .padding(12)
                .background(PixelPanel(fill: Px.pinkSoft, border: Px.ink, shadow: Px.navy))
        }
    }
}
