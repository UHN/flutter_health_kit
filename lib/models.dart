import 'package:collection/collection.dart';

import 'types.dart';

/// A sample of data collected by HealthKit.
abstract class Sample {
  Sample({
    required this.uuid,
    required this.start,
    required this.end,
    required this.sourceRevision,
    required this.device,
    required this.metadata,
    required this.type,
  });

  /// The unique identifier of the sample.
  final String uuid;

  /// The start date of the sample.
  final DateTime start;

  /// The end date of the sample.
  final DateTime end;

  /// The source revision of the sample.
  final SourceRevision sourceRevision;

  /// The device that collected the sample.
  final Device? device;

  /// Additional metadata for the sample.
  final Map<String, dynamic>? metadata;

  /// The type of the sample.
  final SampleTypeId type;
}

class WorkoutEvent {
  factory WorkoutEvent.fromJson(Map<String, dynamic> json) => WorkoutEvent(
        type: WorkoutEventType.values.firstWhere((e) => e.code == json['type']),
        start: DateTime.fromMillisecondsSinceEpoch(
          ((json['interval']['startTimestamp'] as double) * 1000).toInt(),
        ),
        end: DateTime.fromMillisecondsSinceEpoch(
          ((json['interval']['endTimestamp'] as double) * 1000).toInt(),
        ),
        duration:
            Duration(seconds: (json['interval']['duration'] as double).toInt()),
        metadata: json['metadata'] != null ? Map.from(json['metadata']) : null,
      );

  WorkoutEvent({
    required this.type,
    required this.start,
    required this.end,
    required this.metadata,
    this.duration,
  });

  final WorkoutEventType type;
  final DateTime start;
  final DateTime end;
  final Duration? duration;
  final Map<String, dynamic>? metadata;
}

class Statistic {
  factory Statistic.fromJson(Map<String, dynamic> json) => Statistic(
        unit: json['unit'],
        average: json['average'],
        total: json['total'],
        maximum: json['maximum'],
        minimum: json['minimum'],
      );

  Statistic({
    required this.unit,
    this.average,
    this.total,
    this.maximum,
    this.minimum,
  });

  final double? average;
  final double? total;
  final double? maximum;
  final double? minimum;
  final String unit;
}

/// A workout sample.
class Workout extends Sample {
  factory Workout.fromJson(Map<String, dynamic> json) {
    return Workout(
      uuid: json['uuid'] as String,
      start: DateTime.fromMillisecondsSinceEpoch(
        ((json['startTimestamp'] as double) * 1000).toInt(),
      ),
      end: DateTime.fromMillisecondsSinceEpoch(
        ((json['endTimestamp'] as double) * 1000).toInt(),
      ),
      sourceRevision: SourceRevision.fromJson(Map.from(json['sourceRevision'])),
      device: json['device'] != null
          ? Device.fromJson(Map.from(json['device']))
          : null,
      workoutActivityType: WorkoutActivityType.values.firstWhereOrNull(
            (e) => e.code == json['workoutActivityType'],
          ) ??
          WorkoutActivityType.other,
      metadata: json['metadata'] != null ? Map.from(json['metadata']) : null,
      duration: Duration(seconds: (json['duration'] as double).toInt()),
    );
  }

  Workout({
    required super.uuid,
    required super.start,
    required super.end,
    required super.sourceRevision,
    required this.workoutActivityType,
    required this.duration,
    super.metadata,
    super.device,
    super.type = HKSampleTypeIdentifier.workout,
  });

  /// The type of workout.
  final WorkoutActivityType workoutActivityType;

  /// The duration of the workout.
  final Duration duration;
}

/// A quantity sample.
class Quantity extends Sample {
  factory Quantity.fromJson(Map<String, dynamic> json) => Quantity(
        uuid: json['uuid'] as String,
        start: DateTime.fromMillisecondsSinceEpoch(
          ((json['startTimestamp'] as double) * 1000).toInt(),
        ),
        end: DateTime.fromMillisecondsSinceEpoch(
          ((json['endTimestamp'] as double) * 1000).toInt(),
        ),
        sourceRevision:
            SourceRevision.fromJson(Map.from(json['sourceRevision'])),
        device: json['device'] != null
            ? Device.fromJson(Map.from(json['device']))
            : null,
        metadata: json['metadata'] != null ? Map.from(json['metadata']) : null,
        type: HKQuantityTypeIdentifier.values.firstWhere(
          (e) => e.identifier == json['quantityType'],
        ),
        count: json['count'] as int,
        values: Map.from(json['values']),
      );

  Quantity({
    required super.uuid,
    required super.start,
    required super.end,
    required super.sourceRevision,
    required super.type,
    required this.count,
    required this.values,
    super.metadata,
    super.device,
  });

  /// The type of quantity.
  HKQuantityTypeIdentifier get quantityType => type as HKQuantityTypeIdentifier;

  /// The number of values.
  final int count;

  /// The values of the quantity.
  final Map<String, double> values;
}

/// An electrocardiogram sample.
class Electrocardiogram extends Sample {
  factory Electrocardiogram.fromJson(Map<String, dynamic> json) =>
      Electrocardiogram(
        uuid: json['uuid'] as String,
        start: DateTime.fromMillisecondsSinceEpoch(
          ((json['startTimestamp'] as double) * 1000).toInt(),
        ),
        end: DateTime.fromMillisecondsSinceEpoch(
          ((json['endTimestamp'] as double) * 1000).toInt(),
        ),
        sourceRevision:
            SourceRevision.fromJson(Map.from(json['sourceRevision'])),
        device: json['device'] != null
            ? Device.fromJson(Map.from(json['device']))
            : null,
        metadata: json['metadata'] != null ? Map.from(json['metadata']) : null,
        symptomsStatus: SymptomsStatus.values.firstWhere(
          (e) => e.code == json['symptomsStatus'],
        ),
        classification: Classification.values.firstWhere(
          (e) => e.code == json['classification'],
        ),
        numberOfVoltageMeasurements: json['numberOfVoltageMeasurements'] as int,
        averageHeartRate: json['averageHeartRate'] != null
            ? Map.from(json['averageHeartRate'])
            : null,
        samplingFrequency: json['samplingFrequency'] != null
            ? Map.from(json['samplingFrequency'])
            : null,
      );

  Electrocardiogram({
    required super.uuid,
    required super.start,
    required super.end,
    required super.sourceRevision,
    required this.numberOfVoltageMeasurements,
    required this.symptomsStatus,
    required this.classification,
    this.averageHeartRate,
    this.samplingFrequency,
    super.metadata,
    super.device,
    super.type = HKSampleTypeIdentifier.dataElectrocardiogram,
  });

  /// The number of voltage measurements.
  final int numberOfVoltageMeasurements;

  /// The symptoms status.
  final SymptomsStatus symptomsStatus;

  /// The classification of the electrocardiogram.
  final Classification classification;

  /// The average heart rate.
  final Map<String, double>? averageHeartRate;

  /// The sampling frequency.
  final Map<String, double>? samplingFrequency;
}

class VoltageMeasurement {
  factory VoltageMeasurement.fromJson(Map<String, dynamic> json) =>
      VoltageMeasurement(
        timeSinceSampleStart: Duration(
          milliseconds:
              ((json['timeSinceSampleStart'] as double) * 1000).toInt(),
        ),
        values: Map.from(json['values']),
      );

  VoltageMeasurement({
    required this.timeSinceSampleStart,
    required this.values,
  });

  final Duration timeSinceSampleStart;
  final Map<String, double> values;
}

/// A correlation sample.
class Correlation extends Sample {
  factory Correlation.fromJson(Map<String, dynamic> json) {
    return Correlation(
      uuid: json['uuid'] as String,
      start: DateTime.fromMillisecondsSinceEpoch(
        ((json['startTimestamp'] as double) * 1000).toInt(),
      ),
      end: DateTime.fromMillisecondsSinceEpoch(
        ((json['endTimestamp'] as double) * 1000).toInt(),
      ),
      type: HKCorrelationTypeIdentifier.values.firstWhere(
        (e) => e.identifier == json['correlationType'],
      ),
      sourceRevision: SourceRevision.fromJson(Map.from(json['sourceRevision'])),
      device: json['device'] != null
          ? Device.fromJson(Map.from(json['device']))
          : null,
      objects: (json['objects'] as List)
          .map((e) => Quantity.fromJson(Map.from(e)))
          .toList(),
      metadata: json['metadata'] != null ? Map.from(json['metadata']) : null,
    );
  }

  Correlation({
    required super.uuid,
    required super.start,
    required super.end,
    required super.sourceRevision,
    required this.objects,
    required super.type,
    super.metadata,
    super.device,
  });

  /// The type of correlation.
  final List<Quantity> objects;

  /// The objects of the correlation.
  HKCorrelationTypeIdentifier get correlationType =>
      type as HKCorrelationTypeIdentifier;
}

/// A category sample.
class Category extends Sample {
  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      uuid: json['uuid'] as String,
      start: DateTime.fromMillisecondsSinceEpoch(
        ((json['startTimestamp'] as double) * 1000).toInt(),
      ),
      end: DateTime.fromMillisecondsSinceEpoch(
        ((json['endTimestamp'] as double) * 1000).toInt(),
      ),
      type: HKCategoryTypeIdentifier.values.firstWhere(
        (e) => e.identifier == json['categoryType'],
      ),
      sourceRevision: SourceRevision.fromJson(Map.from(json['sourceRevision'])),
      device: json['device'] != null
          ? Device.fromJson(Map.from(json['device']))
          : null,
      value: json['value'] as int,
      metadata: json['metadata'] != null ? Map.from(json['metadata']) : null,
    );
  }

  Category({
    required super.uuid,
    required super.start,
    required super.end,
    required super.sourceRevision,
    required this.value,
    required super.type,
    super.metadata,
    super.device,
  });

  /// The value of category.
  final int value;

  /// The type of category.
  HKCategoryTypeIdentifier get categoryType => type as HKCategoryTypeIdentifier;
}

/// A source revision.
class SourceRevision {
  factory SourceRevision.fromJson(Map<String, dynamic> json) => SourceRevision(
        source: Source.fromJson(Map.from(json['source'])),
        version: json['version'],
        productType: json['productType'],
        operatingSystemVersion: OperatingSystemVersion.fromJson(
          Map.from(json['operatingSystemVersion']),
        ),
      );

  const SourceRevision({
    required this.source,
    required this.operatingSystemVersion,
    this.version,
    this.productType,
  });

  /// The source of the revision.
  final Source source;

  /// The version of the revision.
  final String? version;

  /// The product type of the revision.
  final String? productType;

  /// The operating system version of the revision.
  final OperatingSystemVersion operatingSystemVersion;

  /// The system version of the revision.
  String get systemVersion =>
      '${operatingSystemVersion.majorVersion}.${operatingSystemVersion.minorVersion}.${operatingSystemVersion.patchVersion}';

  Map<String, dynamic> toJson() => {
        'source': source.toJson(),
        'version': version,
        'productType': productType,
        'systemVersion': systemVersion,
        'operatingSystemVersion': operatingSystemVersion.toJson(),
      };
}

/// A device.
class Device {
  factory Device.fromJson(Map<String, dynamic> json) => Device(
        name: json['name'],
        manufacturer: json['manufacturer'],
        model: json['model'],
        hardware: json['hardwareVersion'],
        software: json['softwareVersion'],
      );

  const Device({
    required this.name,
    required this.manufacturer,
    required this.model,
    required this.hardware,
    required this.software,
  });

  /// The name of the device.
  final String? name;

  /// The manufacturer of the device.
  final String? manufacturer;

  /// The model of the device.
  final String? model;

  /// The hardware version of the device.
  final String? hardware;

  /// The software version of the device.
  final String? software;

  Map<String, dynamic> toJson() => {
        'name': name,
        'manufacturer': manufacturer,
        'model': model,
        'hardwareVersion': hardware,
        'softwareVersion': software,
      };
}

/// A source.
class Source {
  factory Source.fromJson(Map<String, dynamic> json) => Source(
        name: json['name'],
        bundleIdentifier: json['bundleIdentifier'],
      );

  const Source({
    required this.name,
    required this.bundleIdentifier,
  });

  /// The name of the source.
  final String name;

  /// The bundle identifier of the source.
  final String bundleIdentifier;

  Map<String, dynamic> toJson() => {
        'name': name,
        'bundleIdentifier': bundleIdentifier,
      };
}

/// An operating system version.
class OperatingSystemVersion {
  factory OperatingSystemVersion.fromJson(Map<String, dynamic> json) =>
      OperatingSystemVersion(
        majorVersion: json['majorVersion'],
        minorVersion: json['minorVersion'],
        patchVersion: json['patchVersion'],
      );

  const OperatingSystemVersion({
    required this.majorVersion,
    required this.minorVersion,
    required this.patchVersion,
  });

  /// The major version of the operating system.
  final int majorVersion;

  /// The minor version of the operating system.
  final int minorVersion;

  /// The patch version of the operating system.
  final int patchVersion;

  Map<String, dynamic> toJson() => {
        'majorVersion': majorVersion,
        'minorVersion': minorVersion,
        'patchVersion': patchVersion,
      };
}

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

  /// The type of characteristic.
  final HKCharacteristicTypeIdentifier type;

  /// The value of the characteristic.
  ///
  /// Type depends on characteristic type:
  /// - biologicalSex: [BiologicalSex]
  /// - bloodType: [BloodType]
  /// - dateOfBirth: [DateTime]
  /// - fitzpatrickSkinType: [FitzpatrickSkinType]
  /// - wheelchairUse: [WheelchairUse]
  /// - activityMoveMode: [ActivityMoveMode]
  final dynamic value;

  /// Returns the biological sex value if this characteristic is biologicalSex.
  BiologicalSex? get biologicalSex =>
      type == HKCharacteristicTypeIdentifier.biologicalSex &&
              value is BiologicalSex
          ? value as BiologicalSex
          : null;

  /// Returns the blood type value if this characteristic is bloodType.
  BloodType? get bloodType =>
      type == HKCharacteristicTypeIdentifier.bloodType && value is BloodType
          ? value as BloodType
          : null;

  /// Returns the date of birth value if this characteristic is dateOfBirth.
  DateTime? get dateOfBirth =>
      type == HKCharacteristicTypeIdentifier.dateOfBirth && value is DateTime
          ? value as DateTime
          : null;

  /// Returns the Fitzpatrick skin type value if this characteristic is fitzpatrickSkinType.
  FitzpatrickSkinType? get fitzpatrickSkinType =>
      type == HKCharacteristicTypeIdentifier.fitzpatrickSkinType &&
              value is FitzpatrickSkinType
          ? value as FitzpatrickSkinType
          : null;

  /// Returns the wheelchair use value if this characteristic is wheelchairUse.
  WheelchairUse? get wheelchairUse =>
      type == HKCharacteristicTypeIdentifier.wheelchairUse &&
              value is WheelchairUse
          ? value as WheelchairUse
          : null;

  /// Returns the activity move mode value if this characteristic is activityMoveMode.
  ActivityMoveMode? get activityMoveMode =>
      type == HKCharacteristicTypeIdentifier.activityMoveMode &&
              value is ActivityMoveMode
          ? value as ActivityMoveMode
          : null;
}

enum WorkoutEventType {
  pause._(1),
  resume._(2),
  lap._(3),
  marker._(4),
  motionPause._(5),
  motionResumed._(6),
  segment._(7),
  pauseOrResumeRequest._(8);

  const WorkoutEventType._(this.code);

  final int code;
}

/// A workout activity type.
enum WorkoutActivityType {
  americanFootball._(1),
  archery._(2),
  australianFootball._(3),
  badminton._(4),
  baseball._(5),
  basketball._(6),
  bowling._(7),
  boxing._(8),
  climbing._(9),
  cricket._(10),
  crossTraining._(11),
  curling._(12),
  cycling._(13),
  dance._(14),
  danceInspiredTraining._(15),
  elliptical._(16),
  equestrianSports._(17),
  fencing._(18),
  fishing._(19),
  functionalStrengthTraining._(20),
  golf._(21),
  gymnastics._(22),
  handball._(23),
  hiking._(24),
  hockey._(25),
  hunting._(26),
  lacrosse._(27),
  martialArts._(28),
  mindAndBody._(29),
  mixedMetabolicCardioTraining._(30),
  paddleSports._(31),
  play._(32),
  preparationAndRecovery._(33),
  racquetball._(34),
  rowing._(35),
  rugby._(36),
  running._(37),
  sailing._(38),
  skatingSports._(39),
  snowSports._(40),
  soccer._(41),
  softball._(42),
  squash._(43),
  stairClimbing._(44),
  surfingSports._(45),
  swimming._(46),
  tableTennis._(47),
  tennis._(48),
  trackAndField._(49),
  traditionalStrengthTraining._(50),
  volleyball._(51),
  walking._(52),
  waterFitness._(53),
  waterPolo._(54),
  waterSports._(55),
  wrestling._(56),
  yoga._(57),
  barre._(58),
  coreTraining._(59),
  crossCountrySkiing._(60),
  downhillSkiing._(61),
  flexibility._(62),
  highIntensityIntervalTraining._(63),
  jumpRope._(64),
  kickboxing._(65),
  pilates._(66),
  snowboarding._(67),
  stairs._(68),
  stepTraining._(69),
  wheelchairWalkPace._(70),
  wheelchairRunPace._(71),
  taiChi._(72),
  mixedCardio._(73),
  handCycling._(74),
  discSports._(75),
  fitnessGaming._(76),
  cardioDance._(77),
  socialDance._(78),
  pickleball._(79),
  cooldown._(80),
  swimBikeRun._(82),
  transition._(83),
  underwaterDiving._(84),
  other._(3000);

  const WorkoutActivityType._(this.code);

  final int code;
}

/// Update frequency for background delivery.
enum UpdateFrequency {
  immediate._(1),
  hourly._(2),
  daily._(3),
  weekly._(4);

  const UpdateFrequency._(this.code);

  final int code;
}

/// Symptoms status.
enum SymptomsStatus {
  notSet._(0),
  none._(1),
  present._(2);

  const SymptomsStatus._(this.code);

  final int code;
}

/// Classification of an electrocardiogram.
enum Classification {
  notSet._(0),
  sinusRhythm._(1),
  atrialFibrillation._(2),
  inconclusiveLowHeartRate._(3),
  inconclusiveHighHeartRate._(4),
  inconclusivePoorReading._(5),
  inconclusiveOther._(6),
  unrecognized._(100);

  const Classification._(this.code);

  final int code;
}

enum HKStatisticsOptions {
  separateBySource._(1),
  discreteAverage._(2),
  discreteMin._(4),
  discreteMax._(8),
  cumulativeSum._(16),
  mostRecent._(32),
  duration._(64);

  const HKStatisticsOptions._(this.code);

  final int code;
}

enum HKAuthorizationStatus {
  notDetermined._(0),
  sharingDenied._(1),
  sharingAuthorized._(2);

  const HKAuthorizationStatus._(this.code);

  final int code;

  static HKAuthorizationStatus fromCode(int code) =>
      HKAuthorizationStatus.values.firstWhere((e) => e.code == code);
}

/// Biological sex values for HealthKit characteristics.
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

/// Blood type values for HealthKit characteristics.
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

/// Fitzpatrick skin type values (I-VI scale) for HealthKit characteristics.
enum FitzpatrickSkinType {
  notSet._(0),
  // ignore: constant_identifier_names
  I._(1),
  // ignore: constant_identifier_names
  II._(2),
  // ignore: constant_identifier_names
  III._(3),
  // ignore: constant_identifier_names
  IV._(4),
  // ignore: constant_identifier_names
  V._(5),
  // ignore: constant_identifier_names
  VI._(6);

  const FitzpatrickSkinType._(this.code);

  final int code;

  static FitzpatrickSkinType fromCode(int code) =>
      FitzpatrickSkinType.values.firstWhere((e) => e.code == code);
}

/// Wheelchair use values for HealthKit characteristics.
enum WheelchairUse {
  notSet._(0),
  no._(1),
  yes._(2);

  const WheelchairUse._(this.code);

  final int code;

  static WheelchairUse fromCode(int code) =>
      WheelchairUse.values.firstWhere((e) => e.code == code);
}

/// Activity move mode values for HealthKit characteristics.
enum ActivityMoveMode {
  activeEnergy._(1),
  appleMoveTime._(2);

  const ActivityMoveMode._(this.code);

  final int code;

  static ActivityMoveMode fromCode(int code) =>
      ActivityMoveMode.values.firstWhere((e) => e.code == code);
}
