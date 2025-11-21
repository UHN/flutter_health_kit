import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_health_kit/flutter_health_kit.dart';
import 'package:flutter_health_kit/flutter_health_kit_platform_interface.dart';
import 'package:flutter_health_kit/flutter_health_kit_method_channel.dart';
import 'package:flutter_health_kit/models.dart';
import 'package:flutter_health_kit/types.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFlutterHealthKitPlatform
    with MockPlatformInterfaceMixin
    implements FlutterHealthKitPlatform {
  @override
  Future<bool> requestAuthorization({
    List<String>? toShare,
    List<String>? read,
  }) async =>
      true;

  @override
  noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}

void main() {
  final initialPlatform = FlutterHealthKitPlatform.instance;

  test('$MethodChannelFlutterHealthKit is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelFlutterHealthKit>());
  });

  test('requestAuthorization', () async {
    final fakePlatform = MockFlutterHealthKitPlatform();
    FlutterHealthKitPlatform.instance = fakePlatform;

    expect(await FlutterHealthKit.requestAuthorization(), true);
  });

  group('BiologicalSex enum', () {
    test('has correct code values', () {
      expect(BiologicalSex.notSet.code, 0);
      expect(BiologicalSex.female.code, 1);
      expect(BiologicalSex.male.code, 2);
      expect(BiologicalSex.other.code, 3);
    });

    test('fromCode returns correct enum value', () {
      expect(BiologicalSex.fromCode(0), BiologicalSex.notSet);
      expect(BiologicalSex.fromCode(1), BiologicalSex.female);
      expect(BiologicalSex.fromCode(2), BiologicalSex.male);
      expect(BiologicalSex.fromCode(3), BiologicalSex.other);
    });
  });

  group('BloodType enum', () {
    test('has correct code values', () {
      expect(BloodType.notSet.code, 0);
      expect(BloodType.aPositive.code, 1);
      expect(BloodType.aNegative.code, 2);
      expect(BloodType.bPositive.code, 3);
      expect(BloodType.bNegative.code, 4);
      expect(BloodType.abPositive.code, 5);
      expect(BloodType.abNegative.code, 6);
      expect(BloodType.oPositive.code, 7);
      expect(BloodType.oNegative.code, 8);
    });

    test('fromCode returns correct enum value', () {
      expect(BloodType.fromCode(0), BloodType.notSet);
      expect(BloodType.fromCode(1), BloodType.aPositive);
      expect(BloodType.fromCode(2), BloodType.aNegative);
      expect(BloodType.fromCode(3), BloodType.bPositive);
      expect(BloodType.fromCode(4), BloodType.bNegative);
      expect(BloodType.fromCode(5), BloodType.abPositive);
      expect(BloodType.fromCode(6), BloodType.abNegative);
      expect(BloodType.fromCode(7), BloodType.oPositive);
      expect(BloodType.fromCode(8), BloodType.oNegative);
    });
  });

  group('FitzpatrickSkinType enum', () {
    test('has correct code values', () {
      expect(FitzpatrickSkinType.notSet.code, 0);
      expect(FitzpatrickSkinType.I.code, 1);
      expect(FitzpatrickSkinType.II.code, 2);
      expect(FitzpatrickSkinType.III.code, 3);
      expect(FitzpatrickSkinType.IV.code, 4);
      expect(FitzpatrickSkinType.V.code, 5);
      expect(FitzpatrickSkinType.VI.code, 6);
    });

    test('fromCode returns correct enum value', () {
      expect(FitzpatrickSkinType.fromCode(0), FitzpatrickSkinType.notSet);
      expect(FitzpatrickSkinType.fromCode(1), FitzpatrickSkinType.I);
      expect(FitzpatrickSkinType.fromCode(2), FitzpatrickSkinType.II);
      expect(FitzpatrickSkinType.fromCode(3), FitzpatrickSkinType.III);
      expect(FitzpatrickSkinType.fromCode(4), FitzpatrickSkinType.IV);
      expect(FitzpatrickSkinType.fromCode(5), FitzpatrickSkinType.V);
      expect(FitzpatrickSkinType.fromCode(6), FitzpatrickSkinType.VI);
    });
  });

  group('WheelchairUse enum', () {
    test('has correct code values', () {
      expect(WheelchairUse.notSet.code, 0);
      expect(WheelchairUse.no.code, 1);
      expect(WheelchairUse.yes.code, 2);
    });

    test('fromCode returns correct enum value', () {
      expect(WheelchairUse.fromCode(0), WheelchairUse.notSet);
      expect(WheelchairUse.fromCode(1), WheelchairUse.no);
      expect(WheelchairUse.fromCode(2), WheelchairUse.yes);
    });
  });

  group('ActivityMoveMode enum', () {
    test('has correct code values', () {
      expect(ActivityMoveMode.activeEnergy.code, 1);
      expect(ActivityMoveMode.appleMoveTime.code, 2);
    });

    test('fromCode returns correct enum value', () {
      expect(ActivityMoveMode.fromCode(1), ActivityMoveMode.activeEnergy);
      expect(ActivityMoveMode.fromCode(2), ActivityMoveMode.appleMoveTime);
    });
  });

  group('Characteristic', () {
    test('fromJson creates correct Characteristic for biologicalSex', () {
      final json = {
        'type': 'HKCharacteristicTypeIdentifierBiologicalSex',
        'value': 2,
      };
      final characteristic = Characteristic.fromJson(json);

      expect(
        characteristic.type,
        HKCharacteristicTypeIdentifier.biologicalSex,
      );
      expect(characteristic.value, BiologicalSex.male);
      expect(characteristic.biologicalSex, BiologicalSex.male);
      expect(characteristic.bloodType, isNull);
    });

    test('fromJson creates correct Characteristic for bloodType', () {
      final json = {
        'type': 'HKCharacteristicTypeIdentifierBloodType',
        'value': 7,
      };
      final characteristic = Characteristic.fromJson(json);

      expect(characteristic.type, HKCharacteristicTypeIdentifier.bloodType);
      expect(characteristic.value, BloodType.oPositive);
      expect(characteristic.bloodType, BloodType.oPositive);
      expect(characteristic.biologicalSex, isNull);
    });

    test('fromJson creates correct Characteristic for dateOfBirth', () {
      final timestamp = DateTime(1990, 1, 15).millisecondsSinceEpoch / 1000;
      final json = {
        'type': 'HKCharacteristicTypeIdentifierDateOfBirth',
        'value': timestamp,
      };
      final characteristic = Characteristic.fromJson(json);

      expect(
        characteristic.type,
        HKCharacteristicTypeIdentifier.dateOfBirth,
      );
      expect(characteristic.value, isA<DateTime>());
      expect(characteristic.dateOfBirth, isNotNull);
      expect(characteristic.dateOfBirth?.year, 1990);
      expect(characteristic.dateOfBirth?.month, 1);
      expect(characteristic.dateOfBirth?.day, 15);
    });

    test('fromJson creates correct Characteristic for fitzpatrickSkinType', () {
      final json = {
        'type': 'HKCharacteristicTypeIdentifierFitzpatrickSkinType',
        'value': 3,
      };
      final characteristic = Characteristic.fromJson(json);

      expect(
        characteristic.type,
        HKCharacteristicTypeIdentifier.fitzpatrickSkinType,
      );
      expect(characteristic.value, FitzpatrickSkinType.III);
      expect(characteristic.fitzpatrickSkinType, FitzpatrickSkinType.III);
      expect(characteristic.biologicalSex, isNull);
    });

    test('fromJson creates correct Characteristic for wheelchairUse', () {
      final json = {
        'type': 'HKCharacteristicTypeIdentifierWheelchairUse',
        'value': 2,
      };
      final characteristic = Characteristic.fromJson(json);

      expect(
        characteristic.type,
        HKCharacteristicTypeIdentifier.wheelchairUse,
      );
      expect(characteristic.value, WheelchairUse.yes);
      expect(characteristic.wheelchairUse, WheelchairUse.yes);
      expect(characteristic.biologicalSex, isNull);
    });

    test('fromJson creates correct Characteristic for activityMoveMode', () {
      final json = {
        'type': 'HKCharacteristicTypeIdentifierActivityMoveMode',
        'value': 1,
      };
      final characteristic = Characteristic.fromJson(json);

      expect(
        characteristic.type,
        HKCharacteristicTypeIdentifier.activityMoveMode,
      );
      expect(characteristic.value, ActivityMoveMode.activeEnergy);
      expect(characteristic.activityMoveMode, ActivityMoveMode.activeEnergy);
      expect(characteristic.biologicalSex, isNull);
    });

    test('typed getters return null for wrong type', () {
      final json = {
        'type': 'HKCharacteristicTypeIdentifierBiologicalSex',
        'value': 1,
      };
      final characteristic = Characteristic.fromJson(json);

      expect(characteristic.biologicalSex, BiologicalSex.female);
      expect(characteristic.bloodType, isNull);
      expect(characteristic.dateOfBirth, isNull);
      expect(characteristic.fitzpatrickSkinType, isNull);
      expect(characteristic.wheelchairUse, isNull);
      expect(characteristic.activityMoveMode, isNull);
    });
  });
}
