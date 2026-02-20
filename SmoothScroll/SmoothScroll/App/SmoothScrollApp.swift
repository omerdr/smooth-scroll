import SwiftUI

@main
struct SmoothScrollApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra("SmoothScroll", systemImage: "computermouse") {
            MenuBarView()
        }
        .menuBarExtraStyle(.window)
    }
}
