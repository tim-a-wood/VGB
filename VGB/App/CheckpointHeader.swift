import SwiftUI

/// Compact app branding (name + tagline) shown at the top of each main tab.
struct CheckpointHeader: View {
    var body: some View {
        VStack(spacing: 2) {
            Text("Checkpoint")
                .font(.system(size: 22, weight: .bold, design: .rounded))
            Text("Your video game backlog, organized.")
                .font(.system(size: 17, weight: .regular, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Checkpoint. Your video game backlog, organized.")
    }
}
