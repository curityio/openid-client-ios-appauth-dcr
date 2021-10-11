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

struct ApplicationStateManager {
    
    static private var authState: OIDAuthState? = nil
    static private var metadataValue: OIDServiceConfiguration? = nil
    static var idToken: String? = nil
    private static var storageKey = "io.curity.dcrclient"
    
    /*
     * Load any existing state
     */
    static func load() {

        // During development you can force a new registration by deleting existing settings
        // ApplicationStateManager.deleteRegistration()
        
        self.authState = OIDAuthState(authorizationResponse: nil, tokenResponse: nil, registrationResponse: nil)
        self.idToken = KeychainWrapper.standard.string(forKey: self.storageKey + ".idtoken")
        
        let data = KeychainWrapper.standard.data(forKey: self.storageKey + ".registration")
        if data != nil {

            do {

                let registrationResponse = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data!) as? OIDRegistrationResponse
                if registrationResponse != nil {
                    self.authState!.update(with: registrationResponse)
                }
            } catch {
                Logger.error(data: "Problem encountered loading application state: \(error)")
            }
        }
    }
    
    /*
     * The code example saves the id token so that logout works after a restart
     */
    static func saveTokens(tokenResponse: OIDTokenResponse) {
        
        self.authState?.update(with: tokenResponse, error: nil)
        if tokenResponse.idToken != nil {
            self.idToken = tokenResponse.idToken
            KeychainWrapper.standard.set(idToken!, forKey: self.storageKey + ".idtoken")
        }
    }
    
    /*
     * Registration data must be saved across application restarts
     */
    static func saveRegistration(registrationResponse: OIDRegistrationResponse) {
        
        do {
            self.authState!.update(with: registrationResponse)
            let data = try NSKeyedArchiver.archivedData(withRootObject: registrationResponse, requiringSecureCoding: false)
            KeychainWrapper.standard.set(data, forKey: self.storageKey + ".registration")

        } catch {
            Logger.error(data: "Problem encountered saving application state: \(error)")
        }
    }
    
    /*
     * Clear tokens after logout or when the session expires
     */
    static func clearTokens() {
        
        let lastRegistrationResponse = self.authState!.lastRegistrationResponse
        self.authState = OIDAuthState(authorizationResponse: nil, tokenResponse: nil, registrationResponse: nil)
        self.authState!.update(with: lastRegistrationResponse)
        self.idToken = nil
        KeychainWrapper.standard.removeObject(forKey: self.storageKey + ".idtoken")
    }
    
    static func deleteRegistration() {
        
        self.authState = OIDAuthState(authorizationResponse: nil, tokenResponse: nil, registrationResponse: nil)
        KeychainWrapper.standard.removeObject(forKey: self.storageKey + ".registration")
    }

    static var metadata: OIDServiceConfiguration? {
        get {
            return self.metadataValue
        }
        set(value) {
            self.metadataValue = value
        }
    }
    
    static var registrationResponse: OIDRegistrationResponse? {
        get {
            return self.authState?.lastRegistrationResponse
        }
    }
    
    static var tokenResponse: OIDTokenResponse? {
        get {
            return self.authState!.lastTokenResponse
        }
    }
}
