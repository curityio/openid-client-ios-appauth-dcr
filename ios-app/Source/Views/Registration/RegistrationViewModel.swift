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

class RegistrationViewModel: ObservableObject {

    private var appauth: AppAuthHandler?
    private var onRegistered: (() -> Void)?

    @Published var error: ApplicationError?
    
    init(appauth: AppAuthHandler, onRegistered: @escaping () -> Void) {

        self.appauth = appauth
        self.onRegistered = onRegistered
        self.error = nil
    }

    /*
     * Startup handling to lookup metadata
     * Make HTTP requests on a worker thread and then perform updates on the UI thread
     */
    func startRegistration() {
        
        DispatchQueue.main.startCoroutine {
            
            do {

                self.error = nil
                var metadata = ApplicationStateManager.metadata

                try DispatchQueue.global().await {
                    
                    if metadata == nil {
                        metadata = try self.appauth!.fetchMetadata().await()
                    }
                }
                
                ApplicationStateManager.metadata = metadata
                
            } catch {
                
                let appError = error as? ApplicationError
                if appError != nil {
                    self.error = appError!
                }
            }
        }
    }
}

