import SwiftUI

struct EmojiPreview: View {
    let emoji: Emoji
    
    var body: some View {
        VStack(spacing: 8) {
            Text(emoji.emoji)
                .font(.system(size: 100))
                .padding()
            
            Text(emoji.description)
                .font(.headline)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(width: 240)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.windowBackgroundColor))
                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
} 