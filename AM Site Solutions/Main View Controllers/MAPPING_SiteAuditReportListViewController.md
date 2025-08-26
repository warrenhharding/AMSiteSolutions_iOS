# Android to iOS Mapping: SiteAuditReportListViewController

This document outlines the translation of the Android `SiteAuditReportListActivity` and its related components to the iOS `SiteAuditReportListViewController`.

| Android Component | iOS Equivalent | Notes |
| --- | --- | --- |
| `SiteAuditReportListActivity.kt` | `SiteAuditReportListViewController.swift` | The core logic and UI container. |
| `activity_site_audit_report_list.xml` | Programmatic Auto Layout in `setupUI()` | The entire UI is built in code using `NSLayoutConstraint` for consistency with the existing iOS project. |
| `RecyclerView` | `UITableView` | The standard iOS component for displaying scrollable lists. |
| `SiteAuditReportAdapter.kt` | `ReportTableViewCell` (private class) | A custom `UITableViewCell` is created within the view controller file to handle the display of each report. |
| `item_site_audit_report.xml` | `ReportTableViewCell`'s `setupUI()` | The layout for each table row is defined programmatically within the cell class. |
| `SearchView` | `UISearchBar` | The native iOS component for search functionality. |
| `Button` (for new report) | `CustomButton` | Reusing the project's existing custom button class for a consistent look and feel. |
| `FirebaseDatabase` listener | `databaseRef.observe(.value)` | Firebase Realtime Database observation is used to fetch and listen for changes in the reports data. |
| `AlertDialog` (for deletion) | `UIAlertController` | The native iOS way to present alerts and confirmation dialogs. |
| `SiteAuditRecord.kt` | `SiteAuditReport` (struct) | The existing `SiteAuditReport` struct in `CreateSiteAuditReportViewController.swift` is used as the data model. |
| `Log.d` | `os.log` (`Logger`) | Using the unified logging system for consistent logging practices as seen in `SubscriberCustomerCustViewController`. |

## Component Reuse

*   **`HeaderView`**: The concept of a custom header is implemented using the standard `UINavigationBar` by setting the `title` property of the view controller. This aligns with native iOS navigation patterns.
*   **`CustomButton`**: The "Create New Report" button is an instance of the existing `CustomButton` class, ensuring UI consistency.
*   **`UserSession`**: The `UserSession.shared.userParent` is used to construct the correct Firebase database path, just like in other parts of the iOS app.
