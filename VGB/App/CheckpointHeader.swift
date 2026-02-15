import SwiftUI

/// Compact app branding (name + tagline) shown at the top of each main tab.
struct CheckpointHeader: View {
    var body: some View {
        VStack(spacing: 2) {
            Text("Checkpoint")
                .font(.headline)
            Text("Your video game backlog, organized.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}
