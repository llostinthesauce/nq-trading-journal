import SwiftUI

extension View {
    func cardStyle() -> some View {
        self
            .padding()
            .background(Theme.card)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 3)
    }
}
