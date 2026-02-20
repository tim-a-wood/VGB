import SwiftUI

/// Full-screen splash matching the Launch Screen. Shown until graphics are preloaded.
/// Uses the same layout as UILaunchScreen (centered, scale-to-fit) so the transition from
/// system launch screen to this view is seamless with no size jump.
struct SplashView: View {
    var body: some View {
        Color("LaunchBackground")
            .ignoresSafeArea()
            .overlay(alignment: .bottom) {
                ProgressView()
                    .progressViewStyle(.circular)
                    .scaleEffect(1.2)
                    .tint(.white)
                    .padding(.bottom, 48)
            }
            .overlay {
                Image("LaunchLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
    }
}

#Preview {
    SplashView()
}
