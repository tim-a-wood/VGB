import SwiftUI

private enum OnboardingStorage {
    static let hasCompletedKey = "VGB.hasCompletedOnboarding"

    static var hasCompleted: Bool {
        get { UserDefaults.standard.bool(forKey: hasCompletedKey) }
        set { UserDefaults.standard.set(newValue, forKey: hasCompletedKey) }
    }
}

/// First-launch walkthrough (2–3 screens). Shown until the user taps Get Started.
struct OnboardingView: View {
    var onComplete: () -> Void

    @State private var page = 0
    private let pageCount = 3

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $page) {
                onboardingPage(
                    icon: "books.vertical",
                    title: "Your game backlog",
                    body: "Add games from your library. Search IGDB to prefill details, or enter them yourself. Keep one list of what you want to play."
                )
                .tag(0)

                onboardingPage(
                    icon: "arrow.triangle.2.circlepath",
                    title: "Stay on track",
                    body: "Wishlist, Backlog, Playing, Completed, Dropped. Move games through stages and prioritize your backlog with drag and drop."
                )
                .tag(1)

                onboardingPage(
                    icon: "chart.pie",
                    title: "Stats & rankings",
                    body: "See completion %, genre breakdown, and rank your games by your rating or critic score."
                )
                .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea(edges: .bottom)

            VStack(spacing: 20) {
                PageIndicator(current: page, total: pageCount)
                    .padding(.bottom, 8)

                Button {
                    if page < pageCount - 1 {
                        Haptic.light.play()
                        withAnimation { page += 1 }
                    } else {
                        Haptic.light.play()
                        OnboardingStorage.hasCompleted = true
                        onComplete()
                    }
                } label: {
                    Text(page < pageCount - 1 ? "Continue" : "Get started")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
                .accessibilityLabel(page < pageCount - 1 ? "Continue to next screen" : "Get started and open your game catalog")
            }
        }
    }

    private func onboardingPage(icon: String, title: String, body: String) -> some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: icon)
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            VStack(spacing: 12) {
                Text(title)
                    .font(.title2.weight(.semibold))
                    .multilineTextAlignment(.center)
                Text(body)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 32)
            Spacer()
            Spacer()
                .frame(height: 100)
        }
    }
}

private struct PageIndicator: View {
    let current: Int
    let total: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<total, id: \.self) { i in
                Circle()
                    .fill(i == current ? Color.primary : Color.primary.opacity(0.3))
                    .frame(width: 8, height: 8)
            }
        }
    }
}

/// Use to check whether onboarding has been completed (e.g. to show onboarding vs main UI).
enum Onboarding {
    static var hasCompleted: Bool {
        OnboardingStorage.hasCompleted
    }
}

#Preview {
    OnboardingView(onComplete: {})
}
