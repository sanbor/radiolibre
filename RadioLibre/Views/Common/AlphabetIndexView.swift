import SwiftUI

struct AlphabetIndexView: View {
    let letters: [String]
    let onSelect: (String) -> Void

    @GestureState private var isDragging = false

    var body: some View {
        VStack(spacing: 0) {
            ForEach(letters, id: \.self) { letter in
                Text(letter)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.blue)
                    .frame(width: 16, height: 16)
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 6)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .local)
                .updating($isDragging) { _, state, _ in
                    state = true
                }
                .onChanged { value in
                    let totalHeight = CGFloat(letters.count) * 16 + 8
                    let adjustedY = value.location.y - 4
                    let index = Int(adjustedY / (totalHeight / CGFloat(letters.count)))
                    if index >= 0, index < letters.count {
                        onSelect(letters[index])
                    }
                }
        )
    }
}
