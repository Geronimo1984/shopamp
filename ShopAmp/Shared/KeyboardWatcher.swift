import SwiftUI
import UIKit

/// Высота клавиатуры (0 — скрыта): над ней показывается кнопка «Готово»
@MainActor
final class KeyboardWatcher: ObservableObject {
    @Published var height: CGFloat = 0
    private var tokens: [NSObjectProtocol] = []

    init() {
        let center = NotificationCenter.default
        tokens.append(center.addObserver(forName: UIResponder.keyboardWillChangeFrameNotification, object: nil, queue: .main) { [weak self] note in
            guard let frame = note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
            let screen = UIScreen.main.bounds.height
            Task { @MainActor in self?.height = max(screen - frame.minY, 0) }
        })
        tokens.append(center.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.height = 0 }
        })
    }

    deinit { tokens.forEach(NotificationCenter.default.removeObserver) }

    /// Безопасные отступы экрана (строка состояния, полоска «домой») — окна не заходят под них
    static var insets: UIEdgeInsets {
        let window = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }
        var insets = window?.safeAreaInsets ?? UIEdgeInsets(top: 47, left: 0, bottom: 34, right: 0)
        let statusBar = window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0
        insets.top = max(insets.top, statusBar, 20)
        return insets
    }

    static func hide() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
