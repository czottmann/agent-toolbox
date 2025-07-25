# SharedBasics

A package providing recurring code snippets and extensions for my personal
projects. The single files relate to exported modules, e.g.
`File: /docs/AppDetails/*` describes the `AppDetails` module,
`File: /docs/AppIntentsHelpers/*` describes `AppIntentsHelpers`, etc.

## Files

## Module `AppDetails`

```swift
import Foundation
import SwiftUI

/// Holds information about the current build.
public enum AppDetails {
  /// The bundle identifier of the app, e.g. "com.example.app"
  public static let idString: String

  /// The display name of the app as defined in the bundle
  public static let name: String

  /// The marketing version of the app (CFBundleShortVersionString), e.g. "1.0.0"
  public static let version: String

  /// The build number of the app (CFBundleVersion), e.g. "42"
  public static let build: String

  /// Combined version and build number string, e.g. "1.0.0 (42)"
  public static let versionWithBuild: String

  /// Full app details string including bundle ID, version/build and process ID
  public static let details: String

  /// The creation date of the app bundle, determined from either Info.plist or the executable
  /// - Returns: The build date if it can be determined from Info.plist or executable creation date, otherwise returns current date
  public static let buildDate: Date

  /// Whether or not the current build is running in Xcode's preview mode.
  public static let isPreviewBuild: Bool
}
```

## Module `AppIntentsHelpers`

````swift
import AppIntents
import Foundation

// MARK: - DoubleAppEnum

/// Represents an `AppEnum` which adds a `doubleValue` value to the `enum`. Must be used together
/// with `String`, i.e. `enum Whatever: String, DoubleAppEnum {}`.
///
/// `AppEnum` of any type other than `String` is broken in iOS 17.4+ and macOS 14.4+, so this is a
/// workaround because `enum Whatever: String, AppEnum {}` is the only thing that's reliable.
/// For this method to work, each `case` value must contain the string representation of the actual
/// value, e.g. `case onePointTwo = "1.2"` for a `1.2` double.
///
/// ```swift
/// // Broken, the related intent `@Parameter` will always be empty
/// enum Whatever: Double, AppEnum {…}
///
/// // Works
/// enum Whatever: String, AppEnum {…}
/// ```
public protocol DoubleAppEnum: AppEnum, RawRepresentable where RawValue == String {}

public extension DoubleAppEnum {
  /// Parses and returns the raw string value as `Double`. If that fails, it returns 0.0.
  var doubleValue: Double { get }
}
````

## Module `AppIntentsHelpers`

````swift
import AppIntents
import Foundation

// MARK: - IntAppEnum

/// Represents an `AppEnum` which adds an `intValue` value to the `enum`. Must be used together
/// with `String`, i.e. `enum Whatever: String, IntAppEnum {}`.
///
/// `AppEnum` of any type other than `String` is broken in iOS 17.4+ and macOS 14.4+, so this is a
/// workaround because `enum Whatever: String, AppEnum {}` is the only thing that's reliable.
/// For this method to work, each `case` value must contain the string representation of the actual
/// value, e.g. `case one = "1"` for a `1` integer.
///
/// ```swift
/// // Broken, the related intent `@Parameter` will always be empty
/// enum Whatever: Int, AppEnum {…}
///
/// // Works
/// enum Whatever: String, AppEnum {…}
/// ```
public protocol IntAppEnum: AppEnum, RawRepresentable where RawValue == String {}

public extension IntAppEnum {
  /// Parses and returns the raw string value as `Int`. If that fails, it returns 0.
  var intValue: Int { get }
}
````

## Module `AppUpdating`

```swift
import Foundation
import Licensing
import Logging
import Sparkle
import SwiftUI
import TaskExtensions

/// Sets up the Sparkle updater, and starts it. The appcast URL is taken directly from the bundle.
/// Also publishes vars to allow the app to react to available updates coming from the appcast.
///
/// ## Publishes
///   - `isAppUpdateAvailable`
///   - `isLicenseGatedAppUpdateAvailable`
@StaticLogger
public final class AppUpdateManager: NSObject, SPUUpdaterDelegate, SPUStandardUserDriverDelegate, ObservableObject {
  public private(set) static var shared: AppUpdateManager!

  /// This becomes `true` when there is an available update to the app.
  @Published public private(set) var isAppUpdateAvailable: Bool

  /// Becomes `true` when there is an available update to the app that is not available to the
  /// customer with their current license.
  @Published public private(set) var isLicenseGatedAppUpdateAvailable: Bool

  /// Sets up the Sparkle updater, and starts it. The appcast URL is taken directly from the bundle.
  ///
  /// - Parameters:
  ///   - licenseValidator: The shared `LicenseValidator` instance, used to figure out the best
  ///     update available for the currently active license.
  public init(licenseValidator: LicenseValidator)

  /// Checks for updates manually.
  ///
  /// - Parameter sender: The object that initiated the check.
  @objc
  public func checkForUpdates(_ sender: Any?)

  /// The allowed list of system profile keys to be appended to the appcast URL's query string.
  public func allowedSystemProfileKeys(for updater: SPUUpdater) -> [String]?

  /// Returns the item in the appcast corresponding to the update that should be installed.
  ///
  /// The item is selected with the current license's expiry date in mind. The method will pick the
  /// most recent update available to that particular license, or the most recent update, period, if
  /// there is no license.
  ///
  /// If there are newer updates which aren't available to that license, i.e. newer than the license
  /// expiry date, then `self.isLicensePreventingUpdates` will be set to `true`.
  public func bestValidUpdate(in appcast: SUAppcast, for updater: SPUUpdater) -> SUAppcastItem?

  public func updater(_ updater: SPUUpdater, didFindValidUpdate item: SUAppcastItem)
}
```

## Module `ArrayExtensions`

```swift
import Foundation

public extension Array {
  /// Returns true if the array contains at least one element
  /// - Returns: The inverse of `isEmpty`
  var isNotEmpty: Bool { get }
}
```

## Module `ArrayExtensions`

```swift
public extension Array where Element: Equatable {
  /// Merges the current array with another array, replacing matching elements.
  ///
  /// This method creates a new array by iterating through the current array and replacing any
  /// elements that match (by equality) with their counterparts from the provided array. Elements
  /// that don't have a match in the provided array remain unchanged.
  ///
  /// Think of `self` as a list of defaults, and `otherList` as the values that may overwrite the
  /// defaults.
  ///
  /// - Parameter otherList: The array to merge with the current array.
  /// - Returns: A new array containing elements from the current array, with matching elements
  ///            replaced by those from `otherList`.
  ///
  /// - Complexity: O(n * m), where n is the length of the current array
  ///               and m is the length of `otherList`.
  func mergeReplacingMatches(with otherList: [Element]) -> [Element]

  /// Returns a Boolean value indicating whether `self` contains all the elements from another array.
  ///
  /// - Parameter otherArray: The array to check for containment.
  /// - Returns: `true` if the array contains all the elements from `otherArray`, otherwise `false`.
  func containsAll(_ otherArray: [Element]) -> Bool
}
```

## Module `ArrayExtensions`

```swift
public extension Array where Element: Hashable {
  /// Returns a new Array containing those elements from `self` that are not duplicates, the first
  /// occurrence always being retained.
  /// - Returns: A new array with duplicate elements removed, preserving the original order
  /// - Complexity: O(n) where n is the length of the array
  /// - Note: Uses a Set internally to track unique elements, so the Element type must conform to Hashable
  func uniq() -> [Element]
}
```

## Module `ArrayExtensions`

```swift
import Foundation

public extension [String] {
  /// Joins all strings in the array using newline characters as separators
  /// - Returns: A single string with all elements concatenated, separated by newlines
  /// - Complexity: O(n) where n is the total length of all strings
  func joinedByNewlines() -> String

  /// Concatenates the entire list into a string, then splits that by `\n` (while preserving the
  /// line breaks), and returns the new list.
  /// - Returns: A new array of strings, where each element represents a line (including the newline character)
  /// - Note: Uses regular expressions to match lines while preserving line endings
  /// - Complexity: O(n) where n is the total length of all strings
  /// - Important: Returns an empty array if the regex pattern compilation fails
  func rebuiltByNewlines() -> [String]
}
```

## Module `BoolExtensions`

```swift
import Foundation
import SwiftUI

public extension Bool {
  /// Returns the current value as static `Binding<Bool>`.
  var toBinding: Binding<Bool> { get }
}
```

## Module `CodableExtensions`

```swift
import Foundation
import Logging

public extension Encodable {
  /// Converts the Encodable object to a JSON string representation
  /// - Parameter encoder: Optional `JSONEncoder` instance (as reusing an instance might help with
  ///   optimizing performance and memory management)
  /// - Parameter outputFormatting: Optional JSON formatting options (e.g., .prettyPrinted, .sortedKeys)
  /// - Returns: A JSON string representation of the object, or nil if encoding fails
  /// - Note: Uses UTF-8 encoding for the resulting string
  /// - Important: Prints encoding errors to the console and returns nil on failure
  func toJSON(encoder: JSONEncoder = JSONEncoder(),
              outputFormatting: JSONEncoder.OutputFormatting? = nil)
    -> String?
}
```

## Module `ComparableExtensions`

```swift
import Foundation

public extension Comparable {
  /// Clamps the value to a given range.
  ///
  /// - Parameter limits: The range to clamp the value to.
  /// - Returns: The clamped value.
  func clamped(to limits: ClosedRange<Self>) -> Self
}
```

## Module `CustomProtocols`

```swift
/// A protocol for types that require a one-time setup.
public protocol StaticSetupable {
  /// Performs the one-time setup.
  static func setup()
}

public extension StaticSetupable {
  /// The default implementation of `setup()`, which triggers a `fatalError` to ensure that conforming
  /// types implement their own setup logic.
  static func setup()
}
```

## Module `CustomViews`

```swift
import SwiftUI

public struct GoldSymbolInLaurels: View {
  // MARK: - Properties

  public let systemName: String
  public let label: String

  // MARK: - Lifecycle

  public init(systemName: String, label: String)

  // MARK: - Content Properties

  public var body: some View { get }
}
```

## Module `CustomViews`

```swift
import AppDetails
import SwiftUI

/// A custom `Link` which appends a `ref` parameter containing the app's bundle ID.
public struct RefLink: View {
  /// Creates a new `RefLink` view.
  ///
  /// - Parameters:
  ///   - title: The title of the link.
  ///   - url: The URL to link to.
  public init(_ title: LocalizedStringKey, url: String)

  public var body: some View
}
```

## Module `CustomViews`

```swift
import SwiftUI

/// A container view that wraps content in a labeled section with an orange hue,
/// intended for UI elements that should only be visible in development builds.
public struct ShowInDebugOnly<Content: View>: View {
  /// The content to be displayed only in debug builds.
  public let content: Content

  /// Creates a new `ShowInDebugOnly` view.
  ///
  /// - Parameter content: The content to be displayed only in debug builds.
  public init(@ViewBuilder content: () -> Content)

  public var body: some View
}
```

## Module `CustomViews`

```swift
import SwiftUI

/// A view that displays a system symbol with a light font weight.
public struct Symbol: View {
  /// The name of the system symbol to display.
  public let systemName: String

  /// Creates a new `Symbol` view.
  ///
  /// - Parameter systemName: The name of the system symbol to display.
  public init(systemName: String)

  public var body: some View
}
```

## Module `CustomViews`

```swift
import MarkdownUI
import SwiftUI
import ViewExtensions

/// A `DisclosureGroup` whose full title is a click target.
public struct TitleClickableDisclosureGroup: View {
  /// Creates a new `TitleClickableDisclosureGroup` view.
  ///
  /// - Parameters:
  ///   - title: The title of the disclosure group.
  ///   - mdContent: The Markdown content to display when the group is expanded.
  public init(title: String, mdContent: String)

  public var body: some View
}
```

## Module `DataExtensions`

```swift
import AppIntents
import Foundation
import UniformTypeIdentifiers

public extension Data {
  /// Converts `self` to an AppIntents `IntentFile`.
  func toIntentFile(contentType: UTType, filename: String? = nil) -> IntentFile

  /// Converts the data to a string using UTF-8 encoding.
  ///
  /// - Returns: The string representation of the data, or `nil` if the conversion fails.
  func toString() -> String?
}
```

## Module `DateExtensions`

```swift
import Foundation

public extension Date {
  // MARK: - Static Functions

  /// Attempts to create a `Date` instance from a ISO8601 date string.
  ///
  /// - Parameter dateString: The ISO8601 date string to convert.
  /// - Returns: A `Date` object if the conversion was successful, otherwise `nil`.
  static func fromISO8601String(_ dateString: String) -> Date?

  // MARK: - Functions

  /// Returns the ISO8601 representation of the date in the format "yyyy-MM-dd"
  /// - Returns: A string representing the date in ISO8601 format
  /// - Example: "2024-02-20"
  /// - Note: This format only includes the date component, not time
  func iso8601Date() -> String

  /// Returns the localized representation of the date using the system's current locale
  /// - Returns: A string with the date formatted according to the current locale's medium date style
  /// - Example: "Feb 20, 2024" for en_US locale
  /// - Note: The exact format depends on the user's locale settings
  func localeDate() -> String
}
```

## Module `DesktopUI`

```swift
import MarkdownUI
import MarkdownUIExtensions
import SwiftUI

// MARK: - WhatsNewWindow

@available(macOS 14.0, *)
struct ChangelogView: View {
  // MARK: - SwiftUI Properties

  // MARK: - Properties

  let appName: String
  let appVersion: String
  let appIcon: ImageResource
  let mdContent: String
  let releaseNotesLink: URL?
  let onMarkAsRead: AsyncVoidFunction?

  // MARK: - Computed Properties

  // MARK: - Lifecycle

  public init(appName: String,
              appVersion: String,
              appIcon: ImageResource,
              mdContent: String,
              releaseNotesLink: URL? = nil,
              onMarkAsRead: AsyncVoidFunction? = nil)

  // MARK: - Content Properties

  var body: some View { get }

  // MARK: - Functions
}
```

## Module `DesktopUI`

```swift
import AppKit
import CustomProtocols
import Defaults
import StringExtensions
import SwiftUI
import TaskExtensions

public typealias AsyncVoidFunction = () async -> Void

// MARK: - ChangelogWindow

/// The changelog window of the app ("What's New"), showing the `ChangelogView`. The window is
/// created as needed as a `NSWindow`.
@available(macOS 14.0, *)
public final class ChangelogWindow: NSObject, StaticSetupable {
  // MARK: - Static Properties

  public private(set) static var shared: ChangelogWindow!

  // MARK: - Properties

  /// An optional handler that is called when the window is closed.
  public var onWindowWillClose: ((_ notification: Notification) -> Void)?

  let appName: String
  let appVersion: String
  let appIcon: ImageResource
  let mdContent: String
  let changelogChecksum: String
  let releaseNotesLink: URL?
  let onMarkAsRead: AsyncVoidFunction?

  // MARK: - Computed Properties

  /// Is the changelog window currently visible?
  public var isVisible: Bool { get }

  // MARK: - Lifecycle

  public init(appName: String,
              appVersion: String,
              appIcon: ImageResource,
              mdContent: String,
              changelogChecksum: String,
              releaseNotesLink: URL? = nil,
              onMarkAsRead: AsyncVoidFunction? = nil)

  // MARK: - Functions

  /// Creates and shows the window.
  public func show(centered: Bool = false)

  /// Only bring up the changelog window if the app has an updated changelog. Used during app launch.
  public func showOnUpdatedChangelog()
}

// MARK: NSWindowDelegate

@available(macOS 14.0, *)
extension ChangelogWindow: NSWindowDelegate {
  public func windowWillClose(_ notification: Notification)
}
```

## Module `DesktopUI`

```swift
import Foundation

/// An error that can occur when working with the changelog window.
public enum ChangelogWindowError: Error {
  /// The changelog file is missing.
  case fileMissing
}
```

## Module `DesktopUI`

```swift
import Defaults
import Foundation

public extension Defaults.Keys {
  /// The checksum of the last seen changelog.
  static let seenChangelogWithChecksum: Key<String>
}
```

## Module `DesktopUI`

```swift
import AppKit
import TaskExtensions

// MARK: - DockIcon

/// Convenience functions for showing and hiding the app's dock icon.
public enum DockIcon {
  // MARK: - Static Computed Properties

  /// Convenience method that checks whether activation policy is set to `.regular`.
  public static var isEnabled: Bool { get }

  // MARK: - Static Functions

  /// Changes activation policy to `.regular`.
  public static func show()

  /// Changes activation policy to `.prohibited`.
  public static func hide()
}
```

## Module `DictionaryExtensions`

```swift
import AppIntents
import DataExtensions
import Foundation

public extension Dictionary where Key == String {
  /// Converts `self` to an `IntentFile` which Shortcuts uses as "Dictionary".
  func toIntentFile(filename: String? = nil) throws -> IntentFile

  /// Returns `self` as a JSON string.
  func toJSONString() throws -> String?
}
```

## Module `EncodingExtensions`

```swift
import Foundation

public extension KeyedDecodingContainer {
  /// A very lenient decoding method that tries to return a default value even when the requested
  /// key isn't present.
  func decode<T: Decodable>(_ type: T.Type, forKey key: Key, defaultValue: T) -> T
}
```

## Module `ErrorHandling`

```swift
/// A protocol for dealing errors across ZCo modules.
///
/// This protocol defines the interface for error reporting in the ZCo ecosystem.
/// Implementations can handle error reporting in various ways, such as logging to a
/// file, sending to a remote error tracking service, or displaying to the user.
public protocol ErrorHandler {
  /// Handles an error with additional context.
  ///
  /// - Parameters:
  ///   - error: The error that occurred.
  ///   - metadata: Additional contextual information about the error.
  ///              This can include things like the current app version,
  ///              module state, or any other relevant debugging information.
  func handle(error: Error, metadata: [String: Any])
}
```

## Module `ErrorTracking`

```swift
import Defaults
import Foundation

/// Extension to provide user defaults keys for license-related data storage.
public extension Defaults.Keys {
  static let lastPingToSentryForVersion = Key<String>("48ae42df", default: "")
}
```

## Module `ErrorTracking`

```swift
import AppDetails
import Defaults
import Logging
import Sentry

// MARK: - SentryManager

/// A manager for configuring and initializing Sentry error tracking in the app.
///
/// This struct handles the setup of Sentry SDK with appropriate configuration based on the current
/// build environment. It manages initial setup, configures tracking options, and sends
/// installation/update analytics.
@StaticLogger
public struct SentryManager {
  // MARK: - Properties

  /// The Data Source Name (DSN) used to authenticate with Sentry.
  let dsn: String

  /// Is this app build a dev build?
  let isDevBuild: Bool

  /// Is this app build a beta build?
  let isBetaBuild: Bool

  // MARK: - Lifecycle

  /// Initializes a new instance of `SentryManager` with the given configuration.
  ///
  /// - Parameters:
  ///   - dsn: The Data Source Name (DSN) used to authenticate with Sentry.
  ///   - isDevBuild: A boolean indicating whether the current build is a development build.
  ///   - isBetaBuild: A boolean indicating whether the current build is a beta build.
  ///   - sendLaunchPing: An optional boolean (defaulting to `false`) that determines whether to
  ///     send a launch ping to Sentry (once for every device and version) after initialization.
  public init(dsn: String,
              isDevBuild: Bool,
              isBetaBuild: Bool,
              sendLaunchPing: Bool = false)
}
```

## Module `ErrorTracking`

```swift
import ErrorHandling
import Logging
import Sentry

/// An error handler that calls `SentrySDK.capture(error:)`.
@StaticLogger
public struct SentryReporter: ErrorHandler {
  // MARK: - Lifecycle

  public init()

  // MARK: - Functions

  public func handle(error: Error, metadata: [String: Any] = [:])
}
```

## Module `IntExtensions`

```swift
import Foundation

public extension Int {
  /// Returns a Date object representing the specified number of days ago from the current date.
  /// - Returns: A Date object representing the `self` number of days ago from the current date.
  func daysAgo() -> Date
}
```

## Module `JSONExtensions`

```swift
import Foundation

public extension JSONDecoder {
  // MARK: - Nested Types

  enum JSONDecoderCustomError: Error {
    case unableToLocateJSONFile(file: String)
    case unableToLoadJSONFile(file: String)
    case unableToDecodeJSONFile(file: String)
  }

  // MARK: - Functions

  /// Decodes a `Decodable` type from a JSON file in the main bundle.
  ///
  /// - Parameters:
  ///   - type: The `Decodable` type to decode.
  ///   - file: The name of the JSON file (including extension) in the main bundle.
  ///
  /// - Returns: An instance of the specified type, decoded from the JSON file.
  func decode<T: Decodable>(_ type: T.Type, from file: String) throws -> T
}
```

## Module `Licensing`

```swift
import Defaults
import Foundation

/// Extension to provide user defaults keys for license-related data storage.
public extension Defaults.Keys {
  /// The timestamp of when the license was last validated.
  ///
  /// Stored as a TimeInterval (seconds since 1970) to track when the last
  /// successful license validation occurred. A value of 0 indicates no
  /// validation has been performed.
  static let licenseValidatedAt = Key<TimeInterval>("licenseValidatedAt", default: 0)

  /// The signature from the last successful license validation.
  ///
  /// This signature is used to verify the integrity of the stored license
  /// information and prevent tampering. An empty string indicates no
  /// validation signature is present.
  static let licenseValidatedSignature = Key<String>("licenseValidatedSignature", default: "")

  /// The current state of the application's license.
  ///
  /// This key stores the overall licensing state of the application,
  /// defaulting to unlicensed when no valid license is present.
  static let licenseState = Key<LicensingState>("licenseState", default: LicensingState.unlicensed)
}
```

## Module `Licensing`

```swift
import Foundation

/// Represents the details of a license in the application.
///
/// This struct encapsulates all relevant information about a license,
/// including its unique key, descriptive title, and expiration date.
public struct LicenseDetails: Codable {
  // MARK: - Properties

  /// The unique license key string.
  ///
  /// This key is used to validate and identify the license in the system.
  public let key: String

  /// A human-readable title or description of the license.
  ///
  /// This can include information about the license type, owner, or other
  /// relevant identifying information.
  public let title: String

  /// The date when the license expires.
  ///
  /// After this date, the license may no longer be valid depending on
  /// the application's validation rules.
  public let expiry: Date

  // MARK: - Lifecycle

  public init(key: String, title: String, expiry: Date)
}
```

## Module `Licensing`

```swift
import Foundation

/// Represents the response structure from a Keygen license validation request.
///
/// This model maps the JSON response received when validating a license,
/// containing metadata about the validation result and the license details.
public struct LicenseValidationResponse: Codable {
  // MARK: - Nested Types

  /// Contains metadata about the validation response.
  public struct Meta: Codable {
    /// The response code indicating the validation result.
    ///
    /// This code can be used to determine if the validation was successful
    /// or if there were any issues.
    public let code: String
  }

  /// Contains the main data payload of the validation response.
  public struct Data: Codable {
    /// The detailed attributes of the license, if available.
    ///
    /// May be `nil` if the validation failed or no license data was returned.
    public let attributes: Attributes?
  }

  /// Contains detailed attributes about the license.
  public struct Attributes: Codable {
    // MARK: - Nested Types

    /// Contains additional metadata about the license.
    public struct Metadata: Codable {
      /// The human-readable title of the license.
      ///
      /// This may be `nil` if no title was set for the license.
      public let licenseTitle: String?

      /// The license title as stored in the Paddle account, set by my custom webhook receiver
      /// script.
      ///
      /// This may be `nil` if the license wasn't issued through Paddle or if no name was provided.
      public let paddleLicenseName: String?
    }

    // MARK: - Properties

    /// Additional metadata associated with the license.
    public let metadata: Metadata

    /// The expiration date of the license as an ISO 8601 string.
    ///
    /// This may be `nil` for perpetual licenses or if no expiration
    /// date was set.
    public let expiry: String?
  }

  // MARK: - Properties

  /// Metadata about the validation response.
  public let meta: Meta

  /// The main data payload of the validation response.
  ///
  /// May be `nil` if the validation failed or no data was returned.
  public let data: Data?
}
```

## Module `Licensing`

```swift
import Defaults
import Foundation

/// Represents the current licensing state of the application.
///
/// This enum is used to track and manage the application's licensing status,
/// providing different states that reflect whether the app is licensed,
/// unlicensed, or was previously licensed but requires an upgrade.
public enum LicensingState: String, Defaults.Serializable {
  /// The application has no valid license key entered.
  case unlicensed

  /// The application has a valid, active license.
  case licensed

  /// The application had a valid license that is no longer valid for the current version.
  case previouslyLicensed
}
```

## Module `Licensing`

```swift
#if os(macOS)
  import AppKit
#elseif os(iOS)
  import UIKit
#endif
import Foundation
import Networking

// MARK: - KeygenAPIClient

/// A client for interacting with the Keygen.sh license validation API.
///
/// This class implements the `LicenseNetworkProvider` protocol to provide
/// license validation functionality through the Keygen.sh API service.
final class KeygenAPIClient: LicenseNetworkProvider {
  // MARK: - Properties

  /// The underlying networking client used for HTTP requests.
  ///
  /// Configured with specific headers and settings required for
  /// communicating with the Keygen.sh API.
  private let client: NetworkingClient

  // MARK: - Lifecycle

  /// Creates a new Keygen API client instance.
  ///
  /// - Parameter baseURL: The base URL of the Keygen.sh API endpoint, e.g.
  ///   `https://app.keygen.sh/v1/accounts/<account-id>`. This URL will be used as the prefix for
  ///   all API requests.
  public init(baseURL: URL)

  // MARK: - Functions

  /// Validates a license key with the Keygen.sh API.
  ///
  /// This method sends a POST request to validate the provided license key
  /// along with any additional parameters required for validation.
  ///
  /// - Parameters:
  ///   - key: The license key to validate.
  ///   - parameters: Additional parameters required for the validation request.
  /// - Returns: A `LicenseValidationResponse` containing the validation results.
  /// - Throws: An error if the validation request fails or the response is invalid.
  public func validate(key: String, parameters: Params) async throws -> LicenseValidationResponse
}
```

## Module `Licensing`

```swift
import Networking

/// A protocol defining the requirements for a license validation network service.
///
/// This protocol abstracts the network layer for license validation, allowing
/// different implementations (like Keygen.sh, custom servers, etc.) to be used
/// interchangeably in the licensing system.
public protocol LicenseNetworkProvider {
  /// Validates a license key with the licensing service.
  ///
  /// - Parameters:
  ///   - key: The license key to validate.
  ///   - parameters: Additional parameters required for the validation request.
  ///                These may include things like machine identifiers, version numbers,
  ///                or other context needed for validation.
  /// - Returns: A `LicenseValidationResponse` containing the validation results.
  /// - Throws: An error if the validation request fails or the response is invalid.
  func validate(key: String, parameters: Params) async throws -> LicenseValidationResponse
}
```

## Module `Licensing`

```swift
import Foundation
import SimpleKeychain
import StringExtensions

/// A secure storage implementation for license details using the system keychain.
///
/// This class implements the `LicenseStorage` protocol to provide secure storage
/// of license information using the macOS/iOS keychain through SimpleKeychain.
final class KeychainStorage: LicenseStorage {
  // MARK: - Lifecycle

  /// Creates a new keychain storage instance.
  ///
  /// - Parameter storageKey: The key under which to store the license details
  ///                        in the keychain. Defaults to "license".
  public init(storageKey: String = "license")

  // MARK: - Functions

  /// Stores license details securely in the keychain.
  ///
  /// This method serializes the license details to JSON and stores them
  /// in the system keychain under the configured storage key.
  ///
  /// - Parameter details: The license details to store.
  /// - Throws: An error if the encoding or storage operation fails.
  ///          Possible errors include JSON encoding failures or keychain access errors.
  public func store(details: LicenseDetails) throws

  /// Retrieves stored license details from the keychain.
  ///
  /// This method attempts to retrieve and deserialize the stored license
  /// details from the system keychain.
  ///
  /// - Returns: The stored license details, or `nil` if no details are stored.
  /// - Throws: An error if the retrieval or decoding operation fails.
  ///          Possible errors include JSON decoding failures or keychain access errors.
  public func retrieve() throws -> LicenseDetails?

  /// Removes the stored license details from the keychain.
  ///
  /// This method deletes any stored license information from the system
  /// keychain under the configured storage key.
  ///
  /// - Throws: An error if the deletion operation fails.
  public func clear() throws
}
```

## Module `Licensing`

```swift
/// A protocol defining the requirements for secure license storage.
///
/// This protocol abstracts the storage layer for license details, allowing
/// different storage implementations (like keychain, file system, etc.)
/// to be used interchangeably in the licensing system.
public protocol LicenseStorage {
  /// Stores license details in the storage system.
  ///
  /// - Parameter details: The license details to store.
  /// - Throws: An error if the storage operation fails.
  func store(details: LicenseDetails) throws

  /// Retrieves stored license details from the storage system.
  ///
  /// - Returns: The stored license details, or `nil` if no details are stored.
  /// - Throws: An error if the retrieval operation fails.
  func retrieve() throws -> LicenseDetails?

  /// Removes any stored license details from the storage system.
  ///
  /// - Throws: An error if the deletion operation fails.
  func clear() throws
}
```

## Module `Licensing`

```swift
import CryptoKit
import Foundation

/// Extension providing additional functionality to String for cryptographic
/// hashing and date parsing operations.
extension String {
  /// Computes the SHA-256 hash of the string.
  ///
  /// This method converts the string to UTF-8 data and computes its SHA-256
  /// hash using CryptoKit, returning the result as a lowercase hexadecimal string.
  ///
  /// - Returns: A string containing the hexadecimal representation of the SHA-256 hash.
  ///           The returned string is always 64 characters long (32 bytes represented as hex).
  func sha256() -> String

  /// Attempts to parse the string as an ISO 8601 formatted date.
  ///
  /// This method uses `ISO8601DateFormatter` to parse dates that include
  /// internet date/time format and fractional seconds, e.g. `2025-02-06T18:16:30.123Z`.
  ///
  /// - Returns: A `Date` object if the string could be parsed successfully,
  ///           or `nil` if the string is not a valid ISO 8601 date.
  func toDate() -> Date?
}
```

## Module `Licensing`

```swift
import SwiftUI

/// A SwiftUI view that presents a sheet for license key activation.
///
/// This view provides a form interface for users to enter and validate
/// their license key. It includes input validation, error handling,
/// and visual feedback during the validation process.
public struct LicenseActivationSheet: View {
  // MARK: - SwiftUI Properties

  // MARK: - Lifecycle

  /// Creates a new license activation sheet.
  ///
  /// - Parameter validator: The license validator instance to use for
  ///                       validating the entered license key.
  public init(validator: LicenseValidator)

  // MARK: - Content Properties

  /// The body of the view.
  ///
  /// Presents a form with a text field for the license key, error display
  /// if applicable, and navigation controls for canceling or activating
  /// the license.
  public var body: some View { get }

  // MARK: - Functions
}
```

## Module `Licensing`

```swift
import Foundation
import SwiftUI

// MARK: - LicenseValidationError

/// Represents errors that can occur during license validation.
///
/// This enum implements `LocalizedError` to provide human-readable error
/// descriptions for various license validation failure scenarios.
public enum LicenseValidationError: LocalizedError {
  // MARK: - Keychain / Storage

  /// The system keychain could not be accessed.
  case keychainUnavailable(underlying: Error)

  /// A keychain entry exists but the stored JSON is corrupt or cannot be decoded.
  case licenseCorrupted(underlying: Error)

  // MARK: - Key preparation

  /// The stored license key string is empty or consists of whitespace only.
  case licenseKeyEmpty

  /// The local validation timestamp or its signature was tampered with.
  case timestampTampered

  // MARK: - Server reported problems (well-known codes)

  /// The provided license key does not exist in the system.
  case licenseKeyUnknown

  /// The license key has been suspended or revoked.
  case licenseSuspended

  /// The license key is only valid for an older version of the application.
  case licenseValidForOlderVersion

  // MARK: - Networking / server response

  /// Low-level networking error (no connection, timeout, etc.).
  case network(Error)

  /// The validation service returned an unrecognized response code.
  ///
  /// - Parameter code: The unknown response code received from the validation service.
  case unknownServerCode(String)

  // MARK: - Computed Properties

  /// A human-readable description of the error.
  ///
  /// This property is part of the `LocalizedError` protocol and provides
  /// user-friendly error messages that can be displayed in the UI or logged
  /// for debugging purposes.
  ///
  /// - Returns: A localized string describing the error.
  public var errorDescription: String? { get }
}

// MARK: CustomLocalizedStringResourceConvertible

extension LicenseValidationError: CustomLocalizedStringResourceConvertible {
  public var localizedStringResource: LocalizedStringResource { get }
}
```

## Module `Licensing`

```swift
import Defaults
import ErrorHandling
import Foundation
import Networking
import StringExtensions
import TaskExtensions

/// The main class responsible for handling license validation and management.
///
/// This class provides functionality for validating, storing, and managing license keys. It handles
/// communication with the licensing server, maintains the current licensing state, and manages
/// cached license data.
public final class LicenseValidator: ObservableObject {
  // MARK: - Static Properties

  public private(set) static var shared: LicenseValidator!

  // MARK: - Properties

  /// The current state of the license. Set via `setState(_)`.
  ///
  /// This published property will update the UI whenever the licensing state changes.
  @Published public private(set) var state: LicensingState

  /// The currently stored license details.
  ///
  /// This property attempts to retrieve license details from the cache first,
  /// falling back to storage if necessary. Any errors during retrieval are
  /// reported through the error reporter.
  public var storedLicenseDetails: LicenseDetails? { get }

  /// Convenience method to reduce explicit `state` checks.
  ///
  /// Returns `true` if the license was successfully validated in the last few days, within the
  /// grace period, i.e. `LicenseConfiguration.gracePeriod`.
  public var isLicensed: Bool { get }

  // MARK: - Lifecycle

  /// Creates a new license validator instance.
  ///
  /// - Parameters:
  ///   - configuration: The configuration settings for license validation.
  ///   - errorHandler: Optional error handler for dealing with validation errors.
  public init(configuration: LicensingConfiguration,
              errorHandler: ErrorHandler? = nil,
              storage: LicenseStorage? = nil,
              networkProvider: LicenseNetworkProvider? = nil)

  // MARK: - Functions

  /// Validates the passed-in key, and sets `state` accordingly.
  ///
  /// This method validates it against the licensing server.
  ///
  /// - Returns: A result indicating success or failure of the validation. A success with a value
  ///   of `false` means the passed-in license key was blank.
  public func setStateForLicenseKey(key: String) async -> Result<Bool, LicenseValidationError>

  /// Retrieves the stored license key if it exists, validates it, and sets `state` accordingly.
  ///
  /// This method retrieves any stored license key and validates it
  /// against the licensing server.
  ///
  /// - Returns: A result indicating success or failure of the validation. A success with a value
  ///   of `false` means there's no stored license key present.
  public func setStateForStoredLicenseKey() async -> Result<Bool, LicenseValidationError>

  /// Deactivates the current license.
  ///
  /// This method clears all stored license information and resets the
  /// validation state to unlicensed.
  public func deactivateLicense()
}
```

## Module `Licensing`

```swift
import Foundation

/// Configuration settings for the license validation system.
///
/// This structure holds all the necessary configuration parameters for setting up and managing
/// license validation, including API endpoints, security settings, and timing parameters.
public struct LicensingConfiguration {
  // MARK: - Properties

  /// Is this app build a dev build?
  let isDevBuild: Bool

  /// Is this app build a beta build?
  let isBetaBuild: Bool

  /// The product identifier in the Keygen.sh system.
  ///
  /// This ID is used to identify which product the license belongs to
  /// when making validation requests.
  let keygenProductID: String

  /// The base URL for the Keygen.sh API.
  ///
  /// This URL is used as the prefix for all API requests to the
  /// Keygen.sh service.
  let keygenBaseURL: URL

  /// The current version of the application.
  ///
  /// This version is used during license validation to ensure the
  /// license is valid for the current app version.
  let appVersion: String

  /// A salt value used for additional security in license validation.
  ///
  /// This salt is combined with other data to create unique signatures
  /// and prevent tampering with license data.
  let securitySalt: String

  /// The interval between license validations, in seconds.
  ///
  /// Specifies how often the application should re-validate the license
  /// with the Keygen.sh service. Defaults to 86400 seconds (1 day).
  let validationInterval: TimeInterval

  /// The grace period for license validation, in seconds.
  ///
  /// If license validation fails (e.g., due to network issues), the app
  /// will continue to work for this duration before requiring a successful
  /// validation. Defaults to 259,200 seconds (3 days).
  let gracePeriod: TimeInterval

  // MARK: - Lifecycle

  /// Creates a new licensing configuration instance.
  ///
  /// - Parameters:
  ///   - isDevBuild: Is this app build a dev build?
  ///   - isBetaBuild: Is this app build a beta build?
  ///   - keygenProductID: The product identifier in the Keygen.sh system.
  ///   - keygenBaseURL: The base URL for the Keygen.sh API.
  ///   - appVersion: The current version of the application.
  ///   - securitySalt: A salt value used for additional security.
  ///   - validationInterval: The interval between license validations in seconds.
  ///                        Defaults to 86400 (1 day).
  ///   - gracePeriod: The grace period for failed validations in seconds.
  ///                  Defaults to 259,200 (3 days).
  public init(isDevBuild: Bool,
              isBetaBuild: Bool,
              keygenProductID: String,
              keygenBaseURL: URL,
              appVersion: String,
              securitySalt: String,
              validationInterval: TimeInterval = 86400, // 1 day
              gracePeriod: TimeInterval = 259_200 // 3 days
  )
}
```

## Module `Logging`

```swift
/// Re-exporting `OSLog` and `StaticLogger`, making their types available to users package without
/// requiring explicit importing.
@_exported import OSLog
@_exported import StaticLogger

public extension Logger {
  /// Custom method which logs debug-level message and *only* when in debug env.
  ///
  /// This wrapper prevents the Xcode log to display the correct source file and line but since it's
  /// only used during development, I think I can live with that.
  func debugOnly(_ message: String)
}
```

## Module `MarkdownUIExtensions`

```swift
import MarkdownUI
import SwiftUI

public extension Theme {
  /// The default Markdown theme.
  ///
  /// Style | Preview
  /// --- | ---
  /// Inline text | ![](BasicInlines)
  /// Headings | ![](Heading)
  /// Blockquote | ![](BlockquoteContent)
  /// Code block | ![](CodeBlock)
  /// Image | ![](Paragraph)
  /// Task list | ![](TaskList)
  /// Bulleted list | ![](NestedBulletedList)
  /// Numbered list | ![](NumberedList)
  /// Table | ![](Table-Collection)
  static let basicEnhanced: Theme
}
```

## Module `Opening`

```swift
import AppDetails
import Foundation
import Logging
import URLExtensions
#if os(macOS)
  import AppKit
#elseif os(iOS)
  import UIKit
#endif

public extension Opening {
  /// Opens a URL after adding a `ref=\(AppDetails.idString)` parameter to it.
  static func openURL(_ urlString: String)

  /// Opens a URL after adding a `ref=…` parameter to it.
  static func openURL(_ urlString: String, ref: String = "")

  /// Opens the website's store page.
  static func openStore()
}
```

## Module `Opening`

```swift
import AppDetails
import Foundation
import URLExtensions

public extension Opening {
  static func openMail(additionalMetadata: String = "")
}
```

## Module `Opening`

```swift
public struct Opening {}
```

## Module `PropertyWrappers`

````swift
import Foundation

// MARK: - Sorted

/// A property wrapper that automatically sorts an array by a specified property of its elements.
/// The property must be `Comparable`.
///
/// Example usage:
/// ```swift
/// @Sorted(property: \.title)
/// var list: [TaggedWorkflow] = []
///
/// @Sorted(property: \.title, direction: .descending)
/// var reversedList: [TaggedWorkflow] = []
/// ```
@propertyWrapper
public struct Sorted<Element, Value: Comparable> {
  // MARK: - Nested Types

  // MARK: - SortDirection

  /// The direction to sort in, either ascending or descending order.
  public enum SortDirection {
    case ascending
    case descending
  }

  // MARK: - Properties

  public var wrappedValue: [Element] { get set }

  // MARK: - Lifecycle

  public init(wrappedValue: [Element] = [],
              property keyPath: KeyPath<Element, Value>,
              direction: SortDirection = .ascending)
}
````

## Module `PropertyWrappers`

````swift
import Foundation

/// A wrapper around a string that automatically lowercases it.
///
/// ```
/// @Lowercased var text = "Hello, World!"
///
/// print(text) // "hello, world!"
/// ```
@propertyWrapper
public struct Lowercased: Sendable, Equatable, Hashable {
  // MARK: - Properties

  public var wrappedValue: String { get set }

  // MARK: - Lifecycle

  public init(wrappedValue: String)
}
````

## Module `PropertyWrappers`

````swift
import Foundation

/// A wrapper around a string that automatically trims leading and trailing whitespace and newlines.
///
/// ```
/// @Lowercased var text = """
///   Hello, World!
/// """
///
/// print(text) // "hello, world!"
/// ```
@propertyWrapper
public struct Trimmed: Sendable, Equatable, Hashable {
  // MARK: - Properties

  public var wrappedValue: String { get set }

  // MARK: - Lifecycle

  public init(wrappedValue: String)
}
````

## Module `StringExtensions`

```swift
import CommonCrypto
import JavaScriptCore
import Logging

public extension String {
  // MARK: - Nested Types

  enum EscapableCharacter: String {
    case doublequotes = #"(\")"#
    case backslashes = #"(\\)"#
    case backticks = #"(`)"#
  }

  enum StringError: Error {
    case unableToDecodeJSON
  }

  // MARK: - Computed Properties

  /// Basically an `.isEmpty` check with prior trimming of whitespace.
  ///
  /// - Returns: `true` if the string contains nothing but whitespace or linebreaks or is zero chars
  ///            in length, `false` otherwise
  ///
  /// Note: I made this a var because I wanted it to behave like the built-in `.isEmpty`.
  var isBlank: Bool { get }

  /// Basically an inverted `.isEmpty` check with prior trimming of whitespace.
  ///
  /// - Returns: `true` if the string contains anything other than whitespace or linebreaks, `false`
  ///            otherwise
  ///
  /// Note: I made this a var because I wanted it to behave like the built-in `.isEmpty`.
  var isPresent: Bool { get }

  /// Checks whether the string contains a valid `http`, `https`, or `file` URL.
  var isValidURL: Bool { get }

  // MARK: - Functions

  /// Checks whether the string matches a regular expression pattern.
  ///
  /// - Parameters:
  ///   - regex: The regular expression pattern to check against.
  ///
  /// - Returns: `true` if the string is a valid JavaScript regular expression, otherwise `false`.
  func matchesRegex(_ regex: String) -> Bool

  /// Parses the JSON data into an object of the specified type.
  ///
  /// - Returns: A `Result` object containing either the decoded object or a `StringError` if the
  ///            JSON could not be parsed.
  func parseJSON<T: Decodable>() -> Result<T, Error>

  /// Returns a new string consisting of the first and last N characters of the current instance,
  /// with an ellipsis in the middle if the current is longer than `N * 2` characters.
  ///
  /// - Parameters:
  ///   - numberOfChars: The max length of the new string.
  ///
  /// - Returns: A new string.
  func shortenToMaxChars(_ numberOfChars: Int) -> String

  /// Convenience regex-based string replacement.
  ///
  /// - Parameters:
  ///   - regex: A string representation of a regex, e.g. "^\\d:(.+):"
  ///   - with: A string representation of a regex replacement, e.g. "- $1:"
  func replacing(regex: String, with replacement: String) -> String

  func escaped(_ char: EscapableCharacter) -> String

  /// Removes whitespace from the beginning of this string and returns a new string, without
  /// modifying the original string.
  func trimmedStart() -> String

  /// Removes whitespace from the end of this string and returns a new string, without modifying the
  /// original string. Whitespace is defined as white space characters plus line terminators.
  func trimmedEnd() -> String

  /// Convenience method, returns `true` if `self` is "true" (case-insensitive), `false` otherwise.
  func toBool() -> Bool

  /// If `self` is a ISO8601 timestamp, returns a `Date` object.
  func toDate() -> Date?

  /// Returns the SHA256 hash for `self`.
  func sha256() -> String

  /// Returns `self` with its firts character capitalized.
  func capitalizedFirstChar() -> String
}
```

## Module `TaskExtensions`

````swift
import Foundation

public extension Task where Success == Never, Failure == Never {
  /// Suspends the current task for the specified number of seconds.
  ///
  /// This function pauses execution in an asynchronous context. It wraps the `Task.sleep(for:)`
  /// method, handling any potential errors internally.
  ///
  /// - Parameter seconds: The duration to wait, in seconds. If the value is 0 or negative, the
  /// function returns immediately without waiting.
  ///
  /// - Note: This function uses `try?` to silently ignore any errors that might occur during the
  /// sleep operation.
  ///
  /// Usage example:
  /// ```
  /// await Task.wait(2.5) // Waits for 2.5 seconds
  /// ```
  static func wait(_ seconds: TimeInterval) async
}

public extension Task where Failure == Error {
  /// Runs a task after an arbitrary number of seconds.
  ///
  /// Source: [https://www.swiftbysundell.com/articles/delaying-an-async-swift-task/](https://www.swiftbysundell.com/articles/delaying-an-async-swift-task/)
  static func delayed(by seconds: TimeInterval,
                      priority: TaskPriority? = nil,
                      operation: @escaping @Sendable () async throws -> Success)
    -> Task
}
````

## Module `TaskExtensions`

```swift
#if canImport(AppKit)
  import AppKit
#elseif canImport(UIKit)
  import UIKit
#endif

/// Executes a block synchronously on the main thread and returns its value.
/// If the current thread is already the main thread, executes the block directly.
///
/// - Parameter block: The block to execute
/// - Returns: The return value of the block of type T
@inlinable
public func executeOnMainThread<T>(_ block: () -> T) -> T
```

## Module `Trialling`

```swift
import Defaults
import Foundation

/// Extension to provide user defaults keys for license-related data storage.
public extension Defaults.Keys {
  static let firstInstallDate = Key<TimeInterval>("402b34ee", default: 0)
}
```

## Module `Trialling`

```swift
import ArrayExtensions
import Defaults
import ErrorHandling
import Foundation
import Logging
import SimpleKeychain

// MARK: - FirstInstallTracker

/// Tracks and validates the first installation date of the app across multiple storage locations
/// to prevent tampering.
///
/// The tracker stores the first install date in three locations:
/// - Keychain
/// - UserDefaults
/// - A hidden file with randomized timestamps
///
/// This redundancy helps ensure the integrity of the first install date by cross-validating
/// multiple sources.
@StaticLogger
public struct FirstInstallTracker {
  // MARK: - Properties

  /// The key used to store the first install date in the keychain
  let keychainKey: String

  /// The path to the hidden file where the first install date is stored
  let hiddenFilePath: String

  /// Optional error handler for reporting file operation errors
  let errorHandler: ErrorHandler?

  // MARK: - Lifecycle

  /// Creates a new FirstInstallTracker instance
  /// - Parameters:
  ///   - keychainKey: The key to use for storing the date in the keychain
  ///   - hiddenFilePath: The path where the hidden file will be created
  ///   - errorHandler: Optional handler for file operation errors
  public init(keychainKey: String,
              hiddenFilePath: String,
              errorHandler: ErrorHandler?)

  // MARK: - Functions

  /// Sequentially checks all places where the first install date ("FID") is stored. If there was
  /// tampering with one or more of them, all places will be re-set to the oldest known FID. The
  /// first time the method is run, it'll set up all places.
  ///
  /// When this method is done, `Defaults[.firstInstallDate]` will be set.
  ///
  /// This method performs the following checks:
  ///   1. Retrieves timestamp from keychain
  ///   2. Retrieves timestamp from UserDefaults
  ///   3. Retrieves timestamp from hidden file
  ///   4. If no timestamps exist, sets current time as first install date
  ///   5. If timestamps exist but don't match, uses the oldest timestamp
  public func validate()
}
```

## Module `Trialling`

```swift
import ComparableExtensions
import Defaults
import ErrorHandling
import Licensing
import Logging
import SwiftUI

// MARK: - TrialManager

/// A manager class responsible for handling trial period functionality in the app. It tracks the
/// installation date, manages trial period status, and decides whether or not to display purchase
/// reminders. (It doesn't show them, it just makes the decision.)
///
/// The class is designed as a singleton, accessible through the `shared` property which is
/// automatically set during initialization.
@StaticLogger
public final class TrialManager: ObservableObject {
  // MARK: - Static Properties

  public private(set) static var shared: TrialManager!

  // MARK: - Properties

  // MARK: - Computed Properties

  public var currentSituation: CurrentSituation { get }

  /// The number of days since the app was first installed.
  public var daysSinceFirstInstall: Int { get }

  // MARK: - Lifecycle

  /// Creates a new trial period manager instance.
  ///
  /// - Parameters:
  ///   - isBetaBuild: Is this app build a beta build?
  ///   - trialPeriodInDays: The duration of the trial period in days
  ///   - offersExtendedTrial: Whether the trial period should end after `trialPeriodInDays` days
  ///   (`false`), or slowly fade out over the next 20 days (`true`)
  ///   - firstInstallDate: In dev builds, used to set a fake install date. In beta/release, pass in
  ///   `Defaults[.firstInstallDate]`
  ///   - licenseValidator: The license validator
  ///   - purchaseReminderHandler: Optional closure to be called when a purchase reminder should be shown
  ///   - errorHandler: Optional error reporter for handling trial period errors
  public init(isBetaBuild: Bool,
              trialPeriodInDays: Int,
              offersExtendedTrial: Bool = true,
              firstInstallDate: TimeInterval,
              licenseValidator: LicenseValidator,
              purchaseReminderHandler: (() -> Void)? = nil,
              errorHandler: ErrorHandler? = nil)

  // MARK: - Functions

  /// Conditionally sends a signal to show the purchase reminder in the main app. Whether it is
  /// shown depends on the trial period, among other things.
  public func executePurchaseReminderHandlerIfNecessary()

  /// Conditionally shows the purchase reminder in the intents, by way of an showstopping error.
  /// Whether it is shown depends on the trial period, among other things.
  ///
  /// The method will throw an error when the reminder needs to be shown. Adding
  /// `try await TrialPeriodManager.shared.throwPurchaseReminderInIntentIfNecessary()` in the
  /// intent's `perform()` method is sufficient.
  public func throwPurchaseReminderInIntentIfNecessary() async throws
}

// MARK: TrialManager.CurrentSituation

public extension TrialManager {
  enum CurrentSituation: String {
    /// The app was installed less than 2 weeks ago.
    case inTrial

    /// Extended trial is enabled, the app was installed more than 2 weeks ago, but hasn't been
    /// licensed yet.
    case inExtendedTrial

    /// Extended trial is disabled, and the app was installed more than 2 weeks ago.
    case isUnlicensed

    /// The app is licensed, i.e. out of trial.
    case isLicensed

    // MARK: - Computed Properties

    public var description: String { get }
  }
}

// MARK: TrialManager.TrialPeriodError

public extension TrialManager {
  enum TrialPeriodError: LocalizedError, CustomLocalizedStringResourceConvertible {
    case purchaseReminder
    case invalidDayDifference(DateComponents)

    // MARK: - Computed Properties

    public var errorDescription: String? { get }

    public var localizedStringResource: LocalizedStringResource { get }
  }
}
```

## Module `URLExtensions`

````swift
import Foundation

public extension URL {
  // MARK: - Computed Properties

  /// Extracts query parameters from the URL into a dictionary
  /// - Returns: Dictionary of query parameters where keys are parameter names and values are parameter values
  /// - Note: If a query parameter has no value, an empty string is used
  /// - Note: Returns nil if the URL has no query parameters or is malformed
  /// - Example:
  /// ```swift
  /// let url = URL(string: "https://example.com?key1=value1&key2=value2")!
  /// let params = url.queryParameters
  /// // Result: ["key1": "value1", "key2": "value2"]
  /// ```
  var queryParameters: [String: String]? { get }

  // MARK: - Functions

  /// Adds or appends query parameters to the URL from a dictionary, ensuring all components are in
  /// Unicode Normalization Form C (NFC).
  ///
  /// This method first normalizes both the keys and values of the input dictionary to their
  /// precomposed Unicode representation (NFC) before creating `URLQueryItem`s. This ensures that
  /// characters like "ü" are represented by a single code point (`U+00FC`) rather than a combination
  /// of "u" and a combining diaeresis (`U+0075`, `U+0308`), leading to cleaner and more compatible
  /// URLs.
  ///
  /// - Parameter dictionary: A dictionary of key-value pairs to add as query parameters.
  /// - Returns: A new `URL` with the normalized and appended query parameters. Returns the original URL if the process fails.
  ///
  /// - Example:
  /// ```swift
  /// let url = URL(string: "https://example.com")!
  /// // Using a decomposed string for "ü" (u + ¨)
  /// let params = ["name": "Ru\u{0308}diger"]
  /// let newURL = url.addDictionaryAsQueryParameters(params)
  /// // Result: https://example.com?name=R%C3%BCdiger
  ///
  /// - Note: If the URL already has query parameters, the new ones are appended.
  func addDictionaryAsQueryParameters(_ dictionary: [String: String]) -> Self
}
````

## Module `ViewExtensions`

````swift
import SwiftUI

public extension View {
  /// Marks a text view as multiline by removing the line limit and allowing vertical growth
  /// - Returns: A view that can expand vertically to show all text content
  /// - Example:
  /// ```swift
  /// Text("Long content that may wrap to multiple lines")
  ///   .multilineText()
  /// ```
  func multilineText() -> some View

  /// Makes the view expand to fill the available horizontal space
  /// - Returns: A view that fills the entire available width
  /// - Example:
  /// ```swift
  /// Button("Wide Button") { }
  ///   .fullWidth()
  ///   .background(Color.blue)
  /// ```
  func fullWidth() -> some View

  /// Marks a text view as left-aligned and multiline, removes its line limit, and allows vertical
  /// growth, while using the max horizontal space.
  ///
  /// - Returns: A view that can expand vertically to show all text content
  /// - Example:
  /// ```swift
  /// Text("Long content that may wrap to multiple lines")
  ///   .fullWidthMultilineText()
  /// ```
  func fullWidthMultilineText() -> some View

  /// Embeds the view in a scroll view. Looted from Sindre Sorhus's Actions app.
  /// - Parameters:
  ///   - shouldEmbed: Whether the view should be embedded in a scroll view. Defaults to true.
  ///   - alignment: The alignment of the content within the scroll view. Defaults to center.
  /// - Returns: The view wrapped in a ScrollView if shouldEmbed is true, otherwise returns the original view
  /// - Example:
  /// ```swift
  /// VStack {
  ///   ForEach(items) { item in
  ///     ItemView(item)
  ///   }
  /// }
  /// .embedInScrollView(alignment: .top)
  /// ```
  @ViewBuilder
  func embedInScrollView(shouldEmbed: Bool = true, alignment: Alignment = .center) -> some View

  /// Performs the specified code block the first time the view this modifier is attached to appears.
  /// - Parameter block: The callback to be performed only the first time the view appears.
  ///
  ///  Created by Guilherme Rambo, https://github.com/insidegui/VirtualBuddy/blob/main/VirtualUI/Source/Components/OnAppearOnce.swift#L14
  func onAppearOnce(perform block: @escaping () -> Void) -> some View
}

// MARK: - OnAppearOnce

private struct OnAppearOnce: ViewModifier {
  // MARK: - Content Methods

  func body(content: Content) -> some View
}
````
