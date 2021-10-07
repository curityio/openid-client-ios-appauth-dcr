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

import Foundation
import SwiftCoroutine

class MainViewModel: ObservableObject {

    var config: ApplicationConfig?
    var appauth: AppAuthHandler?
    @Published var isRegistered = false
    @Published var isAuthenticated = false

    let registrationModel: RegistrationViewModel
    let unauthenticatedModel: UnauthenticatedViewModel
    let authenticatedModel: AuthenticatedViewModel

    init() {

        self.config = nil
        self.appauth = nil
        self.isRegistered = true

        self.registrationModel = RegistrationViewModel()
        self.unauthenticatedModel = UnauthenticatedViewModel()
        self.authenticatedModel = AuthenticatedViewModel()
    }
    
    func load() throws {

        // Load configuration
        self.config = try ApplicationConfigLoader.load()
        self.appauth = AppAuthHandler(config: self.config!)

        // Load state from the keychain
        ApplicationStateManager.load()
        self.isRegistered = ApplicationStateManager.registrationResponse != nil

        // Update child view models
        self.registrationModel.load(config: self.config, appauth: self.appauth, onRegistered: self.onRegistered)
        self.unauthenticatedModel.load(config: self.config, appauth: self.appauth, onLoggedIn: self.onLoggedIn)
        self.authenticatedModel.load(config: self.config, appauth: self.appauth, onLoggedOut: self.onLoggedOut)
    }

    func onRegistered() {
        self.isRegistered = true
    }

    func onLoggedIn() {
        self.isAuthenticated = true
    }

    func onLoggedOut() {
        self.isAuthenticated = false
    }
}
