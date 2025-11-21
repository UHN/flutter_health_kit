# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Flutter plugin that provides access to Apple's HealthKit framework for iOS. It enables Flutter apps to read and observe health data from the HealthKit store, including workouts, quantities (heart rate, steps, etc.), categories (sleep analysis, mindful sessions, etc.), correlations (blood pressure), and electrocardiograms.

## Development Commands

### Lint and Analyze
```bash
# Run static analysis
flutter analyze

# Check for linting issues
flutter analyze --no-pub
```

### Testing
```bash
# Run all tests
flutter test

# Run a specific test file
flutter test test/flutter_health_kit_test.dart
```

### Building
```bash
# Get dependencies
flutter pub get

# Run example app (iOS only - requires physical device or simulator)
cd example && flutter run
```

### Running the Example App
The example app demonstrates basic authorization and querying. Note: This plugin only works on iOS devices/simulators, not on Android or other platforms.

```bash
cd example
flutter run -d <device-id>
```

## Architecture

### Plugin Architecture Pattern
This plugin follows the standard Flutter federated plugin pattern with three layers:

1. **API Layer** (`lib/flutter_health_kit.dart`): Main entry point with static methods that users interact with. Handles type mapping between Dart models and platform data.

2. **Platform Interface** (`lib/flutter_health_kit_platform_interface.dart`): Abstract interface defining the contract for platform implementations.

3. **Method Channel Implementation** (`lib/flutter_health_kit_method_channel.dart`): iOS-specific implementation using method channels to communicate with native code.

### Data Flow
```
Flutter App → FlutterHealthKit (static methods)
           → FlutterHealthKitPlatform.instance
           → MethodChannelFlutterHealthKit
           → Method Channel
           → Swift Plugin (FlutterHealthKitPlugin.swift)
           → HealthKit Framework
```

### Type System
The type system mirrors Apple's HealthKit hierarchy:

- **ObjectTypeId**: Base type for all HealthKit objects
  - **SampleTypeId**: Base for all sample types
    - **HKQuantityTypeIdentifier**: Numeric measurements (heart rate, steps, etc.) - ~140 types
    - **HKCategoryTypeIdentifier**: Categorical data (sleep, mindful sessions, etc.) - ~70 types
    - **HKCharacteristicTypeIdentifier**: Fixed characteristics (biological sex, blood type, etc.)
    - **HKCorrelationTypeIdentifier**: Related samples (blood pressure = systolic + diastolic)
    - **HKDocumentTypeIdentifier**: Documents (CDA)
    - **HKSampleTypeIdentifier**: Special samples (workouts, ECGs, audiograms, etc.)

All type identifiers are enums with a private constructor that takes the HealthKit identifier string.

### Core Models
Located in `lib/models.dart`:

- **Sample**: Abstract base class for all health samples with uuid, start/end dates, source, device, and metadata
  - **Workout**: Exercise session with activity type, duration, events, and statistics
  - **Quantity**: Numeric measurement with unit and values map
  - **Category**: Categorical data with integer value
  - **Correlation**: Related samples (e.g., blood pressure combining systolic/diastolic)
  - **Electrocardiogram**: ECG data with classification, symptoms status, and voltage measurements

- **WorkoutEvent**: Events during workout (pause, resume, lap, marker, etc.)
- **Statistic**: Statistical data (average, total, min, max) with unit
- **SourceRevision**: Metadata about data source (app, OS version, device)
- **Device**: Physical device information
- **VoltageMeasurement**: ECG voltage data points

### Querying System

#### Query Types
1. **Sample Queries** (`querySampleType<T>`): Fetch historical samples with optional predicates, sorting, and limits
2. **Statistics Queries** (`queryStatistics<T>`): Get aggregated statistics (avg, min, max, sum)
3. **Observer Queries** (`observeQuery`): Stream of changes to specific data types
4. **Anchored Object Queries** (`anchoredObjectQuery<T>`): Incremental updates with added/deleted samples
5. **ECG Voltage Queries** (`queryElectrocardiogram`): Detailed voltage measurements for a specific ECG

#### Predicates
Defined in `lib/predicate.dart`:
- `predicateForSamples`: Filter by date range
- `predicateForObjectsWithMetadataKey`: Filter by metadata key/value with operators
- `predicateForObjectsAssociated`: Filter by associated samples
- Logical operators: `and`, `or`

#### Sort Descriptors
Defined in `lib/sort.dart`:
- Sort by start date, end date, or end date (ascending/descending)

### Type Mappers
The `mappers` static field in `FlutterHealthKit` maps Dart types to their `fromJson` factory constructors:
```dart
static final mappers = <Type, dynamic Function(Map<dynamic, dynamic>)>{
  Workout: (map) => Workout.fromJson(Map.from(map)),
  Quantity: (map) => Quantity.fromJson(Map.from(map)),
  Correlation: (map) => Correlation.fromJson(Map.from(map)),
  Electrocardiogram: (map) => Electrocardiogram.fromJson(Map.from(map)),
  Category: (map) => Category.fromJson(Map.from(map)),
};
```

When adding new sample types, ensure they are registered in this map.

### Native iOS Implementation
Located in `ios/Classes/`:

- **FlutterHealthKitPlugin.swift**: Main plugin class handling method calls, background delivery, and observer queries
- **Extensions+HealthKit.swift**: Extensions for converting between Swift HealthKit types and Flutter representations
- **Extensions+String.swift**: String utilities for type identifier conversion

Key features:
- Background delivery support with persistent queries
- Observer queries for real-time data updates
- Anchored object queries for incremental sync
- Query restoration on app launch

### Category Values
The `lib/category_values.dart` file contains enums for category sample values, mirroring Apple's HKCategoryValue enums (e.g., sleep analysis values, cervical mucus quality values, etc.).

### Authorization
HealthKit requires explicit authorization for each data type:
- `requestAuthorization`: Request read/write permissions
- `authorizationStatus`: Check current authorization state

Important: Users can grant/deny individual data types, so always check authorization status before querying.

## Common Patterns

### Reading Data
```dart
// 1. Request authorization
await FlutterHealthKit.requestAuthorization(
  read: [HKSampleTypeIdentifier.workout],
);

// 2. Query samples
final workouts = await FlutterHealthKit.querySampleType<Workout>(
  HKSampleTypeIdentifier.workout,
  limit: 100,
  predicate: Predicate.predicateForSamples(
    withStart: DateTime.now().subtract(Duration(days: 7)),
    end: DateTime.now(),
  ),
);
```

### Observing Changes
```dart
final stream = await FlutterHealthKit.observeQuery(
  HKQuantityTypeIdentifier.heartRate,
  startDate: DateTime.now().subtract(Duration(days: 1)),
  endDate: DateTime.now(),
);

stream.listen((typeId) {
  // Query new data when notified
  final data = await FlutterHealthKit.querySampleType<Quantity>(typeId);
});
```

### Incremental Sync
```dart
final stream = await FlutterHealthKit.anchoredObjectQuery<Quantity>(
  HKQuantityTypeIdentifier.stepCount,
  withStart: DateTime.now().subtract(Duration(days: 1)),
  end: DateTime.now(),
);

stream.listen((record) {
  final (addedSamples, deletedUuids) = record;
  // Process added samples and handle deletions
});
```

## Testing Notes

- Tests are minimal and primarily verify plugin initialization
- Real testing requires iOS simulator/device with HealthKit access
- HealthKit data is sandboxed per app in simulator
- Background delivery requires proper entitlements in iOS

## Code Style

This project follows `flutter_lints` with additional rules (see `analysis_options.yaml`):
- Use single quotes for strings
- Require trailing commas
- Prefer relative imports within the package
- Prefer const constructors where possible
- Always put required named parameters first
- Sort constructors first

## Platform Support

**iOS only** - This plugin requires iOS and the HealthKit framework. Minimum iOS version should be checked in the podspec file.

## Known Limitations

- Write operations are not implemented (read-only plugin)
- Some newer HealthKit types may not be included in the type identifiers
- Background delivery requires app to be registered for background modes
- HealthKit data access requires privacy descriptions in Info.plist
