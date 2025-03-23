import SwiftUI

struct SectionHeader: View {
    let title: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }
} 