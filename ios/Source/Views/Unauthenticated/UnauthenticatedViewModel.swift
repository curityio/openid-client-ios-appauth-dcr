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
import AppAuth

class UnauthenticatedViewModel: ObservableObject {

    private var config: ApplicationConfig?
    private var state: ApplicationStateManager?
    private var appauth: AppAuthHandler?
    private var onLoggedIn: (() -> Void)?

    @Published var isLoaded: Bool
    @Published var error: ApplicationError?
    
    init() {
        self.config = nil
        self.state = nil
        self.appauth = nil
        self.onLoggedIn = nil
        self.error = nil
        self.isLoaded = false
    }
    
    func load(
        config: ApplicationConfig,
        state: ApplicationStateManager,
        appauth: AppAuthHandler,
        onLoggedIn: @escaping () -> Void) {

        self.config = config
        self.state = state
        self.appauth = appauth
        self.onLoggedIn = onLoggedIn
        self.isLoaded = true
    }
    
    /*
     * Run the authorization redirect on the UI thread, then redeem the code for tokens on a background thread
     */
    func startLogin() {

        DispatchQueue.main.startCoroutine {

            do {

                self.error = nil
                let registrationResponse = self.state!.registrationResponse!
                var metadata = self.state!.metadata

                // First get metadata if required
                if metadata == nil {
                    try DispatchQueue.global().await {
                        metadata = try self.appauth!.fetchMetadata().await()
                    }
                    self.state!.metadata = metadata
                }
                
                // Then trigger a redirect to sign the user in
                let authorizationResponse = try self.appauth!.performAuthorizationRedirect(
                    metadata: metadata!,
                    clientID: registrationResponse.clientID,
                    scope: self.config!.scope,
                    viewController: self.getViewController(),
                    force: self.isForcedLogin()
                ).await()

                if authorizationResponse != nil {
                    
                    var tokenResponse: OIDTokenResponse? = nil
                    try DispatchQueue.global().await {
                        
                        tokenResponse = try self.appauth!.redeemCodeForTokens(
                            clientSecret: registrationResponse.clientSecret,
                            authResponse: authorizationResponse!
                            
                        ).await()
                    }
                    
                    self.state!.saveTokens(tokenResponse: tokenResponse!)
                    self.state!.isFirstRun = false
                    self.onLoggedIn!()
                }

            } catch {
                
                let appError = error as? ApplicationError
                if appError != nil {
                    self.error = appError!
                }
            }
        }
    }

    private func getViewController() -> UIViewController {
        return UIApplication.shared.windows.first!.rootViewController!
    }

    private func isForcedLogin() -> Bool {

        // On the first run the user authenticates to register and then single signs on
        if self.state!.isFirstRun {
            return false
        }

        // Demonstrate an approach if cookies become stuck in the in app browser window
        // Our force login logic will run it the user is logged out, which is true when there is no ID token
        // https://github.com/openid/AppAuth-iOS/issues/542
        if self.state!.idToken == nil {
            return true
        }
        
        return false
    }
}
