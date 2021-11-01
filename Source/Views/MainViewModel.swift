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

    private let config: ApplicationConfig
    private let state: ApplicationStateManager
    private let appauth: AppAuthHandler
    private var registrationModel: RegistrationViewModel?
    private var unauthenticatedModel: UnauthenticatedViewModel?
    private var authenticatedModel: AuthenticatedViewModel?
    
    @Published var isRegistered = false
    @Published var isAuthenticated = false

    init() {

        self.config = try! ApplicationConfigLoader.load()
        self.state = ApplicationStateManager()
        self.appauth = AppAuthHandler(config: self.config)
        self.isRegistered = self.state.registrationResponse != nil
    }
    
    func getRegistrationViewModel() -> RegistrationViewModel {
        
        if self.registrationModel == nil {
            self.registrationModel = RegistrationViewModel(
                config: self.config,
                state: self.state,
                appauth: self.appauth,
                onRegistered: self.onRegistered)
        }
    
        return self.registrationModel!
    }

    func getUnauthenticatedViewModel() -> UnauthenticatedViewModel {
        
        if self.unauthenticatedModel == nil {
            self.unauthenticatedModel = UnauthenticatedViewModel(
                config: self.config,
                state: self.state,
                appauth: self.appauth,
                onLoggedIn: self.onLoggedIn)
        }
    
        return self.unauthenticatedModel!
    }
    
    func getAuthenticatedViewModel() -> AuthenticatedViewModel {
        
        if self.authenticatedModel == nil {
            self.authenticatedModel = AuthenticatedViewModel(
                config: self.config,
                state: self.state,
                appauth: self.appauth,
                onLoggedOut: self.onLoggedOut)
        }
    
        return self.authenticatedModel!
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
