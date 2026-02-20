import SwiftUI

/// Full-screen splash matching the Launch Screen. Shown until graphics are preloaded.
struct SplashView: View {
    var body: some View {
        ZStack {
            Color("LaunchBackground")
                .ignoresSafeArea()
            Image("LaunchLogo")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 280, maxHeight: 373)
        }
    }
}

#Preview {
    SplashView()
}
