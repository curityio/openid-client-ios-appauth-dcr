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

class AppAuthHandler {
    
    private let config: ApplicationConfig
    private var userAgentSession: OIDExternalUserAgentSession?
    private var loginResponseHandler: LoginResponseHandler?
    private var logoutResponseHandler: LogoutResponseHandler?
    
    init(config: ApplicationConfig) {
        self.config = config
        self.userAgentSession = nil
    }
    
    /*
     * Get OpenID Connect endpoints and ensure that dynamic client registration is configured
     */
    func fetchMetadata() async throws -> OIDServiceConfiguration {
        
        let issuerUrl = try self.config.getIssuerUri()

        return try await withCheckedThrowingContinuation { continuation in
            
            OIDAuthorizationService.discoverConfiguration(forIssuer: issuerUrl) { metadata, ex in
                
                if metadata != nil {
                    
                    if (metadata!.registrationEndpoint == nil) {
                        
                        let configurationError = ApplicationError(
                            title: "Invalid Configuration Error",
                            description: "No registration endpoint is configured in the Identity Server"
                        )
                        continuation.resume(throwing: configurationError)

                    } else {
                        
                        Logger.info(data: "Metadata retrieved successfully")
                        continuation.resume(returning: metadata!)
                    }
                    
                } else {
                    
                    let error = self.createAuthorizationError(title: "Metadata Download Error", ex: ex)
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /*
     * Trigger a redirect with standard parameters
     * acr_values can be sent as an extra parameter, to control authentication methods
     */
    func performAuthorizationRedirect(
        metadata: OIDServiceConfiguration,
        clientID: String,
        scope: String,
        viewController: UIViewController,
        force: Bool) throws {
        
        let redirectUri = try self.config.getRedirectUri()

        // Use acr_values to select a particular authentication method at runtime
        var extraParams = [String: String]()
        // extraParams["acr_values"] = "urn:se:curity:authentication:html-form:Username-Password"
        if force {
            extraParams["prompt"] = "login"
        }

        let scopesArray = scope.components(separatedBy: " ")
        let request = OIDAuthorizationRequest(
            configuration: metadata,
            clientId: clientID,
            clientSecret: nil,
            scopes: scopesArray,
            redirectURL: redirectUri,
            responseType: OIDResponseTypeCode,
            additionalParameters: extraParams)
            
        let userAgent = OIDExternalUserAgentIOS(presenting: viewController)
        self.loginResponseHandler = LoginResponseHandler()
        self.userAgentSession = OIDAuthorizationService.present(
            request,
            externalUserAgent: userAgent!,
            callback: self.loginResponseHandler!.callback)
    }
    
    /*
     * Finish processing, which occurs on a worker thread
     */
    func handleAuthorizationResponse() async throws -> OIDAuthorizationResponse? {
        
        do {
            
            let response = try await self.loginResponseHandler!.waitForCallback()
            self.loginResponseHandler = nil
            return response

        } catch {
            
            self.loginResponseHandler = nil
            if (self.isUserCancellationErrorCode(ex: error)) {
                return nil
            }
            
            throw self.createAuthorizationError(title: "Authorization Request Error", ex: error)
        }
    }
    
    /*
     * Handle the authorization response, including the user closing the Chrome Custom Tab
     */
    func redeemCodeForTokens(
        clientSecret: String?,
        authResponse: OIDAuthorizationResponse) async throws -> OIDTokenResponse {

        try await withCheckedThrowingContinuation { continuation in
            
            var extraParams = [String: String]()
            if clientSecret != nil {
                extraParams["client_secret"] = clientSecret
            }
            let request = authResponse.tokenExchangeRequest(withAdditionalParameters: extraParams)
            
            OIDAuthorizationService.perform(
                request!,
                originalAuthorizationResponse: authResponse) { tokenResponse, ex in
                    
                if tokenResponse != nil {
                    
                    Logger.info(data: "Authorization code grant response received successfully")
                    continuation.resume(returning: tokenResponse!)
                    
                } else {
                    
                    let error = self.createAuthorizationError(title: "Authorization Response Error", ex: ex)
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /*
     * Perform dynamic client registration and then store the response
     */
    func registerClient(metadata: OIDServiceConfiguration, accessToken: String) async throws -> OIDRegistrationResponse {
        
        let redirectUri = try self.config.getRedirectUri()
        
        var extraParams = [String: String]()
        extraParams["scope"] = self.config.scope
        extraParams["requires_consent"] = "false"
        extraParams["post_logout_redirect_uris"] = self.config.postLogoutRedirectUri

        let nonTemplatizedRequest = OIDRegistrationRequest(
            configuration: metadata,
            redirectURIs: [redirectUri],
            responseTypes: nil,
            grantTypes: [OIDGrantTypeAuthorizationCode],
            subjectType: nil,
            tokenEndpointAuthMethod: "client_secret_basic",
            initialAccessToken: accessToken,
            additionalParameters: extraParams)
        
        return try await withCheckedThrowingContinuation { continuation in
            
            OIDAuthorizationService.perform(nonTemplatizedRequest) { response, ex in
                
                if response != nil {
                    
                    let registrationResponse = response!
                    let clientSecret = registrationResponse.clientSecret == nil ? "" : registrationResponse.clientSecret!
                    Logger.info(data: "Registration data retrieved successfully")
                    Logger.debug(data: "Created dynamic client: ID: \(registrationResponse.clientID), Secret: \(clientSecret)")
                    continuation.resume(returning: registrationResponse)
                    
                } else {
                    
                    let error = self.createAuthorizationError(title: "Registration Error", ex: ex)
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /*
     * Try to refresh an access token and return null when the refresh token expires
     */
    func refreshAccessToken(
            metadata: OIDServiceConfiguration,
            clientID: String,
            clientSecret: String,
            refreshToken: String) async throws -> OIDTokenResponse? {
        
        let request = OIDTokenRequest(
            configuration: metadata,
            grantType: OIDGrantTypeRefreshToken,
            authorizationCode: nil,
            redirectURL: nil,
            clientID: clientID,
            clientSecret: clientSecret,
            scope: nil,
            refreshToken: refreshToken,
            codeVerifier: nil,
            additionalParameters: nil)
        
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<OIDTokenResponse?, Error>) -> Void in
            
            OIDAuthorizationService.perform(request) { tokenResponse, ex in
                
                if tokenResponse != nil {
                    
                    Logger.info(data: "Refresh token code grant response received successfully")
                    continuation.resume(returning: tokenResponse!)
                    
                } else {
                    
                    if ex != nil && self.isRefreshTokenExpiredErrorCode(ex: ex!) {
                        
                        Logger.info(data: "Refresh token expired and the user must re-authenticate")
                        continuation.resume(returning: nil)
                        
                    } else {
                        
                        let error = self.createAuthorizationError(title: "Refresh Token Error", ex: ex)
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }

    /*
     * Do an OpenID Connect end session redirect and remove the SSO cookie
     */
    func performEndSessionRedirect(metadata: OIDServiceConfiguration,
                                   idToken: String,
                                   viewController: UIViewController) throws {
        
        let extraParams = [String: String]()
        let postLogoutRedirectUri = try self.config.getPostLogoutRedirectUri()

        let request = OIDEndSessionRequest(
            configuration: metadata,
            idTokenHint: idToken,
            postLogoutRedirectURL: postLogoutRedirectUri,
            additionalParameters: extraParams)

        let userAgent = OIDExternalUserAgentIOS(presenting: viewController)
        self.logoutResponseHandler = LogoutResponseHandler()
        self.userAgentSession = OIDAuthorizationService.present(
            request,
            externalUserAgent: userAgent!,
            callback: self.logoutResponseHandler!.callback)
    }

    /*
     * Finish processing, which occurs on a worker thread
     */
    func handleEndSessionResponse() async throws -> OIDEndSessionResponse? {
        
        do {
            
            let response = try await self.logoutResponseHandler!.waitForCallback()
            self.logoutResponseHandler = nil
            return response

        } catch {
            
            self.logoutResponseHandler = nil
            if (self.isUserCancellationErrorCode(ex: error)) {
                return nil
            }
            
            throw self.createAuthorizationError(title: "Logout Request Error", ex: error)
        }
    }

    /*
     * We can check for specific error codes to handle the user cancelling the ASWebAuthenticationSession window
     */
    private func isUserCancellationErrorCode(ex: Error) -> Bool {

        let error = ex as NSError
        return error.domain == OIDGeneralErrorDomain && error.code == OIDErrorCode.userCanceledAuthorizationFlow.rawValue
    }
    
    /*
     * We can check for a specific error code when the refresh token expires and the user needs to re-authenticate
     */
    private func isRefreshTokenExpiredErrorCode(ex: Error) -> Bool {

        let error = ex as NSError
        return error.domain == OIDOAuthTokenErrorDomain && error.code == OIDErrorCodeOAuth.invalidGrant.rawValue
    }

    /*
     * Process standard OAuth error / error_description fields and also AppAuth error identifiers
     */
    private func createAuthorizationError(title: String, ex: Error?) -> ApplicationError {
        
        var parts = [String]()
        if (ex == nil) {

            parts.append("Unknown Error")

        } else {

            let nsError = ex! as NSError
            
            if nsError.domain.contains("org.openid.appauth") {
                parts.append("(\(nsError.domain) / \(String(nsError.code)))")
            }

            if !ex!.localizedDescription.isEmpty {
                parts.append(ex!.localizedDescription)
            }
        }

        let fullDescription = parts.joined(separator: " : ")
        let error = ApplicationError(title: title, description: fullDescription)
        Logger.error(data: "\(error.title) : \(error.description)")
        return error
    }
}
