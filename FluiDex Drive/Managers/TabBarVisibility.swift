import SwiftUI
import Combine

final class TabBarVisibility: ObservableObject {
    @Published var isVisible: Bool = true

    func show(animated: Bool = true) {
        if animated {
            withAnimation { isVisible = true }
        } else {
            isVisible = true
        }
    }

    func hide(animated: Bool = true) {
        if animated {
            withAnimation { isVisible = false }
        } else {
            isVisible = false
        }
    }

    func set(_ visible: Bool, animated: Bool = true) {
        if animated {
            withAnimation { isVisible = visible }
        } else {
            isVisible = visible
        }
    }
}
