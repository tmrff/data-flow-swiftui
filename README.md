# Data Flow with SwiftUI

As SwiftUI evolves, Apple has introduced new methods for managing data flow. This document explores various approaches to managing data flow within a simple counter app.

## Introducing Counter App

The behaviour we aim to achieve is displaying a number on the screen that changes when a user presses a button.

If you've never created a SwiftUI app before, you might attempt something like the following code:

```swift
struct ContentView: View {
    var count = 0
    
    var body: some View {
        VStack {
            Text(count.description)
            Button("Next") {
               changeCount()
            }
        }
    }
    
    private func changeCount() {
        count = Int.random(in: 0...100)
    }
}
```

However, you encounter a compiler error:

‼️ "Cannot use mutating member on immutable value: 'self' is immutable"



The issue here is that `ContentView` is a struct, which means it's immutable.

## A Wild @State Appears

Using `@State` allows us to treat a value type as if it were a reference type, enabling us to effectively mutate its state.

```swift
struct ContentView: View {
    @State var count = 0
    
    // The rest of ContentView implementation...
}
```
- The `@State` property wrapper enables us to modify `count`
- SwiftUI takes responsibility for managing the lifecycle and state of `count`
- The `count` becomes part of SwiftUI's managed state rather than being solely owned by `ContentView`

Now, when `count` is updated, `ContentView`'s reference to it remains unchanged, while the underlying value managed by SwiftUI changes.

### What is happening?

When `count` is updated due to user interaction or other triggers, `ContentView` itself remains visible on the screen. However, SwiftUI detects the state change and triggers a process:
- SwiftUI signals an update due to the change in count
- The `ContentView` is notified of this change and rebuilds its body property to reflect the updated state of count
- The view updates on the screen to display the new value of `count`, ensuring the UI remains in sync with the underlying data

But what if we have state that exists outside of ContentView?

## State Outside of ContentView

### The Wrong Way

```swift
struct ContentView: View {
    
    @State var viewModel = ViewModel()
    
    var body: some View {
        VStack {
            Text(viewModel.count.description)
            Button("Next") {
                viewModel.changeCount()
            }
        }
    }
}

class ViewModel {
    private(set) var count = 0
    
    func changeCount() {
        count = Int.random(in: 0...100)
    }
}
```

Adding `@State` to our view model does not achieve the desired behavior. Why?
- When the button is tapped, it calls the `viewModel.changeCount()` function
- `changeCount()` successfully updates the `count` property of the ViewModel
- However, nothing is telling `ContentView` the `count` will change, so it doesn't update the displayed value.

The issue arises because the ViewModel is a reference type. Even though its count property changes, there is no mechanism to notify ContentView of this change. SwiftUI's `@State` is designed for value types, like structs, where changes automatically trigger view updates. Since ViewModel is a class (reference type), SwiftUI does not automatically observe changes to its properties. It is still the same memory address. Nothing has changed.

Therefore, despite count changing internally within ViewModel, no signal is sent to inform ContentView to refresh its view, resulting in the displayed Text not reflecting the updated count value.

### The Correct Approach - Using Combine

```swift
struct ContentView: View {
    
    @StateObject var viewModel = ViewModel()
    
    var body: some View {
        VStack {
            Text(viewModel.count.description)
            Button("Next") {
                viewModel.changeCount()
            }
        }
    }
}

class ViewModel: ObservableObject {
    @Published private(set) var count = 0
    
    func changeCount() {
        count = Int.random(in: 0...100)
    }
}
```

To achieve proper state management with Combine, follow these steps:

- Mark `count` with `@Published` to make it a published property
- Since `@Published` requires an `ObservableObject`, ensure ViewModel conforms to the `ObservableObject` protocol
- ObservableObject is a Combine type that provides an object with a publisher that emits before the object changes
- Use the `@StateObject` property wrapper to initialise `viewModel` in `ContentView`

Now, when count changes:
- The ViewModel instance announces the impending change with `viewModel.objectWillChange()`
- `ContentView`, being subscribed to changes in `@Published` properties of `viewModel`, receives the notification and updates accordingly

### The Newer Correct Approach - Using Observation

```swift
struct ContentView: View {
    
    @State var viewModel = ViewModel()
    
    var body: some View {
        VStack {
            Text(viewModel.count.description)
            Button("Next") {
                viewModel.changeCount()
            }
        }
    }
}

@Observable
class ViewModel {
    private(set) var count = 0
    
    func changeCount() {
        count = Int.random(in: 0...100)
    }
}
```
To implement effective state observation:
- Ensure you import observation framework
- Annotate ViewModel with `@Observable` to facilitate state observation. This [macro](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/macros) aids in managing state changes seamlessly
- Use the `@State` property wrapper during ViewModel initialisation in `ContentView`. This wrapper is crucial for SwiftUI to manage the lifecycle of the observable class correctly


#### By expanding the macro we can uncover the magic


```swift
struct ContentView: View {
    
    @State var viewModel = ViewModel()
    
    var body: some View {
        VStack {
            Text(viewModel.count.description)
            Button("Next") {
                viewModel.changeCount()
            }
        }
    }
}

@Observable
class ViewModel {

    @ObservationTracked
    private(set) var count = 0
    
    func changeCount() {
        count = Int.random(in: 0...100)
    }

    @ObservationIgnored
    private let _$observationRegistrar = Observation.ObservationRegistrar()

    internal nonisolated func access<Member>(
      keyPath: KeyPath<ViewModel, Member>,
    ) {
      _$observationRegistrar.access(self, keyPath: keyPath)
    }

    internal nonisolated func withMutation<Member, MutationResult>(
      keyPath: KeyPath<ViewModel, Member>,
      _ mutation: () throws -> MutationResult
    ) rethrows -> MutationResult {
      try _$observationRegistrar.withMutation(of: self, keyPath: keyPath, mutation)
    }
}

extension ViewModel: Observation.Observable {
}
```

Let's break down the components and their roles step by step

#### 1. Conform the ViewModel to the Observable protocol

```swift
extension ViewModel: Observation.Observable {
}
```

This extension ensures that ViewModel conforms to the necessary protocols and can participate in observation mechanisms

#### 2. Mark `count` with `@ObservationTracked` macro

```swift
@ObservationTracked
private(set) var count = 0
```

By using `@ObservationTracked`, we instruct the system to monitor changes to the count property. This allows SwiftUI to observe and react to changes in count. More on this macro soon.

#### 3. Observation registrar is added

```swift
@ObservationIgnored
private let _$observationRegistrar = Observation.ObservationRegistrar()
```

The observation registrar serves as the registration mechanism for observations within the ViewModel. This is how SwiftUI is going to get its updates.

We don't need to track changes to changes to observation registrar so it uses `@ObservationIgnored` macro.

#### 4. Gets are registered

```swift
internal nonisolated func access<Member>(
  keyPath: KeyPath<ViewModel, Member>,
) {

  _$observationRegistrar.access(self, keyPath: keyPath)

}
```

Every time we try to get a property, it is registered here. 


The `access` method registers accesses to properties defined by keyPath. This registration ensures that whenever a property (like `count`) is accessed, it is noted by the observation registrar.

#### 5. Sets are registered

```swift
internal nonisolated func withMutation<Member, MutationResult>(
  keyPath: KeyPath<ViewModel, Member>,
  _ mutation: () throws -> MutationResult
) rethrows -> MutationResult {

  try _$observationRegistrar.withMutation(of: self, keyPath: keyPath, mutation)

}
```

Every time we try to set a property, the observation registrar takes note.

The `withMutation` method registers mutations (changes) to properties defined by keyPath. It ensures that whenever a property is mutated (like setting a new value to `count`), the observation registrar tracks this mutation.

#### Uncovering the magic of the `@ObservationTracked` macro

Expanding the `@ObservationTracked` macro uncovers the following code:

```swift
@Observable
class ViewModel {
    @ObservationTracked
    private(set) var count = 0
    {
        @storageRestrictions(initializes: _count)
        init(initialValue) {
            _count = initialValue
        }
        get {
            access(keyPath: \.count)
            return _count
        }
        set {
            withMutation(keyPath: \.count) {
                _count = newValue
        }
    }
    _modify {
        access(keyPath: \.count)
        _$observationRegistrar.willSet(self, keyPath: \.count)
        defer {
            _$observationRegistrar.didSet(self, keyPath: \.count)
        }
        yield &_count
    }

    @ObservationIgnored private  var _count  = 0

    // The rest of ViewModel implementation
}
```

Let's break down the key components and their roles step by step

```swift
@ObservationIgnored private var _count  = 0
```
- A private property is added `_count`
- `_count` is annotated with `@ObservationIgnored`, ensuring that direct changes to count are not tracked; instead, `_count` serves as the underlying storage

```swift
get {
  access(keyPath: \.count )
  return _count
}
```

When we get `count` it calls `access()` which registers the get with the observation registrar and returns the value in the underlying `_count`.

```swift
set {
  withMutation(keyPath: \.count ) {
    _count  = newValue
  }
}
```

When we set `count` it calls `withMutation()` which registers the set with the observation registrar and changes the value in the underlying `_count`.

So for each stored property it's registering it and it's modifying it. All for just adding the `@Observed` macro to our view model.

## Computed Properties with Observation

- We can make `count` private so it's inaccessible by `ContentView`
- An extension on ViewModel introduces `annotatedCount`, a computed property
- Now `ContentView` can access `annotatedCount` but `count` itself is private
- `count` is observable and `annotatedCount` depends on `count`, `annotatedCount`
- Even though `count` is private, changes to `count` trigger updates to `annotatedCount` due to the implicit observability

```swift
struct ContentView: View {
    
    @State var viewModel = ViewModel()
    
    var body: some View {
        VStack {
            Text(viewModel.annotatedCount.description)
            Button("Next") {
                viewModel.changeCount()
            }
        }
    }
}

@Observable
class ViewModel {
    private var count = 0
    
    func changeCount() {
        count = Int.random(in: 0...100)
    }
}

extension ViewModel {
    var annotatedCount: String {
        return "The view-model's count is: \(count)"
    }
}
```

## Separating Code Further with Observable Model

Someone unfamiliar with Observation framework might try something like the following:

```swift
// Model
class Model {
    private(set) var count = 0
}

extension Model {
    func updateCount() {
        count = Int.random(in: 0...100)
    }
}

//ViewModel
@Observable
class ViewModel {
    private var model = Model()
}

extension ViewModel {
    var annotatedCount: String {
        return "The view-model's count is: \(model.count)"
    }
}

extension ViewModel {
    func changeCount() {
        model.updateCount()
    }
}
```

- This does not work because `Model` is a reference type
- `Model` does not change when `count` changes
- We do not get the update, the `ContentView` just sits there

By making Model observable with `@Observable`, changes to count are now properly detected and reflected in `ContentView`.

```swift
@Observable
class Model {
    private(set) var count = 0
}
```

Now `ContentView` updates just fine.

### Refining ViewModel and Model

We don't need `ViewModel` to be observable because it contains the computed property `annotatedCount` that depends on the observable property `count` in `Model`.

We can remove `@Observable` from `ViewModel` because 'annotatedCount' is implicitly observable.

If `model` is observable we get updates to the ViewModel's computed property because it still depends on an observable property, just not one it happens to own.

```swift
class ViewModel {
    private var model = Model()
}

extension ViewModel {
    var annotatedCount: String {
        return "The view-model's count is: \(model.count)"
    }
}
```

We can even change `Model` to a `let` and change `ViewModel` to a `struct`, it all still works.


## Introducing CountApp

We have been initialising `ViewModel` in `ContentView`. Let's pass it in instead.

```swift
struct ContentView {
    let viewModel: ViewModel
}
```

```swift
@main
struct CountApp: App {

    @State private var viewModel = ViewModel()    

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel)
        }
    }
}
```

Even though the Model is the only part that is `@Observable` everything still works thanks to the power of observation registrar.

## Making `count` a Double

We can make `count` a double so it works with a `Slider` view.

```swift
@Observable
class Model {
    var count = 0.0
}
```

Round count so it looks nicer in the view.

```swift
struct ViewModel {
    let model = Model()
}

extension ViewModel {
    var annotatedCount: String {
        Int(model.count.rounded()).description
    }
}
```

```swift
struct ValueSlider {
    // What to do?
}

extension ValueSlider: View {
    var body: some View {
        Slider(value: <Binding>, in: 0...100)
            .padding()
    }
}
```
We need a `Binding` to a `Double` for `Slider`

- `@State var count = 0.0` doesn't work, it's for local state ❌
- `@Binding var count: Double` would need to pass in `model.count`, we can do better ❌
- `@Bindable var count: Double` we can't pass in the property we want to bind it to ❌
- `@Bindable var model: Model` applies to an observable object, so we have to pass in something that is observable ✅

So we we can bind `Slider` value to `$model.count`
 
```swift
struct ValueSlider {
    @Bindable var model: Model
}

extension ValueSlider: View {
    var body: some View {
        Slider(value: $model.count, in: 0...100)
            .padding()
    }
}
```

## Questions and Answers (edited) from the Conference

- **Q:** How long do developers have until they must transition away from `@StateObject`, `@ObservedObject`, and Combine to the Observation framework?
- **A:** Apple has indicated it's the future, but the transition won't be imminent.

---
- **Q:** Why is Model defined as a class?
- **A:** Both Observable and SwiftData necessitate it being a class. Initially, Apple aimed for a struct with a persistent ID, but this requirement led them to effectively create a class. Their stance on preferring value types has evolved; the type marked `@Observable` must be a class and cannot be a struct or enum.

---
- **Q:** Traditionally, we've used `@State` to treat a value type like a reference type. What does `@StateObject` signify?
- **A:** `@StateObject` signifies two things: firstly, that I'm responsible for its lifecycle and I'm creating it, unlike `@ObservedObject` or `@EnvironmentObject`; secondly, I aim to receive updates back.


## Acknowledgements

- The content of this document was created based on notes taken from the Pragma Conference 2023 session titled "Data flow in SwiftUI - from @State to @Observable and beyond!" by Daniel Steinberg.
