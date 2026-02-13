import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Text("VGB")
                    .font(.largeTitle.weight(.bold))
                Text("Your video game backlog, organized.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .navigationTitle("Backlog")
        }
    }
}

#Preview {
    ContentView()
}
