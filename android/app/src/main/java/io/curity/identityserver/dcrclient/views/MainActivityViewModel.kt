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

package io.curity.identityserver.dcrclient.views

import android.content.Context
import androidx.lifecycle.ViewModel
import io.curity.identityserver.dcrclient.AppAuthHandler
import io.curity.identityserver.dcrclient.ApplicationStateManager
import io.curity.identityserver.dcrclient.configuration.ApplicationConfig
import io.curity.identityserver.dcrclient.configuration.ApplicationConfigLoader
import java.lang.ref.WeakReference

class MainActivityViewModel() : ViewModel() {

    lateinit var context: WeakReference<Context>
    lateinit var config: ApplicationConfig
    lateinit var state: ApplicationStateManager
    lateinit var appauth: AppAuthHandler

    fun initialize(activity: WeakReference<Context>) {
        this.context = activity
        this.config = ApplicationConfigLoader().load(this.context.get()!!)
        this.state = ApplicationStateManager(context)
        this.appauth = AppAuthHandler(this.config, this.context.get()!!)
    }

    fun isRegistered(): Boolean {
        return this.state.registrationResponse != null;
    }

    fun dispose() {
        this.appauth.dispose()
    }
}