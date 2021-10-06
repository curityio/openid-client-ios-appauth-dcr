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

    private var config: ApplicationConfig
    private var appauth: AppAuthHandler?
    private var onLoggedIn: (() -> Void)?

    @Published var error: ApplicationError?
    
    init(config: ApplicationConfig, appauth: AppAuthHandler, onLoggedIn: @escaping () -> Void) {

        self.config = config
        self.appauth = appauth
        self.onLoggedIn = onLoggedIn
        self.error = nil
    }
    
    /*
     * Run the authorization redirect on the UI thread, then redeem the code for tokens on a background thread
     */
    func startLogin() {

        DispatchQueue.main.startCoroutine {

            do {

                self.error = nil
                let registrationResponse = ApplicationStateManager.registrationResponse!

                // First get metadata
                var metadata = ApplicationStateManager.metadata
                if metadata == nil {
                    try DispatchQueue.global().await {
                        metadata = try self.appauth!.fetchMetadata().await()
                    }
                    ApplicationStateManager.metadata = metadata
                }
                
                // Then 
                let authorizationResponse = try self.appauth!.performAuthorizationRedirect(
                    metadata: metadata!,
                    clientID: registrationResponse.clientID,
                    scope: self.config.scope,
                    viewController: self.getViewController()
                ).await()

                if authorizationResponse != nil {
                    
                    var tokenResponse: OIDTokenResponse? = nil
                    try DispatchQueue.global().await {
                        
                        tokenResponse = try self.appauth!.redeemCodeForTokens(
                            clientSecret: registrationResponse.clientSecret,
                            authResponse: authorizationResponse!
                            
                        ).await()
                    }
                    
                    ApplicationStateManager.tokenResponse = tokenResponse
                    ApplicationStateManager.idToken = tokenResponse?.idToken
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
}
