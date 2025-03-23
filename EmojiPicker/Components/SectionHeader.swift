import SwiftUI

struct SectionHeader: View {
    let title: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.vertical, 8)
                .padding(.horizontal, 10)
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(backgroundMaterial)
        .cornerRadius(8)
        .padding(.horizontal, 10)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }
    
    private var backgroundMaterial: some View {
        #if os(macOS)
        return VisualEffectView(material: .headerView, blendingMode: .withinWindow)
            .edgesIgnoringSafeArea(.all)
        #else
        // iOS implementation
        return ZStack {
            Color.gray.opacity(0.15)
            
            if #available(iOS 15.0, *) {
                Rectangle()
                    .fill(.ultraThinMaterial)
            } else {
                BlurView(style: .systemUltraThinMaterial)
            }
        }
        #endif
    }
}

// MARK: - Supporting views for blur effects

#if os(macOS)
struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let visualEffectView = NSVisualEffectView()
        visualEffectView.material = material
        visualEffectView.blendingMode = blendingMode
        visualEffectView.state = .active
        return visualEffectView
    }
    
    func updateNSView(_ visualEffectView: NSVisualEffectView, context: Context) {
        visualEffectView.material = material
        visualEffectView.blendingMode = blendingMode
    }
}
#else
// iOS BlurView implementation
struct BlurView: UIViewRepresentable {
    let style: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        let blurEffect = UIBlurEffect(style: style)
        let view = UIVisualEffectView(effect: blurEffect)
        return view
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
}
#endif 