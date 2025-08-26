# Mapping: SubscriberCustomerManagement

This document outlines the translation from the Android `SubscriberCustomerManagementActivity` to the iOS `SubscriberCustomerManagementViewController`.

## Component Mapping

| Android Component | iOS Equivalent | Notes |
| --- | --- | --- |
| `SubscriberCustomerManagementActivity.kt` | `SubscriberCustomerManagementViewController.swift` | The core logic is translated from an Android `Activity` to a Swift `UIViewController`. |
| `activity_subscriber_customer_management.xml` | Programmatic Auto Layout | The UI, defined in XML on Android, is created programmatically using Auto Layout constraints within `viewDidLoad`. |
| `ListView` | `UITableView` | A `UITableView` is the standard iOS component for displaying scrollable lists of data, equivalent to Android's `ListView`. |
| `FolderAdapter.kt` | `UITableViewDataSource`, `UITableViewDelegate` | The adapter's responsibilities are handled directly by the view controller, which conforms to the table view's data source and delegate protocols. |
| `FolderItem` data class | `MenuSection` struct | A simple `struct` is used to organize the table view data into sections and rows, mirroring the structure from the Android version. |
| `HeaderView` (custom view) | `HeaderView` (reused) | The existing `HeaderView` component from the iOS project is reused to maintain a consistent look and feel. |
| `Intent` for navigation | `UINavigationController.pushViewController` | Screen transitions are managed by pushing new view controllers onto the navigation stack. |
| `R.color.amBlue` | `UIColor(named: "amBlue")` | Color resources are mapped to the iOS Asset Catalog. |

## Reused Components

-   **`HeaderView`**: The existing custom `HeaderView` is used for the screen title and back button, configured identically to how it's used in `MyFolderViewController.swift`.
-   **Custom UI Elements**: While this screen primarily uses standard `UITableView`, the principle is to reuse existing custom components like `CustomButton` or `CustomTextField` where applicable, which is a pattern followed from the reference files.
