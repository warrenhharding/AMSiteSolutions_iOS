
# Android to iOS Translation Mapping: Customer Site Form

This document outlines the mapping of components and concepts from the Android `CustomerSiteFormActivity` to the iOS `CustomerSiteFormViewController`.

### Core Components

| Android Component                                | iOS Equivalent                                                  | Notes                                                                                                                         |
| ------------------------------------------------ | --------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------- |
| `Activity` (`CustomerSiteFormActivity.kt`)   | `UIViewController` (`CustomerSiteFormViewController.swift`) | The fundamental building block for a screen in each platform.                                                                 |
| XML Layout (`activity_customer_site_form.xml`) | Programmatic Auto Layout                                        | iOS UI is defined in Swift using `NSLayoutConstraint` anchors for flexibility and maintainability.                          |
| `ScrollView`                                   | `UIScrollView`                                                | Provides scrollable content area.                                                                                             |
| `LinearLayout` / `ConstraintLayout`          | `UIStackView`                                                 | Used to arrange UI elements vertically.`UIStackView` simplifies linear layouts.                                             |
| `EditText`                                     | `CustomTextField`                                             | Reused the existing `CustomTextField` for all text input fields.                                                            |
| `Spinner`                                      | `UIPickerView` + `CustomTextField`                          | A `CustomTextField` is used as the display, with a `UIPickerView` set as its `inputView` to provide the selection list. |
| `CheckBox`                                     | `UISwitch`                                                    | The standard iOS equivalent for a boolean toggle.                                                                             |
| `Button`                                       | `CustomButton`                                                | Reused the existing `CustomButton` for consistent styling.                                                                  |
| `TextView` (for labels)                        | `UILabel`                                                     | Standard text label component.                                                                                                |
| `ProgressDialog` / `ProgressBar`             | `UIActivityIndicatorView`                                     | A spinner overlay to indicate loading states.                                                                                 |
| `AlertDialog`                                  | `UIAlertController`                                           | Used for showing alerts for validation errors, success messages, and other notifications.                                     |

### Data Models

| Android Component                       | iOS Equivalent                        | Notes                                                                                                 |
| --------------------------------------- | ------------------------------------- | ----------------------------------------------------------------------------------------------------- |
| Kotlin Data Class (`CustomerSite.kt`) | Swift Struct (`CustomerSite.swift`) | The `CustomerSite` struct is made `Codable` for easy serialization/deserialization with Firebase. |

### Logic and Architecture

| Android Concept                 | iOS Equivalent                              | Notes                                                                                    |
| ------------------------------- | ------------------------------------------- | ---------------------------------------------------------------------------------------- |
| `onCreate()`                  | `viewDidLoad()`                           | The primary method for setting up the view controller's UI and initial state.            |
| Firebase `ValueEventListener` | Firebase `observeSingleEvent(of: .value)` | Used to fetch data from the Firebase Realtime Database.                                  |
| Intent Extras                   | `init(customerSite:)`                     | Data (like the `CustomerSite` object in edit mode) is passed via a custom initializer. |
| `finish()`                    | `dismiss(animated: true)`                 | Used to close the view controller, for example, after saving or canceling.               |
| Logging (`Log.d`)             | `os.Logger`                               | Structured logging is used for better debugging and monitoring.                          |

### Reused Components

To maintain consistency with the existing application, the following custom components were reused:

- **`HeaderView`**: Assumed to be provided for the main screen header.
- **`CustomButton`**: Used for the "Save" button.
- **`CustomTextField`**: Used for all text-based input fields.
- **`CustomPickerView`**: While not directly used, the concept of a custom picker was adapted by assigning a `UIPickerView` to a `CustomTextField`'s input.
