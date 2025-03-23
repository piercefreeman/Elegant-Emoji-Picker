import SwiftUI

struct SkinToneSelector: View {
    let onSkinToneSelected: (EmojiSkinTone?) -> Void
    let currentSkinTone: EmojiSkinTone?
    
    var body: some View {
        HStack(spacing: 8) {
            // Default yellow emoji
            Button(action: {
                onSkinToneSelected(nil)
            }) {
                Circle()
                    .fill(Color.yellow)
                    .frame(width: 24, height: 24)
                    .overlay(
                        Circle()
                            .stroke(currentSkinTone == nil ? Color.accentColor : Color.clear, lineWidth: 2)
                    )
            }
            .buttonStyle(.plain)
            
            // Skin tones
            ForEach(EmojiSkinTone.allCases, id: \.self) { tone in
                Button(action: {
                    onSkinToneSelected(tone)
                }) {
                    Circle()
                        .fill(colorForSkinTone(tone))
                        .frame(width: 24, height: 24)
                        .overlay(
                            Circle()
                                .stroke(currentSkinTone == tone ? Color.accentColor : Color.clear, lineWidth: 2)
                        )
                }
                .buttonStyle(.plain)
                .help(tone.displayName)
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.windowBackgroundColor))
                .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
        )
    }
    
    private func colorForSkinTone(_ tone: EmojiSkinTone) -> Color {
        switch tone {
        case .Light:
            return Color(red: 0.98, green: 0.91, blue: 0.82)
        case .MediumLight:
            return Color(red: 0.95, green: 0.85, blue: 0.67)
        case .Medium:
            return Color(red: 0.85, green: 0.68, blue: 0.50)
        case .MediumDark:
            return Color(red: 0.66, green: 0.47, blue: 0.33)
        case .Dark:
            return Color(red: 0.45, green: 0.30, blue: 0.18)
        }
    }
} 