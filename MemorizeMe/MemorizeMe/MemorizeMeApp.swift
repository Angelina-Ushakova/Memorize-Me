import SwiftUI
import SwiftData

@main
struct MemorizeMeApp: App {
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [SignificantDate.self])
    }
}
