import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var significantDateViewModel = SignificantDateViewModel()
    
    var body: some View {
        RootView()
            .environmentObject(significantDateViewModel)
            .task {
                await significantDateViewModel.initialize(modelContext: modelContext)
                
                if significantDateViewModel.shouldRefreshAnalysis() {
                    await significantDateViewModel.refreshAnalysis(modelContext: modelContext)
                }
            }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .modelContainer(for: [SignificantDate.self], inMemory: true)
    }
}
