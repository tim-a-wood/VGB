import SwiftUI

/// Compact app branding (name + tagline) shown at the top of each main tab.
struct CheckpointHeader: View {
    var body: some View {
        VStack(spacing: 2) {
            Text("Checkpoint")
                .font(.system(size: 25.5, weight: .bold))
            Text("Your video game backlog, organized.")
                .font(.system(size: 18))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}
