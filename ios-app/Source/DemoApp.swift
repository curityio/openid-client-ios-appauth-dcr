//
// Copyright (C) 2021 Curity AB.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import SwiftUI

@main
struct DemoApp: App {
    
    private let config: ApplicationConfig
    private let appauth: AppAuthHandler
    private let model: MainViewModel
    
    init() {
        self.config = ApplicationConfigLoader.load()
        self.appauth = AppAuthHandler(config: config)
        self.model = MainViewModel(config: config, appauth: appauth)
    }
    
    var body: some Scene {
        WindowGroup {
            MainView(config: self.config, model: self.model)
        }
    }
}
