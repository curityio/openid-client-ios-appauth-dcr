/*
 *  Copyright 2021 Curity AB
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 */

package io.curity.identityserver.dcrclient

import android.content.Context
import android.content.Context.MODE_PRIVATE
import net.openid.appauth.AuthState
import net.openid.appauth.AuthorizationServiceConfiguration
import net.openid.appauth.RegistrationResponse
import net.openid.appauth.TokenResponse

/*
 * Wraps the AuthState class from the AppAuth library
 * Some or all of the auth state can be persisted to a secure location such as Encrypted Shared Preferences
 */
object ApplicationStateManager {

    private var authState: AuthState? = null
    var idToken: String? = null

    fun load(context: Context) {

        // Delete settings during development if required
        // delete(context)

        val prefs = context.getSharedPreferences("authState", MODE_PRIVATE)
        val registration = prefs.getString("registration", null)
        val idToken = prefs.getString("idToken", null)

        if (registration != null) {
            val lastRegistrationResponse = RegistrationResponse.jsonDeserialize(registration)
            this.authState = AuthState(lastRegistrationResponse)
        }

        if (idToken != null) {
            this.idToken = idToken
        }
    }

    fun save(context: Context) {

        if (this.authState?.lastRegistrationResponse != null) {

            val prefs = context.getSharedPreferences("authState", MODE_PRIVATE)
            prefs.edit()
                .putString("registration", this.authState!!.lastRegistrationResponse!!.jsonSerializeString())
                .apply()
        }

        if (this.idToken != null) {

            val prefs = context.getSharedPreferences("authState", MODE_PRIVATE)
            prefs.edit()
                .putString("idToken", this.idToken)
                .apply()
        }
    }

    fun delete(context: Context) {

        val prefs = context.getSharedPreferences("authState", MODE_PRIVATE)
        prefs.edit()
            .remove("registration")
            .remove("idToken")
            .apply()
    }

    var metadata: AuthorizationServiceConfiguration?
        get () {
            return this.authState?.authorizationServiceConfiguration
        }
        set (configuration) {

            val lastRegistrationResponse = this.authState?.lastRegistrationResponse
            this.authState = AuthState(configuration!!)
            if (lastRegistrationResponse != null) {
                this.authState!!.update(lastRegistrationResponse)
            }
        }

    var registrationResponse: RegistrationResponse?
        get () {
            return this.authState?.lastRegistrationResponse
        }
        set (registrationResponse) {
            this.authState?.update(registrationResponse)
        }

    var tokenResponse: TokenResponse?
        get () {
            return this.authState?.lastTokenResponse
        }
        set(tokenResponse) {

            this.authState!!.update(tokenResponse, null)
            if (tokenResponse?.idToken != null) {
                this.idToken = tokenResponse.idToken
            }
        }

    fun clearTokens() {
        val metadata = this.authState?.authorizationServiceConfiguration
        val lastRegistrationResponse = this.authState?.lastRegistrationResponse
        this.authState = AuthState(metadata!!)
        this.authState!!.update(lastRegistrationResponse)
        this.idToken = null
    }
}
