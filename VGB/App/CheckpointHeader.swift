import SwiftUI

/// Compact app branding (name + tagline) shown at the top of each main tab.
struct CheckpointHeader: View {
    var body: some View {
        VStack(spacing: 2) {
            Text("Checkpoint")
                .font(.title.weight(.bold))
            Text("Your video game backlog, organized.")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Checkpoint. Your video game backlog, organized.")
    }
}
