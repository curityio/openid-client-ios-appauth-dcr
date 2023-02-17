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

import AppAuth
import SwiftKeychainWrapper

class ApplicationStateManager {
    
    private var authState: OIDAuthState
    private var metadataValue: OIDServiceConfiguration? = nil
    var idToken: String? = nil
    var isFirstRun: Bool
    private var storageKey = "io.curity.dcrclient"

    /*
     * Load any existing state
     */
    init() {
        
        // During development, when the database is recreated, this can be used to delete old registrations
        // KeychainWrapper.standard.removeObject(forKey: self.storageKey + ".registration")
        
        self.authState = OIDAuthState(authorizationResponse: nil, tokenResponse: nil, registrationResponse: nil)
        self.isFirstRun = true

        let data = KeychainWrapper.standard.data(forKey: self.storageKey + ".registration")
        if data != nil {

            do {

                let registrationResponse = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data!) as? OIDRegistrationResponse
                if registrationResponse != nil {
                    self.authState.update(with: registrationResponse)
                    Logger.debug(data: "Loaded dynamic client: ID: \(registrationResponse!.clientID), Secret: \(registrationResponse!.clientSecret!)")
                    self.isFirstRun = false
                }
            } catch {
                Logger.error(data: "Problem encountered loading application state: \(error)")
            }
        }
    }
    
    /*
     * The code example saves the id token so that logout works after a restart
     */
    func saveTokens(tokenResponse: OIDTokenResponse) {
        
        // When refreshing tokens, the Curity Identity Server does not issue a new ID token
        // The AppAuth code does not allow us to update the token response with the original ID token
        // Therefore we store the ID token separately
        if (tokenResponse.idToken != nil) {
            self.idToken = tokenResponse.idToken
        }
    
        self.authState.update(with: tokenResponse, error: nil)
        
        /* Tokens can be optionally stored in mobile secure storage, though this may not be appropriate for high security apps
         */
    }
    
    /*
     * Registration data must be saved across application restarts
     */
    func saveRegistration(registrationResponse: OIDRegistrationResponse) {
        
        do {
            self.authState.update(with: registrationResponse)
            let data = try NSKeyedArchiver.archivedData(withRootObject: registrationResponse, requiringSecureCoding: false)
            KeychainWrapper.standard.set(data, forKey: self.storageKey + ".registration")

        } catch {
            Logger.error(data: "Problem encountered saving application state: \(error)")
        }
    }
    
    /*
     * Clear tokens after logout or when the session expires
     */
    func clearTokens() {
        
        let lastRegistrationResponse = self.authState.lastRegistrationResponse
        self.authState = OIDAuthState(authorizationResponse: nil, tokenResponse: nil, registrationResponse: nil)
        self.authState.update(with: lastRegistrationResponse)
        self.idToken = nil
        KeychainWrapper.standard.removeObject(forKey: self.storageKey + ".idtoken")
    }

    var metadata: OIDServiceConfiguration? {
        get {
            return self.metadataValue
        }
        set(value) {
            self.metadataValue = value
        }
    }
    
    var registrationResponse: OIDRegistrationResponse? {
        get {
            return self.authState.lastRegistrationResponse
        }
    }
    
    var tokenResponse: OIDTokenResponse? {
        get {
            return self.authState.lastTokenResponse
        }
    }
}
