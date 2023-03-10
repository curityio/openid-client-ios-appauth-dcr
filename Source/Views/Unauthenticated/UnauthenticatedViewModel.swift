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
import AppAuth

class UnauthenticatedViewModel: ObservableObject {

    private let config: ApplicationConfig
    private let state: ApplicationStateManager
    private let appauth: AppAuthHandler
    private let onLoggedIn: (() -> Void)

    @Published var error: ApplicationError?
    
    init(
        config: ApplicationConfig,
        state: ApplicationStateManager,
        appauth: AppAuthHandler,
        onLoggedIn: @escaping () -> Void) {
            
        self.config = config
        self.state = state
        self.appauth = appauth
        self.onLoggedIn = onLoggedIn
        self.error = nil
    }
    
    /*
     * Run the authorization redirect on the UI thread, then redeem the code for tokens on a background thread
     */
    func startLogin() {

        Task {

            do {

                // First get metadata
                self.error = nil
                let registrationResponse = self.state.registrationResponse!
                let metadata = try await self.appauth.fetchMetadata()
                
                // Redirect on the main thread, to sign the user in
                try await MainActor.run {
                    
                    self.state.metadata = metadata
                    try self.appauth.performAuthorizationRedirect(
                        metadata: metadata,
                        clientID: registrationResponse.clientID,
                        scope: self.config.scope,
                        viewController: self.getViewController(),
                        force: self.isForcedLogin()
                    )
                }
                
                // Wait for the response
                let authorizationResponse = try await self.appauth.handleAuthorizationResponse()
                if authorizationResponse != nil {
                    
                    let tokenResponse = try await self.appauth.redeemCodeForTokens(
                        clientSecret: registrationResponse.clientSecret,
                        authResponse: authorizationResponse!
                        
                    )
                    
                    // Update state on the UI thread
                    await MainActor.run {
                        self.state.saveTokens(tokenResponse: tokenResponse)
                        self.state.isFirstRun = false
                        self.onLoggedIn()
                    }
                }

            } catch {
                
                // Handle errors on the UI thread
                await MainActor.run {
                    let appError = error as? ApplicationError
                    if appError != nil {
                        self.error = appError!
                    }
                }
            }
        }
    }

    private func isForcedLogin() -> Bool {

        // On the first run the user authenticates to register and then single signs on
        if self.state.isFirstRun {
            return false
        }

        // The app can also force its state to be logged out by clearing the ID token
        if self.state.idToken == nil {
            return true
        }
        
        return false
    }
    
    private func getViewController() -> UIViewController {
        let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        return scene!.keyWindow!.rootViewController!
    }
}
