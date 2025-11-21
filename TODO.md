# TODO: Add HealthKit Characteristic Support

## Overview

This TODO tracks the implementation of HealthKit Characteristic data support in the flutter_health_kit plugin.

### What are HealthKit Characteristics?

Characteristics are **read-once values** stored per user in HealthKit, fundamentally different from Samples:

| Aspect | Samples (Workout, Quantity, etc.) | Characteristics |
|--------|-----------------------------------|-----------------|
| **Time-bound** | Yes (start/end dates) | No |
| **Multiple instances** | Yes (time-series data) | No (one value per user) |
| **Query method** | Query objects (HKSampleQuery, etc.) | Direct HKHealthStore methods |
| **Metadata** | sourceRevision, device, metadata | None |
| **Examples** | Heart rate readings, workouts | Biological sex, blood type, date of birth |

### Characteristic Types to Support

1. **biologicalSex**: Male, Female, Other, Not Set
2. **bloodType**: A+, A-, B+, B-, AB+, AB-, O+, O-, Not Set
3. **dateOfBirth**: Date
4. **fitzpatrickSkinType**: I-VI scale for skin sensitivity to sun
5. **wheelchairUse**: Yes, No, Not Set
6. **activityMoveMode**: Active Energy, Apple Move Time

## Current State

### ✅ Already Implemented

- [x] Type identifiers defined in `lib/types.dart` (lines 279-291)
  ```dart
  enum HKCharacteristicTypeIdentifier implements SampleTypeId {
    biologicalSex, bloodType, dateOfBirth, fitzpatrickSkinType,
    wheelchairUse, activityMoveMode
  }
  ```
- [x] Type identifiers integrated in `ObjectTypeId.fromIdentifier` factory
- [x] Authorization support (works via existing `requestAuthorization`)
- [x] iOS String extension for characteristic type mapping (`ios/Classes/Extensions+String.swift:665-687`)

### ❌ Not Yet Implemented

- [ ] Characteristic value enums
- [ ] Characteristic data model
- [ ] Query method in API
- [ ] Platform interface method
- [ ] Method channel implementation
- [ ] iOS native handler
- [ ] Tests
- [ ] Documentation updates

---

## Implementation Tasks

### 1. Dart Models (`lib/models.dart`)

#### 1.1 Create Characteristic Value Enums

Add these enums to `lib/models.dart`:

```dart
/// Biological sex values
enum BiologicalSex {
  notSet._(0),
  female._(1),
  male._(2),
  other._(3);

  const BiologicalSex._(this.code);
  final int code;

  static BiologicalSex fromCode(int code) =>
      BiologicalSex.values.firstWhere((e) => e.code == code);
}

/// Blood type values
enum BloodType {
  notSet._(0),
  aPositive._(1),
  aNegative._(2),
  bPositive._(3),
  bNegative._(4),
  abPositive._(5),
  abNegative._(6),
  oPositive._(7),
  oNegative._(8);

  const BloodType._(this.code);
  final int code;

  static BloodType fromCode(int code) =>
      BloodType.values.firstWhere((e) => e.code == code);
}

/// Fitzpatrick skin type values (I-VI scale)
enum FitzpatrickSkinType {
  notSet._(0),
  I._(1),
  II._(2),
  III._(3),
  IV._(4),
  V._(5),
  VI._(6);

  const FitzpatrickSkinType._(this.code);
  final int code;

  static FitzpatrickSkinType fromCode(int code) =>
      FitzpatrickSkinType.values.firstWhere((e) => e.code == code);
}

/// Wheelchair use values
enum WheelchairUse {
  notSet._(0),
  no._(1),
  yes._(2);

  const WheelchairUse._(this.code);
  final int code;

  static WheelchairUse fromCode(int code) =>
      WheelchairUse.values.firstWhere((e) => e.code == code);
}

/// Activity move mode values
enum ActivityMoveMode {
  activeEnergy._(1),
  appleMoveTime._(2);

  const ActivityMoveMode._(this.code);
  final int code;

  static ActivityMoveMode fromCode(int code) =>
      ActivityMoveMode.values.firstWhere((e) => e.code == code);
}
```

**Notes:**
- Match Apple's HKBiologicalSex, HKBloodType, etc. raw values
- Include `notSet` cases where applicable
- Use private constructor pattern consistent with other enums in the codebase

#### 1.2 Create Characteristic Class

```dart
/// A characteristic value from HealthKit.
///
/// Unlike samples, characteristics are read-once values that don't change
/// frequently (e.g., biological sex, blood type, date of birth).
class Characteristic {
  factory Characteristic.fromJson(Map<String, dynamic> json) {
    final type = HKCharacteristicTypeIdentifier.values.firstWhere(
      (e) => e.identifier == json['type'],
    );

    dynamic value;
    switch (type) {
      case HKCharacteristicTypeIdentifier.biologicalSex:
        value = BiologicalSex.fromCode(json['value'] as int);
        break;
      case HKCharacteristicTypeIdentifier.bloodType:
        value = BloodType.fromCode(json['value'] as int);
        break;
      case HKCharacteristicTypeIdentifier.dateOfBirth:
        value = DateTime.fromMillisecondsSinceEpoch(
          ((json['value'] as double) * 1000).toInt(),
        );
        break;
      case HKCharacteristicTypeIdentifier.fitzpatrickSkinType:
        value = FitzpatrickSkinType.fromCode(json['value'] as int);
        break;
      case HKCharacteristicTypeIdentifier.wheelchairUse:
        value = WheelchairUse.fromCode(json['value'] as int);
        break;
      case HKCharacteristicTypeIdentifier.activityMoveMode:
        value = ActivityMoveMode.fromCode(json['value'] as int);
        break;
    }

    return Characteristic(
      type: type,
      value: value,
    );
  }

  Characteristic({
    required this.type,
    required this.value,
  });

  /// The type of characteristic
  final HKCharacteristicTypeIdentifier type;

  /// The value of the characteristic
  /// Type depends on characteristic type:
  /// - biologicalSex: BiologicalSex
  /// - bloodType: BloodType
  /// - dateOfBirth: DateTime
  /// - fitzpatrickSkinType: FitzpatrickSkinType
  /// - wheelchairUse: WheelchairUse
  /// - activityMoveMode: ActivityMoveMode
  final dynamic value;
}
```

**Notes:**
- Does NOT extend Sample (characteristics are not samples)
- No uuid, start/end dates, sourceRevision, device, or metadata
- Type-safe value access via switch statement in fromJson
- Consider adding typed getters like `BiologicalSex? get biologicalSex => value is BiologicalSex ? value : null`

**Tasks:**
- [ ] Add BiologicalSex enum
- [ ] Add BloodType enum
- [ ] Add FitzpatrickSkinType enum
- [ ] Add WheelchairUse enum
- [ ] Add ActivityMoveMode enum
- [ ] Add Characteristic class with fromJson factory
- [ ] Run `flutter analyze` to verify no issues

---

### 2. API Layer (`lib/flutter_health_kit.dart`)

#### 2.1 Add Characteristic Mapper

Update the `mappers` static field (line 8):

```dart
static final mappers = <Type, dynamic Function(Map<dynamic, dynamic>)>{
  Workout: (map) => Workout.fromJson(Map.from(map)),
  Quantity: (map) => Quantity.fromJson(Map.from(map)),
  Correlation: (map) => Correlation.fromJson(Map.from(map)),
  Electrocardiogram: (map) => Electrocardiogram.fromJson(Map.from(map)),
  Category: (map) => Category.fromJson(Map.from(map)),
  Characteristic: (map) => Characteristic.fromJson(Map.from(map)), // ADD THIS
};
```

#### 2.2 Add Query Method

Add this static method after `queryElectrocardiogram` (around line 146):

```dart
/// Queries a characteristic value from HealthKit.
///
/// Characteristics are read-once values like biological sex, blood type,
/// date of birth, etc. Unlike samples, they don't have time ranges or
/// multiple instances.
///
/// [type] is the [HKCharacteristicTypeIdentifier] to query.
///
/// Returns a [Characteristic] with the value, or throws if not authorized
/// or the characteristic is not set.
static Future<Characteristic> queryCharacteristic(
  HKCharacteristicTypeIdentifier type,
) async {
  final result = await FlutterHealthKitPlatform.instance.queryCharacteristic(
    type.identifier,
  );
  return Characteristic.fromJson(result);
}
```

**Tasks:**
- [ ] Add Characteristic to mappers
- [ ] Add queryCharacteristic method
- [ ] Add documentation comments
- [ ] Consider error handling for "not set" cases

---

### 3. Platform Interface (`lib/flutter_health_kit_platform_interface.dart`)

Add abstract method declaration after `queryElectrocardiogram` (around line 85):

```dart
Future<Map<String, dynamic>> queryCharacteristic(String type) {
  throw UnimplementedError(
    'queryCharacteristic() has not been implemented.',
  );
}
```

**Tasks:**
- [ ] Add abstract method to FlutterHealthKitPlatform
- [ ] Ensure method signature returns `Map<String, dynamic>` (not `List`)

---

### 4. Method Channel Implementation (`lib/flutter_health_kit_method_channel.dart`)

Add implementation after `queryElectrocardiogram` method:

```dart
@override
Future<Map<String, dynamic>> queryCharacteristic(String type) async {
  final result = await methodChannel.invokeMethod<Map<dynamic, dynamic>>(
    'queryCharacteristic',
    {'type': type},
  );
  if (result == null) {
    throw PlatformException(
      code: 'NULL_RESULT',
      message: 'queryCharacteristic returned null',
    );
  }
  return Map<String, dynamic>.from(result);
}
```

**Tasks:**
- [ ] Add method implementation
- [ ] Handle null result case
- [ ] Test method channel invocation

---

### 5. iOS Native Implementation

#### 5.1 Swift Plugin Handler (`ios/Classes/FlutterHealthKitPlugin.swift`)

Add case in `handle(_ call: FlutterMethodCall, result: @escaping FlutterResult)` method:

```swift
case "queryCharacteristic":
    guard let arguments = call.arguments as? [String: Any],
          let typeString = arguments["type"] as? String,
          let characteristicType = typeString.characteristicTypeIdentifier else {
        result(
            FlutterError(
                code: "flutter_health_kit",
                message: "\(call.method) invalid arguments \(String(describing: call.arguments))",
                details: nil))
        return
    }

    Task {
        do {
            let characteristic = try await queryCharacteristic(type: characteristicType)
            result(characteristic)
        } catch {
            result(
                FlutterError(
                    code: "flutter_health_kit",
                    message: "\(call.method) error: \(error.localizedDescription)",
                    details: nil))
        }
    }
```

#### 5.2 Add queryCharacteristic Method to FlutterHealthKitPlugin

Add this private method:

```swift
private func queryCharacteristic(type: HKCharacteristicTypeIdentifier) async throws -> [String: Any] {
    var value: Any
    let typeString = type.identifier

    switch type {
    case .biologicalSex:
        let biologicalSex = try store.biologicalSex()
        value = biologicalSex.biologicalSex.rawValue

    case .bloodType:
        let bloodTypeObject = try store.bloodType()
        value = bloodTypeObject.bloodType.rawValue

    case .dateOfBirth:
        let components = try store.dateOfBirthComponents()
        if let date = Calendar.current.date(from: components) {
            value = date.timeIntervalSince1970
        } else {
            throw NSError(
                domain: "flutter_health_kit",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Could not construct date from components"]
            )
        }

    case .fitzpatrickSkinType:
        let skinTypeObject = try store.fitzpatrickSkinType()
        value = skinTypeObject.skinType.rawValue

    case .wheelchairUse:
        let wheelchairUseObject = try store.wheelchairUse()
        value = wheelchairUseObject.wheelchairUse.rawValue

    case .activityMoveMode:
        let activityMoveModeObject = try store.activityMoveMode()
        value = activityMoveModeObject.activityMoveMode.rawValue

    default:
        throw NSError(
            domain: "flutter_health_kit",
            code: -1,
            userInfo: [NSLocalizedDescriptionKey: "Unsupported characteristic type: \(type.identifier)"]
        )
    }

    return [
        "type": typeString,
        "value": value
    ]
}
```

**Notes:**
- Use `try store.biologicalSex()` pattern (direct HKHealthStore methods)
- Return raw values (Int for enums, Double for date timestamp)
- Handle `dateOfBirth` specially (returns DateComponents, needs conversion)
- Wrap in async/await for consistency
- Throw errors if characteristic not set (let Dart handle gracefully)

**Tasks:**
- [ ] Add "queryCharacteristic" case to handle method
- [ ] Add private queryCharacteristic method
- [ ] Handle all 6 characteristic types
- [ ] Test with characteristics that are/aren't set
- [ ] Verify error handling

#### 5.3 iOS Extensions (Optional)

Consider adding extensions in `ios/Classes/Extensions+HealthKit.swift` if needed for cleaner serialization:

```swift
extension HKBiologicalSexObject {
    func toJson() -> [String: Any] {
        return ["value": biologicalSex.rawValue]
    }
}

// Similar for HKBloodTypeObject, etc.
```

**Tasks:**
- [ ] Evaluate if extensions are needed
- [ ] Add if they improve code organization

---

### 6. Testing

#### 6.1 Unit Tests (`test/flutter_health_kit_test.dart`)

Add tests for:
- [ ] Characteristic enum value conversions
- [ ] Characteristic.fromJson with all types
- [ ] FlutterHealthKit.queryCharacteristic method exists

```dart
test('BiologicalSex enum has correct values', () {
  expect(BiologicalSex.notSet.code, 0);
  expect(BiologicalSex.female.code, 1);
  expect(BiologicalSex.male.code, 2);
  expect(BiologicalSex.other.code, 3);
});

test('Characteristic.fromJson creates correct object for biologicalSex', () {
  final json = {
    'type': 'HKCharacteristicTypeIdentifierBiologicalSex',
    'value': 2,
  };
  final characteristic = Characteristic.fromJson(json);
  expect(characteristic.type, HKCharacteristicTypeIdentifier.biologicalSex);
  expect(characteristic.value, BiologicalSex.male);
});

// Similar for other types...
```

#### 6.2 Integration Tests

Manual testing required with iOS device/simulator:
- [ ] Query each characteristic type
- [ ] Verify correct values returned
- [ ] Test with characteristics not set (should handle gracefully)
- [ ] Test authorization flow

---

### 7. Documentation Updates

#### 7.1 Update README.md

Add section on querying characteristics:

```markdown
### Query Characteristics

Characteristics are read-once values like biological sex, blood type, date of birth:

\`\`\`dart
final biologicalSex = await FlutterHealthKit.queryCharacteristic(
  HKCharacteristicTypeIdentifier.biologicalSex,
);

if (biologicalSex.value is BiologicalSex) {
  print('Biological sex: ${biologicalSex.value}');
}
\`\`\`
```

**Tasks:**
- [ ] Add characteristic query example to README
- [ ] Update feature list to include characteristics

#### 7.2 Update CLAUDE.md

Add section on characteristics to architecture documentation:

- [ ] Add Characteristic to Core Models section
- [ ] Add queryCharacteristic to Query Types section
- [ ] Note differences from samples in Common Patterns

#### 7.3 Code Documentation

- [ ] Ensure all new classes/methods have doc comments
- [ ] Add examples in doc comments where helpful

---

### 8. Example App Update (Optional)

Consider updating `example/lib/main.dart` to demonstrate characteristic queries:

```dart
Future<void> queryCharacteristics() async {
  try {
    await FlutterHealthKit.requestAuthorization(
      read: [
        HKCharacteristicTypeIdentifier.biologicalSex,
        HKCharacteristicTypeIdentifier.dateOfBirth,
      ],
    );

    final sex = await FlutterHealthKit.queryCharacteristic(
      HKCharacteristicTypeIdentifier.biologicalSex,
    );
    debugPrint('Biological sex: ${sex.value}');

    final dob = await FlutterHealthKit.queryCharacteristic(
      HKCharacteristicTypeIdentifier.dateOfBirth,
    );
    debugPrint('Date of birth: ${dob.value}');
  } catch (e) {
    debugPrint('Error querying characteristics: $e');
  }
}
```

**Tasks:**
- [ ] Add characteristic query example to example app
- [ ] Test on device/simulator

---

## Technical Considerations

### Key Differences from Sample Implementation

1. **No time-based queries**: No predicate, sortDescriptors, or limit parameters
2. **Direct store methods**: Use `store.biologicalSex()` not query objects
3. **Single value per user**: No array of results
4. **Different return types**: Each characteristic has unique type (not HKSample)
5. **Error handling**: May throw if not set (need graceful handling)
6. **No Sample inheritance**: Characteristic is standalone, not Sample subclass

### Error Handling Strategy

- iOS will throw if characteristic not set
- Options:
  1. Let error propagate to Dart (caller handles)
  2. Return `notSet` enum value by default
  3. Return null/optional

**Recommendation**: Let error propagate, document in API that caller should handle

### Type Safety

Consider adding typed getters to Characteristic class:

```dart
BiologicalSex? get biologicalSex =>
    type == HKCharacteristicTypeIdentifier.biologicalSex && value is BiologicalSex
    ? value
    : null;

BloodType? get bloodType =>
    type == HKCharacteristicTypeIdentifier.bloodType && value is BloodType
    ? value
    : null;

// etc.
```

This provides type-safe access without casting.

---

## Open Questions / Design Decisions

### 1. Error Handling for "Not Set" Characteristics

**Question**: What should happen when a characteristic is not set?

**Options**:
- A. Throw PlatformException (current iOS behavior)
- B. Return Characteristic with `notSet` enum value
- C. Return null from queryCharacteristic

**Recommendation**: Option A (throw) - most explicit, caller can catch and handle

### 2. Generic queryCharacteristic vs Type-Specific Methods

**Question**: Should we have one generic method or specific methods per type?

**Current approach**:
```dart
Future<Characteristic> queryCharacteristic(HKCharacteristicTypeIdentifier type)
```

**Alternative**:
```dart
Future<BiologicalSex> queryBiologicalSex()
Future<BloodType> queryBloodType()
// etc.
```

**Recommendation**: Keep generic for consistency with existing API patterns

### 3. Caching Strategy

**Question**: Should characteristics be cached since they rarely change?

**Options**:
- A. No caching (query each time)
- B. Simple in-memory cache
- C. Let caller implement caching

**Recommendation**: Option C (no caching) - keep plugin simple, let apps cache if needed

---

## Implementation Checklist

### Phase 1: Dart Models & Types
- [ ] Add BiologicalSex enum to lib/models.dart
- [ ] Add BloodType enum to lib/models.dart
- [ ] Add FitzpatrickSkinType enum to lib/models.dart
- [ ] Add WheelchairUse enum to lib/models.dart
- [ ] Add ActivityMoveMode enum to lib/models.dart
- [ ] Add Characteristic class to lib/models.dart
- [ ] Run `flutter analyze` - verify no errors

### Phase 2: Dart API
- [ ] Add queryCharacteristic to lib/flutter_health_kit.dart
- [ ] Add Characteristic mapper to FlutterHealthKit.mappers
- [ ] Add abstract method to lib/flutter_health_kit_platform_interface.dart
- [ ] Implement method in lib/flutter_health_kit_method_channel.dart
- [ ] Run `flutter analyze` - verify no errors

### Phase 3: iOS Implementation
- [ ] Add "queryCharacteristic" case to FlutterHealthKitPlugin.swift handle method
- [ ] Implement queryCharacteristic method in FlutterHealthKitPlugin.swift
- [ ] Handle biologicalSex
- [ ] Handle bloodType
- [ ] Handle dateOfBirth (DateComponents → timestamp)
- [ ] Handle fitzpatrickSkinType
- [ ] Handle wheelchairUse
- [ ] Handle activityMoveMode
- [ ] Test compilation with `flutter build ios --no-codesign`

### Phase 4: Testing
- [ ] Add unit tests for enums (value conversions)
- [ ] Add unit tests for Characteristic.fromJson
- [ ] Manual test on iOS device/simulator
- [ ] Test with set characteristics
- [ ] Test with unset characteristics (error handling)
- [ ] Test authorization flow

### Phase 5: Documentation
- [ ] Update README.md with characteristic query example
- [ ] Update CLAUDE.md architecture section
- [ ] Add/verify doc comments on all new code
- [ ] Update example app (optional)

### Phase 6: Review & Polish
- [ ] Run `flutter analyze` - confirm no issues
- [ ] Run `flutter test` - confirm all tests pass
- [ ] Review code for consistency with existing patterns
- [ ] Check that error messages are helpful
- [ ] Verify enum raw values match Apple's HKHealthKit values

---

## References

- [Apple HealthKit Characteristics Documentation](https://developer.apple.com/documentation/healthkit/hkcharacteristictypeidentifier)
- [HKHealthStore Characteristic Methods](https://developer.apple.com/documentation/healthkit/hkhealthstore)
- Existing implementation: lib/flutter_health_kit.dart (Sample query pattern)
- Type definitions: lib/types.dart:279-291

---

## Notes

- Remember to test on actual iOS device/simulator with HealthKit data
- Some characteristics require specific entitlements or iOS versions
- The `dateOfBirth` characteristic requires special handling (DateComponents vs timestamp)
- Always request authorization before querying characteristics
- Consider privacy implications - characteristics are sensitive personal data
