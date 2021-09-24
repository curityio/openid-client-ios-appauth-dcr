#!/bin/bash

###############################################################################################
# A script to run dynamic client registration manually with the access token from the code flow
###############################################################################################

# First run an OAuth tools code flow for the dcr mobile app client to get an access token
DCR_ACCESS_TOKEN="25dd1e0a-9cc3-415f-8302-8d6c8fb105e5"

This required these parameters:

- registration_client_id: mobile_dcr_client
- scope: dcr
- redirect URI: https://oauth.tools/callback/code

# Then post data to create a row
DCR_URL=https://600c9eacfeac.eu.ngrok.io/token-service/oauth-registration
DATA="{\"redirect_uris\":[\"io.curity.dcrclient:\/callback\"],\"post_logout_redirect_uris\":[\"io.curity.dcrclient:\/logoutcallback\"],\"application_type\":\"native\",\"grant_types\":[\"authorization_code\"], \"scope\":\"openid profile\"}"

curl -i -X POST $DCR_URL \
-H 'content-type: application/json' \
-H 'accept: application/json' \
-H "Authorization: Bearer $DCR_ACCESS_TOKEN" \
-d "$DATA"

# Then get a response like this
{
    "refresh_token_max_rolling_lifetime":3600,
    "default_acr_values":["urn:se:curity:authentication:html-form:Username-Password"],
    "application_type":"native",
    "client_id":"2b47abb4-7e4d-4af0-acf8-5303497bd3bb",
    "token_endpoint_auth_method":
    "client_secret_basic",
    "scope":"openid profile",
    "client_id_issued_at":1632499175,
    "client_secret":"W-PnTC0mdZq2NLI4nzys7u0PBnMBN8txPAXzGxZhpZI",
    "id_token_signed_response_alg":
    "RS256","post_logout_redirect_uris":["io.curity.dcrclient:/logoutcallback"],
    "grant_types":["authorization_code","refresh_token"],
    "subject_type":"public",
    "redirect_uris":["io.curity.dcrclient:/callback"],
    "client_secret_expires_at":0,
    "token_endpoint_auth_methods":["client_secret_basic","client_secret_post"],
    "response_types":["code","id_token"],
    "refresh_token_ttl":3600
}

# Then query the data saved by remoting to the postgres container
export PGPASSWORD=Password1 && psql -p 5432 -d idsvr -U postgres
select * from dynamically_registered_clients;
