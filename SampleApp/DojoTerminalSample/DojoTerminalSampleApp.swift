import SwiftUI

@main
struct DojoTerminalSampleApp: App {
    var body: some Scene {
        WindowGroup {
            if #available(iOS 16.7, *) {
                ContentView()
            } else {
                // Fallback on earlier versions
            }
        }
    }
}
