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

import android.os.Bundle
import androidx.activity.viewModels
import androidx.appcompat.app.AppCompatActivity
import androidx.databinding.DataBindingUtil
import androidx.navigation.fragment.NavHostFragment
import io.curity.identityserver.dcrclient.ApplicationStateManager
import io.curity.identityserver.dcrclient.R
import io.curity.identityserver.dcrclient.databinding.ActivityMainBinding
import java.lang.ref.WeakReference

class MainActivity : AppCompatActivity() {

    private lateinit var binding: ActivityMainBinding

    override fun onCreate(savedInstanceState: Bundle?) {

        super.onCreate(savedInstanceState)

        val model: MainActivityViewModel by viewModels()
        model.initialize(WeakReference(this))

        this.binding = DataBindingUtil.setContentView(this, R.layout.activity_main)
        this.binding.model = model

        this.moveToInitialView();
    }

    fun onRegisteredNavigate() {
        val navHostFragment = supportFragmentManager.findFragmentById(R.id.nav_host_fragment) as NavHostFragment
        navHostFragment.navController.navigate(R.id.fragment_unauthenticated)
    }

    fun onLoggedInNavigate() {
        val navHostFragment = supportFragmentManager.findFragmentById(R.id.nav_host_fragment) as NavHostFragment
        navHostFragment.navController.navigate(R.id.fragment_authenticated)
    }

    fun onLoggedOutNavigate() {
        val navHostFragment = supportFragmentManager.findFragmentById(R.id.nav_host_fragment) as NavHostFragment
        navHostFragment.navController.navigate(R.id.fragment_unauthenticated)
    }

    private fun moveToInitialView() {

        val navHostFragment = supportFragmentManager.findFragmentById(R.id.nav_host_fragment) as NavHostFragment
        if (this.binding.model!!.isRegistered()) {
            navHostFragment.navController.navigate(R.id.fragment_registration)
        } else {
            navHostFragment.navController.navigate(R.id.fragment_unauthenticated)
        }
    }

    override fun onDestroy() {
        this.binding.model!!.dispose()
        super.onDestroy()
    }
}
