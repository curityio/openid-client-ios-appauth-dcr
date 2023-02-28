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

class RegistrationViewModel: ObservableObject {

    private let config: ApplicationConfig
    private let state: ApplicationStateManager
    private let appauth: AppAuthHandler
    private let onRegistered: (() -> Void)

    @Published var error: ApplicationError?
    
    init(
        config: ApplicationConfig,
        state: ApplicationStateManager,
        appauth: AppAuthHandler,
        onRegistered: @escaping () -> Void) {
            
        self.config = config
        self.state = state
        self.appauth = appauth
        self.onRegistered = onRegistered
        self.error = nil
    }

    /*
     * Lookup metadata and perform an initial login using the code flow and the DCR scope
     * Make HTTP requests on a worker thread and then perform updates on the UI thread
     */
    func startRegistration() {
        
        Task {

            do {

                // First get metadata
                self.error = nil
                let metadata = try await self.appauth.fetchMetadata()
                
                // Redirect on the main thread, to sign the user in with a dcr scope
                try await MainActor.run {
                    
                    self.state.metadata = metadata
                    try self.appauth.performAuthorizationRedirect(
                        metadata: metadata,
                        clientID: self.config.registrationClientID,
                        scope: "dcr",
                        viewController: self.getViewController(),
                        force: true
                    )
                }

                // Wait for the response
                let authorizationResponse = try await self.appauth.handleAuthorizationResponse()
                if authorizationResponse != nil {

                    // Swap the code for a DCR access token
                    let tokenResponse = try await self.appauth.redeemCodeForTokens(
                        clientSecret: nil,
                        authResponse: authorizationResponse!)
                    let dcrAccessToken = tokenResponse.accessToken
                
                    // Then send the registration request, which is secured via the access token
                    let registrationResponse = try await self.appauth.registerClient(
                        metadata: metadata,
                        accessToken: dcrAccessToken!)
                
                    // Update state on the UI thread, and tell the main view to update
                    await MainActor.run {
                        self.state.saveRegistration(registrationResponse: registrationResponse)
                        self.onRegistered()
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
    
    private func getViewController() -> UIViewController {
        let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        return scene!.keyWindow!.rootViewController!
    }
}

