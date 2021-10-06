# AppAuth with Dynamic Client Registration

An extended AppAuth sample using Dynamic Client Registration, in line with [Mobile Best Practices](https://curity.io/resources/learn/oauth-for-mobile-apps-best-practices/).

## Walkthrough

The [Mobile Authenticated DCR Code Example](https://curity.io/resources/learn/resources/appauth-dcr) article explains the complete configuration and behavior.

## Prerequisites

First copy a `license.json` file for the Curity Identity Server into the `idsvr` folder.

## Quick Start

Deploy the Curity Identity Server with preconfigured settings:

```bash
./deploy.sh
```

- Open the `ios-app` folder in XCode 12.5 or later and run the app on a simulator or device.
- Open the `android-app` folder in Android 4.2 or later and run the app on an emulator or device.

## User Experience

When the user first runs the app they are prompted to register, which requires authentication.\
This gets an access token with the DCR scope, after which registration request is sent.

![images](/images/registration-view.png)

The user must then authenticate again, and this is automatic via Single Sign On.\
On all subsequent authentication requests the user only sees this screen:

![images](/images/unauthenticated-view.png)

Once authenticated the user is moved to the authenticated view.\
The demo app simply allows other lifecycle events to be tested from here.

![images](/images/authenticated-view.png)

## More Information

Please visit [curity.io](https://curity.io/) for more information about the Curity Identity Server.
