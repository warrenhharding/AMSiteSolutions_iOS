# Mapping: LogoManagementActivity.kt to LogoManagementViewController.swift

This document outlines the translation of the Android `LogoManagementActivity` and its corresponding XML layout into a native iOS `LogoManagementViewController` using Swift and UIKit.

## Component Mapping

| Android Component | iOS Equivalent | Notes |
| --- | --- | --- |
| `AppCompatActivity` | `UIViewController` | The base class for a screen in Android is mapped to the base view controller in iOS. |
| `activity_logo_management.xml` | Programmatic Auto Layout | The declarative XML layout is translated into programmatic constraints in Swift for a flexible and maintainable UI. |
| `RelativeLayout` | `UIView` with Auto Layout | The root layout is a standard `UIView`, with child views positioned using `NSLayoutConstraint`. |
| `HeaderView` | `UINavigationBar` | The custom `HeaderView` is replaced by the standard iOS `UINavigationBar`, configured with a title. The back button is provided by the `UINavigationController`. |
| `ImageView` | `UIImageView` | A direct mapping for displaying the logo. |
| `TextView` (Placeholder) | `UILabel` | Used to display the placeholder text when no logo is present. |
| `ProgressBar` | `UIActivityIndicatorView` | The standard iOS loading spinner is used to indicate network activity. |
| `Button` | `CustomButton` | The existing `CustomButton` class is reused to maintain a consistent look and feel with the rest of the app. |
| `AlertDialog` | `UIAlertController` | Used for showing alerts for success/failure messages and for confirming actions like logo removal. |
| `registerForActivityResult` | `PHPickerViewControllerDelegate`, `UIImagePickerControllerDelegate` | The modern `PHPicker` is used for gallery selection, and `UIImagePickerController` is used for camera capture. Delegates handle the results. |
| Firebase `StorageReference` | Firebase `StorageReference` | The Firebase Storage SDK for iOS is used, with method calls being very similar to their Android counterparts (`getData` for `getBytes`, `putData` for `putBytes`, `delete` for `delete`). |
| Permission Handling (`RequestPermission`) | `AVCaptureDevice.requestAccess`, `PHPhotoLibrary.requestAuthorization` | Native iOS frameworks are used to request permissions for the camera and photo library at the time of use. |
| Logging (`Log`, `FirebaseCrashlytics`) | `os.log`, `FirebaseCrashlytics` | `os.log` is used for structured, on-device logging, while Firebase Crashlytics is used for remote logging and error reporting, mirroring the Android implementation. |

## Reused Components

*   **`CustomButton`**: This existing component was used for the "Upload Logo" and "Remove Logo" buttons to ensure UI consistency.
*   **`UserSession`**: The singleton `UserSession` is used to retrieve the `userParent` ID, which is essential for constructing the correct Firebase Storage path. This mirrors the `UserSession` usage in the Android version.

## Key Implementation Choices

*   **Programmatic UI**: The UI is built entirely in code using Auto Layout, which avoids Storyboards/XIBs and keeps all view logic self-contained within the view controller file, as requested.
*   **Modern Image Picker**: `PHPickerViewController` was chosen for gallery access over the older `UIImagePickerController` because it is the modern, recommended API that offers better privacy for users. `UIImagePickerController` is still used for camera access, as is standard practice.
*   **Permissions**: Permissions are checked and requested just-in-time, which is the standard iOS pattern. This ensures the user understands the context of the permission request.
*   **Error Handling**: Network and permission errors are handled gracefully by showing alerts to the user with `UIAlertController`. Errors are also logged to Crashlytics for monitoring.
*   **Structured Logging**: `os.log` is used to provide detailed, categorized logs for debugging and monitoring view controller lifecycle and key events.
