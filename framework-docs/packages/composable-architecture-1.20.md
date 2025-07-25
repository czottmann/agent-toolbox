# Composable Architecture

GitHub repo: https://github.com/pointfreeco/swift-composable-architecture

Documentation below generated from these files in the repo's directory structure:

└── ./
    └── Sources
        └── ComposableArchitecture
            └── Documentation.docc
                ├── Articles
                │   ├── Bindings.md
                │   ├── DependencyManagement.md
                │   ├── FAQ.md
                │   ├── GettingStarted.md
                │   ├── MigrationGuides.md
                │   ├── Navigation.md
                │   ├── ObservationBackport.md
                │   ├── Performance.md
                │   ├── SharingState.md
                │   ├── StackBasedNavigation.md
                │   ├── SwiftConcurrency.md
                │   ├── TestingTCA.md
                │   ├── TreeBasedNavigation.md
                │   └── WhatIsNavigation.md
                ├── Extensions
                │   ├── Action.md
                │   ├── Effect.md
                │   ├── EffectRun.md
                │   ├── EffectSend.md
                │   ├── IdentifiedAction.md
                │   ├── NavigationLinkState.md
                │   ├── ObservableState.md
                │   ├── Presents.md
                │   ├── Reduce.md
                │   ├── Reducer.md
                │   ├── ReducerBody.md
                │   ├── ReducerBuilder.md
                │   ├── ReducerForEach.md
                │   ├── ReducerlIfLet.md
                │   ├── ReducerlIfLetPresentation.md
                │   ├── ReducerMacro.md
                │   ├── Scope.md
                │   ├── State.md
                │   ├── Store.md
                │   ├── StoreDynamicMemberLookup.md
                │   ├── StoreState.md
                │   ├── SwiftUIBinding.md
                │   ├── SwiftUIBindingScopeForEach.md
                │   ├── SwiftUIBindingScopeIfLet.md
                │   ├── SwiftUIBindingSubscript.md
                │   ├── SwiftUIIntegration.md
                │   ├── SwitchStore.md
                │   ├── TaskResult.md
                │   ├── TestStore.md
                │   ├── TestStoreDependencies.md
                │   ├── TestStoreExhaustivity.md
                │   ├── UIKit.md
                │   ├── ViewStore.md
                │   ├── ViewStoreBinding.md
                │   ├── WithViewStore.md
                │   └── WithViewStoreInit.md
                └── ComposableArchitecture.md



---
File: /Sources/ComposableArchitecture/Documentation.docc/Articles/Bindings.md
---

# Working with SwiftUI bindings

Learn how to connect features written in the Composable Architecture to SwiftUI bindings.

## Overview

Many APIs in SwiftUI use bindings to set up two-way communication between your application's state
and a view. The Composable Architecture provides several tools for creating bindings that establish
such communication with your application's store.

### Ad hoc bindings

The simplest tool for creating bindings that communicate with your store is to create a dedicated
action that can change a piece of state in your feature. For example, a reducer may have a domain
that tracks if the user has enabled haptic feedback. First, it can define a boolean property on
state:

```swift
@Reducer
struct Settings {
  struct State: Equatable {
    var isHapticsEnabled = true
    // ...
  }

  // ...
}
```

Then, in order to allow the outside world to mutate this state, for example from a toggle, it must
define a corresponding action that can be sent updates:

```swift
@Reducer
struct Settings {
  struct State: Equatable { /* ... */ }

  enum Action { 
    case isHapticsEnabledChanged(Bool)
    // ...
  }

  // ...
}
```

When the reducer handles this action, it can update state accordingly:

```swift
@Reducer
struct Settings {
  struct State: Equatable { /* ... */ }
  enum Action { /* ... */ }

  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case let .isHapticsEnabledChanged(isEnabled):
        state.isHapticsEnabled = isEnabled
        return .none
      // ...
      }
    }
  }
}
```

And finally, in the view, we can derive a binding from the domain that allows a toggle to 
communicate with our Composable Architecture feature. First you must hold onto the store in a 
bindable way, which can be done using the `@Bindable` property wrapper from SwiftUI:

```swift
struct SettingsView: View {
  @Bindable var store: StoreOf<Settings>
  // ...
}
```

> Important: If you are targeting older Apple platforms (iOS 16, macOS 13, tvOS 16, watchOS 9, or
> less), then you must use our backport of the `@Bindable` property wrapper:
>
> ```diff
> -@Bindable var store: StoreOf<Settings>
> +@Perception.Bindable var store: StoreOf<Settings>
> ```

Once that is done you can derive a binding to a piece of state that sends an action when the 
binding is mutated:

```swift
var body: some View {
  Form {
    Toggle(
      "Haptic feedback",
      isOn: $store.isHapticsEnabled.sending(\.isHapticsEnabledChanged)
    )

    // ...
  }
}
```

### Binding actions and reducers

Deriving ad hoc bindings requires many manual steps that can feel tedious, especially for screens
with many controls driven by many bindings. Because of this, the Composable Architecture comes with
tools that can be applied to a reducer's domain and logic to make this easier.

For example, a settings screen may model its state with the following struct:

```swift
@Reducer
struct Settings {
  @ObservableState
  struct State {
    var digest = Digest.daily
    var displayName = ""
    var enableNotifications = false
    var isLoading = false
    var protectMyPosts = false
    var sendEmailNotifications = false
    var sendMobileNotifications = false
  }

  // ...
}
```

The majority of these fields should be editable by the view, and in the Composable Architecture this
means that each field requires a corresponding action that can be sent to the store. Typically this
comes in the form of an enum with a case per field:

```swift
@Reducer
struct Settings {
  @ObservableState
  struct State { /* ... */ }

  enum Action {
    case digestChanged(Digest)
    case displayNameChanged(String)
    case enableNotificationsChanged(Bool)
    case protectMyPostsChanged(Bool)
    case sendEmailNotificationsChanged(Bool)
    case sendMobileNotificationsChanged(Bool)
  }

  // ...
}
```

And we're not even done yet. In the reducer we must now handle each action, which simply replaces
the state at each field with a new value:

```swift
@Reducer
struct Settings {
  @ObservableState
  struct State { /* ... */ }
  enum Action { /* ... */ }

  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case let digestChanged(digest):
        state.digest = digest
        return .none

      case let displayNameChanged(displayName):
        state.displayName = displayName
        return .none

      case let enableNotificationsChanged(isOn):
        state.enableNotifications = isOn
        return .none

      case let protectMyPostsChanged(isOn):
        state.protectMyPosts = isOn
        return .none

      case let sendEmailNotificationsChanged(isOn):
        state.sendEmailNotifications = isOn
        return .none

      case let sendMobileNotificationsChanged(isOn):
        state.sendMobileNotifications = isOn
        return .none
      }
    }
  }
}
```

This is a _lot_ of boilerplate for something that should be simple. Luckily, we can dramatically
eliminate this boilerplate using ``BindableAction`` and ``BindingReducer``.

First, we can conform the action type to ``BindableAction`` by collapsing all of the individual,
field-mutating actions into a single case that holds a ``BindingAction`` that is generic over the
reducer's state:

```swift
@Reducer
struct Settings {
  @ObservableState
  struct State { /* ... */ }

  enum Action: BindableAction {
    case binding(BindingAction<State>)
  }

  // ...
}
```

And then, we can simplify the settings reducer by adding a ``BindingReducer`` that handles these
field mutations for us:

```swift
@Reducer
struct Settings {
  @ObservableState
  struct State { /* ... */ }
  enum Action: BindableAction { /* ... */ }

  var body: some Reducer<State, Action> {
    BindingReducer()
  }
}
```

Then in the view you must hold onto the store in a bindable manner, which can be done using the
`@Bindable` property wrapper (or the backported tool `@Perception.Bindable` if targeting older
Apple platforms):

```swift
struct SettingsView: View {
  @Bindable var store: StoreOf<Settings>
  // ...
}
```

Then bindings can be derived from the store using familiar `$` syntax:

```swift
TextField("Display name", text: $store.displayName)
Toggle("Notifications", text: $store.enableNotifications)
// ...
```

Should you need to layer additional functionality over these bindings, your can pattern match the
action for a given key path in the reducer:

```swift
var body: some Reducer<State, Action> {
  BindingReducer()

  Reduce { state, action in
    switch action
    case .binding(\.displayName):
      // Validate display name
  
    case .binding(\.enableNotifications):
      // Return an effect to request authorization from UNUserNotificationCenter
  
    // ...
    }
  }
}
```

Or you can apply ``Reducer/onChange(of:_:)`` to the ``BindingReducer`` to react to changes to
particular fields:

```swift
var body: some Reducer<State, Action> {
  BindingReducer()
    .onChange(of: \.displayName) { oldValue, newValue in
      // Validate display name
    }
    .onChange(of: \.enableNotifications) { oldValue, newValue in
      // Return an authorization request effect
    }

  // ...
}
```

Binding actions can also be tested in much the same way regular actions are tested. Rather than send
a specific action describing how a binding changed, such as `.displayNameChanged("Blob")`, you will
send a ``BindingAction`` action that describes which key path is being set to what value, such as
`\.displayName, "Blob"`:

```swift
let store = TestStore(initialState: Settings.State()) {
  Settings()
}

store.send(\.binding.displayName, "Blob") {
  $0.displayName = "Blob"
}
store.send(\.binding.protectMyPosts, true) {
  $0.protectMyPosts = true
)
```



---
File: /Sources/ComposableArchitecture/Documentation.docc/Articles/DependencyManagement.md
---

# Dependencies

Learn how to register dependencies with the library so that they can be immediately accessible from
any reducer.

## Overview

Dependencies in an application are the types and functions that need to interact with outside 
systems that you do not control. Classic examples of this are API clients that make network requests
to servers, but also seemingly innocuous things such as `UUID` and `Date` initializers, and even
clocks, can be thought of as dependencies.

By controlling the dependencies our features need to do their job we gain the ability to completely
alter the execution context a feature runs in. This means in tests and Xcode previews you can 
provide a mock version of an API client that immediately returns some stubbed data rather than 
making a live network request to a server.

> Note: The dependency management system in the Composable Architecture is driven off of our 
> [Dependencies][swift-dependencies-gh] library. That repository has extensive 
> [documentation][swift-deps-docs] and articles, and we highly recommend you familiarize yourself
> with all of that content to best leverage dependencies.

## Overriding dependencies

It is possible to change the dependencies for just one particular reducer inside a larger composed
reducer. This can be handy when running a feature in a more controlled environment where it may not 
be appropriate to communicate with the outside world.

For example, suppose you want to teach users how to use your feature through an onboarding
experience. In such an experience it may not be appropriate for the user's actions to cause
data to be written to disk, or user defaults to be written, or any number of things. It would be
better to use mock versions of those dependencies so that the user can interact with your feature
in a fully controlled environment.

To do this you can use the ``Reducer/dependency(_:_:)`` method to override a reducer's
dependency with another value:

```swift
@Reducer
struct Onboarding {
  var body: some Reducer<State, Action> {
    Reduce { state, action in 
      // Additional onboarding logic
    }
    Feature()
      .dependency(\.userDefaults, .mock)
      .dependency(\.database, .mock)
  }
}
```

This will cause the `Feature` reducer to use a mock user defaults and database dependency, as well
as any reducer `Feature` uses under the hood, _and_ any effects produced by `Feature`.

[swift-identified-collections]: https://github.com/pointfreeco/swift-identified-collections
[environment-values-docs]: https://developer.apple.com/documentation/swiftui/environmentvalues
[xctest-dynamic-overlay-gh]: http://github.com/pointfreeco/xctest-dynamic-overlay
[swift-dependencies-gh]: http://github.com/pointfreeco/swift-dependencies
[swift-deps-docs]: https://pointfreeco.github.io/swift-dependencies/main/documentation/dependencies/



---
File: /Sources/ComposableArchitecture/Documentation.docc/Articles/FAQ.md
---

# Frequently asked questions

A collection of some of the most common questions and comments people have concerning the library.

## Overview

We often see articles and discussions online concerning the Composable Architecture (TCA for short) that are outdated or slightly misinformed. Often these articles and discussions focus solely on “cons” of using TCA without giving time to what “pros” are unlocked by embracing any “cons” should they still exist in the latest version of TCA. 

However, focusing only on “cons” is missing the forest from the trees. As an analogy, one could write a scathing article about the “cons” of value types in Swift, including the fact that they lack a stable identity like classes do. But that would be missing one of their greatest strengths, which is their ability to be copied and compared in a lightweight way!

App architecture is filled with trade-offs, and it is important to think deeply about what one gains and loses with each choice they make. We have collected some of the most common issues brought up here in order to dispel some myths:

* [Should TCA be used for every kind of app?](#Should-TCA-be-used-for-every-kind-of-app)
* [Should I adopt a 3rd party library for my app’s architecture?](#Should-I-adopt-a-3rd-party-library-for-my-apps-architecture)
* [Does TCA go against the grain of SwiftUI?](#Does-TCA-go-against-the-grain-of-SwiftUI)
* [Isn't TCA just a port of Redux? Is there a need for a library?](#Isnt-TCA-just-a-port-of-Redux-Is-there-a-need-for-a-library)
* [Do features built in TCA have a lot of boilerplate?](#Do-features-built-in-TCA-have-a-lot-of-boilerplate)
* [Isn't maintaining a separate enum of “actions” unnecessary work?](#Isnt-maintaining-a-separate-enum-of-actions-unnecessary-work)
* [Are TCA features inefficient because all of an app’s state is held in one massive type?](#Are-TCA-features-inefficient-because-all-of-an-apps-state-is-held-in-one-massive-type)
  * [Does that cause views to over-render?](#Does-that-cause-views-to-over-render)
  * [Are large value types expensive to mutate?](#Are-large-value-types-expensive-to-mutate)
  * [Can large value types cause stack overflows?](#Can-large-value-types-cause-stack-overflows)
* [Don't TCA features have excessive “ping-ponging”?](#Dont-TCA-features-have-excessive-ping-ponging)
* [If features are built with value types, doesn't that mean they cannot share state since value types are copied?](#If-features-are-built-with-value-types-doesnt-that-mean-they-cannot-share-state-since-value-types-are-copied)
* [Do I need a Point-Free subscription to learn or use TCA?](#Do-I-need-a-Point-Free-subscription-to-learn-or-use-TCA)
* [Do I need to be familiar with "functional programming" to use TCA?](#Do-I-need-to-be-familiar-with-functional-programming-to-use-TCA)

### Should TCA be used for every kind of app?

We do not recommend people use TCA when they are first learning Swift or SwiftUI. TCA is not a substitute or replacement for SwiftUI, but rather is meant to be paired with SwiftUI. You will need to be familiar with all of SwiftUI's standard concepts to wield TCA correctly.

We also don't think TCA really shines when building simple “reader” apps that mostly load JSON from the network and display it. Such apps don’t tend to have much in the way of nuanced logic or complex side effects, and so the benefits of TCA aren’t as clear.

In general it can be fine to start a project with vanilla SwiftUI (with a concentration on concise domain modeling), and then transition to TCA later if there is a need for any of its powers.

### Should I adopt a 3rd party library for my app’s architecture?

Adopting a 3rd party library is a big decision that should be had by you and your team after thoughtful discussion and consideration. We cannot make that decision for you. 🙂

But the "not invented here" mentality cannot be the _sole_ reason to not adopt a library. If a library's core tenets align with your priorities for building your app, then adopting a library can be a sensible choice. It would be better to coalesce on a well-defined set of tools with a consistent history of maintenance and a strong community than to glue together many "tips and tricks" found in blog posts scattered around the internet. 

Blog posts tend to be written from the perspective of something that was interesting and helpful in a particular moment, but it doesn't necessarily stand the test of time. How many blog posts have been vetted for the many real world edge cases one actually encouters in app development? How many blog post techniques are still used by their authors 4 years later? How many blog posts have follow-up retrospectives describing how the technique worked in practice and evolved over time?

So, in comparison, we do not feel the adoption of a 3rd party library is significantly riskier than adopting ideas from blog posts, but it is up to you and your team to figure out your priorities for your application.

### Does TCA go against the grain of SwiftUI?

We actually feel that TCA complements SwiftUI quite well! The design of TCA has been heavily inspired by SwiftUI, and so you will find a lot of similarities:

* TCA features can minimally and implicitly observe minimal state changes just as in SwiftUI, but one uses the [`@ObservableState`][observation-state-docs] macro to do so, which is like Swift's `@Observable`. We even [back-ported][observation-backport-article] Swift's observation tools so that they could be used with iOS 16 and earlier.
* One composes TCA features together much like one composes SwiftUI features, by implementing a [`body`][reducer-body-docs] property and using result builder syntax.
* Dependencies are declared using the [`@Dependency`][dependency-management-article] property wrapper, which behaves much like SwiftUI's `@Environment` property wrapper, but it works outside of views.
* The library's [state sharing][sharing-state-article] tools work a lot like SwiftUI's `@Binding` tool, but it works outside of views and it is 100% testable.

We also feel that often TCA allows one to even more fully embrace some of the super powers of SwiftUI:

* TCA apps are allowed to use Swift's observation tools with value types, whereas vanilla SwiftUI is limited to only reference types. The author of the observation proposal even intended for `@Observable` to work with value types but ultimately had to abandon it due to limitations of Swift. But we are able to overcome those limitations thanks to the [`Store`][store-docs] type.
* Navigation in TCA uses all of the same tools from vanilla SwiftUI, such as `sheet(item:)`, `popover(item:)`, and even `NavigationStack`. But we also provide tools for [driving navigation][navigation-article] from more concise domains, such as enums and optionals.
* TCA allows one to “hot swap” a feature’s logic and behavior for alternate versions, with essentially no extra work. For example when showing a “placeholder” version of a UI using SwiftUI’s `redacted` API, you can [swap the feature’s logic](https://www.pointfree.co/collections/swiftui/redactions) for an “inert” version that does nothing when interacted with.
* TCA features tend to be easier to view in Xcode previews because [dependencies are controlled][dependency-management-article] from the beginning. There are many dependencies that don't work in previews (_e.g._ location managers), and some that are dangerous to use in previews (_e.g._ analytics clients), but one does not need to worry about that when controlling dependencies properly.
* TCA features can be fully tested, including how dependencies execute and feed data back into the system, all without needing to run a UI test.

And the more familiar you are with SwiftUI and its patterns, the better you will be able to leverage the Composable Architecture. We’ve never said that you must abandon SwiftUI in order to use TCA, and in fact we think the opposite is true!

### Isn't TCA just a port of Redux? Is there a need for a library?

While TCA certainly shares some ideas and terminology with Redux, the two libraries are quite different. First, Redux is a JavaScript library, not a Swift library, and it was never meant to be an opinionated and cohesive solution to many app architecture problems. It focused on a particular problem, and stuck with it.

TCA broadened the focus to include tools for a lot of common problems one runs into with app architecture, such as:

* …tools for concise domain modeling.
* Allowing one to embrace value types fully instead of reference types.
* A full suite of tools are provided for integrating with Apple’s platforms (SwiftUI, UIKit, AppKit, _etc._), including [navigation][navigation-article].
* A powerful [dependency management system][dependency-management-article] for controlling and propagating dependencies throughout your app.
* A [testing tool][testing-article] that makes it possible to exhaustively test how your feature behaves with user actions, including how side effects execute and feed data back into the system.
* …and more!

Redux does not provide tools itself for any of the above problems.

And you can certainly opt to build your own TCA-inspired library instead of depending directly on TCA, and in fact many large companies do just that. But it is also worth considering if it is worth losing out on the continual development and improvements TCA makes over the years. With each major release of iOS we have made sure to keep TCA up-to-date, including concurrency tools, `NavigationStack`, and [Swift 5.9’s observation tools][migration-1.7-article] (of which we even [back-ported][observation-backport-article] so that they could be used all the way back to iOS 13), [state sharing][sharing-state-article] tools, and more. And further you will be missing out on the community of thousands of developers that use TCA and frequent our GitHub discussions and [Slack](http://pointfree.co/slack-invite).

### Do features built in TCA have a lot of boilerplate?

Often people complain of boilerplate in TCA, especially with regards a legacy concept known as “view stores”. Those were objects that allowed views to observe the minimal amount of state in a view, and they were [deprecated a long time ago][migration-1.7-article] after Swift 5.9 released with the Observation framework. Features built with modern TCA do not need to worry about view stores and instead can access state directly off of stores and the view will observe the minimal amount of state, just as in vanilla SwiftUI.

In our experience, a standard TCA feature should not require very many more lines of code than an equivalent vanilla SwiftUI feature, and if you write tests or integrate features together using the tools TCA provides, it should require much *less* code than the equivalent vanilla code.

### Isn't maintaining a separate enum of “actions” unnecessary work?

Modeling user actions with an enum rather than methods defined on some object is certainly a big decision to make, and some people find it off-putting, but it wasn’t made just for the fun of it. There are massive benefits one gains from having a data description of every action in your application:

- It fully decouples the logic of your feature from the view of your feature, even more than a dedicated `@Observable` model class can. You can write a reducer that wraps an existing reducer and “tweaks” the underlying reducer’s logic in anyway it sees fit. 

  For example, in our open source word game, [isowords](http://github.com/pointfreeco/isowords), we have an onboarding feature that runs the game feature inside, but with additional logic layered on. Since each action in the game has a simple enum description we are able to intercept any action and execute some additional logic. For example, when the user submits a word during onboarding we can inspect which word they submitted as well as which step of the onboarding process they are on in order to figure out if they should proceed to the next step:

  ```swift
  case .game(.submitButtonTapped):
  switch state.step {
  case
    .step5_SubmitGame where state.game.selectedWordString == "GAME",
    .step8_FindCubes where state.game.selectedWordString == "CUBES",
    .step12_CubeIsShaking where state.game.selectedWordString == "REMOVE",
    .step16_FindAnyWord where dictionary.contains(state.game.selectedWordString, .en):

  state.step.next()
  ```

  This is quite complex logic that was easy to implement thanks to the enum description of actions. And on top of that, it was all 100% unit testable.

- Having a data type of all actions in your feature makes it possible to write powerful debugging tools. For example, the `_printChanges()` reducer operator gives you insight into every action that enters the system, and prints a nicely formatted message showing exactly how state changed when the action was processed:

  ```
  received action:
    AppFeature.Action.syncUpsList(.addSyncUpButtonTapped)
    AppFeature.State(
      _path: [:],
      _syncUpsList: SyncUpsList.State(
  -     _destination: nil,
  +     _destination: .add(
  +       SyncUpForm.State(
  +         …
  +       )
  +     ),
        _syncUps: #1 […]
      )
    )
  ```

  You can also create a tool, [`signpost`][signpost-docs], that automatically instruments every action of your feature with signposts to find any potential performance problems in your app. And 3rd parties have built their own tools for tracking and instrumenting features, all thanks to the fact that there is a data representation of every action in the app.

- Having a data type of all actions in your feature also makes it possible to write exhaustive tests on every aspect of your feature. Using something known as a [`TestStore`][test-store-docs] you can emulate user flows by sending it actions and asserting how state changes each step of the way. And further, you must also assert on how effects feed their data back into the system by asserting on actions received:

  ```swift
  store.send(.refreshButtonTapped) {
    $0.isLoading = true
  }
  store.receive(\.userResponse) {
    $0.currentUser = User(id: 42, name: "Blob")
    $0.isLoading = false
  }
  ```

  Again this is only possible thanks to the data type of all actions in the feature. See  for more information on testing in TCA.

<!-- TODO: Navigation tools? -->

### Are TCA features inefficient because all of an app’s state is held in one massive type?

This comes up often, but this misunderstands how real world features are actually modeled in practice. An app built with TCA does not literally hold onto the state of every possible screen of the app all at once. In reality most features of an app are not presented at once, but rather incrementally. Features are presented in sheets, drill-downs and other forms of navigation, and those forms of navigation are gated by optional state. This means if a feature is not presented, then its state is `nil`, and hence not represented in the app state.

* ##### Does that cause views to over-render?

  In reality views re-compute the minimal number of times based off of what state is accessed in the view, just as it does in vanilla SwiftUI with the `@Observable` macro. But because we [back-ported][observation-backport-article] the observation framework to iOS 13 you can make use of the tools today, and not wait until you can drop iOS 16 support.

<!-- [ ] Other redux libraries-->

* ##### Are large value types expensive to mutate?

  This doesn’t really seem to be the case with in-place mutation in Swift. Mutation _via_ `inout` has been quite efficient from our testing, and there’s a chance that Swift’s new borrowing and consuming tools will allow us to make it even more efficient.

* ##### Can large value types cause stack overflows?

  While it is true that large value types can overflow the stack, in practice this does not really happen if you are using the navigation tools of the library. The navigation tools insert a heap allocated, copy-on-write wrapper at each presentation node of your app’s state. So if feature A can present feature B, then feature A’s state does not literally contain feature B’s state.

### Don't TCA features have excessive “ping-ponging"?

There have been complaints of action “ping-ponging”, where one wants to perform multiple effects and so has to send multiple actions:

```swift
case .refreshButtonTapped:
  return .run { send in 
    await send(.userResponse(apiClient.fetchCurrentUser()))
  }
case let .userResponse(response):
  return .run { send in 
    await send(.moviesResponse(apiClient.fetchMovies(userID: response.id)))
  }
case let .moviesResponse(response):
  // Do something with response
```

However, this is really only necessary if you specifically need to intermingle state mutations *and* async operations. If you only need to execute multiple async operations with no state mutations in between, then all of that work can go into a single effect:

```swift
case .refreshButtonTapped:
  return .run { send in 
    let userResponse = await apiClient.fetchCurrentUser()    
    let moviesResponse = await apiClient.fetchMovies(userID: userResponse.id)
    await send(.moviesResponse(moviesResponse))
  }
```

And if you really do need to perform state mutations between each of these asynchronous operations then you will incur a bit of ping-ponging. But, [as mentioned above](#Maintaining-a-separate-enum-of-actions-is-unnecessary-work), there are great benefits to having a data description of actions, such as an extreme decoupling of logic from the view, powerful debugging tools, the ability to test every aspect of your feature, and more. If you were to try to reproduce those abilities in a non-TCA app you would be inevitably led to the same ping-ponging.

<!-- TODO: We should be able to completely eliminate ping-ponging in TCA 2.0 -->

### If features are built with value types, doesn't that mean they cannot share state since value types are copied?

This *used* to be true, but in [version 1.10][migration-1.10-article] of the library we released all new [state sharing][sharing-state-article] tools that allow you to easily share state between multiple features, and even persist state to external systems, such as user defaults and the file system. 

Further, one of the dangers of introducing shared state to an app, any app, is that it can make it difficult to understand since it introduces reference semantics into your domain. But we put in extra work to make sure that shared state remains 100% testable, and even _exhaustively_ testable, which makes it far easier to keep track of how shared state is mutated in your features.

### Do I need a Point-Free subscription to learn or use TCA?

While we do release a lot of material on our website that is subscriber-only, we also release a _ton_ of material completely for free. The [documentation][tca-docs] for TCA contains numerous articles and tutorials, including a [massive tutorial][sync-ups-tutorial] building a complex app from scratch that demonstrates domain modeling, navigation, dependencies, testing, and more.

### Do I need to be familiar with "functional programming" to use TCA?

TCA does not describe itself as a "functional programming" library, and never has. At the end of the day Swift is not a functional language, and so there is no way to force functional patterns at  compile time, such as "pure" functions. And so familiarity of "functional programming" is not necessary.

However, certain concepts of functional programming languages are quite important to us, and we have used those concepts to guide aspects of the library. For example, a core tenet of the library is to build as much of your domain using value types, which are easy to understand and behaviorless, as opposed to reference types, which allow for "action at a distance". The library also values  separating side effects from pure logic transformations. This allows for great testability, 
including how side effects execute and feed data back into the system.

However, one does not need to have any prior experience with these concepts. The ideas are imbued into the library and documentation, and so you will gain experience by simply following our materials and demo apps.

[observation-backport-article]: <doc:ObservationBackport>
[dependency-management-article]: <doc:DependencyManagement>
[sharing-state-article]: <doc:SharingState>
[navigation-article]: <doc:Navigation>
[testing-article]: <doc:TestingTCA>
[migration-1.7-article]: <doc:MigratingTo1.7>
[migration-1.10-article]: <doc:MigratingTo1.10>
[sync-ups-tutorial]: <doc:BuildingSyncUps>
[tca-docs]: <doc:ComposableArchitecture> 
[observation-state-docs]: <doc:ObservableState()>
[reducer-body-docs]: <doc:Reducer/body-20w8t>
[store-docs]: <doc:Store>
[signpost-docs]: <doc:Reducer/signpost(_:log:)>
[test-store-docs]: <doc:TestStore>



---
File: /Sources/ComposableArchitecture/Documentation.docc/Articles/GettingStarted.md
---

# Getting started

Learn how to integrate the Composable Architecture into your project and write your first 
application.

## Adding the Composable Architecture as a dependency

To use the Composable Architecture in a SwiftPM project, add it to the dependencies of your
Package.swift and specify the `ComposableArchitecture` product in any targets that need access to 
the library:

```swift
let package = Package(
  dependencies: [
    .package(
      url: "https://github.com/pointfreeco/swift-composable-architecture",
      from: "1.0.0"
    ),
  ],
  targets: [
    .target(
      name: "<target-name>",
      dependencies: [
        .product(
          name: "ComposableArchitecture",
          package: "swift-composable-architecture"
        )
      ]
    )
  ]
)
```

## Writing your first feature

> Note: For a step-by-step interactive tutorial, be sure to check out 
> <doc:MeetComposableArchitecture>.

To build a feature using the Composable Architecture you define some types and values that model
your domain:

* **State**: A type that describes the data your feature needs to perform its logic and render its
    UI.
* **Action**: A type that represents all of the actions that can happen in your feature, such as
    user actions, notifications, event sources and more.
* **Reducer**: A function that describes how to evolve the current state of the app to the next
    state given an action. The reducer is also responsible for returning any effects that should be
    run, such as API requests, which can be done by returning an `Effect` value.
* **Store**: The runtime that actually drives your feature. You send all user actions to the store
    so that the store can run the reducer and effects, and you can observe state changes in the
    store so that you can update UI.

The benefits of doing this are that you will instantly unlock testability of your feature, and you
will be able to break large, complex features into smaller domains that can be glued together.

As a basic example, consider a UI that shows a number along with "+" and "−" buttons that increment 
and decrement the number. To make things interesting, suppose there is also a button that when 
tapped makes an API request to fetch a random fact about that number and displays it in the view.

To implement this feature we create a new type that will house the domain and behavior of the 
feature, and it will be annotated with the [`@Reducer`](<doc:Reducer()>) macro:

```swift
import ComposableArchitecture

@Reducer
struct Feature {
}
```

In here we need to define a type for the feature's state, which consists of an integer for the 
current count, as well as an optional string that represents the fact being presented:

```swift
@Reducer
struct Feature {
  @ObservableState
  struct State: Equatable {
    var count = 0
    var numberFact: String?
  }
}
```

> Note: We've applied the `@ObservableState` macro to `State` in order to take advantage of the
> observation tools in the library.

We also need to define a type for the feature's actions. There are the obvious actions, such as 
tapping the decrement button, increment button, or fact button. But there are also some slightly 
non-obvious ones, such as the action that occurs when we receive a response from the fact API 
request:

```swift
@Reducer
struct Feature {
  @ObservableState
  struct State: Equatable { /* ... */ }
  enum Action {
    case decrementButtonTapped
    case incrementButtonTapped
    case numberFactButtonTapped
    case numberFactResponse(String)
  }
}
```

And then we implement the `body` property, which is responsible for composing the actual logic and 
behavior for the feature. In it we can use the `Reduce` reducer to describe how to change the
current state to the next state, and what effects need to be executed. Some actions don't need to
execute effects, and they can return `.none` to represent that:

```swift
@Reducer
struct Feature {
  @ObservableState
  struct State: Equatable { /* ... */ }
  enum Action { /* ... */ }

  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .decrementButtonTapped:
        state.count -= 1
        return .none

      case .incrementButtonTapped:
        state.count += 1
        return .none

      case .numberFactButtonTapped:
        return .run { [count = state.count] send in
          let (data, _) = try await URLSession.shared.data(
            from: URL(string: "http://numbersapi.com/\(count)/trivia")!
          )
          await send(
            .numberFactResponse(String(decoding: data, as: UTF8.self))
          )
        }

      case let .numberFactResponse(fact):
        state.numberFact = fact
        return .none
      }
    }
  }
}
```

And then finally we define the view that displays the feature. It holds onto a `StoreOf<Feature>` 
so that it can observe all changes to the state and re-render, and we can send all user actions to 
the store so that state changes:

```swift
struct FeatureView: View {
  let store: StoreOf<Feature>

  var body: some View {
    Form {
      Section {
        Text("\(store.count)")
        Button("Decrement") { store.send(.decrementButtonTapped) }
        Button("Increment") { store.send(.incrementButtonTapped) }
      }

      Section {
        Button("Number fact") { store.send(.numberFactButtonTapped) }
      }
      
      if let fact = store.numberFact {
        Text(fact)
      }
    }
  }
}
```

It is also straightforward to have a UIKit controller driven off of this store. You can observe
state changes in the store in `viewDidLoad`, and then populate the UI components with data from
the store. The code is a bit longer than the SwiftUI version, so we have collapsed it here:

```swift
class FeatureViewController: UIViewController {
  let store: StoreOf<Feature>

  init(store: StoreOf<Feature>) {
    self.store = store
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    let countLabel = UILabel()
    let decrementButton = UIButton()
    let incrementButton = UIButton()
    let factLabel = UILabel()
    
    // Omitted: Add subviews and set up constraints...
    
    observe { [weak self] in
      guard let self 
      else { return }
      
      countLabel.text = "\(self.store.count)"
      factLabel.text = self.store.numberFact
    }
  }

  @objc private func incrementButtonTapped() {
    self.store.send(.incrementButtonTapped)
  }
  @objc private func decrementButtonTapped() {
    self.store.send(.decrementButtonTapped)
  }
  @objc private func factButtonTapped() {
    self.store.send(.numberFactButtonTapped)
  }
}
```

Once we are ready to display this view, for example in the app's entry point, we can construct a 
store. This can be done by specifying the initial state to start the application in, as well as 
the reducer that will power the application:

```swift
import ComposableArchitecture

@main
struct MyApp: App {
  var body: some Scene {
    WindowGroup {
      FeatureView(
        store: Store(initialState: Feature.State()) {
          Feature()
        }
      )
    }
  }
}
```

And that is enough to get something on the screen to play around with. It's definitely a few more 
steps than if you were to do this in a vanilla SwiftUI way, but there are a few benefits. It gives 
us a consistent manner to apply state mutations, instead of scattering logic in some observable 
objects and in various action closures of UI components. It also gives us a concise way of 
expressing side effects. And we can immediately test this logic, including the effects, without 
doing much additional work.

## Testing your feature

> Note: For more in-depth information on testing, see the dedicated <doc:TestingTCA> 
article.

To test use a `TestStore`, which can be created with the same information as the `Store`, but it 
does extra work to allow you to assert how your feature evolves as actions are sent:

```swift
@Test
func basics() async {
  let store = TestStore(initialState: Feature.State()) {
    Feature()
  }
}
```

Once the test store is created we can use it to make an assertion of an entire user flow of steps. 
Each step of the way we need to prove that state changed how we expect. For example, we can 
simulate the user flow of tapping on the increment and decrement buttons:

```swift
// Test that tapping on the increment/decrement buttons changes the count
await store.send(.incrementButtonTapped) {
  $0.count = 1
}
await store.send(.decrementButtonTapped) {
  $0.count = 0
}
```

Further, if a step causes an effect to be executed, which feeds data back into the store, we must 
assert on that. For example, if we simulate the user tapping on the fact button we expect to 
receive a fact response back with the fact, which then causes the `numberFact` state to be 
populated:

```swift
await store.send(.numberFactButtonTapped)

await store.receive(\.numberFactResponse) {
  $0.numberFact = ???
}
```

However, how do we know what fact is going to be sent back to us?

Currently our reducer is using an effect that reaches out into the real world to hit an API server, 
and that means we have no way to control its behavior. We are at the whims of our internet 
connectivity and the availability of the API server in order to write this test.

It would be better for this dependency to be passed to the reducer so that we can use a live 
dependency when running the application on a device, but use a mocked dependency for tests. We can 
do this by adding a property to the `Feature` reducer:

```swift
@Reducer
struct Feature {
  let numberFact: (Int) async throws -> String
  // ...
}
```

Then we can use it in the `reduce` implementation:

```swift
case .numberFactButtonTapped:
  return .run { [count = state.count] send in 
    let fact = try await self.numberFact(count)
    await send(.numberFactResponse(fact))
  }
```

And in the entry point of the application we can provide a version of the dependency that actually 
interacts with the real world API server:

```swift
@main
struct MyApp: App {
  var body: some Scene {
    WindowGroup {
      FeatureView(
        store: Store(initialState: Feature.State()) {
          Feature(
            numberFact: { number in
              let (data, _) = try await URLSession.shared.data(
                from: URL(string: "http://numbersapi.com/\(number)")!
              )
              return String(decoding: data, as: UTF8.self)
            }
          )
        }
      )
    }
  }
}
```

But in tests we can use a mock dependency that immediately returns a deterministic, predictable 
fact: 

```swift
@Test
func basics() async {
  let store = TestStore(initialState: Feature.State()) {
    Feature(numberFact: { "\($0) is a good number Brent" })
  }
}
```

With that little bit of upfront work we can finish the test by simulating the user tapping on the 
fact button, and then receiving the response from the dependency to present the fact:

```swift
await store.send(.numberFactButtonTapped)

await store.receive(\.numberFactResponse) {
  $0.numberFact = "0 is a good number Brent"
}
```

We can also improve the ergonomics of using the `numberFact` dependency in our application. Over 
time the application may evolve into many features, and some of those features may also want access 
to `numberFact`, and explicitly passing it through all layers can get annoying. There is a process 
you can follow to “register” dependencies with the library, making them instantly available to any 
layer in the application.

> Note: For more in-depth information on dependency management, see the dedicated
<doc:DependencyManagement> article. 

We can start by wrapping the number fact functionality in a new type:

```swift
struct NumberFactClient {
  var fetch: (Int) async throws -> String
}
```

And then registering that type with the dependency management system by conforming the client to
the `DependencyKey` protocol, which requires you to specify the live value to use when running the
application in simulators or devices:

```swift
extension NumberFactClient: DependencyKey {
  static let liveValue = Self(
    fetch: { number in
      let (data, _) = try await URLSession.shared
        .data(from: URL(string: "http://numbersapi.com/\(number)")!
      )
      return String(decoding: data, as: UTF8.self)
    }
  )
}

extension DependencyValues {
  var numberFact: NumberFactClient {
    get { self[NumberFactClient.self] }
    set { self[NumberFactClient.self] = newValue }
  }
}
```

With that little bit of upfront work done you can instantly start making use of the dependency in 
any feature by using the `@Dependency` property wrapper:

```diff
 @Reducer
 struct Feature {
-  let numberFact: (Int) async throws -> String
+  @Dependency(\.numberFact) var numberFact
   
   …

-  try await self.numberFact(count)
+  try await self.numberFact.fetch(count)
 }
```

This code works exactly as it did before, but you no longer have to explicitly pass the dependency 
when constructing the feature's reducer. When running the app in previews, the simulator or on a 
device, the live dependency will be provided to the reducer, and in tests the test dependency will 
be provided.

This means the entry point to the application no longer needs to construct dependencies:

```swift
@main
struct MyApp: App {
  var body: some Scene {
    WindowGroup {
      FeatureView(
        store: Store(initialState: Feature.State()) {
          Feature()
        }
      )
    }
  }
}
```

And the test store can be constructed without specifying any dependencies, but you can still 
override any dependency you need to for the purpose of the test:

```swift
let store = TestStore(initialState: Feature.State()) {
  Feature()
} withDependencies: {
  $0.numberFact.fetch = { "\($0) is a good number Brent" }
}

// ...
```

That is the basics of building and testing a feature in the Composable Architecture. There are 
_a lot_ more things to be explored. Be sure to check out the <doc:MeetComposableArchitecture> 
tutorial, as well as dedicated articles on <doc:DependencyManagement>, <doc:TestingTCA>, 
<doc:Navigation>, <doc:Performance>, and more. Also, the [Examples][examples] directory has 
a bunch of projects to explore to see more advanced usages.

[examples]: https://github.com/pointfreeco/swift-composable-architecture/tree/main/Examples



---
File: /Sources/ComposableArchitecture/Documentation.docc/Articles/MigrationGuides.md
---

# Migration guides

Learn how to upgrade your application to the newest version of the Composable Architecture.

## Overview

The Composable Architecture is under constant development, and we are always looking for ways to
simplify the library, and make it more powerful. As such, we often need to deprecate certain APIs
in favor of newer ones. We recommend people update their code as quickly as possible to the newest
APIs, and these guides contain tips to do so.

> Important: Before following any particular migration guide be sure you have followed all the 
> preceding migration guides.

## Topics

- <doc:MigratingTo1.19>
- <doc:MigratingTo1.18>
- <doc:MigratingTo1.17.1>
- <doc:MigratingTo1.17>
- <doc:MigratingTo1.16>
- <doc:MigratingTo1.15>
- <doc:MigratingTo1.14>
- <doc:MigratingTo1.13>
- <doc:MigratingTo1.12>
- <doc:MigratingTo1.11>
- <doc:MigratingTo1.10>
- <doc:MigratingTo1.9>
- <doc:MigratingTo1.8>
- <doc:MigratingTo1.7>
- <doc:MigratingTo1.6>
- <doc:MigratingTo1.5>
- <doc:MigratingTo1.4>



---
File: /Sources/ComposableArchitecture/Documentation.docc/Articles/Navigation.md
---

# Navigation

Learn how to use the navigation tools in the library, including how to best model your domains, how
to integrate features in the reducer and view layers, and how to write tests.

## Overview

State-driven navigation is a powerful concept in application development, but can be tricky to
master. The Composable Architecture provides the tools necessary to model your domains as concisely
as possible and drive navigation from state, but there are a few concepts to learn in order to best
use these tools.

## Topics

### Essentials

- <doc:WhatIsNavigation>

### Tree-based navigation

- <doc:TreeBasedNavigation>
- ``Presents()``
- ``PresentationAction``
- ``Reducer/ifLet(_:action:destination:fileID:filePath:line:column:)-4ub6q``

### Stack-based navigation

- <doc:StackBasedNavigation>
- ``StackState``
- ``StackAction``
- ``StackActionOf``
- ``StackElementID``
- ``Reducer/forEach(_:action:destination:fileID:filePath:line:column:)-9svqb``

### Dismissal

- ``DismissEffect``
- ``Dependencies/DependencyValues/dismiss``
- ``Dependencies/DependencyValues/isPresented``



---
File: /Sources/ComposableArchitecture/Documentation.docc/Articles/ObservationBackport.md
---

# Observation backport

Learn how the Observation framework from Swift 5.9 was backported to support iOS 16 and earlier,
as well as the caveats of using the backported tools.

## Overview

With version 1.7 of the Composable Architecture we have introduced support for Swift 5.9's
observation tools, _and_ we have backported those tools to work in iOS 13 and later. Using the
observation tools in pre-iOS 17 does require a few additional steps and there are some gotchas to be
aware of.

## The Perception framework

The Composable Architecture comes with a framework known as Perception, which is our backport of
Swift 5.9's Observation to iOS 13, macOS 12, tvOS 13 and watchOS 6. For all of the tools in the
Observation framework there is a corresponding tool in Perception.

For example, instead of the `@Observable` macro, there is the `@Perceptible` macro:

```swift
@Perceptible
class CounterModel {
  var count = 0
}
```

However, in order for a view to properly observe changes to a "perceptible" model, you must
remember to wrap the contents of your view in the `WithPerceptionTracking` view:

```swift
struct CounterView: View {
  let model = CounterModel()

  var body: some View {
    WithPerceptionTracking {
      Form {
        Text(self.model.count.description)
        Button("Decrement") { self.model.count -= 1 }
        Button("Increment") { self.model.count += 1 }
      }
    }
  }
}
```

This will make sure that the view subscribes to any fields accessed in the `@Perceptible` model so
that changes to those fields invalidate the view and cause it to re-render.

If a field of a `@Perceptible` model is accessed in a view while _not_ inside
`WithPerceptionTracking`, then a runtime warning will be triggered:

> 🟣 Runtime Warning: Perceptible state was accessed but is not being tracked. Track changes to
> state by wrapping your view in a 'WithPerceptionTracking' view.

To debug this, expand the warning in the Issue Navigator of Xcode (⌘5), and click through the stack
frames displayed to find the line in your view where you are accessing state without being inside
`WithPerceptionTracking`.

## Bindings

If you want to derive bindings from the store (see <doc:Bindings> for more information), then you
would typically use the `@Bindable` property wrapper that comes with SwiftUI:

```swift
struct MyView: View {
  @Bindable var store: StoreOf<MyFeature>
  // ...
}
```

However, `@Bindable` is iOS 17+. So, the Perception library comes with a tool that can be used in
its place until you can target iOS 17 and later. You just have to qualify `@Bindable` with the
`Perception` namespace:

```swift
struct MyView: View {
  @Perception.Bindable var store: StoreOf<MyFeature>
  // ...
}
```

## Gotchas

There are a few gotchas to be aware of when using `WithPerceptionTracking`.

### Lazy view closures

There are many "lazy" closures in SwiftUI that evaluate only when something happens in the view, and
not necessarily in the same stack frames as the `body` of the view. For example, the trailing
closure of `ForEach` is called _after_ the `body` of the view has been computed.

This means that even if you wrap the body of the view in `WithPerceptionTracking`:

```swift
WithPerceptionTracking {
  ForEach(store.scope(state: \.rows, action: \.rows), id: \.state.id) { store in
    Text(store.title)
  }
}
```

…the access to the row's `store.title` happens _outside_ `WithPerceptionTracking`, and hence will
not work and will trigger a runtime warning as described above.

The fix for this is to wrap the content of the trailing closure in another `WithPerceptionTracking`:

```swift
WithPerceptionTracking {
  ForEach(store.scope(state: \.rows, action: \.rows), id: \.state.id) { store in
    WithPerceptionTracking {
      Text(store.title)
    }
  }
}
```

### Mixing legacy and modern features together

Some problems can arise when mixing together features built in the "legacy" style, using
``ViewStore`` and ``WithViewStore``, and features built in the "modern" style, using the
``ObservableState()`` macro. The problems mostly manifest themselves as re-computing view bodies
more often than necessary, but that can also put strain on SwiftUI's ability to figure out what
state changed, and can cause glitches or exacerbate navigation bugs.

See <doc:MigratingTo1.7#Incrementally-migrating> for more information about this.



---
File: /Sources/ComposableArchitecture/Documentation.docc/Articles/Performance.md
---

# Performance

Learn how to improve the performance of features built in the Composable Architecture.

As your features and application grow you may run into performance problems, such as reducers
becoming slow to execute, SwiftUI view bodies executing more often than expected, and more. This
article outlines a few common pitfalls when developing features in the library, and how to fix
them.

* [Sharing logic with actions](#Sharing-logic-with-actions)
* [CPU-intensive calculations](#CPU-intensive-calculations)
* [High-frequency actions](#High-frequency-actions)
* [Store scoping](#Store-scoping)

### Sharing logic with actions

There is a common pattern of using actions to share logic across multiple parts of a reducer.
This is an inefficient way to share logic. Sending actions is not as lightweight of an operation
as, say, calling a method on a class. Actions travel through multiple layers of an application, and 
at each layer a reducer can intercept and reinterpret the action.

It is far better to share logic via simple methods on your ``Reducer`` conformance.
The helper methods can take `inout State` as an argument if it needs to make mutations, and it
can return an `Effect<Action>`. This allows you to share logic without incurring the cost
of sending needless actions.

For example, suppose that there are 3 UI components in your feature such that when any is changed
you want to update the corresponding field of state, but then you also want to make some mutations
and execute an effect. That common mutation and effect could be put into its own action and then
each user action can return an effect that immediately emits that shared action:

```swift
@Reducer
struct Feature {
  @ObservableState
  struct State { /* ... */ }
  enum Action { /* ... */ }

  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .buttonTapped:
        state.count += 1
        return .send(.sharedComputation)

      case .toggleChanged:
        state.isEnabled.toggle()
        return .send(.sharedComputation)

      case let .textFieldChanged(text):
        state.description = text
        return .send(.sharedComputation)

      case .sharedComputation:
        // Some shared work to compute something.
        return .run { send in
          // A shared effect to compute something
        }
      }
    }
  }
}
```

This is one way of sharing the logic and effect, but we are now incurring the cost of two actions
even though the user performed a single action. That is not going to be as efficient as it would
be if only a single action was sent.

Besides just performance concerns, there are two other reasons why you should not follow this 
pattern. First, this style of sharing logic is not very flexible. Because the shared logic is 
relegated to a separate action it must always be run after the initial logic. But what if
instead you need to run some shared logic _before_ the core logic? This style cannot accommodate that.

Second, this style of sharing logic also muddies tests. When you send a user action you have to 
further assert on receiving the shared action and assert on how state changed. This bloats tests
with unnecessary internal details, and the test no longer reads as a script from top-to-bottom of
actions the user is taking in the feature:

```swift
let store = TestStore(initialState: Feature.State()) {
  Feature()
}

store.send(.buttonTapped) {
  $0.count = 1
}
store.receive(\.sharedComputation) {
  // Assert on shared logic
}
store.send(.toggleChanged) {
  $0.isEnabled = true
}
store.receive(\.sharedComputation) {
  // Assert on shared logic
}
store.send(.textFieldChanged("Hello")) {
  $0.description = "Hello"
}
store.receive(\.sharedComputation) {
  // Assert on shared logic
}
```

So, we do not recommend sharing logic in a reducer by having dedicated actions for the logic
and executing synchronous effects.

Instead, we recommend sharing logic with methods defined in your feature's reducer. The method has
full access to all dependencies, it can take an `inout State` if it needs to make mutations to 
state, and it can return an `Effect<Action>` if it needs to execute effects.

The above example can be refactored like so:

```swift
@Reducer
struct Feature {
  @ObservableState
  struct State { /* ... */ }
  enum Action { /* ... */ }

  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .buttonTapped:
        state.count += 1
        return self.sharedComputation(state: &state)

      case .toggleChanged:
        state.isEnabled.toggle()
        return self.sharedComputation(state: &state)

      case let .textFieldChanged(text):
        state.description = text
        return self.sharedComputation(state: &state)
      }
    }
  }

  func sharedComputation(state: inout State) -> Effect<Action> {
    // Some shared work to compute something.
    return .run { send in
      // A shared effect to compute something
    }
  }
}
```

This effectively works the same as before, but now when a user action is sent all logic is executed
at once without sending an additional action. This also fixes the other problems we mentioned above.

For example, if you need to execute the shared logic _before_ the core logic, you can do so easily:

```swift
case .buttonTapped:
  let sharedEffect = self.sharedComputation(state: &state)
  state.count += 1
  return sharedEffect
```

You have complete flexibility to decide how, when and where you want to execute the shared logic.

Further, tests become more streamlined since you do not have to assert on internal details of 
shared actions being sent around. The test reads  like a user script of what the user is doing
in the feature:

```swift
let store = TestStore(initialState: Feature.State()) {
  Feature()
}

store.send(.buttonTapped) {
  $0.count = 1
  // Assert on shared logic
}
store.send(.toggleChanged) {
  $0.isEnabled = true
  // Assert on shared logic
}
store.send(.textFieldChanged("Hello") {
  $0.description = "Hello"
  // Assert on shared logic
}
```

##### Sharing logic in child features

There is another common scenario for sharing logic in features where the parent feature wants to
invoke logic in a child feature. One can technically do this by sending actions from the parent 
to the child, but we do not recommend it (see above in <doc:Performance#Sharing-logic-with-actions>
to learn why):

```swift
// Handling action from parent feature:
case .buttonTapped:
  // Send action to child to perform logic:
  return .send(.child(.refresh))
```

Instead, we recommend invoking the child reducer directly:

```swift
case .buttonTapped:
  return reduce(into: &state, action: .child(.refresh))
```

### CPU intensive calculations

Reducers are run on the main thread and so they are not appropriate for performing intense CPU
work. If you need to perform lots of CPU-bound work, then it is more appropriate to use an
``Effect``, which will operate in the cooperative thread pool, and then send actions back into 
the system. You should also make sure to perform your CPU intensive work in a cooperative manner by
periodically suspending with `Task.yield()` so that you do not block a thread in the cooperative
pool for too long.

So, instead of performing intense work like this in your reducer:

```swift
case .buttonTapped:
  var result = // ...
  for value in someLargeCollection {
    // Some intense computation with value
  }
  state.result = result
```

...you should return an effect to perform that work, sprinkling in some yields every once in awhile,
and then delivering the result in an action:

```swift
case .buttonTapped:
  return .run { send in
    var result = // ...
    for (index, value) in someLargeCollection.enumerated() {
      // Some intense computation with value

      // Yield every once in awhile to cooperate in the thread pool.
      if index.isMultiple(of: 1_000) {
        await Task.yield()
      }
    }
    await send(.computationResponse(result))
  }

case let .computationResponse(result):
  state.result = result
```

This will keep CPU intense work from being performed in the reducer, and hence not on the main 
thread.

### High-frequency actions

Sending actions in a Composable Architecture application should not be thought as simple method
calls that one does with classes, such as `ObservableObject` conformances. When an action is sent
into the system there are multiple layers of features that can intercept and interpret it, and 
the resulting state changes can reverberate throughout the entire application.

Because of this, sending actions does come with a cost. You should aim to only send "significant" 
actions into the system, that is, actions that cause the execution of important logic and effects
for your application. High-frequency actions, such as sending dozens of actions per second, 
should be avoided unless your application truly needs that volume of actions in order to implement
its logic.

However, there are often times that actions are sent at a high frequency but the reducer doesn't
actually need that volume of information. For example, say you were constructing an effect that 
wanted to report its progress back to the system for each step of its work. You could choose to send
the progress for literally every step:

```swift
case .startButtonTapped:
  return .run { send in
    var count = 0
    let max = await self.eventsClient.count()

    for await event in self.eventsClient.events() {
      defer { count += 1 }
      await send(.progress(Double(count) / Double(max)))
    }
  }
}
```

However, what if the effect required 10,000 steps to finish? Or 100,000? Or more? It would be 
immensely wasteful to send 100,000 actions into the system to report a progress value that is only
going to vary from 0.0 to 1.0.

Instead, you can choose to report the progress every once in awhile. You can even do the math
to make it so that you report the progress at most 100 times:

```swift
case .startButtonTapped:
  return .run { send in
    var count = 0
    let max = await self.eventsClient.count()
    let interval = max / 100

    for await event in self.eventsClient.events() {
      defer { count += 1 }
      if count.isMultiple(of: interval) {
        await send(.progress(Double(count) / Double(max)))
      }
    }
  }
}
```

This greatly reduces the bandwidth of actions being sent into the system so that you are not 
incurring unnecessary costs for sending actions.

Another example that comes up often is sliders. If done in the most direct way, by deriving a 
binding from the store to hand to a `Slider`:

```swift
Slider(value: store.$opacity, in: 0...1)
```

This will send an action into the system for every little change to the slider, which can be dozens
or hundreds of actions as the user is dragging the slider. If this turns out to be problematic then
you can consider alternatives.

For example, you can hold onto some local `@State` in the view for using with the `Slider`, and
then you can use the trailing `onEditingChanged` closure to send an action to the store:

```swift
Slider(value: self.$opacity, in: 0...1) {
  self.store.send(.setOpacity(self.opacity))
}
```

This way an action is only sent once the user stops moving the slider.

### Store scoping

In the 1.5.6 release of the library a change was made to ``Store/scope(state:action:)-90255`` that
made it more sensitive to performance considerations.

The most common form of scoping, that of scoping directly along boundaries of child features, is
the most performant form of scoping and is the intended use of scoping. The library is slowly 
evolving to a state where that is the _only_ kind of scoping one can do on a store.

The simplest example of this directly scoping to some child state and actions for handing to a 
child view:

```swift
ChildView(
  store: store.scope(state: \.child, action: \.child)
)
```

Furthermore, scoping to a child domain to be used with one of the libraries navigation view modifiers,
such as ``SwiftUI/View/sheet(store:onDismiss:content:)``, also falls under the intended 
use of scope:

```swift
.sheet(store: store.scope(state: \.child, action: \.child)) { store in
  ChildView(store: store)
}
```

All of these examples are how ``Store/scope(state:action:)-90255`` is intended to be used, and you
can continue using it in this way with no performance concerns.

Where performance can become a concern is when using `scope` on _computed_ properties rather than
simple stored fields. For example, say you had a computed property in the parent feature's state
for deriving the child state:

```swift
extension ParentFeature.State {
  var computedChild: ChildFeature.State {
    ChildFeature.State(
      // Heavy computation here...
    )
  }
}
```

And then in the view, say you scoped along that computed property: 

```swift
ChildView(
  store: store.scope(state: \.computedChild, action: \.child)
)
```

If the computation in that property is heavy, it is going to become exacerbated by the changes
made in 1.5, and the problem worsens the closer the scoping is to the root of the application.

The problem is that in version 1.5 scoped stores stopped directly holding onto their local state,
and instead hold onto a reference to the store at the root of the application. And when you access
state from the scoped store, it transforms the root state to the child state on the fly.

This transformation will include the heavy computed property, and potentially compute it many times
if you need to access multiple pieces of state from the store. If you are noticing a performance
problem while depending on 1.5+ of the library, look through your code base for any place you are
using computed properties in scopes. You can even put a `print` statement in the computed property
so that you can see first hand just how many times it is being invoked while running your 
application.

To fix the problem we recommend using ``Store/scope(state:action:)-90255`` only along stored 
properties of child features. Such key paths are simple getters, and so not have a problem with
performance. If you are using a computed property in a scope, then reconsider if that could instead
be done along a plain, stored property and moving the computed logic into the child view. The 
further you push the computation towards the leaf nodes of your application, the less performance
problems you will see.



---
File: /Sources/ComposableArchitecture/Documentation.docc/Articles/SharingState.md
---

# Sharing state

Learn techniques for sharing state throughout many parts of your application, and how to persist
data to user defaults, the file system, and other external mediums.

## Overview

Sharing state is the process of letting many features have access to the same data so that when any
feature makes a change to this data it is instantly visible to every other feature. Such sharing can
be really handy, but also does not play nicely with value types, which are copied rather than
shared. Because the Composable Architecture highly prefers modeling domains with value types rather
than reference types, sharing state can be tricky.

This is why the library comes with a few tools for sharing state with many parts of your
application. The majority of these tools exist outside of the Composable Architecture, and are in
a separate library called [Sharing](https://github.com/pointfreeco/swift-sharing). You can refer
to that library's documentation for more information, but we have also repeated some of the most
important concepts in this article.

There are two main kinds of shared state in the library: explicitly passed state and
persisted state. And there are 3 persistence strategies shipped with the library: 
in-memory, user defaults, and file storage. You can also implement 
your own persistence strategy if you want to use something other than user defaults or the file 
system, such as SQLite.

* ["Source of truth"](#Source-of-truth)
* [Explicit shared state](#Explicit-shared-state)
* [Persisted shared state](#Persisted-shared-state)
  * [In-memory](#In-memory)
  * [User defaults](#User-defaults)
  * [File storage](#File-storage)
  * [Custom persistence](#Custom-persistence)
* [Observing changes to shared state](#Observing-changes-to-shared-state)
* [Initialization rules](#Initialization-rules)
* [Deriving shared state](#Deriving-shared-state)
* [Concurrent mutations to shared state](#Concurrent-mutations-to-shared-state)
* [Testing shared state](#Testing-shared-state)
  * [Testing when using persistence](#Testing-when-using-persistence)
  * [Testing when using custom persistence strategies](#Testing-when-using-custom-persistence-strategies)
  * [Overriding shared state in tests](#Overriding-shared-state-in-tests)
  * [UI Testing](#UI-Testing)
  * [Testing tips](#Testing-tips)
* [Read-only shared state](#Read-only-shared-state)
* [Type-safe keys](#Type-safe-keys)
* [Shared state in pre-observation apps](#Shared-state-in-pre-observation-apps)
* [Gotchas of @Shared](#Gotchas-of-Shared)

## "Source of truth"

First a quick discussion on defining exactly what "shared state" is. A common concept thrown around
in architectural discussions is "single source of truth." This is the idea that the complete state
of an application, even its navigation, can be driven off a single piece of data. It's a great idea,
in theory, but in practice it can be quite difficult to completely embrace.

First of all, a _single_ piece of data to drive _all_ of application state is just not feasible.
There is a lot of state in an application that is fine to be local to a view and does not need 
global representation. For example, the state of whether a button is being pressed is probably fine
to reside privately inside the button.

And second, applications typically do not have a _single_ source of truth. That is far too 
simplistic. If your application loads data from an API, or from disk, or from user defaults, then
the "truth" for that data does not lie in your application. It lies externally.

In reality, there are _two_ sources of "truth" in any application:

1. There is the state the application needs to execute its logic and behavior. This is the kind of 
state that determines if a button is enabled or disabled, drives navigation such as sheets and
drill-downs, and handles validation of forms. Such state only makes sense for the application.

2. Then there is a second source of "truth" in an application, which is the data that lies in some 
external system and needs to be loaded into the application. Such state is best modeled as a 
dependency or using the shared state tools discussed in this article.

## Explicit shared state

This is the simplest kind of shared state to get started with. It allows you to share state amongst
many features without any persistence. The data is only held in memory, and will be cleared out the
next time the application is run.

To share data in this style, use the `@Shared` property wrapper with no arguments.
For example, suppose you have a feature that holds a count and you want to be able to hand a shared
reference to that count to other features. You can do so by holding onto a `@Shared` property in
the feature's state:

```swift
@Reducer
struct ParentFeature {
  @ObservableState
  struct State {
    @Shared var count: Int
    // Other properties
  }
  // ...
}
```

Then suppose that this feature can present a child feature that wants access to this shared `count`
value. It too would hold onto a `@Shared` property to a count:

```swift
@Reducer
struct ChildFeature {
  @ObservableState
  struct State {
    @Shared var count: Int
    // Other properties
  }
  // ...
}
```

When the parent features creates the child feature's state, it can pass a _reference_ to the shared
count rather than the actual count value by using the `$count` projected value:

```swift
case .presentButtonTapped:
  state.child = ChildFeature.State(count: state.$count)
  // ...
```

Now any mutation the `ChildFeature` makes to its `count` will be instantly made to the 
`ParentFeature`'s count too.

## Persisted shared state

Explicitly shared state discussed above is a nice, lightweight way to share a piece of data with
many parts of your application. However, sometimes you want to share state with the entire 
application without having to pass it around explicitly. One can do this by passing a
`SharedKey` to the `@Shared` property wrapper, and the library comes with three persistence
strategies, as well as the ability to create custom persistence strategies.

#### In-memory

This is the simplest persistence strategy in that it doesn't actually persist at all. It keeps
the data in memory and makes it available to every part of the application, but when the app is
relaunched the data will be reset back to its default.

It can be used by passing `inMemory` to the `@Shared` property wrapper.
For example, suppose you want to share an integer count value with the entire application so that
any feature can read from and write to the integer. This can be done like so:

```swift
@Reducer
struct ChildFeature {
  @ObservableState
  struct State {
    @Shared(.inMemory("count")) var count = 0
    // Other properties
  }
  // ...
}
```

> Note: When using a persistence strategy with `@Shared` you must provide a default value, which is
> used for the first access of the shared state.

Now any part of the application can read from and write to this state, and features will never
get out of sync.

#### User defaults

If you would like to persist your shared value across application launches, then you can use the
`appStorage` strategy with `@Shared` in order to automatically
persist any changes to the value to user defaults. It works similarly to in-memory sharing discussed
above. It requires a key to store the value in user defaults, as well as a default value that will
be used when there is no value in the user defaults:

```swift
@Shared(.appStorage("count")) var count = 0
```

That small change will guarantee that all changes to `count` are persisted and will be 
automatically loaded the next time the application launches.

This form of persistence only works for simple data types because that is what works best with
`UserDefaults`. This includes strings, booleans, integers, doubles, URLs, data, and more. If you
need to store more complex data, such as custom data types serialized to JSON, then you will want
to use the `.fileStorage` strategy or a custom persistence strategy.

#### File storage

If you would like to persist your shared value across application launches, and your value is
complex (such as a custom data type), then you can use the `fileStorage`
strategy with `@Shared`. It automatically persists any changes to the file system.

It works similarly to the in-memory sharing discussed above, but it requires a URL to store the data
on disk, as well as a default value that will be used when there is no data in the file system:

```swift
@Shared(.fileStorage(URL(/* ... */)) var users: [User] = []
```

This strategy works by serializing your value to JSON to save to disk, and then deserializing JSON
when loading from disk. For this reason the value held in `@Shared(.fileStorage(…))` must conform to
`Codable`.

#### Custom persistence

It is possible to define all new persistence strategies for the times that user defaults or JSON
files are not sufficient. To do so, define a type that conforms to the `SharedKey` protocol:

```swift
public final class CustomSharedKey: SharedKey {
  // ...
}
```

And then define a static function on the `SharedKey` protocol for creating your new
persistence strategy:

```swift
extension SharedReaderKey {
  public static func custom<Value>(/*...*/) -> Self
  where Self == CustomPersistence<Value> {
    CustomPersistence(/* ... */)
  }
}
```

With those steps done you can make use of the strategy in the same way one does for 
`appStorage` and `fileStorage`:

```swift
@Shared(.custom(/* ... */)) var myValue: Value
```

The `SharedKey` protocol represents loading from _and_ saving to some external storage, 
such as the file system or user defaults. Sometimes saving is not a valid operation for the external
system, such as if your server holds onto a remote configuration file that your app uses to 
customize its appearance or behavior. In those situations you can conform to the 
`SharedReaderKey` protocol. See <doc:SharingState#Read-only-shared-state> for more 
information.

## Observing changes to shared state

The `@Shared` property wrapper exposes a `publisher` property so that you can observe
changes to the reference from any part of your application. For example, if some feature in your
app wants to listen for changes to some shared `count` value, then it can introduce an `onAppear`
action that kicks off a long-living effect that subscribes to changes of `count`:

```swift
case .onAppear:
  return .publisher {
    state.$count.publisher
      .map(Action.countUpdated)
  }

case .countUpdated(let count):
  // Do something with count
  return .none
```

Note that you will have to be careful for features that both hold onto shared state and subscribe
to changes to that state. It is possible to introduce an infinite loop if you do something like 
this:

```swift
case .onAppear:
  return .publisher {
    state.$count.publisher
      .map(Action.countUpdated)
  }

case .countUpdated(let count):
  state.count = count + 1
  return .none
```

If `count` changes, then `$count.publisher` emits, causing the `countUpdated` action to be sent, 
causing the shared `count` to be mutated, causing `$count.publisher` to emit, and so on.

## Initialization rules

Because the state sharing tools use property wrappers there are special rules that must be followed
when writing custom initializers for your types. These rules apply to _any_ kind of property 
wrapper, including those that ship with vanilla SwiftUI (e.g. `@State`, `@StateObject`, etc.),
but the rules can be quite confusing and so below we describe the various ways to initialize
shared state.

It is common to need to provide a custom initializer to your feature's 
``Reducer/State`` type, especially when modularizing. When using
`@Shared` in your `State` that can become complicated.
Depending on your exact situation you can do one of the following:

* You are using non-persisted shared state (i.e. no argument is passed to `@Shared`), and the 
"source of truth" of the state lives with the parent feature. Then the initializer should take a 
`Shared` value and you can assign through the underscored property:

  ```swift
  public struct State {
    @Shared public var count: Int
    // other fields

    public init(count: Shared<Int>, /* other fields */) {
      self._count = count
      // other assignments
    }
  }
  ```

* You are using non-persisted shared state (_i.e._ no argument is passed to `@Shared`), and the 
"source of truth" of the state lives within the feature you are initializing. Then the initializer
should take a plain, non-`Shared` value and you construct the `Shared` value in the initializer:

  ```swift
  public struct State {
    @Shared public var count: Int
    // other fields

    public init(count: Int, /* other fields */) {
      self._count = Shared(count)
      // other assignments
    }
  }
  ```

* You are using a persistence strategy with shared state (_e.g._ 
`appStorage`, `fileStorage`, _etc._),
then the initializer should take a plain, non-`Shared` value and you construct the `Shared` value in
the initializer using the initializer which takes a
`SharedKey` as the second argument:

  ```swift
  public struct State {
    @Shared public var count: Int
    // other fields

    public init(count: Int, /* other fields */) {
      self._count = Shared(wrappedValue: count, .appStorage("count"))
      // other assignments
    }
  }
  ```

  The declaration of `count` can use `@Shared` without an argument because the persistence
  strategy is specified in the initializer.

  > Important: The value passed to this initializer is only used if the external storage does not
  > already have a value. If a value exists in the storage then it is not used. In fact, the
  > `wrappedValue` argument of `Shared.init(wrappedValue:)` is an
  > `@autoclosure` so that it is not even evaluated if not used. For that reason you
  > may prefer to make the argument to the initializer an `@autoclosure` so that it too is evaluated
  > only if actually used:
  > 
  > ```swift
  > public struct State {
  >   @Shared public var count: Int
  >   // other fields
  > 
  >   public init(count: @autoclosure () -> Int, /* other fields */) {
  >     self._count = Shared(wrappedValue: count(), .appStorage("count"))
  >     // other assignments
  >   }
  > }
  > ```

## Deriving shared state

It is possible to derive shared state for sub-parts of an existing piece of shared state. For 
example, suppose you have a multi-step signup flow that uses `Shared<SignUpData>` in order to share
data between each screen. However, some screens may not need all of `SignUpData`, but instead just a
small part. The phone number confirmation screen may only need access to `signUpData.phoneNumber`,
and so that feature can hold onto just `Shared<String>` to express this fact:

```swift
@Reducer 
struct PhoneNumberFeature { 
  struct State {
    @Shared var phoneNumber: String
  }
  // ...
}
```

Then, when the parent feature constructs the `PhoneNumberFeature` it can derive a small piece of
shared state from `Shared<SignUpData>` to pass along:

```swift
case .nextButtonTapped:
  state.path.append(
    PhoneNumberFeature.State(phoneNumber: state.$signUpData.phoneNumber)
  )
```

Here we are using the projected value of `@Shared` value using `$` syntax, `$signUpData`, and then
further dot-chaining onto that projection to derive a `Shared<String>`. This can be a powerful way
for features to hold onto only the bare minimum of shared state it needs to do its job.

It can be instructive to think of `@Shared` as the Composable Architecture analogue of `@Bindable`
in vanilla SwiftUI. You use it to express that the actual "source of truth" of the value lies 
elsewhere, but you want to be able to read its most current value and write to it.

This also works for persistence strategies. If a parent feature holds onto a `@Shared` piece of 
state with a persistence strategy:

```swift
@Reducer
struct ParentFeature {
  struct State {
    @Shared(.fileStorage(.currentUser)) var currentUser
  }
  // ...
}
```

…and a child feature wants access to just a shared _piece_ of `currentUser`, such as their name, 
then they can do so by holding onto a simple, unadorned `@Shared`:

```swift
@Reducer
struct ChildFeature {
  struct State {
    @Shared var currentUserName: String
  }
  // ...
}
```

And then the parent can pass along `$currentUser.name` to the child feature when constructing its
state:

```swift
case .editNameButtonTapped:
  state.destination = .editName(
    EditNameFeature(name: state.$currentUser.name)
  )
```

Any changes the child feature makes to its shared `name` will be automatically made to the parent's
shared `currentUser`, and further those changes will be automatically persisted thanks to the
`.fileStorage` persistence strategy used. This means the child feature gets to describe that it
needs access to shared state without describing the persistence strategy, and the parent can be
responsible for persisting and deriving shared state to pass to the child.

If your shared state is a collection, and in particular an `IdentifiedArray`, then we have another
tool for deriving shared state to a particular element of the array. You can subscript into a 
`Shared` collection with the `[id:]` subscript, and that will give a piece of shared optional
state, which you can then unwrap to turn into honest shared state using a special `Shared` 
initializer:

```swift
@Shared(.fileStorage(.todos)) var todos: IdentifiedArrayOf<Todo> = []

guard let todo = Shared($todos[id: todoID])
else { return }
todo // Shared<Todo>
```

## Concurrent mutations to shared state

[mutating-shared-state-article]: https://swiftpackageindex.com/pointfreeco/swift-sharing/main/documentation/sharing/mutatingsharedstate

While the `@Shared` property wrapper makes it possible to treat shared state
_mostly_ like regular state, you do have to perform some extra steps to mutate shared state. 
This is because shared state is technically a reference deep down, even
though we take extra steps to make it appear value-like. And this means it's possible to mutate the
same piece of shared state from multiple threads, and hence race conditions are possible. See
[Mutating Shared State][mutating-shared-state-article] for a more in-depth explanation.

To mutate a piece of shared state in an isolated fashion, use the `withLock` method
defined on the `@Shared` projected value:

```swift
state.$count.withLock { $0 += 1 }
```

That locks the entire unit of work of reading the current count, incrementing it, and storing it
back in the reference.

Technically it is still possible to write code that has race conditions, such as this silly example:

```swift
let currentCount = state.count
state.$count.withLock { $0 = currentCount + 1 }
```

But there is no way to 100% prevent race conditions in code. Even actors are susceptible to 
problems due to re-entrancy. To avoid problems like the above we recommend wrapping as many 
mutations of the shared state as possible in a single `withLock`. That will make
sure that the full unit of work is guarded by a lock.

## Testing shared state

Shared state behaves quite a bit different from the regular state held in Composable Architecture
features. It is capable of being changed by any part of the application, not just when an action is
sent to the store, and it has reference semantics rather than value semantics. Typically references
cause serious problems with testing, especially exhaustive testing that the library prefers (see
<doc:TestingTCA>), because references cannot be copied and so one cannot inspect the changes 
before and after an action is sent.

For this reason, the `@Shared` property wrapper does extra work during testing to preserve a 
previous snapshot of the state so that one can still exhaustively assert on shared state, even 
though it is a reference.

For the most part, shared state can be tested just like any regular state held in your features. For
example, consider the following simple counter feature that uses in-memory shared state for the
count:

```swift
@Reducer 
struct Feature {
  struct State: Equatable {
    @Shared var count: Int
  }
  enum Action {
    case incrementButtonTapped
  }
  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .incrementButtonTapped:
        state.$count.withLock { $0 += 1 }
        return .none
      }
    }
  }
}
```

This feature can be tested in a similar same way as when you are using non-shared state:

```swift
@Test
func increment() async {
  let store = TestStore(initialState: Feature.State(count: Shared(0))) {
    Feature()
  }

  await store.send(.incrementButtonTapped) {
    $0.$count.withLock { $0 = 1 }
  }
}
```

This test passes because we have described how the state changes. But even better, if we mutate the
`count` incorrectly:


```swift
@Test
func increment() async {
  let store = TestStore(initialState: Feature.State(count: Shared(0))) {
    Feature()
  }

  await store.send(.incrementButtonTapped) {
    $0.$count.withLock { $0 = 2 }
  }
}
```

…we immediately get a test failure letting us know exactly what went wrong:

```
❌ State was not expected to change, but a change occurred: …

    − Feature.State(_count: 2)
    + Feature.State(_count: 1)

(Expected: −, Actual: +)
```

This works even though the `@Shared` count is a reference type. The ``TestStore`` and `@Shared`
type work in unison to snapshot the state before and after the action is sent, allowing us to still
assert in an exhaustive manner.

However, exhaustively testing shared state is more complicated than testing non-shared state in
features. Shared state can be captured in effects and mutated directly, without ever sending an
action into system. This is in stark contrast to regular state, which can only ever be mutated when
sending an action.

For example, it is possible to alter the `incrementButtonTapped` action so that it captures the 
shared state in an effect, and then increments from the effect:

```swift
case .incrementButtonTapped:
  return .run { [sharedCount = state.$count] _ in
    await sharedCount.withLock { $0 += 1 }
  }
```

The only reason this is possible is because `@Shared` state is reference-like, and hence can 
technically be mutated from anywhere.

However, how does this affect testing? Since the `count` is no longer incremented directly in
the reducer we can drop the trailing closure from the test store assertion:

```swift
@Test
func increment() async {
  let store = TestStore(initialState: SimpleFeature.State(count: Shared(0))) {
    SimpleFeature()
  }
  await store.send(.incrementButtonTapped)
}
```

This is technically correct, but we aren't testing the behavior of the effect at all.

Luckily the ``TestStore`` has our back. If you run this test you will immediately get a failure
letting you know that the shared count was mutated but we did not assert on the changes:

```
❌ Tracked changes to 'Shared<Int>@MyAppTests/FeatureTests.swift:10' but failed to assert: …

  − 0
  + 1

(Before: −, After: +)

Call 'Shared<Int>.assert' to exhaustively test these changes, or call 'skipChanges' to ignore them.
```

In order to get this test passing we have to explicitly assert on the shared counter state at
the end of the test, which we can do using the ``TestStore/assert(_:fileID:file:line:column:)``
method:

```swift
@Test
func increment() async {
  let store = TestStore(initialState: SimpleFeature.State(count: Shared(0))) {
    SimpleFeature()
  }
  await store.send(.incrementButtonTapped)
  store.assert {
    $0.$count.withLock { $0 = 1 }
  }
}
```

Now the test passes.

So, even though the `@Shared` type opens our application up to a little bit more uncertainty due
to its reference semantics, it is still possible to get exhaustive test coverage on its changes.

#### Testing when using persistence

It is also possible to test when using one of the persistence strategies provided by the library, 
which are `appStorage` and
`fileStorage`. Typically persistence is difficult to test because the
persisted data bleeds over from test to test, making it difficult to exhaustively prove how each
test behaves in isolation.

But the `.appStorage` and `.fileStorage` strategies do extra work to make sure that happens. By
default the `.appStorage` strategy uses a non-persisting user defaults so that changes are not
actually persisted across test runs. And the `.fileStorage` strategy uses a mock file system so that
changes to state are not actually persisted to the file system.

This means that if we altered the `SimpleFeature` of the <doc:SharingState#Testing-shared-state> 
section above to use app storage:

```swift
struct State: Equatable {
  @Shared(.appStorage("count")) var count: Int
}
````

…then the test for this feature can be written in the same way as before and will still pass.

#### Testing when using custom persistence strategies

When creating your own custom persistence strategies you must careful to do so in a style that
is amenable to testing. For example, the `appStorage` persistence
strategy that comes with the library injects a `defaultAppStorage`
dependency so that one can inject a custom `UserDefaults` in order to execute in a controlled
environment. By default `defaultAppStorage` uses a non-persisting
user defaults, but you can also customize it to use any kind of defaults.

Similarly the `fileStorage` persistence strategy uses an internal
dependency for changing how files are written to the disk and loaded from disk. In tests the
dependency will forgo any interaction with the file system and instead write data to a `[URL: Data]`
dictionary, and load data from that dictionary. That emulates how the file system works, but without
persisting any data to the global file system, which can bleed over into other tests.

#### Overriding shared state in tests

When testing features that use `@Shared` with a persistence strategy you may want to set the initial
value of that state for the test. Typically this can be done by declaring the shared state at 
the beginning of the test so that its default value can be specified:

```swift
@Test
func basics() {
  @Shared(.appStorage("count")) var count = 42

  // Shared state will be 42 for all features using it.
  let store = TestStore(…)
}
```

However, if your test suite is a part of an app target, then the entry point of the app will execute
and potentially cause an early access of `@Shared`, thus capturing a different default value than
what is specified above. This quirk of tests in app targets is documented in
<doc:TestingTCA#Testing-gotchas> of the <doc:TestingTCA> article, and a similar quirk
exists for Xcode previews and is discussed below in <doc:SharingState#Gotchas-of-Shared>.

The most robust workaround to this issue is to simply not execute your app's entry point when tests
are running, which we detail in <doc:TestingTCA#Testing-host-application>. This makes it so that you
are not accidentally execute network requests, tracking analytics, etc. while running tests.

You can also work around this issue by simply setting the shared state again after initializing
it:

```swift
@Test
func basics() {
  @Shared(.appStorage("count")) var count = 42
  count = 42  // NB: Set again to override any value set by the app target.

  // Shared state will be 42 for all features using it.
  let store = TestStore(…)
}
```

#### UI Testing

When UI testing your app you must take extra care so that shared state is not persisted across
app runs because that can cause one test to bleed over into another test, making it difficult to
write deterministic tests that always pass. To fix this, you can set an environment value from
your UI test target, and then if that value is present in the app target you can override the
`defaultAppStorage` and 
`defaultFileStorage` dependencies so that they use in-memory 
storage, i.e. they do not persist ever:

```swift
@main
struct EntryPoint: App {
  let store = Store(initialState: AppFeature.State()) {
    AppFeature()
  } withDependencies: {
    if ProcessInfo.processInfo.environment["UITesting"] == "true" {
      $0.defaultAppStorage = UserDefaults(
        suiteName:"\(NSTemporaryDirectory())\(UUID().uuidString)"
      )!
      $0.defaultFileStorage = .inMemory
    }
  }
}
```

#### Testing tips

There is something you can do to make testing features with shared state more robust and catch
more potential future problems when you refactor your code. Right now suppose you have two features
using `@Shared(.appStorage("count"))`:

```swift
@Reducer
struct Feature1 {
  struct State {
    @Shared(.appStorage("count")) var count = 0
  }
  // ...
}

@Reducer
struct Feature2 {
  struct State {
    @Shared(.appStorage("count")) var count = 0
  }
  // ...
}
```

And suppose you wrote a test that proves one of these counts is incremented when a button is tapped:

```swift
await store.send(.feature1(.buttonTapped)) {
  $0.feature1.count = 1
}
```

Because both features are using `@Shared` you can be sure that both counts are kept in sync, and
so you do not need to assert on `feature2.count`.

However, if someday during a long, complex refactor you accidentally removed `@Shared` from 
the second feature:

```swift
@Reducer
struct Feature2 {
  struct State {
    var count = 0
  }
  // ...
}
```

…then all of your code would continue compiling, and the test would still pass, but you may have
introduced a bug by not having these two pieces of state in sync anymore.

You could also fix this by forcing yourself to assert on all shared state in your features, even
though technically it's not necessary:

```swift
await store.send(.feature1(.buttonTapped)) {
  $0.feature1.count = 1
  $0.feature2.count = 1
}
```

If you are worried about these kinds of bugs you can make your tests more robust by not asserting
on the shared state in the argument handed to the trailing closure of ``TestStore``'s `send`, and
instead capture a reference to the shared state in the test and mutate it in the trailing
closure:


```swift
@Test
func increment() async {
  @Shared(.appStorage("count")) var count = 0
  let store = TestStore(initialState: ParentFeature.State()) {
    ParentFeature()
  }

  await store.send(.feature1(.buttonTapped)) {
    // Mutate $0 to expected value.
    count = 1
  }
}
```

This will fail if you accidentally remove a `@Shared` from one of your features.

Further, you can enforce this pattern in your codebase by making all `@Shared` properties 
`fileprivate` so that they can never be mutated outside their file scope:

```swift
struct State {
  @Shared(.appStorage("count")) fileprivate var count = 0
}
```

## Read-only shared state

The `@Shared` property wrapper described above gives you access to a piece of shared
state that is both readable and writable. That is by far the most common use case when it comes to
shared state, but there are times when one wants to express access to shared state for which you
are not allowed to write to it, or possibly it doesn't even make sense to write to it.

For those times there is the `@SharedReader` property wrapper. It represents
a reference to some piece of state shared with multiple parts of the application, but you are not
allowed to write to it. Every persistence strategy discussed above works with `SharedReader`,
however if you try to mutate the state you will get a compiler error:

```swift
@SharedReader(.appStorage("isOn")) var isOn = false
isOn = true  // 🛑
```

It is also possible to make custom persistence strategies that only have the notion of loading and
subscribing, but cannot write. To do this you will conform only to the `SharedReaderKey`
protocol instead of the full `SharedKey` protocol. 

For example, you could create a `.remoteConfig` strategy that loads (and subscribes to) a remote
configuration file held on your server so that it is kept automatically in sync:

```swift
@SharedReader(.remoteConfig) var remoteConfig
```

## Type-safe keys

Due to the nature of persisting data to external systems, you lose some type safety when shuffling
data from your app to the persistence storage and back. For example, if you are using the
`fileStorage` strategy to save an array of users to disk you might do so
like this:

```swift
extension URL {
  static let users = URL(/* ... */))
}

@Shared(.fileStorage(.users)) var users: [User] = []
```

And say you have used this file storage users in multiple places throughout your application.

But then, someday in the future you may decide to refactor this data to be an identified array
instead of a plain array:

```swift
// Somewhere else in the application
@Shared(.fileStorage(.users)) var users: IdentifiedArrayOf<User> = []
```

But if you forget to convert _all_ shared user arrays to the new identified array your application
will still compile, but it will be broken. The two types of storage will not share state.

To add some type-safety and reusability to this process you can extend the `SharedReaderKey`
protocol to add a static variable for describing the details of your persistence:

```swift
extension SharedReaderKey where Self == FileStorageKey<IdentifiedArrayOf<User>> {
  static var users: Self {
    fileStorage(.users)
  }
}
```

Then when using `@Shared` you can specify this key directly without `.fileStorage`:

```swift
@Shared(.users) var users: IdentifiedArrayOf<User> = []
```

And now that the type is baked into the key you cannot accidentally use the wrong type because you
will get an immediate compiler error:

```swift
@Shared(.users) var users = [User]()
```

> 🛑 Error:  Cannot convert value of type '[User]' to expected argument type 'IdentifiedArrayOf<User>'

This technique works for all types of persistence strategies. For example, a type-safe `.inMemory`
key can be constructed like so:

```swift
extension SharedReaderKey where Self == InMemoryKey<IdentifiedArrayOf<User>> {
  static var users: Self {
    inMemory("users")
  }
}
```

And a type-safe `.appStorage` key can be constructed like so:

```swift
extension SharedReaderKey where Self == AppStorageKey<Int> {
  static var count: Self {
    appStorage("count")
  }
}
```

And this technique also works on [custom persistence](<doc:SharingState#Custom-persistence>)
strategies.

Further, you can also bake in the default of the shared value into your key by doing the following:

```swift
extension SharedReaderKey where Self == FileStorageKey<IdentifiedArrayOf<User>>.Default {
  static var users: Self {
    Self[.fileStorage(.users), default: []]
  }
}
```

And now anytime you reference the shared users state you can leave off the default value, and
you can even leave off the type annotation:

```swift
@Shared(.users) var users
```

## Shared state in pre-observation apps

It is possible to use `@Shared` in features that have not yet been updated with
the observation tools released in 1.7, such as the ``ObservableState()`` macro. In the reducer
you can use `@Shared` regardless of your use of the observation tools. 

However, if you are deploying to iOS 16 or earlier, then you must use `WithPerceptionTracking`
in your views if you are accessing shared state. For example, the following view:

```swift
struct FeatureView: View {
  let store: StoreOf<Feature>

  var body: some View {
    Form {
      Text(store.sharedCount.description)
    }
  }
}
```

…will not update properly when `sharedCount` changes. This view will even generate a runtime warning
letting you know something is wrong:

> 🟣 Runtime Warning: Perceptible state was accessed but is not being tracked. Track changes to
> state by wrapping your view in a 'WithPerceptionTracking' view.

The fix is to wrap the body of the view in `WithPerceptionTracking`:

```swift
struct FeatureView: View {
  let store: StoreOf<Feature>

  var body: some View {
    WithPerceptionTracking {
      Form {
        Text(store.sharedCount.description)
      }
    }
  }
}
```

## Gotchas of @Shared

There are a few gotchas to be aware of when using shared state in the Composable Architecture.

#### Hashability

Because the `@Shared` type is equatable based on its wrapped value, and because the value is held 
in a reference and can change over time, it cannot be hashable. This also means that types 
containing `@Shared` properties should not compute their hashes from shared values.

#### Codability

The `@Shared` type is not conditionally encodable or decodable because the source of truth of the 
wrapped value is rarely local: it might be derived from some other shared value, or it might rely on 
loading the value from a backing persistence strategy.

When introducing shared state to a data type that is encodable or decodable, you must provide your 
own implementations of `encode(to:)` and `init(from:)` that do the appropriate thing.

For example, if the data type is sharing state with a persistence strategy, you can decode by 
delegating to the memberwise initializer that implicitly loads the shared value from the property 
wrapper's persistence strategy, or you can explicitly initialize a shared value. And for encoding 
you can often skip encoding the shared value:

```swift
struct AppState {
  @Shared(.appStorage("launchCount")) var launchCount = 0
  var todos: [String] = []
}

extension AppState: Codable {
  enum CodingKeys: String, CodingKey { case todos }

  init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    // Use the property wrapper default via the memberwise initializer:
    try self.init(
      todos: container.decode([String].self, forKey: .todos)
    )

    // Or initialize the shared storage manually:
    self._launchCount = Shared(wrappedValue: 0, .appStorage("launchCount"))
    self.todos = try container.decode([String].self, forKey: .todos)
  }

  func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(self.todos, forKey: .todos)
    // Skip encoding the launch count.
  }
}
```

#### Tests

While shared properties are compatible with the Composable Architecture's testing tools, assertions
may not correspond directly to a particular action when several actions are received by effects.

Take this simple example, in which a `tap` action kicks off an effect that returns a `response`,
which finally mutates some shared state:

```swift
@Reducer
struct Feature {
  struct State: Equatable {
    @Shared(value: false) var bool
  }
  enum Action {
    case tap
    case response
  }
  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .tap:
        return .run { send in
          await send(.response)
        }
      case .response:
        state.$bool.withLock { $0.toggle() }
        return .none
      }
    }
  }
}
```

We would expect to assert against this mutation when the test store receives the `response` action,
but this will fail:

```swift
// ❌ State was not expected to change, but a change occurred: …
//
//     Feature.State(
//   -   _shared: #1 false
//   +   _shared: #1 true
//     )
//
// (Expected: −, Actual: +)
await store.send(.tap)

// ❌ Expected state to change, but no change occurred.
await store.receive(.response) {
  $0.$shared.withLock { $0 = true }
}
```

This is due to an implementation detail of the `TestStore` that predates `@Shared`, in which the
test store eagerly processes all actions received _before_ you have asserted on them. As such, you
must always assert against shared state mutations in the first action:

```swift
await store.send(.tap) {  // ✅
  $0.$shared.withLock { $0 = true }
}

// ❌ Expected state to change, but no change occurred.
await store.receive(.response)  // ✅
```

In a future major version of the Composable Architecture, we will be able to introduce a breaking
change that allows you to assert against shared state mutations in the action that performed the
mutation.



---
File: /Sources/ComposableArchitecture/Documentation.docc/Articles/StackBasedNavigation.md
---

# Stack-based navigation

Learn about stack-based navigation, that is navigation modeled with collections, including how to
model your domains, how to integrate features, how to test your features, and more.

## Overview

Stack-based navigation is the process of modeling navigation using collections of state. This style
of navigation allows you to deep-link into any state of your application by simply constructing a
flat collection of data, handing it off to SwiftUI, and letting it take care of the rest.
It also allows for complex and recursive navigation paths in your application.

  * [Basics](#Basics)
  * [Pushing features onto the stack](#Pushing-features-onto-the-stack)
  * [Integration](#Integration)
  * [Dismissal](#Dismissal)
  * [Testing](#Testing)
  * [StackState vs NavigationPath](#StackState-vs-NavigationPath)
  * [UIKit](#UIKit)

## Basics

The tools for this style of navigation include ``StackState``, ``StackAction`` and the
``Reducer/forEach(_:action:destination:fileID:filePath:line:column:)-9svqb`` operator, as well as a new 
initializer ``SwiftUI/NavigationStack/init(path:root:destination:fileID:filePath:line:column:)`` on 
`NavigationStack` that behaves like the normal initializer, but is tuned specifically for 
the Composable Architecture.

The process of integrating features into a navigation stack largely consists of 2 steps: 
integrating the features' domains together, and constructing a `NavigationStack` for a 
store describing all the views in the stack. One typically starts by integrating the features' 
domains together. This consists of defining a new reducer, typically called `Path`, that holds the 
domains of all the features that can be pushed onto the stack:

```swift
@Reducer
struct RootFeature {
  // ...

  @Reducer
  enum Path {
    case addItem(AddFeature)
    case detailItem(DetailFeature)
    case editItem(EditFeature)
  }
}
```

> Note: The `Path` reducer is identical to the `Destination` reducer that one creates for 
> tree-based navigation when using enums. See <doc:TreeBasedNavigation#Enum-state> for more
> information.

Once the `Path` reducer is defined we can then hold onto ``StackState`` and ``StackAction`` in the 
feature that manages the navigation stack:

```swift
@Reducer
struct RootFeature {
  @ObservableState
  struct State {
    var path = StackState<Path.State>()
    // ...
  }
  enum Action {
    case path(StackActionOf<Path>)
    // ...
  }
}
```

> Tip: ``StackAction`` is generic over both state and action of the `Path` domain, and so you can
> use the ``StackActionOf`` typealias to simplify the syntax a bit. This is different from
> ``PresentationAction``, which only has a single generic of `Action`.

And then we must make use of the ``Reducer/forEach(_:action:)`` method to integrate the domains of
all the features that can be navigated to with the domain of the parent feature:

```swift
@Reducer
struct RootFeature {
  // ...

  var body: some ReducerOf<Self> {
    Reduce { state, action in 
      // Core logic for root feature
    }
    .forEach(\.path, action: \.path)
  }
}
```

> Note: You do not need to specify `Path()` in a trailing closure of `forEach` because it can be
> automatically inferred from `@Reducer enum Path`.

That completes the steps to integrate the child and parent features together for a navigation stack.

Next we must integrate the child and parent views together. This is done by a 
`NavigationStack` using a special initializer that comes with this library, called
``SwiftUI/NavigationStack/init(path:root:destination:fileID:filePath:line:column:)``. This initializer takes 3 
arguments: a binding of a store focused in on ``StackState`` and ``StackAction`` in your domain, a 
trailing view builder for the root view of the stack, and another trailing view builder for all of 
the views that can be pushed onto the stack:

```swift
NavigationStack(
  path: // Store focused on StackState and StackAction
) {
  // Root view of the navigation stack
} destination: { store in
  // A view for each case of the Path.State enum
}
```

To fill in the first argument you only need to scope a binding of your store to the `path` state and
`path` action you already hold in the root feature:

```swift
struct RootView: View {
  @Bindable var store: StoreOf<RootFeature>

  var body: some View {
    NavigationStack(
      path: $store.scope(state: \.path, action: \.path)
    ) {
      // Root view of the navigation stack
    } destination: { store in
      // A view for each case of the Path.State enum
    }
  }
}
```

The root view can be anything you want, and would typically have some `NavigationLink`s or other
buttons that push new data onto the ``StackState`` held in your domain.

And the last trailing closure is provided a store of `Path` domain, and you can use the 
``Store/case`` computed property to destructure each case of the `Path` to obtain a store focused
on just that case:

```swift
} destination: { store in
  switch store.case {
  case .addItem(let store):
  case .detailItem(let store):
  case .editItem(let store):
  }
}
```

This will give you compile-time guarantees that you have handled each case of the `Path.State` enum,
which can be nice for when you add new types of destinations to the stack.

In each of these cases you can return any kind of view that you want, but ultimately you want to
scope the store down to a specific case of the `Path.State` enum:

```swift
} destination: { store in
  switch store.case {
  case .addItem(let store):
    AddView(store: store)
  case .detailItem(let store):
    DetailView(store: store)
  case .editItem(let store):
    EditView(store: store)
  }
}
```

And that is all it takes to integrate multiple child features together into a navigation stack, 
and done so with concisely modeled domains. Once those steps are taken you can easily add 
additional features to the stack by adding a new case to the `Path` reducer state and action enums, 
and you get complete introspection into what is happening in each child feature from the parent. 
Continue reading into <doc:StackBasedNavigation#Integration> for more information on that.

## Pushing features onto the stack

There are two primary ways to push features onto the stack once you have their domains integrated
and `NavigationStack` in the view, as described above. The simplest way is to use the 
``SwiftUI/NavigationLink/init(state:label:fileID:filePath:line:column:)`` initializer on 
`NavigationLink`, which requires you to specify the state of the feature you want to push onto the 
stack. You must specify the full state, going all the way back to the `Path` reducer's state:

```swift
Form {
  NavigationLink(
    state: RootFeature.Path.State.detail(DetailFeature.State())
  ) {
    Text("Detail")
  }
}
```

When the link is tapped a ``StackAction/push(id:state:)`` action will be sent, causing the `path`
collection to be mutated and appending the `.detail` state to the stack.

This is by far the simplest way to navigate to a screen, but it also has its drawbacks. In 
particular, it makes modularity difficult since the view that holds onto the `NavigationLink` must
have access to the `Path.State` type, which means it needs to build all of the `Path` reducer, 
including _every_ feature that can be navigated to.

This hurts modularity because it is no longer possible to build each feature that can be presented
in the stack individually, in full isolation. You must build them all together. Technically you can
move all features' `State` types (and only the `State` types) to a separate module, and then
features can depend on only that module without needing to build every feature's reducer.

Another alternative is to forgo `NavigationLink` entirely and just use `Button` that sends an action
in the child feature's domain:

```swift
Form {
  Button("Detail") {
    store.send(.detailButtonTapped)
  }
}
```

Then the root feature can listen for that action and append to the `path` with new state in order
to drive navigation:

```swift
case .path(.element(id: _, action: .list(.detailButtonTapped))):
  state.path.append(.detail(DetailFeature.State()))
  return .none
```

## Integration

Once your features are integrated together using the steps above, your parent feature gets instant
access to everything happening inside the navigation stack. You can use this as a means to integrate
the logic of the stack element features with the parent feature. For example, if you want to detect 
when the "Save" button inside the edit feature is tapped, you can simply destructure on that action. 
This consists of pattern matching on the ``StackAction``, then the 
``StackAction/element(id:action:)`` action, then the feature you are interested in, and finally the 
action you are interested in:

```swift
case let .path(.element(id: id, action: .editItem(.saveButtonTapped))):
  // ...
```

Once inside that case you can then try extracting out the feature state so that you can perform
additional logic, such as popping the "edit" feature and saving the edited item to the database:

```swift
case let .path(.element(id: id, action: .editItem(.saveButtonTapped))):
  guard let editItemState = state.path[id: id]?.editItem
  else { return .none }

  state.path.pop(from: id)
  return .run { _ in
    await self.database.save(editItemState.item)
  }
```

Note that when destructuring the ``StackAction/element(id:action:)`` action we get access to not
only the action that happened in the child domain, but also the ID of the element in the stack.
``StackState`` automatically manages IDs for every feature added to the stack, which can be used
to look up specific elements in the stack using 
``StackState/subscript(id:fileID:filePath:line:column:)`` and pop elements from the stack using
``StackState/pop(from:)``.

## Dismissal

Dismissing a feature in a stack is as simple as mutating the ``StackState`` using one of its
methods, such as ``StackState/popLast()``, ``StackState/pop(from:)`` and more:

```swift
case .closeButtonTapped:
  state.popLast()
  return .none
```

However, in order to do this you must have access to that stack state, and usually only the parent 
has access. But often we would like to encapsulate the logic of dismissing a feature to be inside 
the child feature without needing explicit communication with the parent.

SwiftUI provides a wonderful tool for allowing child _views_ to dismiss themselves from the parent,
all without any explicit communication with the parent. It's an environment value called `dismiss`,
and it can be used like so:

```swift
struct ChildView: View {
  @Environment(\.dismiss) var dismiss
  var body: some View {
    Button("Close") { self.dismiss() }
  }
}
```

When `self.dismiss()` is invoked, SwiftUI finds the closest parent view that is presented in the
navigation stack, and removes that state from the collection powering the stack. This can be 
incredibly useful, but it is also relegated to the view layer. It is not possible to use 
`dismiss` elsewhere, like in an observable object, which would allow you to have nuanced logic
for dismissal such as validation or async work.

The Composable Architecture has a similar tool, except it is appropriate to use from a reducer,
where the rest of your feature's logic and behavior resides. It is accessed via the library's
dependency management system (see <doc:DependencyManagement>) using ``DismissEffect``:

```swift
@Reducer
struct Feature {
  @ObservableState
  struct State { /* ... */ }
  enum Action { 
    case closeButtonTapped
    // ...
  }
  @Dependency(\.dismiss) var dismiss
  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .closeButtonTapped:
        return .run { _ in await self.dismiss() }
      // ...
      }
    }
  }
}
```

> Note: The ``DismissEffect`` function is async which means it cannot be invoked directly inside a 
> reducer. Instead it must be called from 
> ``Effect/run(priority:operation:catch:fileID:filePath:line:column:)``.

When `self.dismiss()` is invoked it will remove the corresponding value from the ``StackState``
powering the navigation stack. It does this by sending a ``StackAction/popFrom(id:)`` action back
into the system, causing the feature state to be removed. This allows you to encapsulate the logic 
for dismissing a child feature entirely inside the child domain without explicitly communicating 
with the parent.

> Note: Because dismissal is handled by sending an action, it is not valid to ever send an action
> after invoking `dismiss()`:
> 
> ```swift
> return .run { send in 
>   await self.dismiss()
>   await send(.tick)  // ⚠️
> }
> ```
> 
> To do so would be to send an action for a feature while its state is not present in the stack, 
> and that will cause a runtime warning in Xcode and a test failure when running tests.

> Warning: SwiftUI's environment value `@Environment(\.dismiss)` and the Composable Architecture's
> dependency value `@Dependency(\.dismiss)` serve similar purposes, but are completely different 
> types. SwiftUI's environment value can only be used in SwiftUI views, and this library's
> dependency value can only be used inside reducers.

## Testing

A huge benefit of using the tools of this library to model navigation stacks is that testing becomes 
quite easy. Further, using "non-exhaustive testing" (see <doc:TestingTCA#Non-exhaustive-testing>) can 
be very useful for testing navigation since you often only want to assert on a few high level 
details and not all state mutations and effects.

As an example, consider the following simple counter feature that wants to dismiss itself if its
count is greater than or equal to 5:

```swift
@Reducer
struct CounterFeature {
  @ObservableState
  struct State: Equatable {
    var count = 0
  }
  enum Action {
    case decrementButtonTapped
    case incrementButtonTapped
  }

  @Dependency(\.dismiss) var dismiss

  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .decrementButtonTapped:
        state.count -= 1
        return .none

      case .incrementButtonTapped:
        state.count += 1
        return state.count >= 5
          ? .run { _ in await self.dismiss() }
          : .none
      }
    }
  }
}
```

And then let's embed that feature into a parent feature:

```swift
@Reducer
struct Feature {
  @ObservableState
  struct State: Equatable {
    var path = StackState<Path.State>()
  }
  enum Action {
    case path(StackActionOf<Path>)
  }

  @Reducer  
  struct Path {
    enum State: Equatable { case counter(CounterFeature.State) }
    enum Action { case counter(CounterFeature.Action) }
    var body: some ReducerOf<Self> {
      Scope(state: \.counter, action: \.counter) { CounterFeature() }
    }
  }

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      // Logic and behavior for core feature.
    }
    .forEach(\.path, action: \.path) { Path() }
  }
}
```

Now let's try to write a test on the `Feature` reducer that proves that when the child counter 
feature's count is incremented above 5 it will dismiss itself. To do this we will construct a 
``TestStore`` for `Feature` that starts in a state with a single counter already on the stack:

```swift
@Test
func dismissal() {
  let store = TestStore(
    initialState: Feature.State(
      path: StackState([
        CounterFeature.State(count: 3)
      ])
    )
  ) {
    CounterFeature()
  }
}
```

Then we can send the `.incrementButtonTapped` action in the counter child feature inside the
stack in order to confirm that the count goes up by one, but in order to do so we need to provide
an ID:

```swift
await store.send(\.path[id: ???].counter.incrementButtonTapped) {
  // ...
}
```

As mentioned in <doc:StackBasedNavigation#Integration>, ``StackState`` automatically manages IDs
for each feature and those IDs are mostly opaque to the outside. However, specifically in tests
those IDs are integers and generational, which means the ID starts at 0 and then for each feature 
pushed onto the stack the global ID increments by one.

This means that when the ``TestStore`` were constructed with a single element already in the stack
that it was given an ID of 0, and so that is the ID we can use when sending an action:

```swift
await store.send(\.path[id: 0].counter.incrementButtonTapped) {
  // ...
}
```

Next we want to assert how the counter feature in the stack changes when the action is sent. To
do this we must go through multiple layers: first subscript through the ID, then unwrap the 
optional value returned from that subscript, then pattern match on the case of the `Path.State`
enum, and then perform the mutation.

The library provides two different tools to perform all of these steps in a single step. You can
use the `XCTModify` helper:

```swift
await store.send(\.path[id: 0].counter.incrementButtonTapped) {
  XCTModify(&$0.path[id: 0], case: \.counter) {
    $0.count = 4
  }
}
```

The `XCTModify` function takes an `inout` piece of enum state as its first argument and a case
path for its second argument, and then uses the case path to extract the payload in that case, 
allow you to perform a mutation to it, and embed the data back into the enum. So, in the code
above we are subscripting into ID 0, isolating the `.counter` case of the `Path.State` enum, 
and mutating the `count` to be 4 since it incremented by one. Further, if the case of `$0.path[id: 0]`
didn't match the case path, then a test failure would be emitted.

Another option is to use ``StackState/subscript(id:case:)-7gczr`` to simultaneously subscript into an 
ID on the stack _and_ a case of the path enum:

```swift
await store.send(\.path[id: 0].counter.incrementButtonTapped) {
  $0.path[id: 0, case: \.counter]?.count = 4
}
```

The `XCTModify` style is best when you have many things you need to modify on the state, and the
``StackState/subscript(id:case:)-7gczr`` style is best when you have simple mutations.

Continuing with the test, we can send it one more time to see that the count goes up to 5:

```swift
await store.send(\.path[id: 0].counter.incrementButtonTapped) {
  XCTModify(&$0.path[id: 0], case: \.counter) {
    $0.count = 5
  }
}
```

And then we finally expect that the child dismisses itself, which manifests itself as the 
``StackAction/popFrom(id:)`` action being sent to pop the counter feature off the stack, which we 
can assert using the ``TestStore/receive(_:timeout:assert:fileID:file:line:column:)-53wic`` method 
on ``TestStore``:

```swift
await store.receive(\.path.popFrom) {
  $0.path[id: 0] = nil
}
```

If you need to assert that a specific child action is received, you can construct a case key path 
for a specific child element action by subscripting on the `\.path` case with the element ID. 

For example, if the child feature performed an effect that sent an `.response` action, you 
can test that it is received:

```swift
await store.receive(\.path[id: 0].counter.response) {
  // ...
}
```

This shows how we can write very nuanced tests on how parent and child features interact with each
other in a navigation stack.

However, the more complex the features become, the more cumbersome testing their integration can be.
By default, ``TestStore`` requires us to be exhaustive in our assertions. We must assert on how
every piece of state changes, how every effect feeds data back into the system, and we must make
sure that all effects finish by the end of the test (see <doc:TestingTCA> for more info).

But ``TestStore`` also supports a form of testing known as "non-exhaustive testing" that allows you
to assert on only the parts of the features that you actually care about (see 
<doc:TestingTCA#Non-exhaustive-testing> for more info).

For example, if we turn off exhaustivity on the test store (see ``TestStore/exhaustivity``) then we
can assert at a high level that when the increment button is tapped twice that eventually we receive
a ``StackAction/popFrom(id:)`` action:

```swift
@Test
func dismissal() {
  let store = TestStore(
    initialState: Feature.State(
      path: StackState([
        CounterFeature.State(count: 3)
      ])
    )
  ) {
    CounterFeature()
  }
  store.exhaustivity = .off

  await store.send(\.path[id: 0].counter.incrementButtonTapped)
  await store.send(\.path[id: 0].counter.incrementButtonTapped)
  await store.receive(\.path.popFrom)
}
```

This essentially proves the same thing that the previous test proves, but it does so in much fewer
lines and is more resilient to future changes in the features that we don't necessarily care about.

## StackState vs NavigationPath

SwiftUI comes with a powerful type for modeling data in navigation stacks called 
[`NavigationPath`][nav-path-docs], and so you might wonder why we created our own data type, 
``StackState``, instead of leveraging `NavigationPath`.

The `NavigationPath` data type is a type-erased list of data that is tuned specifically for
`NavigationStack`s. It allows you to maximally decouple features in the stack since you can add any
kind of data to a path, as long as it is `Hashable`:

```swift
var path = NavigationPath()
path.append(1)
path.append("Hello")
path.append(false)
```

And SwiftUI interprets that data by describing what view should be pushed onto the stack 
corresponding to a type of data:

```swift
struct RootView: View {
  @State var path = NavigationPath()

  var body: some View {
    NavigationStack(path: self.$path) {
      Form {
        // ...
      }
      .navigationDestination(for: Int.self) { integer in 
        // ...
      }
      .navigationDestination(for: String.self) { string in 
        // ...
      }
      .navigationDestination(for: Bool.self) { bool in 
        // ...
      }
    }
  }
}
```

This can be powerful, but it does come with some downsides. Because the underlying data is 
type-erased, SwiftUI has decided to not expose much API on the data type. For example, the only
things you can do with a path are append data to the end of it, as seen above, or remove data
from the end of it:

```swift
path.removeLast()
```

Or count the elements in the path:

```swift
path.count
```

And that is all. You can't insert or remove elements from anywhere but the end, and you can't even
iterate over the path:

```swift
let path: NavigationPath = …
for element in path {  // 🛑
}
```

This can make it very difficult to analyze what is on the stack and aggregate data across the 
entire stack.

The Composable Architecture's ``StackState`` serves a similar purpose as `NavigationPath`, but
with different trade offs:

* ``StackState`` is fully statically typed, and so you cannot add just _any_ kind of data to it.
* But, ``StackState`` conforms to the `Collection` protocol (as well as `RandomAccessCollection` and 
`RangeReplaceableCollection`), which gives you access to a lot of methods for manipulating the
collection and introspecting what is inside the stack.
* Your feature's data does not need to be `Hashable` to put it in a ``StackState``. The data type
manages stable identifiers for your features under the hood, and automatically derives a hash
value from those identifiers.

We feel that ``StackState`` offers a nice balance between full runtime flexibility and static, 
compile-time guarantees, and that it is the perfect tool for modeling navigation stacks in the
Composable Architecture.

[nav-path-docs]: https://developer.apple.com/documentation/swiftui/navigationpath

## UIKit

The library also comes with a tool that allows you to use UIKit's `UINavigationController` in a 
state-driven manner. If you model your domains using ``StackState`` as described above, then you 
can use the special `NavigationStackController` type to implement a view controller for your stack:

```swift
class AppController: NavigationStackController {
  private var store: StoreOf<AppFeature>!

  convenience init(store: StoreOf<AppFeature>) {
    @UIBindable var store = store

    self.init(path: $store.scope(state: \.path, action: \.path)) {
      RootViewController(store: store)
    } destination: { store in 
      switch store.case {
      case .addItem(let store):
        AddViewController(store: store)
      case .detailItem(let store):
        DetailViewController(store: store)
      case .editItem(let store):
        EditViewController(store: store)
      }
    }

    self.store = store
  }
}
```



---
File: /Sources/ComposableArchitecture/Documentation.docc/Articles/SwiftConcurrency.md
---

# Adopting Swift concurrency

Learn how to write safe, concurrent effects using Swift's structured concurrency.

As of version 5.6, Swift can provide many warnings for situations in which you might be using types
and functions that are not thread-safe in concurrent contexts. Many of these warnings can be ignored
for the time being, but in Swift 6 most (if not all) of these warnings will become errors, and so
you will need to know how to prove to the compiler that your types are safe to use concurrently.

There primary way to create an ``Effect`` in the library is via
``Effect/run(priority:operation:catch:fileID:filePath:line:column:)``. It takes a `@Sendable`, asynchronous closure,
which restricts the types of closures you can use for your effects. In particular, the closure can
only capture `Sendable` variables that are bound with `let`. Mutable variables and non-`Sendable`
types are simply not allowed to be passed to `@Sendable` closures.

There are two primary ways you will run into this restriction when building a feature in the
Composable Architecture: accessing state from within an effect, and accessing a dependency from
within an effect.

### Accessing state in an effect

Reducers are executed with a mutable, `inout` state variable, and such variables cannot be accessed
from within `@Sendable` closures:

```swift
@Reducer
struct Feature {
  @ObservableState
  struct State { /* ... */ }
  enum Action { /* ... */ }

  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .buttonTapped:
        return .run { send in
          try await Task.sleep(for: .seconds(1))
          await send(.delayed(state.count))
          // 🛑 Mutable capture of 'inout' parameter 'state' is
          //    not allowed in concurrently-executing code
        }

        // ...
      }
    }
  }
}
```

To work around this you must explicitly capture the state as an immutable value for the scope of the
closure:

```swift
return .run { [state] send in
  try await Task.sleep(for: .seconds(1))
  await send(.delayed(state.count))  // ✅
}
```

You can also capture just the minimal parts of the state you need for the effect by binding a new
variable name for the capture:

```swift
return .run { [count = state.count] send in
  try await Task.sleep(for: .seconds(1))
  await send(.delayed(count))  // ✅
}
```

### Accessing dependencies in an effect

In the Composable Architecture, one provides dependencies to a reducer so that it can interact with
the outside world in a deterministic and controlled manner. Those dependencies can be used from
asynchronous and concurrent contexts, and so must be `Sendable`.

If your dependency is not sendable, you will be notified at the time of registering it with the
library. In particular, when extending `DependencyValues` to provide the computed property:

```swift
extension DependencyValues {
  var factClient: FactClient {
    get { self[FactClient.self] }
    set { self[FactClient.self] = newValue }
  }
}
```

If `FactClient` is not `Sendable`, for whatever reason, you will get a warning in the `get`
and `set` lines:

```
⚠️ Type 'FactClient' does not conform to the 'Sendable' protocol
```

To fix this you need to make each dependency `Sendable`. This usually just means making sure 
that the interface type only holds onto `Sendable` data, and in particular, any closure-based 
endpoints should be annotated as `@Sendable`:

```swift
struct FactClient {
  var fetch: @Sendable (Int) async throws -> String
}
```

This will restrict the kinds of closures that can be used when constructing `FactClient` values, thus 
making the entire `FactClient` sendable itself.



---
File: /Sources/ComposableArchitecture/Documentation.docc/Articles/TestingTCA.md
---

# Testing

Learn how to write comprehensive and exhaustive tests for your features built in the Composable
Architecture.

The testability of features built in the Composable Architecture is the #1 priority of the library.
It should be possible to test not only how state changes when actions are sent into the store, but
also how effects are executed and feed data back into the system.

* [Testing state changes][Testing-state-changes]
* [Testing effects][Testing-effects]
* [Non-exhaustive testing][Non-exhaustive-testing]
* [Testing gotchas](#Testing-gotchas)

## Testing state changes

State changes are by far the simplest thing to test in features built with the library. A
``Reducer``'s first responsibility is to mutate the current state based on the action received into
the system. To test this we can technically run a piece of mutable state through the reducer and
then assert on how it changed after, like this:

```swift
@Reducer
struct Feature {
  @ObservableState
  struct State: Equatable {
    var count = 0
  }
  enum Action {
    case incrementButtonTapped
    case decrementButtonTapped
  }
  var body: some Reduce<State, Action> {
    Reduce { state, action in
      switch action {
      case .incrementButtonTapped:
        state.count += 1
        return .none
      case .decrementButtonTapped:
        state.count -= 1
        return .none
      }
    }
  }
}

@Test
func basics() {
  let feature = Feature()
  var currentState = Feature.State(count: 0)
  _ = feature.reduce(into: &currentState, action: .incrementButtonTapped)
  #expect(currentState == State(count: 1))

  _ = feature.reduce(into: &currentState, action: .decrementButtonTapped)
  #expect(currentState == State(count: 0))
}
```

This will technically work, but it's a lot boilerplate for something that should be quite simple.

The library comes with a tool specifically designed to make testing like this much simpler and more
concise. It's called ``TestStore``, and it is constructed similarly to ``Store`` by providing the
initial state of the feature and the ``Reducer`` that runs the feature's logic:

```swift
import Testing

@MainActor
struct CounterTests {
  @Test
  func basics() async {
    let store = TestStore(initialState: Feature.State(count: 0)) {
      Feature()
    }
  }
}
```

> Tip: Tests that use ``TestStore`` should be marked as `async` since most assertion helpers on
> ``TestStore`` can suspend. And while tests do not _require_ the main actor, ``TestStore`` _is_
> main actor-isolated, and so we recommend annotating your tests and suites with `@MainActor`.

Test stores have a ``TestStore/send(_:assert:fileID:file:line:column:)-8f2pl`` method, but it behaves differently from
stores and view stores. You provide an action to send into the system, but then you must also
provide a trailing closure to describe how the state of the feature changed after sending the
action:

```swift
await store.send(.incrementButtonTapped) {
  // ...
}
```

This closure is handed a mutable variable that represents the state of the feature _before_ sending
the action, and it is your job to make the appropriate mutations to it to get it into the shape
it should be after sending the action:

```swift
await store.send(.incrementButtonTapped) {
  $0.count = 1
}
```

> The ``TestStore/send(_:assert:fileID:file:line:column:)-8f2pl`` method is `async` for technical reasons that we
> do not have to worry about right now.

If your mutation is incorrect, meaning you perform a mutation that is different from what happened
in the ``Reducer``, then you will get a test failure with a nicely formatted message showing exactly
what part of the state does not match:

```swift
await store.send(.incrementButtonTapped) {
  $0.count = 999
}
```

> ❌ Failure: A state change does not match expectation: …
>
> ```diff
> - TestStoreTests.State(count: 999)
> + TestStoreTests.State(count: 1)
> ```
>
> (Expected: −, Actual: +)

You can also send multiple actions to emulate a script of user actions and assert each step of the
way how the state evolved:

```swift
await store.send(.incrementButtonTapped) {
  $0.count = 1
}
await store.send(.incrementButtonTapped) {
  $0.count = 2
}
await store.send(.decrementButtonTapped) {
  $0.count = 1
}
```

> Tip: Technically we could have written the mutation block in the following manner:
>
> ```swift
> await store.send(.incrementButtonTapped) {
>   $0.count += 1
> }
> await store.send(.decrementButtonTapped) {
>   $0.count -= 1
> }
> ```
>
> …and the test would have still passed.
>
> However, this does not produce as strong of an assertion. It shows that the count did increment
> by one, but we haven't proven we know the precise value of `count` at each step of the way.
>
> In general, the less logic you have in the trailing closure of
> ``TestStore/send(_:assert:fileID:file:line:column:)-8f2pl``, the stronger your assertion will be. It is best to
> use simple, hard-coded data for the mutation.

Test stores do expose a ``TestStore/state`` property, which can be useful for performing assertions
on computed properties you might have defined on your state. For example, if `State` had a 
computed property for checking if `count` was prime, we could test it like so:

```swift
store.send(.incrementButtonTapped) {
  $0.count = 3
}
XCTAssertTrue(store.state.isPrime)
```

However, when inside the trailing closure of ``TestStore/send(_:assert:fileID:file:line:column:)-8f2pl``, the
``TestStore/state`` property is equal to the state _before_ sending the action, not after. That
prevents you from being able to use an escape hatch to get around needing to actually describe the
state mutation, like so:

```swift
store.send(.incrementButtonTapped) {
  $0 = store.state  // ❌ store.state is the previous, not current, state.
}
```

## Testing effects

Testing state mutations as shown in the previous section is powerful, but is only half the story
when it comes to testing features built in the Composable Architecture. The second responsibility of
``Reducer``s, after mutating state from an action, is to return an ``Effect`` that encapsulates a
unit of work that runs in the outside world and feeds data back into the system.

Effects form a major part of a feature's logic. They can perform network requests to external
services, load and save data to disk, start and stop timers, interact with Apple frameworks (Core
Location, Core Motion, Speech Recognition, etc.), and more.

As a simple example, suppose we have a feature with a button such that when you tap it, it starts
a timer that counts up until you reach 5, and then stops. This can be accomplished using the
``Effect/run(priority:operation:catch:fileID:filePath:line:column:)`` helper on ``Effect``, which provides you with
an asynchronous context to operate in and can send multiple actions back into the system:

```swift
@Reducer
struct Feature {
  @ObservableState
  struct State: Equatable {
    var count = 0
  }
  enum Action {
    case startTimerButtonTapped
    case timerTick
  }
  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .startTimerButtonTapped:
        state.count = 0
        return .run { send in
          for _ in 1...5 {
            try await Task.sleep(for: .seconds(1))
            await send(.timerTick)
          }
        }

      case .timerTick:
        state.count += 1
        return .none
      }
    }
  }
}
```

To test this we can start off similar to how we did in the [previous section][Testing-state-changes]
when testing state mutations:

```swift
@MainActor
struct TimerTests {
  @Test
  func basics() async {
    let store = TestStore(initialState: Feature.State(count: 0)) {
      Feature()
    }
  }
}
```

With the basics set up, we can send an action into the system to assert on what happens, such as the
`.startTimerButtonTapped` action. This time we don't actually expect state to change at first
because when starting the timer we don't change state, and so in this case we can leave off the
trailing closure:

```swift
await store.send(.startTimerButtonTapped)
```

However, if we run the test as-is with no further interactions with the test store, we get a
failure:

> ❌ Failure: An effect returned for this action is still running. It must complete before the end
> of the test. …

This is happening because ``TestStore`` requires you to exhaustively prove how the entire system
of your feature evolves over time. If an effect is still running when the test finishes and the
test store did _not_ fail then it could be hiding potential bugs. Perhaps the effect is not
supposed to be running, or perhaps the data it feeds into the system later is wrong. The test store
requires all effects to finish.

To get this test passing we need to assert on the actions that are sent back into the system
by the effect. We do this by using the ``TestStore/receive(_:timeout:assert:fileID:file:line:column:)-53wic``
method, which allows you to assert which action you expect to receive from an effect, as well as how
the state changes after receiving that effect:

```swift
await store.receive(\.timerTick) {
  $0.count = 1
}
```

> Note: We are using key path syntax `\.timerTick` to specify the case of the action we expect to 
> receive. This works because the ``ComposableArchitecture/Reducer()`` macro automatically applies
> the `@CasePathable` macro to the `Action` enum, and `@CasePathable` comes from our
> [CasePaths][swift-case-paths] library which brings key path syntax to enum cases.

However, if we run this test we still get a failure because we asserted a `timerTick` action was
going to be received, but after waiting around for a small amount of time no action was received:

> ❌ Failure: Expected to receive an action, but received none after 0.1 seconds.

This is because our timer is on a 1 second interval, and by default
``TestStore/receive(_:timeout:assert:fileID:file:line:column:)-53wic`` only waits for a fraction of a second. This
is because typically you should not be performing real time-based asynchrony in effects, and instead
using a controlled entity, such as a clock, that can be sped up in tests. We will demonstrate this
in a moment, so for now let's increase the timeout:

```swift
await store.receive(\.timerTick, timeout: .seconds(2)) {
  $0.count = 1
}
```

This assertion now passes, but the overall test is still failing because there are still more
actions to receive. The timer should tick 5 times in total, so we need five `receive` assertions:

```swift
await store.receive(\.timerTick, timeout: .seconds(2)) {
  $0.count = 1
}
await store.receive(\.timerTick, timeout: .seconds(2)) {
  $0.count = 2
}
await store.receive(\.timerTick, timeout: .seconds(2)) {
  $0.count = 3
}
await store.receive(\.timerTick, timeout: .seconds(2)) {
  $0.count = 4
}
await store.receive(\.timerTick, timeout: .seconds(2)) {
  $0.count = 5
}
```

Now the full test suite passes, and we have exhaustively proven how effects are executed in this
feature. If in the future we tweak the logic of the effect, like say have it emit 10 times instead 
of 5, then we will immediately get a test failure letting us know that we have not properly
asserted on how the features evolve over time.

However, there is something not ideal about how this feature is structured, and that is the fact
that we are doing actual, uncontrolled time-based asynchrony in the effect:

```swift
return .run { send in
  for _ in 1...5 {
    try await Task.sleep(for: .seconds(1))  // ⬅️
    await send(.timerTick)
  }
}
```

This means for our test to run we must actually wait for 5 real world seconds to pass so that we
can receive all of the actions from the timer. This makes our test suite far too slow. What if in
the future we need to test a feature that has a timer that emits hundreds or thousands of times?
We cannot hold up our test suite for minutes or hours just to test that one feature.

To fix this we need to add a dependency to the reducer that aids in performing time-based
asynchrony, but in a way that is controllable. One way to do this is to add a clock as a
`@Dependency` to the reducer:

```swift
import Clocks

@Reducer
struct Feature {
  struct State { /* ... */ }
  enum Action { /* ... */ }
  @Dependency(\.continuousClock) var clock
  // ...
}
```

> Tip: To make use of controllable clocks you must use the [Clocks][gh-swift-clocks] library, which
> is automatically included with the Composable Architecture.

And then the timer effect in the reducer can make use of the clock to sleep rather than reaching
out to the uncontrollable `Task.sleep` method:

```swift
return .run { send in
  for _ in 1...5 {
    try await self.clock.sleep(for: .seconds(1))
    await send(.timerTick)
  }
}
```

> Tip: The `sleep(for:)` method on `Clock` is provided by the [Swift Clocks][gh-swift-clocks]
> library.

By having a clock as a dependency in the feature we can supply a controlled version in tests, such
as an immediate clock that does not suspend at all when you ask it to sleep:

```swift
let store = TestStore(initialState: Feature.State(count: 0)) {
  Feature()
} withDependencies: {
  $0.continuousClock = ImmediateClock()
}
```

With that small change we can drop the `timeout` arguments from the
``TestStore/receive(_:timeout:assert:fileID:file:line:column:)-53wic`` invocations:

```swift
await store.receive(\.timerTick) {
  $0.count = 1
}
await store.receive(\.timerTick) {
  $0.count = 2
}
await store.receive(\.timerTick) {
  $0.count = 3
}
await store.receive(\.timerTick) {
  $0.count = 4
}
await store.receive(\.timerTick) {
  $0.count = 5
}
```

…and the test still passes, but now does so immediately.

The more time you take to control the dependencies your features use, the easier it will be to
write tests for your features. To learn more about designing dependencies and how to best leverage
dependencies, read the <doc:DependencyManagement> article.

## Non-exhaustive testing

The previous sections describe in detail how to write tests in the Composable Architecture that
exhaustively prove how the entire feature evolves over time. You must assert on how every piece
of state changes, how every effect feeds data back into the system, and you must even make sure
that all effects complete before the test store is deallocated. This can be powerful, but it can
also be a nuisance, especially for highly composed features. This is why sometimes you may want
to test in a non-exhaustive style.

> Tip: The concept of "non-exhaustive test store" was first introduced by
> [Krzysztof Zabłocki][merowing.info] in a [blog post][exhaustive-testing-in-tca] and
> [conference talk][Composable-Architecture-at-Scale], and then later became integrated into the
> core library.

This style of testing is most useful for testing the integration of multiple features where you want
to focus on just a certain slice of the behavior. Exhaustive testing can still be important to use
for leaf node features, where you truly do want to assert on everything happening inside the
feature.
 
For example, suppose you have a tab-based application where the 3rd tab is a login screen. The user 
can fill in some data on the screen, then tap the "Submit" button, and then a series of events
happens to  log the user in. Once the user is logged in, the 3rd tab switches from a login screen 
to a profile screen, _and_ the selected tab switches to the first tab, which is an activity screen.

When writing tests for the login feature we will want to do that in the exhaustive style so that we
can prove exactly how the feature would behave in production. But, suppose we wanted to write an
integration test that proves after the user taps the "Login" button that ultimately the selected
tab switches to the first tab.

In order to test such a complex flow we must test the integration of multiple features, which means
dealing with complex, nested state and effects. We can emulate this flow in a test by sending
actions that mimic the user logging in, and then eventually assert that the selected tab switched
to activity:

```swift
let store = TestStore(initialState: AppFeature.State()) {
  AppFeature()
}

// 1️⃣ Emulate user tapping on submit button.
await store.send(\.login.submitButtonTapped) {
  // 2️⃣ Assert how all state changes in the login feature
  $0.login?.isLoading = true
  // ...
}

// 3️⃣ Login feature performs API request to login, and
//    sends response back into system.
await store.receive(\.login.loginResponse.success) {
// 4️⃣ Assert how all state changes in the login feature
  $0.login?.isLoading = false
  // ...
}

// 5️⃣ Login feature sends a delegate action to let parent
//    feature know it has successfully logged in.
await store.receive(\.login.delegate.didLogin) {
// 6️⃣ Assert how all of app state changes due to that action.
  $0.authenticatedTab = .loggedIn(
    Profile.State(...)
  )
  // ...
  // 7️⃣ *Finally* assert that the selected tab switches to activity.
  $0.selectedTab = .activity
}
```

Doing this with exhaustive testing is verbose, and there are a few problems with this:

  * We need to be intimately knowledgeable in how the login feature works so that we can assert
    on how its state changes and how its effects feed data back into the system.
  * If the login feature were to change its logic we may get test failures here even though the
    logic we are actually trying to test doesn't really care about those changes.
  * This test is very long, and so if there are other similar but slightly different flows we want
    to test we will be tempted to copy-and-paste the whole thing, leading to lots of duplicated,
    fragile tests.

Non-exhaustive testing allows us to test the high-level flow that we are concerned with, that of
login causing the selected tab to switch to activity, without having to worry about what is
happening inside the login feature. To do this, we can turn off ``TestStore/exhaustivity`` in the
test store, and then just assert on what we are interested in:

```swift
let store = TestStore(initialState: AppFeature.State()) {
  AppFeature()
}
store.exhaustivity = .off  // ⬅️

await store.send(\.login.submitButtonTapped)
await store.receive(\.login.delegate.didLogin) {
  $0.selectedTab = .activity
}
```

In particular, we did not assert on how the login's state changed or how the login's effects fed
data back into the system. We just assert that when the "Submit" button is tapped that eventually
we get the `didLogin` delegate action and that causes the selected tab to flip to activity. Now
the login feature is free to make any change it wants to make without affecting this integration
test.

Using ``Exhaustivity/off`` for ``TestStore/exhaustivity`` causes all un-asserted changes to pass
without any notification. If you would like to see what test failures are being suppressed without
actually causing a failure, you can use ``Exhaustivity/off(showSkippedAssertions:)``:

```swift
let store = TestStore(initialState: AppFeature.State()) {
  AppFeature()
}
store.exhaustivity = .off(showSkippedAssertions: true)  // ⬅️

await store.send(\.login.submitButtonTapped)
await store.receive(\.login.delegate.didLogin) {
  $0.selectedTab = .activity
}
```

When this is run you will get grey, informational boxes on each assertion where some change wasn't
fully asserted on:

> ◽️ Expected failure: A state change does not match expectation: …
>
> ```diff
>   AppFeature.State(
>     authenticatedTab: .loggedOut(
>       Login.State(
> -       isLoading: false
> +       isLoading: true,
>         …
>       )
>     )
>   )
> ```
>
> Skipped receiving .login(.loginResponse(.success))
>
> A state change does not match expectation: …
>
> ```diff
>   AppFeature.State(
> -   authenticatedTab: .loggedOut(…)
> +   authenticatedTab: .loggedIn(
> +     Profile.State(…)
> +   ),
>     …
>   )
> ```
>
> (Expected: −, Actual: +)

The test still passes, and none of these notifications are test failures. They just let you know
what things you are not explicitly asserting against, and can be useful to see when tracking down
bugs that happen in production but that aren't currently detected in tests.

#### Understanding non-exhaustive testing

It can be important to understand how non-exhaustive testing works under the hood because it does
limit the ways in which you can assert on state changes.

When you construct an _exhaustive_ test store, which is the default, the `$0` used inside the
trailing closure of ``TestStore/send(_:assert:fileID:file:line:column:)-8f2pl`` represents the state _before_ the
action is sent:

```swift
let store = TestStore(/* ... */)
// ℹ️ "on" is the default so technically this is not needed
store.exhaustivity = .on

store.send(.buttonTapped) {
  $0  // Represents the state *before* the action was sent
}
```

This forces you to apply any mutations necessary to `$0` to match the state _after_ the action
is sent.

Non-exhaustive test stores flip this on its head. In such a test store, the `$0` handed to the
trailing closure of `send` represents the state _after_ the action was sent:

```swift
let store = TestStore(/* ... */)
store.exhaustivity = .off

store.send(.buttonTapped) {
  $0  // Represents the state *after* the action was sent
}
```

This means you don't have to make any mutations to `$0` at all and the assertion will already pass.
But, if you do make a mutation, then it must match what is already in the state, thus allowing you
to assert on only the state changes you are interested in.

However, this difference between how ``TestStore`` behaves when run in exhaustive mode versus
non-exhaustive mode does restrict the kinds of mutations you can make inside the trailing closure of
`send`. For example, suppose you had an action in your feature that removes the last element of a
collection:

```swift
case .removeButtonTapped:
  state.values.removeLast()
  return .none
```

To test this in an exhaustive store it is completely fine to do this:

```swift
await store.send(.removeButtonTapped) {
  $0.values.removeLast()
}
```

This works because `$0` is the state before the action is sent, and so we can remove the last
element to prove that the reducer does the same work.

However, in a non-exhaustive store this will not work:

```swift
store.exhaustivity = .off
await store.send(.removeButtonTapped) {
  $0.values.removeLast()  // ❌
}
```

This will either fail, or possibly even crash the test suite. This is because in a non-exhaustive
test store, `$0` in the trailing closure of `send` represents the state _after_ the action has been
sent, and so the last element has already been removed. By executing `$0.values.removeLast()` we are
just removing an additional element from the end.

So, for non-exhaustive test stores you cannot use "relative" mutations for assertions. That is, you
cannot mutate via methods like `removeLast`, `append`, and anything that incrementally applies a
mutation. Instead you must perform an "absolute" mutation, where you fully replace the collection
with its final value:

```swift
store.exhaustivity = .off
await store.send(.removeButtonTapped) {
  $0.values = []
}
```

Or you can weaken the assertion by asserting only on the count of its elements rather than the
content of the element:

```swift
store.exhaustivity = .off
await store.send(.removeButtonTapped) {
  XCTAssertEqual($0.values.count, 0)
}
```

Further, when using non-exhaustive test stores that also show skipped assertions (via
``Exhaustivity/off(showSkippedAssertions:)``), then there is another caveat to keep in mind. In
such test stores, the trailing closure of ``TestStore/send(_:assert:fileID:file:line:column:)-8f2pl`` is invoked
_twice_ by the test store. First with `$0` representing the state after the action is sent to see if
it does not match the true state, and then again with `$0` representing the state before the action
is sent so that we can show what state assertions were skipped.

Because the test store can invoke your trailing assertion closure twice you must be careful if your
closure performs any side effects, because those effects will be executed twice. For example,
suppose you have a domain model that uses the controllable `@Dependency(\.uuid)` to generate a UUID:

```swift
struct Model: Equatable {
  let id: UUID
  init() {
    @Dependency(\.uuid) var uuid
    self.id = uuid()
  }
}
```

This is a perfectly fine to pattern to adopt in the Composable Architecture, but it does cause
trouble when using non-exhaustive test stores and showing skipped assertions. To see this, consider
the following simple reducer that appends a new model to an array when an action is sent:

```swift
@Reducer
struct Feature {
  struct State: Equatable {
    var values: [Model] = []
  }
  enum Action {
    case addButtonTapped
  }
  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .addButtonTapped:
        state.values.append(Model())
        return .none
      }
    }
  }
}
```

We'd like to be able to write a test for this by asserting that when the `addButtonTapped` action
is sent a model is append to the `values` array:

```swift
@Test
func add() async {
  let store = TestStore(initialState: Feature.State()) {
    Feature()
  } withDependencies: {
    $0.uuid = .incrementing
  }
  store.exhaustivity = .off(showSkippedAssertions: true)

  await store.send(.addButtonTapped) {
    $0.values = [Model()]
  }
}
```

While we would expect this simple test to pass, it fails when `showSkippedAssertions` is set to
`true`:

> ❌ Failure: A state change does not match expectation: …
>
> ```diff
>   TestStoreNonExhaustiveTests.Feature.State(
>     values: [
>       [0]: TestStoreNonExhaustiveTests.Model(
> -       id: UUID(00000000-0000-0000-0000-000000000001)
> +       id: UUID(00000000-0000-0000-0000-000000000000)
>       )
>     ]
>   )
> ```
>
> (Expected: −, Actual: +)

This is happening because the trailing closure is invoked twice, and the side effect that is
executed when the closure is first invoked is bleeding over into when it is invoked a second time.

In particular, when the closure is evaluated the first time it causes `Model()` to be constructed,
which secretly generates the next auto-incrementing UUID. Then, when we run the closure again
_another_ `Model()` is constructed, which causes another auto-incrementing UUID to be generated,
and that value does not match our expectations.

If you want to use the `showSkippedAssertions` option for
``Exhaustivity/off(showSkippedAssertions:)`` then you should avoid performing any kind of side
effect in `send`, including using `@Dependency` directly in your models' initializers. Instead
force those values to be provided at the moment of initializing the model:

```swift
struct Model: Equatable {
  let id: UUID
  init(id: UUID) {
    self.id = id
  }
}
```

And then move the responsibility of generating new IDs to the reducer:

```swift
@Reducer
struct Feature {
  // ...
  @Dependency(\.uuid) var uuid
  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .addButtonTapped:
        state.values.append(Model(id: self.uuid()))
        return .none
      }
    }
  }
}
```

And now you can write the test more simply by providing the ID explicitly:

```swift
await store.send(.addButtonTapped) {
  $0.values = [
    Model(id: UUID(0))
  ]
}
```

And it works if you send the action multiple times:

```swift
await store.send(.addButtonTapped) {
  $0.values = [
    Model(id: UUID(0))
  ]
}
await store.send(.addButtonTapped) {
  $0.values = [
    Model(id: UUID(0)),
    Model(id: UUID(1))
  ]
}
```

## Testing gotchas

### Testing host application

This is not well known, but when an application target runs tests it actually boots up a simulator
and runs your actual application entry point in the simulator. This means while tests are running,
your application's code is separately also running. This can be a huge gotcha because it means you
may be unknowingly making network requests, tracking analytics, writing data to user defaults or to
the disk, and more.

This usually flies under the radar and you just won't know it's happening, which can be problematic.
But, once you start using this library and start controlling your dependencies, the problem can
surface in a very visible manner. Typically, when a dependency is used in a test context without
being overridden, a test failure occurs. This makes it possible for your test to pass successfully,
yet for some mysterious reason the test suite fails. This happens because the code in the _app
host_ is now running in a test context, and accessing dependencies will cause test failures.

This only happens when running tests in a _application target_, that is, a target that is
specifically used to launch the application for a simulator or device. This does not happen when
running tests for frameworks or SPM libraries, which is yet another good reason to modularize
your code base.

However, if you aren't in a position to modularize your code base right now, there is a quick
fix. Our [XCTest Dynamic Overlay][xctest-dynamic-overlay-gh] library, which is transitively included
with this library, comes with a property you can check to see if tests are currently running. If
they are, you can omit the entire entry point of your application:

```swift
import SwiftUI
import ComposableArchitecture

@main
struct MyApp: App {
  var body: some Scene {
    WindowGroup {
      if TestContext.current == nil{
        // Your real root view
      }
    }
  }
}
```

That will allow tests to run in the application target without your actual application code
interfering.

### Statically linking your tests target to ComposableArchitecture

If you statically link the `ComposableArchitecture` module to your tests target, its implementation 
may clash with the implementation that is statically linked to the app itself. The most usually 
manifests by getting mysterious test failures telling you that you are using live dependencies in 
your tests even though you have overridden your dependencies. 

In such cases Xcode will display multiple warnings in the console similar to:

> Class _TtC12Dependencies[…] is implemented in both […] and […].
> One of the two will be used. Which one is undefined.

The solution is to remove the static link to `ComposableArchitecture` from your test target, as you 
transitively get access to it through the app itself. In Xcode, go to "Build Phases" and remove
"ComposableArchitecture" from the "Link Binary With Libraries" section. When using SwiftPM, remove 
the "ComposableArchitecture" entry from the `testTarget`'s' `dependencies` array in `Package.swift`.

### Long-living test stores

Test stores should always be created in individual tests when possible, rather than as a shared
instance variable on the test class:

```diff
 @MainActor
 struct FeatureTests {
   // 👎 Don't do this:
-  let store = TestStore(initialState: Feature.State()) {
-    Feature()
-  }

   @Test
   func basics() async {
     // 👍 Do this:
+    let store = TestStore(initialState: Feature.State()) {
+      Feature()
+    }
     // ...
   }
 }
```

This allows you to be very precise in each test: you can start the store in a very specific state,
and override just the dependencies a test cares about.

More crucially, test stores that are held onto by the test class will not be deinitialized during a
test run, and so various exhaustive assertions made during deinitialization will not be made,
_e.g._ that the test store has unreceived actions that should be asserted against, or in-flight
effects that should complete.

If a test store does _not_ deinitialize at the end of a test, you must explicitly call
``TestStore/finish(timeout:fileID:file:line:column:)-klnc`` at the end of the test to retain 
exhaustive coverage:

```swift
await store.finish()
```

[xctest-dynamic-overlay-gh]: http://github.com/pointfreeco/xctest-dynamic-overlay
[Testing-state-changes]: #Testing-state-changes
[Testing-effects]: #Testing-effects
[gh-combine-schedulers]: http://github.com/pointfreeco/combine-schedulers
[gh-xctest-dynamic-overlay]: http://github.com/pointfreeco/xctest-dynamic-overlay
[tca-examples]: https://github.com/pointfreeco/swift-composable-architecture/tree/main/Examples
[gh-swift-clocks]: http://github.com/pointfreeco/swift-clocks
[merowing.info]: https://www.merowing.info
[exhaustive-testing-in-tca]: https://www.merowing.info/exhaustive-testing-in-tca/
[Composable-Architecture-at-Scale]: https://vimeo.com/751173570
[Non-exhaustive-testing]: #Non-exhaustive-testing
[swift-case-paths]: http://github.com/pointfreeco/swift-case-paths



---
File: /Sources/ComposableArchitecture/Documentation.docc/Articles/TreeBasedNavigation.md
---

# Tree-based navigation

Learn about tree-based navigation, that is navigation modeled with optionals and enums, including
how to model your domains, how to integrate features, how to test your features, and more.

## Overview

Tree-based navigation is the process of modeling navigation using optional and enum state. This 
style of navigation allows you to deep-link into any state of your application by simply 
constructing a deeply nested piece of state, handing it off to SwiftUI, and letting it take care of
the rest.

  * [Basics](#Basics)
  * [Enum state](#Enum-state)
  * [Integration](#Integration)
  * [Dismissal](#Dismissal)
  * [Testing](#Testing)

## Basics

The tools for this style of navigation include the ``Presents()`` macro,
``PresentationAction``, the ``Reducer/ifLet(_:action:destination:fileID:filePath:line:column:)-4ub6q`` operator, 
and that is all. Once your feature is properly integrated with those tools you can use all of 
SwiftUI's normal navigation view modifiers, such as `sheet(item:)`, `popover(item:)`, etc.

The process of integrating two features together for navigation largely consists of 2 steps:
integrating the features' domains together and integrating the features' views together. One
typically starts by integrating the features' domains together. This consists of adding the child's
state and actions to the parent, and then utilizing a reducer operator to compose the child reducer
into the parent.

For example, suppose you have a list of items and you want to be able to show a sheet to display a
form for adding a new item. We can integrate state and actions together by utilizing the 
``Presents()`` macro and ``PresentationAction`` type:

```swift
@Reducer
struct InventoryFeature {
  @ObservableState
  struct State: Equatable {
    @Presents var addItem: ItemFormFeature.State?
    var items: IdentifiedArrayOf<Item> = []
    // ...
  }

  enum Action {
    case addItem(PresentationAction<ItemFormFeature.Action>)
    // ...
  }

  // ...
}
``` 

> Note: The `addItem` state is held as an optional. A non-`nil` value represents that feature is
> being presented, and `nil` presents the feature is dismissed.

Next you can integrate the reducers of the parent and child features by using the 
``Reducer/ifLet(_:action:destination:fileID:filePath:line:column:)-4ub6q`` reducer operator, as well as having an 
action in the parent domain for populating the child's state to drive navigation:

```swift
@Reducer
struct InventoryFeature {
  @ObservableState
  struct State: Equatable { /* ... */ }
  enum Action { /* ... */ }
  
  var body: some ReducerOf<Self> {
    Reduce { state, action in 
      switch action {
      case .addButtonTapped:
        // Populating this state performs the navigation
        state.addItem = ItemFormFeature.State()
        return .none

      // ...
      }
    }
    .ifLet(\.$addItem, action: \.addItem) {
      ItemFormFeature()
    }
  }
}
```

> Note: The key path used with `ifLet` focuses on the `@PresentationState` projected value since it 
> uses the `$` syntax. Also note that the action uses a
> [case path](http://github.com/pointfreeco/swift-case-paths), which is analogous to key paths but
> tuned for enums.

That's all that it takes to integrate the domains and logic of the parent and child features. Next
we need to integrate the features' views. This is done by passing a binding of a store to one
of SwiftUI's view modifiers.

For example, to show a sheet from the `addItem` state in the `InventoryFeature`, we can hand
the `sheet(item:)` modifier a binding of a ``Store`` as an argument that is focused on presentation
state and actions:

```swift
struct InventoryView: View {
  @Bindable var store: StoreOf<InventoryFeature>

  var body: some View {
    List {
      // ...
    }
    .sheet(
      item: $store.scope(state: \.addItem, action: \.addItem)
    ) { store in
      ItemFormView(store: store)
    }
  }
}
```

> Note: We use SwiftUI's `@Bindable` property wrapper to produce a binding to a store, which can be
> further scoped using ``SwiftUI/Binding/scope(state:action:fileID:filePath:line:column:)``.

With those few steps completed the domains and views of the parent and child features are now
integrated together, and when the `addItem` state flips to a non-`nil` value the sheet will be
presented, and when it is `nil`'d out it will be dismissed.

In this example we are using the `.sheet` view modifier, but every view modifier SwiftUI ships can
be handed a store in this fashion, including `popover(item:)`, `fullScreenCover(item:),
`navigationDestination(item:)`, and more. This should make it possible to use optional state to
drive any kind of navigation in a SwiftUI application.

## Enum state

While driving navigation with optional state can be powerful, it can also lead to less-than-ideal
modeled domains. In particular, if a feature can navigate to multiple screens then you may be 
tempted to model that with multiple optional values:

```swift
@ObservableState
struct State {
  @Presents var detailItem: DetailFeature.State?
  @Presents var editItem: EditFeature.State?
  @Presents var addItem: AddFeature.State?
  // ...
}
```

However, this can lead to invalid states, such as 2 or more states being non-nil at the same time,
and that can cause a lot of problems. First of all, SwiftUI does not support presenting multiple 
views at the same time from a single view, and so by allowing this in our state we run the risk of 
putting our application into an inconsistent state with respect to SwiftUI.

Second, it becomes more difficult for us to determine what feature is actually being presented. We
must check multiple optionals to figure out which one is non-`nil`, and then we must figure out how
to interpret when multiple pieces of state are non-`nil` at the same time.

And the number of invalid states increases exponentially with respect to the number of features that
can be navigated to. For example, 3 optionals leads to 4 invalid states, 4 optionals leads to 11
invalid states, and 5 optionals leads to 26 invalid states.

For these reasons, and more, it can be better to model multiple destinations in a feature as a
single enum rather than multiple optionals. So the example of above, with 3 optionals, can be
refactored as an enum:

```swift
enum State {
  case addItem(AddFeature.State)
  case detailItem(DetailFeature.State)
  case editItem(EditFeature.State)
  // ...
}
```

This gives us compile-time proof that only one single destination can be active at a time.

In order to utilize this style of domain modeling you must take a few extra steps. First you model a
"destination" reducer that encapsulates the domains and behavior of all of the features that you can
navigate to. Typically it's best to nest this reducer inside the feature that can perform the
navigation, and the ``Reducer()`` macro can do most of the heavy lifting for us by implementing the
entire reducer from a simple description of the features that can be navigated to:

```swift
@Reducer
struct InventoryFeature {
  // ...

  @Reducer
  enum Destination {
    case addItem(AddFeature)
    case detailItem(DetailFeature)
    case editItem(EditFeature)
  }
}
```

> Note: The ``Reducer()`` macro takes this simple enum description of destination features and
> expands it into a fully composed feature that operates on enum state with a case for each
> feature's state. You can expand the macro code in Xcode to see everything that is written for you.

> Tip: Since the ``Reducer()`` macro generates the `State` and `Action` types for you, if you need
> to apply any protocols to those types you can do so in an extension:
> ```swift
> extension InventoryFeature.Destination.State: Equatable, Sendable {}
> ```

With that done we can now hold onto a _single_ piece of optional state in our feature, using the
``Presents()`` macro, and we hold onto the destination actions using the
``PresentationAction`` type:

```swift
@Reducer
struct InventoryFeature {
  @ObservableState
  struct State { 
    @Presents var destination: Destination.State?
    // ...
  }
  enum Action {
    case destination(PresentationAction<Destination.Action>)
    // ...
  }

  // ...
}
```

And then we must make use of the ``Reducer/ifLet(_:action:destination:fileID:filePath:line:column:)-4ub6q`` operator
to integrate the domain of the destination with the domain of the parent feature:

```swift
@Reducer
struct InventoryFeature {
  // ...

  var body: some ReducerOf<Self> {
    Reduce { state, action in 
      // ...
    }
    .ifLet(\.$destination, action: \.destination) 
  }
}
```

> Note: It's not necessary to specify `Destination` in a trialing closure of `ifLet` because it can
> automatically be inferred due to how the `Destination` enum was defined with the ``Reducer()``
> macro.

That completes the steps for integrating the child and parent features together.

Now when we want to present a particular feature we can simply populate the `destination` state
with a case of the enum:

```swift
case addButtonTapped:
  state.destination = .addItem(AddFeature.State())
  return .none
```

And at any time we can figure out exactly what feature is being presented by switching or otherwise
destructuring the single piece of `destination` state rather than checking multiple optional values.

The final step is to make use of the library's scoping powers to focus in on the `Destination`
domain and further isolate a particular case of the state and action enums via dot-chaining.

For example, suppose the "add" screen is presented as a sheet, the "edit" screen is presented 
by a popover, and the "detail" screen is presented in a drill-down. Then we can use the 
`.sheet(item:)`, `.popover(item:)`, and `.navigationDestination(item:)` view modifiers that come
from SwiftUI to have each of those styles of presentation powered by the respective case of the
destination enum.

To do this you must first hold onto the store in a bindable manner by using the `@Bindable` property
wrapper:

```swift
struct InventoryView: View {
  @Bindable var store: StoreOf<InventoryFeature>
  // ...
}
```

And then in the `body` of the view you can use the
``SwiftUI/Binding/scope(state:action:fileID:filePath:line:column:)`` operator to derive bindings from `$store`:

```swift
var body: some View {
  List {
    // ...
  }
  .sheet(
    item: $store.scope(
      state: \.destination?.addItem,
      action: \.destination.addItem
    )
  ) { store in 
    AddFeatureView(store: store)
  }
  .popover(
    item: $store.scope(
      state: \.destination?.editItem,
      action: \.destination.editItem
    )
  ) { store in 
    EditFeatureView(store: store)
  }
  .navigationDestination(
    item: $store.scope(
      state: \.destination?.detailItem,
      action: \.destination.detailItem
    )
  ) { store in 
    DetailFeatureView(store: store)
  }
}
```

With those steps completed you can be sure that your domains are modeled as concisely as possible.
If the "add" item sheet was presented, and you decided to mutate the `destination` state to point
to the `.detailItem` case, then you can be certain that the sheet will be dismissed and the 
drill-down will occur immediately. 

### API Unification

One of the best features of tree-based navigation is that it unifies all forms of navigation with a
single style of API. First of all, regardless of the type of navigation you plan on performing,
integrating the parent and child features together can be done with the single
``Reducer/ifLet(_:action:destination:fileID:filePath:line:column:)-4ub6q`` operator. This one single API services
all forms of optional-driven navigation.

And then in the view, whether you are wanting to perform a drill-down, show a sheet, display
an alert, or even show a custom navigation component, all you need to do is invoke an API that
is provided a store focused on some ``PresentationState`` and ``PresentationAction``. If you do
that, then the API can handle the rest, making sure to present the child view when the state
becomes non-`nil` and dismissing when it goes back to `nil`.

This means that theoretically you could have a single view that needs to be able to show a sheet,
popover, drill-down, alert _and_ confirmation dialog, and all of the work to display the various
forms of navigation could be as simple as this:

```swift
.sheet(
  item: $store.scope(state: \.addItem, action: \.addItem)
) { store in 
  AddFeatureView(store: store)
}
.popover(
  item: $store.scope(state: \.editItem, action: \.editItem)
) { store in 
  EditFeatureView(store: store)
}
.navigationDestination(
  item: $store.scope(state: \.detailItem, action: \.detailItem)
) { store in 
  DetailFeatureView(store: store)
}
.alert(
  $store.scope(state: \.alert, action: \.alert)
)
.confirmationDialog(
  $store.scope(state: \.confirmationDialog, action: \.confirmationDialog)
)
```

In each case we provide a store scoped to the presentation domain, and a view that will be presented
when its corresponding state flips to non-`nil`. It is incredibly powerful to see that so many
seemingly disparate forms of navigation can be unified under a single style of API.

#### Backwards compatible availability

Depending on your deployment target, certain APIs may be unavailable. For example, if you target \
platforms earlier than iOS 16, macOS 13, tvOS 16 and watchOS 9, then you cannot use 
`navigationDestination`. Instead you can use `NavigationLink`, but you must define helper for 
driving navigation off of a binding of data rather than just a simple boolean. Just paste
the following into your project:

```swift
@available(iOS, introduced: 13, deprecated: 16)
@available(macOS, introduced: 10.15, deprecated: 13)
@available(tvOS, introduced: 13, deprecated: 16)
@available(watchOS, introduced: 6, deprecated: 9)
extension NavigationLink {
  public init<D, C: View>(
    item: Binding<D?>,
    onNavigate: @escaping (_ isActive: Bool) -> Void,
    @ViewBuilder destination: (D) -> C,
    @ViewBuilder label: () -> Label
  ) where Destination == C? {
    self.init(
      destination: item.wrappedValue.map(destination),
      isActive: Binding(
        get: { item.wrappedValue != nil },
        set: { isActive, transaction in
          onNavigate(isActive)
          if !isActive {
            item.transaction(transaction).wrappedValue = nil
          }
        }
      ),
      label: label
    )
  }
}
```

That gives you the ability to drive a `NavigationLink` from state. When the link is tapped the
`onNavigate` closure will be invoked, giving you the ability to populate state. And when the 
feature is dismissed, the state will be `nil`'d out.

## Integration

Once your features are integrated together using the steps above, your parent feature gets instant
access to everything happening inside the child feature. You can use this as a means to integrate
the logic of child and parent features. For example, if you want to detect when the "Save" button
inside the edit feature is tapped, you can simply destructure on that action. This consists of
pattern matching on the ``PresentationAction``, then the ``PresentationAction/presented(_:)`` case,
then the feature you are interested in, and finally the action you are interested in:

```swift
case .destination(.presented(.editItem(.saveButtonTapped))):
  // ...
```

Once inside that case you can then try extracting out the feature state so that you can perform
additional logic, such as closing the "edit" feature and saving the edited item to the database:

```swift
case .destination(.presented(.editItem(.saveButtonTapped))):
  guard case let .editItem(editItemState) = state.destination
  else { return .none }

  state.destination = nil
  return .run { _ in
    self.database.save(editItemState.item)
  }
```

## Dismissal

Dismissing a presented feature is as simple as `nil`-ing out the state that represents the 
presented feature:

```swift
case .closeButtonTapped:
  state.destination = nil
  return .none
```

In order to `nil` out the presenting state you must have access to that state, and usually only the
parent has access, but often we would like to encapsulate the logic of dismissing a feature to be
inside the child feature without needing explicit communication with the parent.

SwiftUI provides a wonderful tool for allowing child _views_ to dismiss themselves from the parent,
all without any explicit communication with the parent. It's an environment value called `dismiss`,
and it can be used like so:

```swift
struct ChildView: View {
  @Environment(\.dismiss) var dismiss
  var body: some View {
    Button("Close") { self.dismiss() }
  }
}
```

When `self.dismiss()` is invoked, SwiftUI finds the closest parent view with a presentation, and
causes it to dismiss by writing `false` or `nil` to the binding that drives the presentation. This 
can be incredibly useful, but it is also relegated to the view layer. It is not possible to use 
`dismiss` elsewhere, like in an observable object, which would allow you to have nuanced logic
for dismissal such as validation or async work.

The Composable Architecture has a similar tool, except it is appropriate to use from a reducer,
where the rest of your feature's logic and behavior resides. It is accessed via the library's
dependency management system (see <doc:DependencyManagement>) using ``DismissEffect``:

```swift
@Reducer
struct Feature {
  @ObservableState
  struct State { /* ... */ }
  enum Action { 
    case closeButtonTapped
    // ...
  }
  @Dependency(\.dismiss) var dismiss
  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .closeButtonTapped:
        return .run { _ in await self.dismiss() }
      }
    }
  }
}
```

> Note: The ``DismissEffect`` function is async which means it cannot be invoked directly inside a 
> reducer. Instead it must be called from ``Effect/run(priority:operation:catch:fileID:filePath:line:column:)``.

When `self.dismiss()` is invoked it will `nil` out the state responsible for presenting the feature
by sending a ``PresentationAction/dismiss`` action back into the system, causing the feature to be
dismissed. This allows you to encapsulate the logic for dismissing a child feature entirely inside 
the child domain without explicitly communicating with the parent.

> Note: Because dismissal is handled by sending an action, it is not valid to ever send an action
> after invoking `dismiss()`:
> 
> ```swift
> return .run { send in 
>   await self.dismiss()
>   await send(.tick)  // ⚠️
> }
> ```
> 
> To do so would be to send an action for a feature while its state is `nil`, and that will cause
> a runtime warning in Xcode and a test failure when running tests.

> Warning: SwiftUI's environment value `@Environment(\.dismiss)` and the Composable Architecture's
> dependency value `@Dependency(\.dismiss)` serve similar purposes, but are completely different 
> types. SwiftUI's environment value can only be used in SwiftUI views, and this library's
> dependency value can only be used inside reducers.

## Testing

A huge benefit of properly modeling your domains for navigation is that testing becomes quite easy.
Further, using "non-exhaustive testing" (see <doc:TestingTCA#Non-exhaustive-testing>) can be very 
useful for testing navigation since you often only want to assert on a few high level details and 
not all state mutations and effects.

As an example, consider the following simple counter feature that wants to dismiss itself if its
count is greater than or equal to 5:

```swift
@Reducer
struct CounterFeature {
  @ObservableState
  struct State: Equatable {
    var count = 0
  }
  enum Action {
    case decrementButtonTapped
    case incrementButtonTapped
  }

  @Dependency(\.dismiss) var dismiss

  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .decrementButtonTapped:
        state.count -= 1
        return .none

      case .incrementButtonTapped:
        state.count += 1
        return state.count >= 5
          ? .run { _ in await self.dismiss() }
          : .none
      }
    }
  }
}
```

And then let's embed that feature into a parent feature using the ``Presents()`` macro, 
``PresentationAction`` type and ``Reducer/ifLet(_:action:destination:fileID:filePath:line:column:)-4ub6q``
operator:

```swift
@Reducer
struct Feature {
  @ObservableState
  struct State: Equatable {
    @Presents var counter: CounterFeature.State?
  }
  enum Action {
    case counter(PresentationAction<CounterFeature.Action>)
  }
  var body: some Reducer<State, Action> {
    Reduce { state, action in
      // Logic and behavior for core feature.
    }
    .ifLet(\.$counter, action: \.counter) {
      CounterFeature()
    }
  }
}
```

Now let's try to write a test on the `Feature` reducer that proves that when the child counter 
feature's count is incremented above 5 it will dismiss itself. To do this we will construct a 
``TestStore`` for `Feature` that starts in a state with the count already set to 3:

```swift
@Test
func dismissal() {
  let store = TestStore(
    initialState: Feature.State(
      counter: CounterFeature.State(count: 3)
    )
  ) {
    CounterFeature()
  }
}
```

Then we can send the `.incrementButtonTapped` action in the counter child feature to confirm
that the count goes up by one:

```swift
await store.send(\.counter.incrementButtonTapped) {
  $0.counter?.count = 4
}
```

And then we can send it one more time to see that the count goes up to 5:

```swift 
await store.send(\.counter.incrementButtonTapped) {
  $0.counter?.count = 5
}
```

And then we finally expect that the child dismisses itself, which manifests itself as the 
``PresentationAction/dismiss`` action being sent to `nil` out the `counter` state, which we can
assert using the ``TestStore/receive(_:timeout:assert:fileID:file:line:column:)-53wic`` method on ``TestStore``:

```swift
await store.receive(\.counter.dismiss) {
  $0.counter = nil
}
```

This shows how we can write very nuanced tests on how parent and child features interact with each
other.

However, the more complex the features become, the more cumbersome testing their integration can be.
By default, ``TestStore`` requires us to be exhaustive in our assertions. We must assert on how
every piece of state changes, how every effect feeds data back into the system, and we must make
sure that all effects finish by the end of the test (see <doc:TestingTCA> for more info).

But ``TestStore`` also supports a form of testing known as "non-exhaustive testing" that allows you
to assert on only the parts of the features that you actually care about (see 
<doc:TestingTCA#Non-exhaustive-testing> for more info).

For example, if we turn off exhaustivity on the test store (see ``TestStore/exhaustivity``) then we
can assert at a high level that when the increment button is tapped twice that eventually we receive
a dismiss action:

```swift
@Test
func dismissal() {
  let store = TestStore(
    initialState: Feature.State(
      counter: CounterFeature.State(count: 3)
    )
  ) {
    CounterFeature()
  }
  store.exhaustivity = .off

  await store.send(\.counter.incrementButtonTapped)
  await store.send(\.counter.incrementButtonTapped)
  await store.receive(\.counter.dismiss) 
}
```

This essentially proves the same thing that the previous test proves, but it does so in much fewer
lines and is more resilient to future changes in the features that we don't necessarily care about.

That is the basics of testing, but things get a little more complicated when you leverage the 
concepts outlined in <doc:TreeBasedNavigation#Enum-state> in which you model multiple destinations
as an enum instead of multiple optionals. In order to assert on state changes when using enum
state you must chain into the particular case to make a mutation:

```swift
await store.send(\.destination.counter.incrementButtonTapped) {
  $0.destination?.counter?.count = 4
}
```



---
File: /Sources/ComposableArchitecture/Documentation.docc/Articles/WhatIsNavigation.md
---

# What is navigation?

Learn about the two main forms of state-driven navigation, tree-based and stack-based navigation, 
as well as their tradeoffs.

## Overview

State-driven navigation broadly falls into 2 main categories: tree-based, where you use optionals
and enums to model navigation, and stack-based, where you use flat collections to model navigation.
Nearly all navigations will use a combination of the two styles, but it is important to know
their strengths and weaknesses.

* [Tree-based navigation](#Tree-based-navigation)
* [Stack-based navigation](#Stack-based-navigation)
* [Tree-based vs stack-based navigation](#Tree-based-vs-stack-based-navigation)
  * [Pros of tree-based navigation](#Pros-of-tree-based-navigation)
  * [Cons of tree-based navigation](#Cons-of-tree-based-navigation)
  * [Pros of stack-based navigation](#Pros-of-stack-based-navigation)
  * [Cons of stack-based navigation](#Cons-of-stack-based-navigation)


## Defining navigation

The word "navigation" can mean a lot of different things to different people. For example, most
people would say that an example of "navigation" is the drill-down style of navigation afforded to 
us by `NavigationStack` in SwiftUI and `UINavigationController` in UIKit "navigation". 
However, if drill-downs are considered navigation, then surely sheets and fullscreen covers should 
be too.  The only difference is that sheets and covers animate from bottom-to-top instead of from 
right-to-left, but is that actually substantive?

And if sheets and covers are considered navigation, then certainly popovers should be too. We can
even expand our horizons to include more styles of navigation, such as alerts and confirmation
dialogs, and even custom forms of navigation that are not handed down to us from Apple.

So, for the purposes of this documentation, we will use the following loose definition of 
"navigation":

> Definition: **Navigation** is a change of mode in the application.

Each of the examples we considered above, such as drill-downs, sheets, popovers, covers, alerts, 
dialogs, and more, are all a "change of mode" in the application.

But, so far we have just defined one term, "navigation", by using another undefined term, 
"change of mode", so we will further make the following definition:

> Definition: A **change of mode** is when some piece of state goes from not existing to existing,
or vice-versa.

So, when a piece of state switches from not existing to existing, that represents a navigation and 
change of mode in the application, and when the state switches back to not existing, it represents 
undoing the navigation and returning to the previous mode.

That is very abstract way of describing state-driven navigation, and the next two sections make
these concepts much more concrete for the two main forms of state-driven navigation:
[tree-based](#Tree-based-navigation) and [stack-based](#Stack-based-navigation) navigation.

## Tree-based navigation

In the previous section we defined state-driven navigation as being controlled by the existence or
non-existence of state. The term "existence" was not defined, and there are a few ways in which
existence can be defined. If we define the existence or non-existence of state as being represented
by Swift's `Optional` type, then we call this "tree-based" navigation because when multiple states
of navigation are nested they form a tree-like structure.

For example, suppose you have an inventory feature with a list of items such that tapping one of
those items performs a drill-down navigation to a detail screen for the item. Then that can be
modeled with the ``Presents()`` macro pointing to some optional state:

```swift
@Reducer
struct InventoryFeature {
  @ObservableState
  struct State {
    @Presents var detailItem: DetailItemFeature.State?
    // ...
  }
  // ...
}
```

Then, inside that detail screen there may be a button to edit the item in a sheet, and that too can
be modeled with the ``Presents()`` macro pointing to a piece of optional state:

```swift
@Reducer
struct DetailItemFeature {
  @ObservableState
  struct State {
    @Presents var editItem: EditItemFeature.State?
    // ...
  }
  // ...
}
```

And further, inside the "edit item" feature there can be a piece of optional state that represents
whether or not an alert is displayed:

```swift
@Reducer
struct EditItemFeature {
  struct State {
    @Presents var alert: AlertState<AlertAction>?
    // ...
  }
  // ...
}
```

And this can continue on and on for as many layers of navigation that exist in the application.

With that done, the act of deep-linking into the application is a mere exercise in constructing
a piece of deeply nested state. So, if we wanted to launch the inventory view into a state where
we are drilled down to a particular item _with_ the edit sheet opened _and_ an alert opened, we 
simply need to construct the piece of state that represents the navigation:

```swift
InventoryView(
  store: Store(
    initialState: InventoryFeature.State(
      detailItem: DetailItemFeature.State(      // Drill-down to detail screen
        editItem: EditItemFeature.State(        // Open edit modal
          alert: AlertState {                   // Open alert
            TextState("This item is invalid.")
          }
        )
      )
    )
  ) {
    InventoryFeature()
  }
)
```

In the above we can start to see the tree-like structure of this form of domain modeling. Each 
feature in your application represents a node of the tree, and each destination you can navigate to
represents a branch from the node. Then the act of navigating to a new feature corresponds to
building another nested piece of state.

That is the basics of tree-based navigation. Read the dedicated <doc:TreeBasedNavigation> article
for information on how to use the tools that come with the Composable Architecture to implement
tree-based navigation in your application.

## Stack-based navigation

In the [previous section](#Tree-based-navigation) we defined "tree-based" navigation as the process
of modeling the presentation of a child feature with optional state. This takes on a tree-like
structure in which a deeply nested feature is represented by a deeply nested piece of state.

There is another powerful tool for modeling the existence and non-existence of state for driving
navigation: collections. This is most used with SwiftUI's `NavigationStack` view in which 
an entire stack of features are represented by a collection of data. When an item is added to the 
collection it represents a new feature being pushed onto the stack, and when an item is removed from 
the collection it represents popping the feature off the stack.

Typically one defines an enum that holds all of the possible features that can be navigated to on
the stack, so continuing the analogy from the previous section, if an inventory list can navigate to
a detail feature for an item and then navigate to an edit screen, this can be represented by:

```swift
enum Path {
  case detail(DetailItemFeature.State)
  case edit(EditItemFeature.State)
  // ...
}
```

Then a collection of these states represents the features that are presented on the stack:

```swift
let path: [Path] = [
  .detail(DetailItemFeature.State(item: item)),
  .edit(EditItemFeature.State(item: item)),
  // ...
]
```

This collection of `Path` elements can be any length necessary, including very long to represent
being drilled down many layers deep, or even empty to represent that we are at the root of the 
stack.

That is the basics of stack-based navigation. Read the dedicated 
<doc:StackBasedNavigation> article for information on how to use the tools that come with the 
Composable Architecture to implement stack-based navigation in your application.

## Tree-based vs stack-based navigation

Most real-world applications will use a mixture of tree-based and stack-based navigation. For
example, the root of your application may use stack-based navigation with a 
`NavigationStack` view, but then each feature inside the stack may use tree-based 
navigation for showing sheets, popovers, alerts, etc. But, there are pros and cons to each form of 
navigation, and so it can be important to be aware of their differences when modeling your domains.

#### Pros of tree-based navigation

  * Tree-based navigation is a very concise way of modeling navigation. You get to statically 
    describe all of the various navigation paths that are valid for your application, and that makes
    it impossible to restore a navigation that is invalid for your application. For example, if it
    only makes sense to navigate to an "edit" screen after a "detail" screen, then your detail
    feature needs only to hold onto a piece of optional edit state:

    ```swift
    @ObservableState
    struct State {
      @Presents var editItem: EditItemFeature.State?
      // ...
    }
    ```

    This statically enforces the relationship that we can only navigate to the edit screen from the
    detail screen.

  * Related to the previous pro, tree-based navigation also allows you to describe the finite number
    of navigation paths that your app supports.

  * If you modularize the features of your application, then those feature modules will be more
    self-contained when built with the tools of tree-based navigation. This means that Xcode
    previews and preview apps built for the feature will be fully functional.

    For example, if you have a `DetailFeature` module that holds all of the logic and views for the
    detail feature, then you will be able to navigate to the edit feature in previews because the
    edit feature's domain is directly embedded in the detail feature.

  * Related to the previous pro, because features are tightly integrated together it makes writing
    unit tests for their integration very simple. You can write deep and nuanced tests that assert 
    how the detail feature and edit feature integrate together, allowing you to prove that they
    interact in the correct way.

  * Tree-based navigation unifies all forms of navigation into a single, concise style of API, 
    including drill-downs, sheets, popovers, covers, alerts, dialogs and a lot more. See
    <doc:TreeBasedNavigation#API-Unification> for more information.

#### Cons of tree-based navigation

  * Unfortunately it can be cumbersome to express complex or recursive navigation paths using
    tree-based navigation. For example, in a movie application you can navigate to a movie, then a
    list of actors in the movies, then to a particular actor, and then to the same movie you started
    at. This creates a recursive dependency between features that can be difficult to model in Swift
    data types.

  * By design, tree-based navigation couples features together. If you can navigate to an edit
    feature from a detail feature, then you must be able to compile the entire edit feature in order
    to compile the detail feature. This can eventually slow down compile times, especially when you
    work on features closer to the root of the application since you must build all destination
    features.

  * Historically, tree-based navigation is more susceptible to SwiftUI's navigation bugs, in 
    particular when dealing with drill-down navigation. However, many of these bugs have been fixed
    in iOS 16.4 and so is less of a concern these days.

#### Pros of stack-based navigation

  * Stack-based navigation can easily handle complex and recursive navigation paths. The example we
    considered earlier, that of navigating through movies and actors, is handily accomplished with
    an array of feature states:

    ```swift
    let path: [Path] = [
      .movie(/* ... */),
      .actors(/* ... */),
      .actor(/* ... */),
      .movies(/* ... */),
      .movie(/* ... */),
    ]
    ```

    Notice that we start on the movie feature and end on the movie feature. There is no real 
recursion in this navigation since it is just a flat array.

* Each feature held in the stack can typically be fully decoupled from all other screens on the
stack. This means the features can be put into their own modules with no dependencies on each
other, and can be compiled without compiling any other features.

* The `NavigationStack` API in SwiftUI typically has fewer bugs than 
`NavigationLink(isActive:)` and `navigationDestination(isPresented:)`, which are used in tree-based 
navigation. There are still a few bugs in `NavigationStack`, but on average it is a lot 
more stable.

#### Cons of stack-based navigation

  * Stack-based navigation is not a concise tool. It makes it possible to express navigation
    paths that are completely non-sensical. For example, even though it only makes sense to navigate
    to an edit screen from a detail screen, in a stack it would be possible to present the features
    in the reverse order:

    ```swift
    let path: [Path] = [
      .edit(/* ... */),
      .detail(/* ... */)
    ]
    ```
  
    That is completely non-sensical. What does it mean to drill down to an edit screen and _then_
    a detail screen. You can create other non-sensical navigation paths, such as multiple edit
    screens pushed on one after another:
  
    ```swift
    let path: [Path] = [
      .edit(/* ... */),
      .edit(/* ... */),
      .edit(/* ... */),
    ]
    ```
  
    This too is completely non-sensical, and it is a drawback to the stack-based approach when you 
    want a finite number of well-defined navigation paths in your app.

  * If you were to modularize your application and put each feature in its own module, then those
    features, when run in isolation in an Xcode preview, would be mostly inert. For example, a
    button in the detail feature for drilling down to the edit feature can't possibly work in an
    Xcode preview since the detail and edit features have been completely decoupled. This makes it
    so that you cannot test all of the functionality of the detail feature in an Xcode preview, and
    instead have to resort to compiling and running the full application in order to preview
    everything.

  * Related to the above, it is also more difficult to unit test how multiple features integrate
    with each other. Because features are fully decoupled we cannot easily test how the detail and
    edit feature interact with each other. The only way to write that test is to compile and run the
    entire application.

  * And finally, stack-based navigation and `NavigationStack` only applies to drill-downs 
    and does not address at all other forms of navigation, such as sheets, popovers, alerts, etc. 
    It's still on you to do the work to decouple those kinds of navigations.

---

We have now defined the basic terms of navigation, in particular state-driven navigation, and we
have further divided navigation into two categories: tree-based and stack-based. Continue reading
the dedicated articles <doc:TreeBasedNavigation> and <doc:StackBasedNavigation> to learn about the 
tools the Composable Architecture provides for modeling your domains and integrating features 
together for navigation.



---
File: /Sources/ComposableArchitecture/Documentation.docc/Extensions/Action.md
---

# ``ComposableArchitecture/Reducer/Action``

## Topics

### View actions

- ``ViewAction``
- ``ViewAction(for:)``
- ``ViewActionSending``



---
File: /Sources/ComposableArchitecture/Documentation.docc/Extensions/Effect.md
---

# ``ComposableArchitecture/Effect``

## Topics

### Creating an effect

- ``none``
- ``run(priority:operation:catch:fileID:filePath:line:column:)``
- ``send(_:)``
- ``EffectOf``
- ``TaskResult``

### Cancellation

- ``cancellable(id:cancelInFlight:)``
- ``cancel(id:)``
- ``ComposableArchitecture/withTaskCancellation(id:cancelInFlight:isolation:operation:)``
- ``_Concurrency/Task/cancel(id:)``

### Composition

- ``map(_:)``
- ``merge(_:)-5ai73``
- ``merge(_:)-8ckqn``
- ``merge(with:)``
- ``concatenate(_:)-3iza9``
- ``concatenate(_:)-4gba2``
- ``concatenate(with:)``

### SwiftUI integration

- ``animation(_:)``
- ``transaction(_:)``

### Combine integration

- ``publisher(_:)``
- ``debounce(id:for:scheduler:options:)``
- ``throttle(id:for:scheduler:latest:)``



---
File: /Sources/ComposableArchitecture/Documentation.docc/Extensions/EffectRun.md
---

# ``ComposableArchitecture/Effect/run(priority:operation:catch:fileID:filePath:line:column:)``

## Topics

### Sending actions

- ``Send``



---
File: /Sources/ComposableArchitecture/Documentation.docc/Extensions/EffectSend.md
---

# ``ComposableArchitecture/Effect/send(_:)``

## Topics

### Animating actions

- ``Effect/send(_:animation:)``



---
File: /Sources/ComposableArchitecture/Documentation.docc/Extensions/IdentifiedAction.md
---

# ``ComposableArchitecture/IdentifiedAction``

## Topics

### Supporting types

- ``IdentifiedActionOf``



---
File: /Sources/ComposableArchitecture/Documentation.docc/Extensions/NavigationLinkState.md
---

# ``SwiftUI/NavigationLink/init(state:label:fileID:filePath:line:column:)``

## Topics

### Overloads

- ``SwiftUI/NavigationLink/init(_:state:fileID:line:)-1fmz8``
- ``SwiftUI/NavigationLink/init(_:state:fileID:line:)-3xjq3``



---
File: /Sources/ComposableArchitecture/Documentation.docc/Extensions/ObservableState.md
---

# ``ComposableArchitecture/ObservableState()``

## Topics

### Conformance

- ``ObservableState``

### Change tracking

- ``ObservableStateID``
- ``ObservationStateRegistrar``

### Supporting macros

- ``ObservationStateTracked()``
- ``ObservationStateIgnored()``



---
File: /Sources/ComposableArchitecture/Documentation.docc/Extensions/Presents.md
---

# ``ComposableArchitecture/Presents()``

## Topics

### Property wrapper

- ``PresentationState``



---
File: /Sources/ComposableArchitecture/Documentation.docc/Extensions/Reduce.md
---

# ``ComposableArchitecture/Reduce``

## Topics

### Creating a reducer

- ``init(_:)-6xl6k``

### Type erased reducers

- ``init(_:)-9kwa6``

### Reduce conformance

- ``Reducer/body-20w8t``
- ``Reducer/reduce(into:action:)-1t2ri``



---
File: /Sources/ComposableArchitecture/Documentation.docc/Extensions/Reducer.md
---

# ``ComposableArchitecture/Reducer``

The ``Reducer`` protocol describes how to evolve the current state of an application to the next
state, given an action, and describes what ``Effect``s should be executed later by the store, if
any. Types that conform to this protocol represent the domain, logic and behavior for a feature.
Conformances to ``Reducer`` can be written by hand, but the ``Reducer()`` can make your reducers 
more concise and more powerful.

* [Conforming to the Reducer protocol](#Conforming-to-the-Reducer-protocol)
* [Using the @Reducer macro](#Using-the-Reducer-macro)
  * [@CasePathable and @dynamicMemberLookup enums](#CasePathable-and-dynamicMemberLookup-enums)
  * [Automatic fulfillment of reducer requirements](#Automatic-fulfillment-of-reducer-requirements)
  * [Destination and path reducers](#Destination-and-path-reducers)
    * [Navigating to non-reducer features](#Navigating-to-non-reducer-features)
    * [Synthesizing protocol conformances on State and Action](#Synthesizing-protocol-conformances-on-State-and-Action)
    * [Nested enum reducers](#Nested-enum-reducers)
  * [Gotchas](#Gotchas)
    * [Autocomplete](#Autocomplete)
    * [#Preview and enum reducers](#Preview-and-enum-reducers)
    * [CI build failures](#CI-build-failures)

## Conforming to the Reducer protocol

The bare minimum of conforming to the ``Reducer`` protocol is to provide a ``Reducer/State`` type
that represents the state your feature needs to do its job, a ``Reducer/Action`` type that
represents the actions users can perform in your feature (as well as actions that effects can
feed back into the system), and a ``Reducer/body-20w8t`` property that compose your feature
together with any other features that are needed (such as for navigation).

As a very simple example, a "counter" feature could model its state as a struct holding an integer:

```swift
struct CounterFeature: Reducer {
  @ObservableState
  struct State {
    var count = 0
  }
}
```

> Note: We have added the ``ObservableState()`` to `State` here so that the view can automatically
> observe state changes. In future versions of the library this macro will be automatically applied
> by the ``Reducer()`` macro.

The actions would be just two cases for tapping an increment or decrement button:

```swift
struct CounterFeature: Reducer {
  // ...
  enum Action {
    case decrementButtonTapped
    case incrementButtonTapped
  }
}
```

The logic of your feature is implemented by mutating the feature's current state when an action
comes into the system. This is most easily done by constructing a ``Reduce`` inside the
``Reducer/body-20w8t`` of your reducer:

```swift
struct CounterFeature: Reducer {
  // ...
  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .decrementButtonTapped:
        state.count -= 1
        return .none
      case .incrementButtonTapped:
        state.count += 1  
        return .none
      }
    }
  }
}
```

The ``Reduce`` reducer's first responsibility is to mutate the feature's current state given an
action. Its second responsibility is to return effects that will be executed asynchronously and feed
their data back into the system. Currently `Feature` does not need to run any effects, and so
``Effect/none`` is returned.

If the feature does need to do effectful work, then more would need to be done. For example, suppose
the feature has the ability to start and stop a timer, and with each tick of the timer the `count`
will be incremented. That could be done like so:

```swift
struct CounterFeature: Reducer {
  @ObservableState
  struct State {
    var count = 0
  }
  enum Action {
    case decrementButtonTapped
    case incrementButtonTapped
    case startTimerButtonTapped
    case stopTimerButtonTapped
    case timerTick
  }
  enum CancelID { case timer }

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .decrementButtonTapped:
        state.count -= 1
        return .none

      case .incrementButtonTapped:
        state.count += 1
        return .none

      case .startTimerButtonTapped:
        return .run { send in
          while true {
            try await Task.sleep(for: .seconds(1))
            await send(.timerTick)
          }
        }
        .cancellable(CancelID.timer)

      case .stopTimerButtonTapped:
        return .cancel(CancelID.timer)

      case .timerTick:
        state.count += 1
        return .none
      }
    }
  }
}
```

> Note: This sample emulates a timer by performing an infinite loop with a `Task.sleep` inside. This
> is simple to do, but is also inaccurate since small imprecisions can accumulate. It would be
> better to inject a clock into the feature so that you could use its `timer` method. Read the
> <doc:DependencyManagement> and <doc:TestingTCA> articles for more information.

That is the basics of implementing a feature as a conformance to ``Reducer``. 

## Using the @Reducer macro

While you technically can conform to the ``Reducer`` protocol directly, as we did above, the
``Reducer()`` macro can automate many aspects of implementing features for you. At a bare minimum,
all you have to do is annotate your reducer with `@Reducer` and you can even drop the `Reducer`
conformance:

```diff
+@Reducer
-struct CounterFeature: Reducer {
+struct CounterFeature {
   @ObservableState
   struct State {
     var count = 0
   }
   enum Action {
     case decrementButtonTapped
     case incrementButtonTapped
   }
   var body: some ReducerOf<Self> {
     Reduce { state, action in
       switch action {
       case .decrementButtonTapped:
         state.count -= 1
         return .none
       case .incrementButtonTapped:
         state.count += 1  
         return .none
       }
     }
   }
 }
```

There are a number of things the ``Reducer()`` macro does for you:

### @CasePathable and @dynamicMemberLookup enums

The `@Reducer` macro automatically applies the [`@CasePathable`][casepathable-docs] macro to your
`Action` enum:

```diff
+@CasePathable
 enum Action {
   // ...
 }
```

[Case paths][casepaths-gh] are a tool that bring the power and ergonomics of key paths to enum
cases, and they are a vital tool for composing reducers together.

In particular, having this macro applied to your `Action` enum will allow you to use key path
syntax for specifying enum cases in various APIs in the library, such as
``Reducer/ifLet(_:action:destination:fileID:filePath:line:column:)-4ub6q``,
``Reducer/forEach(_:action:destination:fileID:filePath:line:column:)-9svqb``, ``Scope``, and more.

Further, if the ``Reducer/State`` of your feature is an enum, which is useful for modeling a feature
that can be one of multiple mutually exclusive values, the ``Reducer()`` will apply the
`@CasePathable` macro, as well as `@dynamicMemberLookup`:

```diff
+@CasePathable
+@dynamicMemberLookup
 enum State {
   // ...
 }
```

This will allow you to use key path syntax for specifying case paths to the `State`'s cases, as well
as allow you to use dot-chaining syntax for optionally extracting a case from the state. This can be
useful when using the operators that come with the library that allow for driving navigation from an
enum of options:

```swift
.sheet(
  item: $store.scope(state: \.destination?.editForm, action: \.destination.editForm)
) { store in
  FormView(store: store)
}
```

The syntax `state: \.destination?.editForm` is only possible due to both `@dynamicMemberLookup` and
`@CasePathable` being applied to the `State` enum.

### Automatic fulfillment of reducer requirements

The ``Reducer()`` macro will automatically fill in any ``Reducer`` protocol requirements that you
leave off. For example, something as simple as this compiles:

```swift
@Reducer
struct Feature {}
```

The `@Reducer` macro will automatically insert an empty ``Reducer/State`` struct, an empty
``Reducer/Action`` enum, and an empty ``Reducer/body-swift.property``. This effectively means that
`Feature` is a logicless, behaviorless, inert reducer.

Having these requirements automatically fulfilled for you can be handy for slowly filling them in
with their real implementations. For example, this `Feature` reducer could be integrated in a parent
domain using the library's navigation tools, all without having implemented any of the domain yet.
Then, once we are ready we can start implementing the real logic and behavior of the feature.

### Destination and path reducers

There is a common pattern in the Composable Architecture of representing destinations a feature can
navigate to as a reducer that operates on enum state, with a case for each feature that can be
navigated to. This is explained in great detail in the <doc:TreeBasedNavigation> and
<doc:StackBasedNavigation> articles.

This form of domain modeling can be very powerful, but also incur a bit of boilerplate. For example,
if a feature can navigate to 3 other features, then one might have a `Destination` reducer like the
following:

```swift
@Reducer
struct Destination {
  @ObservableState
  enum State {
    case add(FormFeature.State)
    case detail(DetailFeature.State)
    case edit(EditFeature.State)
  }
  enum Action {
    case add(FormFeature.Action)
    case detail(DetailFeature.Action)
    case edit(EditFeature.Action)
  }
  var body: some ReducerOf<Self> {
    Scope(state: \.add, action: \.add) {
      FormFeature()
    }
    Scope(state: \.detail, action: \.detail) {
      DetailFeature()
    }
    Scope(state: \.edit, action: \.edit) {
      EditFeature()
    }
  }
}
```

It's not the worst code in the world, but it is 24 lines with a lot of repetition, and if we need to
add a new destination we must add a case to the ``Reducer/State`` enum, a case to the
``Reducer/Action`` enum, and a ``Scope`` to the ``Reducer/body-swift.property``.

The ``Reducer()`` macro is now capable of generating all of this code for you from the following
simple declaration

```swift
@Reducer
enum Destination {
  case add(FormFeature)
  case detail(DetailFeature)
  case edit(EditFeature)
}
```

24 lines of code has become 6. The `@Reducer` macro can now be applied to an _enum_ where each case
holds onto the reducer that governs the logic and behavior for that case. Further, when using the
``Reducer/ifLet(_:action:)`` operator with this style of `Destination` enum reducer you can
completely leave off the trailing closure as it can be automatically inferred:

```diff
 Reduce { state, action in
   // Core feature logic
 }
 .ifLet(\.$destination, action: \.destination)
-{
-  Destination()
-}
```

This pattern also works for `Path` reducers, which is common when dealing with
<doc:StackBasedNavigation>, and in that case you can leave off the trailing closure of the
``Reducer/forEach(_:action:)`` operator:

```diff
Reduce { state, action in
  // Core feature logic
}
.forEach(\.path, action: \.path)
-{
-  Path()
-}
```

Further, for `Path` reducers in particular, the ``Reducer()`` macro also helps you reduce
boilerplate when using the initializer 
``SwiftUI/NavigationStack/init(path:root:destination:fileID:filePath:line:column:)`` that comes with the library. 
In the last trailing closure you can use the ``Store/case`` computed property to switch on the 
`Path.State` enum and extract out a store for each case:

```swift
NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
  // Root view
} destination: { store in
  switch store.case {
  case let .add(store):
    AddView(store: store)
  case let .detail(store):
    DetailView(store: store)
  case let .edit(store):
    EditView(store: store)
  }
}
```

#### Navigating to non-reducer features

There are many times that you want to present or navigate to a feature that is not modeled with a
Composable Architecture reducer. This can happen with legacy features that are not built with the
Composable Architecture, or with features that are very simple and do not need a fully built
reducer.

In those cases you can use the ``ReducerCaseIgnored()`` and ``ReducerCaseEphemeral()`` macros to
annotate cases that are not powered by reducers. See the documentation for those macros for more
details.

As an example, suppose that you have a feature that can navigate to multiple features, all of 
which are Composable Architecture features except for one:

```swift
@Reducer
enum Destination {
  case add(AddItemFeature)
  case edit(EditItemFeature)
  @ReducerCaseIgnored
  case item(Item)
}
```

In this situation the `.item` case holds onto a plain item and not a full reducer, and for that 
reason we have to ignore it from some of `@Reducer`'s macro expansion.

Then, to present a view from this case one can do:

```swift
.sheet(item: $store.scope(state: \.destination?.item, action: \.destination.item)) { store in
  ItemView(item: store.withState { $0 })
}
```

> Note: The ``Store/withState(_:)`` is necessary because the value held inside the `.item` case
does not have the ``ObservableState()`` macro applied, nor should it. And so using `withState`
is a way to get access to the state in the store without any observation taking place.

#### Synthesizing protocol conformances on State and Action

Since the `State` and `Action` types are generated automatically for you when using `@Reducer` on an
enum, you must extend these types yourself to synthesize conformances of `Equatable`, `Hashable`,
_etc._:

```swift
@Reducer
enum Destination {
  // ...
}
extension Destination.State: Equatable {}
```

> Note: In Swift <6 the above extension causes a compiler error due to a bug in Swift.
>
> To work around this compiler bug, the library provides a version of the `@Reducer` macro that
> takes two ``ComposableArchitecture/_SynthesizedConformance`` arguments, which allow you to
> describe the protocols you want to attach to the `State` or `Action` types:
>
> ```swift
> @Reducer(state: .equatable, .sendable, action: .sendable)
> enum Destination {
>   // ...
> }
> ```

#### Nested enum reducers

There may be times when an enum reducer may want to nest another enum reducer. To do so, the parent
enum reducer must specify the child's `Body` associated value and `body` static property explicitly:

```swift
@Reducer
enum Modal { /* ... */ }

@Reducer
enum Destination {
  case modal(Modal.Body = Modal.body)
}
```

### Gotchas

#### Autocomplete

Applying `@Reducer` can break autocompletion in the `body` of the reducer. This is a known
[issue](https://github.com/apple/swift/issues/69477), and it can generally be worked around by
providing additional type hints to the compiler:

 1. Adding an explicit `Reducer` conformance in addition to the macro application can restore
    autocomplete throughout the `body` of the reducer:

    ```diff
     @Reducer
    -struct Feature {
    +struct Feature: Reducer {
    ```

 2. Adding explicit generics to instances of `Reduce` in the `body` can restore autocomplete
    inside the `Reduce`:

    ```diff
     var body: some Reducer<State, Action> {
    -  Reduce { state, action in
    +  Reduce<State, Action> { state, action in
    ```

#### #Preview and enum reducers

The `#Preview` macro is not capable of seeing the expansion of any macros since it is a macro 
itself. This means that when using destination and path reducers (see
<doc:Reducer#Destination-and-path-reducers> above) you cannot construct the cases of the state 
enum inside `#Preview`:

```swift
#Preview {
  FeatureView(
    store: Store(
      initialState: Feature.State(
        destination: .edit(EditFeature.State())  // 🛑
      )
    ) {
      Feature()
    }
  )
}
```

The `.edit` case is not usable from within `#Preview` since it is generated by the ``Reducer()``
macro.

The workaround is to move the view to a helper that be compiled outside of a macro, and then use it
inside the macro:

```swift
#Preview {
  preview
}
private var preview: some View {
  FeatureView(
    store: Store(
      initialState: Feature.State(
        destination: .edit(EditFeature.State())
      )
    ) {
      Feature()
    }
  )
}
```

You can use a computed property, free function, or even a dedicated view if you want. You can also
use the old, non-macro style of previews by using a `PreviewProvider`:

```swift
struct Feature_Previews: PreviewProvider {
  static var previews: some  View {
    FeatureView(
      store: Store(
        initialState: Feature.State(
          destination: .edit(EditFeature.State())
        )
      ) {
        Feature()
      }
    )
  }
}
```

#### Error: External macro implementation … could not be found

When integrating with the Composable Architecture, one may encounter the following error:

> Error: External macro implementation type 'ComposableArchitectureMacros.ReducerMacro' could not be
> found for macro 'Reducer()'

This error can show up when the macro has not yet been enabled, which is a separate error that
should be visible from Xcode's Issue navigator.

Sometimes, however, this error will still emit due to an Xcode bug in which a custom build
configuration name is being used in the project. In general, using a build configuration other than
"Debug" or "Release" can trigger upstream build issues with Swift packages, and we recommend only
using the default "Debug" and "Release" build configuration names to avoid the above issue and
others.

#### CI build failures

When testing your code on an external CI server you may run into errors such as the following:

> Error: CasePathsMacros Target 'CasePathsMacros' must be enabled before it can be used.
>
> ComposableArchitectureMacros Target 'ComposableArchitectureMacros' must be enabled before it can
> be used.

You can fix this in one of two ways. You can write a default to the CI machine that allows Xcode to
skip macro validation:

```shell
defaults write com.apple.dt.Xcode IDESkipMacroFingerprintValidation -bool YES
```

Or if you are invoking `xcodebuild` directly in your CI scripts, you can pass the
`-skipMacroValidation` flag to `xcodebuild` when building your project:

```shell
xcodebuild -skipMacroValidation …
```

[casepathable-docs]: https://swiftpackageindex.com/pointfreeco/swift-case-paths/main/documentation/casepaths/casepathable()
[casepaths-gh]: http://github.com/pointfreeco/swift-case-paths


## Topics

### Implementing a reducer

- ``Reducer()``
- ``State``
- ``Action``
- ``body-swift.property``
- ``Reduce``
- ``Effect``

### Composing reducers

- ``ReducerBuilder``
- ``CombineReducers``

### Embedding child features

- ``Scope``
- ``ifLet(_:action:then:fileID:filePath:line:column:)-2r2pn``
- ``ifCaseLet(_:action:then:fileID:filePath:line:column:)-7sg8d``
- ``forEach(_:action:element:fileID:filePath:line:column:)-6zye8``
- <doc:Navigation>

### Supporting reducers

- ``EmptyReducer``
- ``BindingReducer``
- ``Swift/Optional``

### Reducer modifiers

- ``dependency(_:_:)``
- ``transformDependency(_:transform:)``
- ``onChange(of:_:)``
- ``signpost(_:log:)``
- ``_printChanges(_:)``

### Supporting types

- ``ReducerOf``

### Deprecations

- <doc:ReducerDeprecations>



---
File: /Sources/ComposableArchitecture/Documentation.docc/Extensions/ReducerBody.md
---

# ``ComposableArchitecture/Reducer/body-swift.property``

## Topics

### Associated type

- ``Body``



---
File: /Sources/ComposableArchitecture/Documentation.docc/Extensions/ReducerBuilder.md
---

# ``ComposableArchitecture/ReducerBuilder``

## Topics

### Building reducers

- ``buildExpression(_:)-cp3q``
- ``buildExpression(_:)-9uxku``
- ``buildBlock(_:)``
- ``buildBlock()``
- ``buildPartialBlock(first:)``
- ``buildPartialBlock(accumulated:next:)``
- ``buildOptional(_:)``
- ``buildEither(first:)``
- ``buildEither(second:)``
- ``buildArray(_:)``
- ``buildLimitedAvailability(_:)``
- ``buildFinalResult(_:)``



---
File: /Sources/ComposableArchitecture/Documentation.docc/Extensions/ReducerForEach.md
---

# ``ComposableArchitecture/Reducer/forEach(_:action:element:fileID:filePath:line:column:)-6zye8``

## Topics

### Identifying actions

- ``IdentifiedAction``

### Navigation stacks

- ``StackState``
- ``StackAction``
- ``StackActionOf``
- ``Reducer/forEach(_:action:destination:fileID:filePath:line:column:)-9svqb``
- ``Reducer/forEach(_:action:)``
- ``DismissEffect``



---
File: /Sources/ComposableArchitecture/Documentation.docc/Extensions/ReducerlIfLet.md
---

# ``ComposableArchitecture/Reducer/ifLet(_:action:then:fileID:filePath:line:column:)-2r2pn``

## Topics

### Enum state

- ``Reducer/ifLet(_:action:)``

### Ephemeral state

- ``Reducer/ifLet(_:action:fileID:filePath:line:column:)-5bebx``



---
File: /Sources/ComposableArchitecture/Documentation.docc/Extensions/ReducerlIfLetPresentation.md
---

# ``ComposableArchitecture/Reducer/ifLet(_:action:destination:fileID:filePath:line:column:)-4ub6q``

## Topics

### Ephemeral state

- ``Reducer/ifLet(_:action:fileID:filePath:line:column:)-3ux09``

### Presentation

- ``PresentationState``
- ``PresentationAction``
- ``DismissEffect``



---
File: /Sources/ComposableArchitecture/Documentation.docc/Extensions/ReducerMacro.md
---

# ``ComposableArchitecture/Reducer()``

## Topics

### Enum reducers

- ``Reducer(state:action:)``
- ``ReducerCaseEphemeral()``
- ``ReducerCaseIgnored()``
- ``CaseReducer``
- ``CaseReducerState``



---
File: /Sources/ComposableArchitecture/Documentation.docc/Extensions/Scope.md
---

# ``ComposableArchitecture/Scope``

## Topics

### Struct state

- ``init(state:action:child:)-88vdx``

### Enum state

- ``init(state:action:child:fileID:filePath:line:column:)-9g44g``

### Deprecations

- <doc:ScopeDeprecations>



---
File: /Sources/ComposableArchitecture/Documentation.docc/Extensions/State.md
---

# ``ComposableArchitecture/Reducer/State``

## Topics

### Observing state

- ``ObservableState()``



---
File: /Sources/ComposableArchitecture/Documentation.docc/Extensions/Store.md
---

# ``ComposableArchitecture/Store``

## Topics

### Creating a store

- ``init(initialState:reducer:withDependencies:)``
- ``StoreOf``

### Accessing state

- ``state-1qxwl``
- ``subscript(dynamicMember:)-655ef``
- ``withState(_:)``

### Sending actions

- ``send(_:)``
- ``send(_:animation:)``
- ``send(_:transaction:)``
- ``StoreTask``

### Scoping stores

- ``scope(state:action:)-90255``
- ``scope(state:action:fileID:filePath:line:column:)-3yvuf``
- ``scope(state:action:fileID:filePath:line:column:)-2ym6k``
- ``case``

### Scoping store bindings

- ``SwiftUI/Binding``

### Combine integration

- ``StorePublisher``

### Deprecated interfaces

- <doc:StoreDeprecations>



---
File: /Sources/ComposableArchitecture/Documentation.docc/Extensions/StoreDynamicMemberLookup.md
---

# ``ComposableArchitecture/Store/subscript(dynamicMember:)-655ef``

## Topics

### Writable, bindable state

- ``Store/subscript(dynamicMember:)-6ilk2``
- ``Store/subscript(dynamicMember:)-85nex``



---
File: /Sources/ComposableArchitecture/Documentation.docc/Extensions/StoreState.md
---

# ``ComposableArchitecture/Store/state-1qxwl``

## Topics

### Writable, bindable state

- ``Store/state-20w4g``
- ``Store/state-2wgiw``



---
File: /Sources/ComposableArchitecture/Documentation.docc/Extensions/SwiftUIBinding.md
---

# ``SwiftUI/Binding``

Learn how SwiftUI's `Binding` type has been extended for the Composable Architecture

## Overview

A binding to a ``Store``is extended with several unique scoping operations that can be used to power
controls and drive navigation.

## Topics

### Control bindings

- ``SwiftUI/Binding/subscript(dynamicMember:)``

### Navigation bindings

- ``SwiftUI/Binding/scope(state:action:fileID:filePath:line:column:)``
- ``SwiftUI/Binding/scope(state:action:)-35r82``



---
File: /Sources/ComposableArchitecture/Documentation.docc/Extensions/SwiftUIBindingScopeForEach.md
---

# ``SwiftUI/Binding/scope(state:action:)-35r82``

## Topics

### Bindable

- ``SwiftUI/Bindable/scope(state:action:)``
- ``Perception/Bindable/scope(state:action:)``



---
File: /Sources/ComposableArchitecture/Documentation.docc/Extensions/SwiftUIBindingScopeIfLet.md
---

# ``SwiftUI/Binding/scope(state:action:fileID:filePath:line:column:)``

## Topics

### Bindable

- ``SwiftUI/Bindable/scope(state:action:fileID:line:)``
- ``Perception/Bindable/scope(state:action:fileID:line:)``



---
File: /Sources/ComposableArchitecture/Documentation.docc/Extensions/SwiftUIBindingSubscript.md
---

# ``SwiftUI/Binding/subscript(dynamicMember:)``

## Topics

### Bindable

- ``SwiftUI/Bindable/subscript(dynamicMember:)``
- ``Perception/Bindable/subscript(dynamicMember:)``



---
File: /Sources/ComposableArchitecture/Documentation.docc/Extensions/SwiftUIIntegration.md
---

# SwiftUI Integration

Integrating the Composable Architecture into a SwiftUI application.

## Overview

The Composable Architecture can be used to power applications built in many frameworks, but it was
designed with SwiftUI in mind, and comes with many powerful tools to integrate into your SwiftUI applications.

## Topics

### Alerts and dialogs

- ``SwiftUI/View/alert(_:)``
- ``SwiftUI/View/confirmationDialog(_:)``
- ``_EphemeralState``

### Presentation

- ``SwiftUI/Binding/scope(state:action:fileID:filePath:line:column:)``

### Navigation stacks and links

- ``SwiftUI/Binding/scope(state:action:)-35r82``
- ``SwiftUI/NavigationStack/init(path:root:destination:fileID:filePath:line:column:)``
- ``SwiftUI/NavigationLink/init(state:label:fileID:filePath:line:column:)``

### Bindings

- <doc:Bindings>
- ``BindableAction``
- ``BindingAction``
- ``BindingReducer``

### Deprecations

- <doc:SwiftUIDeprecations>



---
File: /Sources/ComposableArchitecture/Documentation.docc/Extensions/SwitchStore.md
---

# ``ComposableArchitecture/SwitchStore``

## Topics

### Building Content

- ``CaseLet``



---
File: /Sources/ComposableArchitecture/Documentation.docc/Extensions/TaskResult.md
---

# ``ComposableArchitecture/TaskResult``

## Topics

### Representing a task result

- ``success(_:)``
- ``failure(_:)``

### Converting a throwing expression

- ``init(catching:)``

### Accessing a result's value

- ``value``

### Transforming results

- ``map(_:)``
- ``flatMap(_:)``
- ``init(_:)``
- ``Swift/Result/init(_:)``



---
File: /Sources/ComposableArchitecture/Documentation.docc/Extensions/TestStore.md
---

# ``ComposableArchitecture/TestStore``

## Topics

### Creating a test store

- ``init(initialState:reducer:withDependencies:fileID:file:line:column:)``
- ``TestStoreOf``

### Configuring a test store

- ``dependencies``
- ``exhaustivity``
- ``timeout``
- ``useMainSerialExecutor``

### Testing a reducer

- ``send(_:assert:fileID:file:line:column:)-8f2pl``
- ``send(_:assert:fileID:file:line:column:)-8877x``
- ``send(_:_:assert:fileID:file:line:column:)``
- ``receive(_:timeout:assert:fileID:file:line:column:)-8zqxk``
- ``receive(_:timeout:assert:fileID:file:line:column:)-35638``
- ``receive(_:timeout:assert:fileID:file:line:column:)-53wic``
- ``receive(_:_:timeout:assert:fileID:file:line:column:)-9jd7x``
- ``assert(_:fileID:file:line:column:)``
- ``finish(timeout:fileID:file:line:column:)-klnc``
- ``isDismissed``
- ``TestStoreTask``

### Skipping actions and effects

- ``skipReceivedActions(strict:fileID:file:line:column:)``
- ``skipInFlightEffects(strict:fileID:file:line:column:)``

### Accessing state

While the most common way of interacting with a test store's state is via its
``send(_:assert:fileID:file:line:column:)-8f2pl`` and 
``receive(_:timeout:assert:fileID:file:line:column:)-53wic`` methods, you may also access it 
directly throughout a test.

- ``state``

### Supporting types

- ``TestStoreOf``

### Deprecations

- <doc:TestStoreDeprecations>



---
File: /Sources/ComposableArchitecture/Documentation.docc/Extensions/TestStoreDependencies.md
---

# ``ComposableArchitecture/TestStore/dependencies``

## Topics

### Configuring exhaustivity

- ``withDependencies(_:operation:)-988rh``
- ``withDependencies(_:operation:)-61in2``



---
File: /Sources/ComposableArchitecture/Documentation.docc/Extensions/TestStoreExhaustivity.md
---

# ``ComposableArchitecture/TestStore/exhaustivity``

## Topics

### Configuring exhaustivity

- ``Exhaustivity``
- ``withExhaustivity(_:operation:)-3fqeg``
- ``withExhaustivity(_:operation:)-1mhu4``



---
File: /Sources/ComposableArchitecture/Documentation.docc/Extensions/UIKit.md
---

# UIKit Integration

Integrating the Composable Architecture into a UIKit application.

## Overview

While the Composable Architecture was designed with SwiftUI in mind, it comes with tools to 
integrate into application code written in UIKit.

## Topics

### Subscribing to state changes

- ``ObjectiveC/NSObject/observe(_:)-94oxy``
- ``ObservationToken``

### Presenting alerts and action sheets

- ``UIKit/UIAlertController``

### Stack-based navigation

- ``UIKitNavigation/NavigationStackController``
- ``UIKitNavigation/UIPushAction``

### Combine integration

- ``Store/ifLet(then:else:)``
- ``Store/publisher``
- ``ViewStore/publisher``



---
File: /Sources/ComposableArchitecture/Documentation.docc/Extensions/ViewStore.md
---

# ``ComposableArchitecture/ViewStore``

## Topics

### Creating a view store

- ``init(_:observe:send:removeDuplicates:)-9mg12``
- ``init(_:observe:removeDuplicates:)-4f9j5``
- ``init(_:observe:send:)-1m32f``
- ``init(_:observe:)-3ak1y``
- ``ViewStoreOf``

### Accessing state

- ``state-swift.property``
- ``subscript(dynamicMember:)-kwxk``

### Sending actions

- ``send(_:)``
- ``send(_:while:)``
- ``yield(while:)``

### SwiftUI integration

- ``send(_:animation:)``
- ``send(_:animation:while:)``
- ``send(_:transaction:)``
- <doc:Bindings>
- ``objectWillChange-5oies``
- ``init(_:observe:send:removeDuplicates:)-9v9l0``
- ``init(_:observe:removeDuplicates:)-81c6d``
- ``init(_:observe:send:)-4hzhi``
- ``init(_:observe:)-96hm5``
- ``subscript(dynamicMember:)-3q4xh``



---
File: /Sources/ComposableArchitecture/Documentation.docc/Extensions/ViewStoreBinding.md
---

# ``ComposableArchitecture/ViewStore/binding(get:send:)-65xes``

## Topics

### Overloads

- ``binding(get:send:)-l66r``
- ``binding(send:)-7nwak``
- ``binding(send:)-705m7``



---
File: /Sources/ComposableArchitecture/Documentation.docc/Extensions/WithViewStore.md
---

# ``ComposableArchitecture/WithViewStore``

## Overview

## Topics

### Creating a view

- ``init(_:observe:content:file:line:)-8g15l``

### Debugging view updates

- ``_printChanges(_:)``



---
File: /Sources/ComposableArchitecture/Documentation.docc/Extensions/WithViewStoreInit.md
---

# ``ComposableArchitecture/WithViewStore/init(_:observe:content:file:line:)-8g15l``

## Topics

### Overloads

- ``WithViewStore/init(_:observe:removeDuplicates:content:file:line:)-7y5bp``
- ``WithViewStore/init(_:observe:send:content:file:line:)-5d0z5``
- ``WithViewStore/init(_:observe:send:removeDuplicates:content:file:line:)-dheh``

### Bindings

- ``WithViewStore/init(_:observe:content:file:line:)-4gpoj``
- ``WithViewStore/init(_:observe:removeDuplicates:content:file:line:)-1zbzi``
- ``WithViewStore/init(_:observe:send:content:file:line:)-3r7aq``
- ``WithViewStore/init(_:observe:send:removeDuplicates:content:file:line:)-4izbr``



---
File: /Sources/ComposableArchitecture/Documentation.docc/ComposableArchitecture.md
---

# ``ComposableArchitecture``

The Composable Architecture (TCA, for short) is a library for building applications in a consistent
and understandable way, with composition, testing, and ergonomics in mind. It can be used in
SwiftUI, UIKit, and more, and on any Apple platform (iOS, macOS, tvOS, and watchOS).

## Additional Resources

- [GitHub Repo](https://github.com/pointfreeco/swift-composable-architecture)
- [Discussions](https://github.com/pointfreeco/swift-composable-architecture/discussions)
- [Point-Free Videos](https://www.pointfree.co/collections/composable-architecture)

## Overview

This library provides a few core tools that can be used to build applications of varying purpose and
complexity. It provides compelling stories that you can follow to solve many problems you encounter
day-to-day when building applications, such as:

* **State management**

    How to manage the state of your application using simple value types, and share state across
    many screens so that mutations in one screen can be immediately observed in another screen.

* **Composition**

    How to break down large features into smaller components that can be extracted to their own,
    isolated modules and be easily glued back together to form the feature.

* **Side effects**

    How to let certain parts of the application talk to the outside world in the most testable and
    understandable way possible.

* **Testing**

    How to not only test a feature built in the architecture, but also write integration tests for
    features that have been composed of many parts, and write end-to-end tests to understand how
    side effects influence your application. This allows you to make strong guarantees that your
    business logic is running in the way you expect.

* **Ergonomics**

    How to accomplish all of the above in a simple API with as few concepts and moving parts as
    possible.

## Topics

### Essentials

- <doc:GettingStarted>
- <doc:DependencyManagement>
- <doc:TestingTCA>
- <doc:Navigation>
- <doc:SharingState>
- <doc:Performance>
- <doc:FAQ>

### Tutorials

- <doc:MeetComposableArchitecture>
- <doc:BuildingSyncUps>

### State management

- ``Reducer``
- ``Effect``
- ``Store``
- <doc:SharingState>

### Testing

- ``TestStore``
- <doc:TestingTCA>

### Integrations

- <doc:SwiftConcurrency>
- <doc:SwiftUIIntegration>
- <doc:ObservationBackport>
- <doc:UIKit>

### Migration guides

- <doc:MigrationGuides>

## See Also

The collection of videos from [Point-Free](https://www.pointfree.co) that dive deep into the
development of the library.

* [Point-Free Videos](https://www.pointfree.co/collections/composable-architecture)

