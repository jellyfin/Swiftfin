# TestFlight Action

Use this guide to configure the required secrets for the TestFlight action.

> [!IMPORTANT]
> A common cause of errors is erroneous new and empty lines in the base 64 encoded values and then again when they are put into GitHub Secrets. Try to strip strings whenever possible.

## App Store Connect API Key

Follow Apple’s guide to create an API Key: [Creating API keys for App Store Connect API](https://developer.apple.com/documentation/appstoreconnectapi/creating_api_keys_for_app_store_connect_api)

Add these secrets:

- `APP_STORE_ISSUER_ID`: Issuer ID (plain text)
- `APP_STORE_KEY_ID`: Key ID (plain text)
- `APP_STORE_KEY_CONTENTS`: contents of the downloaded `.p8` key file (plain text)

## Certificate and Provisioning Profile

> [!IMPORTANT]
> Assumes that the same certificate is used for the provisioning profiles of all platforms.

Follow GitHub’s guide to get the signing certificate: [Installing an Apple certificate on macOS runners](https://docs.github.com/en/actions/use-cases-and-examples/deploying/installing-an-apple-certificate-on-macos-runners-for-xcode-development)

Add these secrets:

- `BUILD_CERTIFICATE_BASE64`: base64 of the `.p12` certificate file
- `P12_PASSWORD`: password used when exporting the `.p12`
- `CODE_SIGN_BASE64`: base64 of the certificate identity string  
  - Example: `Apple Distribution Firstname Lastname (ABCD123456)`
- `BUILD_PROVISION_PROFILE_IOS_BASE64`: base64 of the iOS `.mobileprovision`
- `BUILD_PROVISION_PROFILE_TVOS_BASE64`: base64 of the tvOS `.mobileprovision`
- `PROFILE_NAME_IOS_BASE64`: base64 of the iOS provisioning profile name
- `PROFILE_NAME_TVOS_BASE64`: base64 of the tvOS provisioning profile name

## Required secrets checklist

- `APP_STORE_ISSUER_ID`
- `APP_STORE_KEY_ID`
- `APP_STORE_KEY_CONTENTS`
- `BUILD_CERTIFICATE_BASE64`
- `P12_PASSWORD`
- `CODE_SIGN_BASE64`
- `BUILD_PROVISION_PROFILE_IOS_BASE64`
- `BUILD_PROVISION_PROFILE_TVOS_BASE64`
- `PROFILE_NAME_IOS_BASE64`
- `PROFILE_NAME_TVOS_BASE64`

### Debugging

Debug the deployment action through repository dispatch by having payload keys match the expected secret values.
