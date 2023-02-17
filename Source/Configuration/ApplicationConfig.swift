//
//  ApplicationConfig.swift
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

struct ApplicationConfig: Decodable {

    let issuer: String
    let registrationClientID: String
    let redirectUri: String
    let postLogoutRedirectUri: String
    let scope: String
    
    init() {
        self.issuer = ""
        self.registrationClientID = ""
        self.redirectUri = ""
        self.postLogoutRedirectUri = ""
        self.scope = ""
    }

    func getIssuerUri() throws -> URL {
        
        guard let url = URL(string: self.issuer) else {

            throw ApplicationError(title: "Invalid Configuration Error", description: "The issuer URI could not be parsed")
        }
        
        return url
    }

    func getRedirectUri() throws -> URL {
        
        guard let url = URL(string: self.redirectUri) else {

            throw ApplicationError(title: "Invalid Configuration Error", description: "The redirect URI could not be parsed")
        }
        
        return url
    }
    
    func getPostLogoutRedirectUri() throws -> URL {
        
        guard let url = URL(string: self.postLogoutRedirectUri) else {

            throw ApplicationError(title: "Invalid Configuration Error", description: "The post logout redirect URI could not be parsed")
        }
        
        return url
    }
}
