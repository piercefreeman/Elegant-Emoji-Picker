import SwiftUI

struct EmojiCell: View {
    let emoji: Emoji
    let isHighlighted: Bool
    var action: () -> Void
    var longPressAction: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Text(emoji.emoji)
            .font(.system(size: 24))
            .frame(width: 40, height: 40)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isHighlighted ? Color.accentColor.opacity(0.2) : Color.clear)
            )
            .contentShape(Rectangle())
            .onTapGesture {
                action()
            }
            .onLongPressGesture(minimumDuration: 0.5, pressing: { isPressing in
                isPressed = isPressing
                if isPressing {
                    longPressAction()
                }
            }, perform: {})
            .scaleEffect(isPressed ? 1.2 : 1.0)
            .animation(.spring(response: 0.3), value: isPressed)
            .help(emoji.description)
    }
} 