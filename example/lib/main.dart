import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_health_kit/flutter_health_kit.dart';
import 'package:flutter_health_kit/models.dart';
import 'package:flutter_health_kit/predicate.dart';
import 'package:flutter_health_kit/types.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HealthKit Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HealthDataScreen(),
    );
  }
}

class HealthDataScreen extends StatefulWidget {
  const HealthDataScreen({super.key});

  @override
  State<HealthDataScreen> createState() => _HealthDataScreenState();
}

class _HealthDataScreenState extends State<HealthDataScreen> {
  bool _isAuthorized = false;
  bool _isLoading = false;
  String? _error;

  // Characteristic data
  List<Characteristic> _characteristics = [];

  // Heart rate data
  Quantity? _latestHeartRate;

  // Workout data
  Workout? _latestWorkout;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _requestAuthorization() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authorized = await FlutterHealthKit.requestAuthorization(
        read: [
          // Characteristic types
          HKCharacteristicTypeIdentifier.biologicalSex,
          HKCharacteristicTypeIdentifier.bloodType,
          HKCharacteristicTypeIdentifier.dateOfBirth,
          HKCharacteristicTypeIdentifier.fitzpatrickSkinType,
          HKCharacteristicTypeIdentifier.wheelchairUse,
          HKCharacteristicTypeIdentifier.activityMoveMode,
          // Quantity types
          HKQuantityTypeIdentifier.heartRate,
          // Sample types
          HKSampleTypeIdentifier.workout,
        ],
      );

      setState(() {
        _isAuthorized = authorized;
      });

      if (authorized) {
        await _loadHealthData();
      }
    } on PlatformException catch (e) {
      setState(() {
        _error = 'Failed to authorize: ${e.message}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadHealthData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load all characteristics
      final characteristicTypes = [
        HKCharacteristicTypeIdentifier.biologicalSex,
        HKCharacteristicTypeIdentifier.bloodType,
        HKCharacteristicTypeIdentifier.dateOfBirth,
        HKCharacteristicTypeIdentifier.fitzpatrickSkinType,
        HKCharacteristicTypeIdentifier.wheelchairUse,
        HKCharacteristicTypeIdentifier.activityMoveMode,
      ];

      final characteristics = <Characteristic>[];
      for (final type in characteristicTypes) {
        try {
          final characteristic =
              await FlutterHealthKit.queryCharacteristic(type);
          characteristics.add(characteristic);
        } catch (e) {
          // Some characteristics may not be available
          debugPrint('Failed to load $type: $e');
        }
      }

      // Load most recent heart rate
      final heartRates = await FlutterHealthKit.querySampleType<Quantity>(
        HKQuantityTypeIdentifier.heartRate,
        limit: 1,
        predicate: Predicate.predicateForSamples(
          withStart: DateTime.now().subtract(const Duration(days: 30)),
          end: DateTime.now(),
        ),
      );

      // Load most recent workout
      final workouts = await FlutterHealthKit.querySampleType<Workout>(
        HKSampleTypeIdentifier.workout,
        limit: 1,
        predicate: Predicate.predicateForSamples(
          withStart: DateTime.now().subtract(const Duration(days: 30)),
          end: DateTime.now(),
        ),
      );

      setState(() {
        _characteristics = characteristics;
        _latestHeartRate = heartRates.isNotEmpty ? heartRates.first : null;
        _latestWorkout = workouts.isNotEmpty ? workouts.first : null;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load health data: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HealthKit Example'),
        elevation: 2,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : !_isAuthorized
              ? _buildAuthorizationView()
              : _buildHealthDataView(),
    );
  }

  Widget _buildAuthorizationView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.favorite,
              size: 80,
              color: Colors.red,
            ),
            const SizedBox(height: 24),
            const Text(
              'HealthKit Access Required',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'This app needs permission to access your health data to display:\n\n'
              '• Biological characteristics (sex, blood type, etc.)\n'
              '• Heart rate data\n'
              '• Workout information',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _error!,
                  style: TextStyle(color: Colors.red.shade900),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
            ],
            ElevatedButton.icon(
              onPressed: _requestAuthorization,
              icon: const Icon(Icons.lock_open),
              label: const Text('Request Authorization'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthDataView() {
    return RefreshIndicator(
      onRefresh: _loadHealthData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _error!,
                style: TextStyle(color: Colors.red.shade900),
              ),
            ),
          ],
          _buildCharacteristicsCard(),
          const SizedBox(height: 16),
          _buildHeartRateCard(),
          const SizedBox(height: 16),
          _buildWorkoutCard(),
        ],
      ),
    );
  }

  Widget _buildCharacteristicsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.person, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Characteristics',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            if (_characteristics.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'No characteristic data available',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                  ),
                ),
              )
            else
              ..._characteristics.map((char) => _buildCharacteristicRow(char)),
          ],
        ),
      ),
    );
  }

  Widget _buildCharacteristicRow(Characteristic char) {
    String label;
    String value;

    switch (char.type) {
      case HKCharacteristicTypeIdentifier.biologicalSex:
        label = 'Biological Sex';
        value = char.biologicalSex?.displayName ?? 'Unknown';
        break;
      case HKCharacteristicTypeIdentifier.bloodType:
        label = 'Blood Type';
        value = char.bloodType?.displayName ?? 'Unknown';
        break;
      case HKCharacteristicTypeIdentifier.dateOfBirth:
        label = 'Date of Birth';
        if (char.dateOfBirth != null) {
          value = DateFormat.yMMMd().format(char.dateOfBirth!);
          final age = DateTime.now().year - char.dateOfBirth!.year;
          value += ' (Age: $age)';
        } else {
          value = 'Unknown';
        }
        break;
      case HKCharacteristicTypeIdentifier.fitzpatrickSkinType:
        label = 'Fitzpatrick Skin Type';
        value = char.fitzpatrickSkinType?.displayName ?? 'Unknown';
        break;
      case HKCharacteristicTypeIdentifier.wheelchairUse:
        label = 'Wheelchair Use';
        value = char.wheelchairUse?.displayName ?? 'Unknown';
        break;
      case HKCharacteristicTypeIdentifier.activityMoveMode:
        label = 'Activity Move Mode';
        value = char.activityMoveMode?.displayName ?? 'Unknown';
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeartRateCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.favorite, color: Colors.red),
                SizedBox(width: 8),
                Text(
                  'Latest Heart Rate',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            if (_latestHeartRate == null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'No heart rate data available',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                  ),
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Heart Rate',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        '${_latestHeartRate!.values['count']?.toInt() ?? 'N/A'} BPM',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Recorded: ${DateFormat.yMMMd().add_jm().format(_latestHeartRate!.start)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Source: ${_latestHeartRate!.sourceRevision.source.name}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.fitness_center, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'Latest Workout',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            if (_latestWorkout == null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'No workout data available',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                  ),
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _latestWorkout!.workoutActivityType.displayName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Icon(
                        _getWorkoutIcon(_latestWorkout!.workoutActivityType),
                        color: Colors.green,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildWorkoutDetailRow(
                    'Duration',
                    _formatDuration(_latestWorkout!.duration.inSeconds.toDouble()),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Date: ${DateFormat.yMMMd().add_jm().format(_latestWorkout!.start)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Source: ${_latestWorkout!.sourceRevision.source.name}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.black87),
          ),
        ],
      ),
    );
  }

  IconData _getWorkoutIcon(WorkoutActivityType type) {
    switch (type) {
      case WorkoutActivityType.running:
        return Icons.directions_run;
      case WorkoutActivityType.cycling:
        return Icons.directions_bike;
      case WorkoutActivityType.swimming:
        return Icons.pool;
      case WorkoutActivityType.walking:
        return Icons.directions_walk;
      case WorkoutActivityType.yoga:
        return Icons.self_improvement;
      case WorkoutActivityType.hiking:
        return Icons.hiking;
      default:
        return Icons.fitness_center;
    }
  }

  String _formatDuration(double seconds) {
    final duration = Duration(seconds: seconds.toInt());
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final secs = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m ${secs}s';
    } else if (minutes > 0) {
      return '${minutes}m ${secs}s';
    } else {
      return '${secs}s';
    }
  }
}

// Extension to add display names to enums
extension BiologicalSexExtension on BiologicalSex {
  String get displayName {
    switch (this) {
      case BiologicalSex.notSet:
        return 'Not Set';
      case BiologicalSex.female:
        return 'Female';
      case BiologicalSex.male:
        return 'Male';
      case BiologicalSex.other:
        return 'Other';
    }
  }
}

extension BloodTypeExtension on BloodType {
  String get displayName {
    switch (this) {
      case BloodType.notSet:
        return 'Not Set';
      case BloodType.aPositive:
        return 'A+';
      case BloodType.aNegative:
        return 'A-';
      case BloodType.bPositive:
        return 'B+';
      case BloodType.bNegative:
        return 'B-';
      case BloodType.abPositive:
        return 'AB+';
      case BloodType.abNegative:
        return 'AB-';
      case BloodType.oPositive:
        return 'O+';
      case BloodType.oNegative:
        return 'O-';
    }
  }
}

extension FitzpatrickSkinTypeExtension on FitzpatrickSkinType {
  String get displayName {
    switch (this) {
      case FitzpatrickSkinType.notSet:
        return 'Not Set';
      // ignore: constant_identifier_names
      case FitzpatrickSkinType.I:
        return 'Type I';
      // ignore: constant_identifier_names
      case FitzpatrickSkinType.II:
        return 'Type II';
      // ignore: constant_identifier_names
      case FitzpatrickSkinType.III:
        return 'Type III';
      // ignore: constant_identifier_names
      case FitzpatrickSkinType.IV:
        return 'Type IV';
      // ignore: constant_identifier_names
      case FitzpatrickSkinType.V:
        return 'Type V';
      // ignore: constant_identifier_names
      case FitzpatrickSkinType.VI:
        return 'Type VI';
    }
  }
}

extension WheelchairUseExtension on WheelchairUse {
  String get displayName {
    switch (this) {
      case WheelchairUse.notSet:
        return 'Not Set';
      case WheelchairUse.no:
        return 'No';
      case WheelchairUse.yes:
        return 'Yes';
    }
  }
}

extension ActivityMoveModeExtension on ActivityMoveMode {
  String get displayName {
    switch (this) {
      case ActivityMoveMode.activeEnergy:
        return 'Active Energy';
      case ActivityMoveMode.appleMoveTime:
        return 'Apple Move Time';
    }
  }
}

extension WorkoutActivityTypeExtension on WorkoutActivityType {
  String get displayName {
    final name = toString().split('.').last;
    return name
        .replaceAllMapped(
          RegExp(r'([A-Z])'),
          (match) => ' ${match.group(0)}',
        )
        .trim()
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}
