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
import java.lang.ref.WeakReference
import net.openid.appauth.AuthState
import net.openid.appauth.AuthorizationServiceConfiguration
import net.openid.appauth.RegistrationResponse
import net.openid.appauth.TokenResponse

/*
 * Wraps the AuthState class from the AppAuth library
 * Some or all of the auth state can be persisted to a secure location such as Encrypted Shared Preferences
 */
class ApplicationStateManager(private val context: WeakReference<Context>) {

    private var authState: AuthState? = null
    var idToken: String? = null

    /*
     * Load any existing state
     */
    init {

        // Delete the existing registration settings during development if required
        // deleteRegistration()

        val prefs = this.context.get()!!.getSharedPreferences("authState", MODE_PRIVATE)
        val registration = prefs.getString("registration", null)
        this.idToken = prefs.getString("idToken", null)

        if (registration != null) {
            val lastRegistrationResponse = RegistrationResponse.jsonDeserialize(registration)
            this.authState = AuthState(lastRegistrationResponse)
        }
    }

    /*
     * The code example saves the id token so that logout works after a restart
     */
    fun saveTokens(tokenResponse: TokenResponse) {

        this.authState!!.update(tokenResponse, null)
        if (tokenResponse.idToken != null) {

            this.idToken = tokenResponse.idToken
            val prefs = this.context.get()!!.getSharedPreferences("authState", MODE_PRIVATE)
            prefs.edit()
                .putString("idToken", this.idToken)
                .apply()
        }
    }

    /*
     * Clear tokens upon logout or when the session expires
     */
    fun clearTokens() {

        val metadata = this.authState?.authorizationServiceConfiguration
        val lastRegistrationResponse = this.authState?.lastRegistrationResponse
        this.authState = AuthState(metadata!!)
        this.authState!!.update(lastRegistrationResponse)
        this.idToken = null

        val prefs = this.context.get()!!.getSharedPreferences("authState", MODE_PRIVATE)
        prefs.edit()
            .remove("idToken")
            .apply()
    }

    /*
     * Registration data must be saved across application restarts
     */
    fun saveRegistration(registrationResponse: RegistrationResponse) {

        this.authState?.update(registrationResponse)
        val prefs = this.context.get()!!.getSharedPreferences("authState", MODE_PRIVATE)
        prefs.edit()
            .putString("registration", this.authState!!.lastRegistrationResponse!!.jsonSerializeString())
            .apply()
    }

    private fun deleteRegistration() {

        val prefs = this.context.get()!!.getSharedPreferences("authState", MODE_PRIVATE)
        prefs.edit()
            .remove("registration")
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

    val registrationResponse: RegistrationResponse?
        get () {
            return this.authState?.lastRegistrationResponse
        }

    val tokenResponse: TokenResponse?
        get () {
            return this.authState?.lastTokenResponse
        }
}
