# SimpleKeychain

A simple Keychain wrapper for iOS, macOS, tvOS, and watchOS. Supports sharing
credentials with an access group or through iCloud, and integrating Touch ID /
Face ID.

https://github.com/auth0/SimpleKeychain

## Requirements

- iOS 14.0+ / macOS 11.0+ / tvOS 14.0+ / watchOS 7.0+
- Xcode 16.x
- Swift 6.0+

## Usage

```swift
let simpleKeychain = SimpleKeychain()
```

You can specify a service name under which to save items. By default the bundle
identifier of your app is used.

```swift
let simpleKeychain = SimpleKeychain(service: "Auth0")
```

### Store a string or data item

```swift
try simpleKeychain.set(accessToken, forKey: "auth0-access-token")
```

### Check if an item is stored

```swift
let isStored = try simpleKeychain.hasItem(forKey: "auth0-access-token")
```

### Retrieve a string item

```swift
let accessToken = try simpleKeychain.string(forKey: "auth0-access-token")
```

### Retrieve a data item

```swift
let accessToken = try simpleKeychain.data(forKey: "auth0-credentials")
```

### Retrieve the keys of all stored items

```swift
let keys = try simpleKeychain.keys()
```

### Remove an item

```swift
try simpleKeychain.deleteItem(forKey: "auth0-access-token")
```

### Remove all items

```swift
try simpleKeychain.deleteAll()
```

### Error handling

All methods will throw a `SimpleKeychainError` upon failure.

```swift
catch let error as SimpleKeychainError {
    print(error)
}
```

## Examples

### Use a custom service name

When creating the SimpleKeychain instance, specify a service name under which to
save items. By default the bundle identifier of your app is used.

```swift
let simpleKeychain = SimpleKeychain(service: "Auth0")
```

### Include additional attributes

When creating the SimpleKeychain instance, specify additional attributes to be
included in every query.

```swift
let attributes = [kSecUseDataProtectionKeychain as String: true]
let simpleKeychain = SimpleKeychain(attributes: attributes)
```

### Share items with other apps and extensions using an access group

When creating the SimpleKeychain instance, specify the access group that the app
may share entries with.

```swift
let simpleKeychain = SimpleKeychain(accessGroup: "ABCDEFGH.com.example.myaccessgroup")
```

> [!NOTE]
> For more information on access group sharing, see
> [Sharing Access to Keychain Items Among a Collection of Apps](https://developer.apple.com/documentation/security/keychain_services/keychain_items/sharing_access_to_keychain_items_among_a_collection_of_apps).

### Share items with other devices through iCloud synchronization

When creating the SimpleKeychain instance, set `synchronizable` to `true` to
enable iCloud synchronization.

```swift
let simpleKeychain = SimpleKeychain(sychronizable: true)
```

> [!NOTE]
> For more information on iCloud synchronization, check the
> [kSecAttrSynchronizable documentation](https://developer.apple.com/documentation/security/ksecattrsynchronizable).

### Restrict item accessibility based on device state

When creating the SimpleKeychain instance, specify a custom accesibility value
to be used. The default value is `.afterFirstUnlock`.

```swift
let simpleKeychain = SimpleKeychain(accessibility: .whenUnlocked)
```

> [!NOTE]
> For more information on accessibility, see
> [Restricting Keychain Item Accessibility](https://developer.apple.com/documentation/security/keychain_services/keychain_items/restricting_keychain_item_accessibility).

### Require Touch ID / Face ID to retrieve an item

When creating the SimpleKeychain instance, specify the access control flags to
be used. You can also include an `LAContext` instance with your Touch ID / Face
ID configuration.

```swift
let context = LAContext()
context.touchIDAuthenticationAllowableReuseDuration = 10
let simpleKeychain = SimpleKeychain(accessControlFlags: .biometryCurrentSet, context: context)
```

> [!NOTE]
> For more information on access control, see
> [Restricting Keychain Item Accessibility](https://developer.apple.com/documentation/security/keychain_services/keychain_items/restricting_keychain_item_accessibility).
