# Android to iOS Mapping: Customer List View

This document outlines the translation of the Android `SubscriberCustomerCustListActivity` and its related components to a single `SubscriberCustomerCustViewController` in Swift for the "AM Site Solutions" iOS project.

## Component Mapping

| Android Component | iOS Equivalent | Notes |
| --- | --- | --- |
| `SubscriberCustomerCustListActivity.kt` | `SubscriberCustomerCustViewController.swift` | A `UIViewController` will manage the view, data, and user interactions. |
| `activity_subscriber_customer_cust_list.xml` | Programmatic Auto Layout in `SubscriberCustomerCustViewController` | The entire UI will be constructed in code using Auto Layout anchors for flexibility and maintainability. |
| `RecyclerView` | `UITableView` | The standard for displaying scrollable lists in UIKit. |
| `CustomerAdapter.kt` | `UITableViewDataSource` & `UITableViewDelegate` | The view controller will adopt these protocols to manage the table view's data and interactions. |
| `item_customer.xml` | `CustomerTableViewCell` (a custom `UITableViewCell`) | A custom cell class will be created inside the view controller file to represent a customer row, similar to the XML layout. |
| `SearchView` | `UISearchBar` | Standard iOS component for search functionality. |
| `CheckBox` (`includeArchivedCheckBox`) | `UISwitch` or a custom checkbox view | A `UISwitch` is the idiomatic iOS control for on/off states. |
| `Button` (`createButton`, `clearFiltersButton`) | `CustomButton` (reusing existing) | The project's existing `CustomButton` class will be used for consistency. |
| `HeaderView` (custom) | `HeaderView` (reusing existing) | The existing `HeaderView` from `ManageMachineryViewController.swift` will be reused. |
| `FirebaseDatabase` Listener | `Database.database().reference()` observer | Firebase Realtime Database observers (`.observe(.value, with: ...)` will be used to fetch and listen for data changes. |
| `Intent` to `CustomerFormActivity` | `navigationController?.pushViewController(...)` | Navigation will be handled by pushing the `CustomerFormViewController` onto the navigation stack. |
| `AlertDialog` | `UIAlertController` | Used for presenting alerts and confirmation dialogs to the user. |

## Reused Components

- **`HeaderView`**: The existing custom `HeaderView` will be used for the screen title and back button, configured similarly to `ManageMachineryViewController.swift`.
- **`CustomButton`**: All buttons will use the existing `CustomButton` class to maintain a consistent look and feel.
- **`AppLogger`**: The existing logging wrapper will be used for structured logging throughout the view controller's lifecycle and for key events.

## Architectural Notes

- **Single File**: All UI, logic, and the custom `UITableViewCell` will be contained within `SubscriberCustomerCustViewController.swift` as requested.
- **Programmatic UI**: The entire view hierarchy will be built in code, avoiding Storyboards or XIBs.
- **Data Model**: A `Customer` struct will be defined to model the data retrieved from Firebase, mirroring the Android `Customer` model.
