import SwiftUI

struct CategoryToolbar: View {
    let sections: [EmojiSection]
    @Binding var selectedSectionIndex: Int
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(sections.enumerated()), id: \.element.id) { index, section in
                    Button(action: {
                        selectedSectionIndex = index
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: section.icon)
                                .foregroundColor(selectedSectionIndex == index ? .accentColor : .primary)
                                .imageScale(.large)
                            
                            if selectedSectionIndex == index {
                                Circle()
                                    .fill(Color.accentColor)
                                    .frame(width: 4, height: 4)
                            } else {
                                Circle()
                                    .fill(Color.clear)
                                    .frame(width: 4, height: 4)
                            }
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 12)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .help(section.title)
                }
            }
            .padding(.horizontal, 8)
        }
        .padding(.horizontal, 8)
        .frame(height: 44)
        .background(Color(.windowBackgroundColor).opacity(0.8))
    }
} 