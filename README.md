# flutter_health_kit

This plugin allows Flutter apps to read and subscribe to changes in the Apple HealthKit store.

## Getting Started

Request authorization to read data from the HealthKit store:

```dart
bool isAuthorized = await FlutterHealthKit.requestAuthorization(
read: [HKSampleTypeIdentifier.workout]);
```

Read sample data from the HealthKit store:

```dart
final workouts = await FlutterHealthKit.querySampleType<Workout>(HKSampleTypeIdentifier.workout);
```

## Querying Characteristics

Characteristics are read-once values like biological sex, blood type, and date of birth. Unlike samples, they don't have time ranges or multiple instances:

```dart
// Request authorization for characteristics
await FlutterHealthKit.requestAuthorization(
  read: [
    HKCharacteristicTypeIdentifier.biologicalSex,
    HKCharacteristicTypeIdentifier.bloodType,
    HKCharacteristicTypeIdentifier.dateOfBirth,
  ],
);

// Query biological sex
final sexCharacteristic = await FlutterHealthKit.queryCharacteristic(
  HKCharacteristicTypeIdentifier.biologicalSex,
);
print('Biological sex: ${sexCharacteristic.biologicalSex}'); // BiologicalSex.male, etc.

// Query blood type
final bloodTypeCharacteristic = await FlutterHealthKit.queryCharacteristic(
  HKCharacteristicTypeIdentifier.bloodType,
);
print('Blood type: ${bloodTypeCharacteristic.bloodType}'); // BloodType.oPositive, etc.

// Query date of birth
final dobCharacteristic = await FlutterHealthKit.queryCharacteristic(
  HKCharacteristicTypeIdentifier.dateOfBirth,
);
print('Date of birth: ${dobCharacteristic.dateOfBirth}'); // DateTime object
```

### Available Characteristics

- `biologicalSex` - BiologicalSex (notSet, female, male, other)
- `bloodType` - BloodType (notSet, aPositive, aNegative, bPositive, bNegative, abPositive, abNegative, oPositive, oNegative)
- `dateOfBirth` - DateTime
- `fitzpatrickSkinType` - FitzpatrickSkinType (notSet, I, II, III, IV, V, VI)
- `wheelchairUse` - WheelchairUse (notSet, no, yes)
- `activityMoveMode` - ActivityMoveMode (activeEnergy, appleMoveTime)


