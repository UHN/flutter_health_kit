# HealthKit Example App

A comprehensive Flutter example app demonstrating how to use the `flutter_health_kit` plugin to access Apple HealthKit data.

## Features

This example app demonstrates:

- **Authorization**: Request permissions for HealthKit data types
- **Characteristic Data**: Display biological characteristics including:
  - Biological Sex
  - Blood Type
  - Date of Birth (with age calculation)
  - Fitzpatrick Skin Type
  - Wheelchair Use
  - Activity Move Mode
- **Heart Rate**: Query and display the most recent heart rate measurement
- **Workouts**: Query and display the most recent workout with details like:
  - Workout type (running, cycling, swimming, etc.)
  - Duration
  - Distance (if applicable)
  - Calories burned
  - Source information

## Requirements

- iOS device or simulator (HealthKit is iOS-only)
- iOS 12.0 or later
- Xcode 14.0 or later
- Physical iOS device recommended (simulators have limited HealthKit data)

## Setup

1. Open the example app:
   ```bash
   cd example
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app on an iOS device or simulator:
   ```bash
   flutter run
   ```

## Usage

1. **Grant Permissions**: Tap the "Request Authorization" button on the first screen. This will prompt iOS to request permissions for:
   - All characteristic types (biological sex, blood type, etc.)
   - Heart rate data
   - Workout data

2. **View Data**: After granting permissions, the app will automatically load and display:
   - Your characteristic data in the top card
   - Your most recent heart rate reading
   - Your most recent workout

3. **Refresh Data**: Pull down to refresh and reload the latest data from HealthKit

## Adding Test Data

If you're testing on a simulator or device without health data, you can add test data using the Health app:

1. Open the Health app on your iOS device/simulator
2. Tap on your profile icon (top right)
3. Scroll to "Health Details" and add:
   - Date of Birth
   - Biological Sex
   - Blood Type
   - Other characteristics

4. For heart rate and workout data:
   - Use the Health app to manually add data
   - Or use Apple Watch to record real workouts and heart rate
   - Or use other health apps that write to HealthKit

## Code Structure

- **main.dart**: Complete example app with:
  - Authorization flow
  - Data loading from HealthKit
  - UI components for displaying health data
  - Extensions for enum display names
  - Pull-to-refresh functionality

## Key API Calls

### Request Authorization
```dart
await FlutterHealthKit.requestAuthorization(
  read: [
    HKCharacteristicTypeIdentifier.biologicalSex,
    HKQuantityTypeIdentifier.heartRate,
    HKSampleTypeIdentifier.workout,
  ],
);
```

### Query Characteristic
```dart
final characteristic = await FlutterHealthKit.queryCharacteristic(
  HKCharacteristicTypeIdentifier.biologicalSex,
);
```

### Query Samples
```dart
final heartRates = await FlutterHealthKit.querySampleType<Quantity>(
  HKQuantityTypeIdentifier.heartRate,
  limit: 1,
  predicate: Predicate.predicateForSamples(
    withStart: DateTime.now().subtract(Duration(days: 30)),
    end: DateTime.now(),
  ),
);
```

## Troubleshooting

### "HealthKit is not available on this device"
- HealthKit is only available on iOS devices
- Ensure your device meets the minimum iOS version requirement

### No data appearing
- Make sure you've granted permissions in the authorization prompt
- Check that you have health data in the Health app
- Try manually adding data to the Health app
- Pull down to refresh the data

### Authorization failing
- Check that Info.plist includes required keys:
  - `NSHealthShareUsageDescription`
  - `NSHealthUpdateUsageDescription`
  - `healthkit` in `UIRequiredDeviceCapabilities`

## Learn More

- [HealthKit Documentation](https://developer.apple.com/documentation/healthkit)
- [flutter_health_kit Plugin](https://pub.dev/packages/flutter_health_kit)
