import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @EnvironmentObject var storeManager: StoreManager

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)

            DuplicatesView()
                .tabItem {
                    Label("Duplicates", systemImage: "doc.on.doc.fill")
                }
                .tag(1)

            SecretVaultView()
                .tabItem {
                    Label("Vault", systemImage: "lock.fill")
                }
                .tag(2)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(3)
        }
        .tint(.blue)
    }
}

#Preview {
    ContentView()
        .environmentObject(StoreManager())
}
