import SwiftUI

@main
struct DemoApp: App {

    private let model: MainViewModel

    init() {
        self.model = MainViewModel()
    }

    var body: some Scene {
        WindowGroup {
            MainView(model: self.model)
        }
    }
}
