package io.curity.identityserver.client.utilities

import java.io.IOException
import java.util.concurrent.TimeUnit
import kotlin.coroutines.resumeWithException
import kotlin.coroutines.suspendCoroutine
import okhttp3.Call
import okhttp3.Callback
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import okhttp3.Response

class HttpHelper {

    /*
     * AppAuth does not currently support sending an access token in DCR requests so we do this manually
     */
    suspend fun postWithAccessToken(endpoint: String, requestData: String, accessToken: String): String {

        val client = OkHttpClient.Builder()
            .callTimeout(10, TimeUnit.SECONDS)
            .build()

        val body = requestData.toRequestBody("application/json".toMediaType())
        val builder = Request.Builder()
            .header("Accept", "application/json")
            .header("Authorization", "Bearer $accessToken")
            .method("POST", body)
            .url(endpoint)
        val request = builder.build()

        return suspendCoroutine { continuation ->

            client.newCall(request).enqueue(object : Callback {
                override fun onResponse(call: Call, response: Response) {

                    val responseData = response.body?.string()
                    continuation.resumeWith(Result.success(responseData!!))
                }

                override fun onFailure(call: Call, e: IOException) {

                    continuation.resumeWithException(e)
                }
            })
        }
    }
}