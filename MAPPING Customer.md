
# Android to iOS Translation Mapping

This document outlines the mapping choices made when translating the Android `CustomerFormActivity` to the iOS `CustomerFormViewController`.

## 1. Core Components

| Android Component | iOS Equivalent | Notes |
| --- | --- | --- |
| `Activity` (`CustomerFormActivity.kt`) | `UIViewController` (`CustomerFormViewController.swift`) | The fundamental building block for a screen in both platforms. |
| `XML Layout` (`activity_customer_form.xml`) | Programmatic Auto Layout | iOS UI was built in code using `NSLayoutConstraint` anchors for flexibility and to match the existing project style found in `NewMachineViewController`. A `UIScrollView` with a `UIStackView` was used to manage the form content, providing automatic scrolling when the keyboard appears. |
| `EditText` | `CustomTextField` | The project's existing `CustomTextField` class was used for all text input fields to maintain a consistent look and feel. |
| `Button` | `CustomButton` | The project's existing `CustomButton` class was used for the save/update button. |
| `CheckBox` | `UISwitch` | The `archived` status, represented by a `CheckBox` in Android, was translated to a `UISwitch` on iOS, which is the idiomatic equivalent for a boolean toggle. |
| `HeaderView` (Custom) | `UINavigationBar` (System) | The Android app used a custom `HeaderView`. The iOS project's `NewMachineViewController` uses a standard `UINavigationController` and `UINavigationBar` for its title and action buttons. This existing pattern was adopted for consistency. The title is set on `navigationItem.title` and a "Cancel" `UIBarButtonItem` is added. |
| `ScrollView` | `UIScrollView` | Both platforms use a scroll view to ensure the form is accessible on smaller screens, especially when the keyboard is visible. |

## 2. Data and Logic

| Android Component | iOS Equivalent | Notes |
| --- | --- | --- |
| `Data Class` (`Customer.kt`) | `struct` (`Customer.swift`) | The Kotlin data class was translated into a Swift `struct`. It was made `Codable` to simplify serialization for Firebase. |
| `FirebaseDatabase` | `FirebaseDatabase` | The logic for accessing Firebase Realtime Database is similar. The database reference is constructed using the `UserSession.shared.userParent` singleton, mirroring the Android implementation. Data is written using `setValue()`. |
| `Toast` / `AlertDialog` | `UIAlertController` | User feedback, such as validation errors or success messages, is presented using `UIAlertController`, which is the standard iOS way to show alerts. |
| `Intent` Extras | `UIViewController` Initializer | In Android, data (like an existing `Customer` object for edit mode) is passed via `Intent` extras. In iOS, this was handled by passing the `Customer` object directly into the `CustomerFormViewController`'s initializer. |
| `Log.d` | `os.Logger` | Structured logging was implemented using Apple's `os.Logger` framework to log lifecycle events, user actions, and errors, as requested. |

## 3. Reused Components

The following existing custom components from the iOS project were reused to ensure visual and functional consistency:

-   `CustomTextField`
-   `CustomButton`

By following these mappings, the `CustomerFormViewController` successfully replicates the features of its Android counterpart while feeling like a native, idiomatic iOS screen that fits perfectly within the existing "AM Site Solutions" project.
