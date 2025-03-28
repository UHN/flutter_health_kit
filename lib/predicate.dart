import 'operator_type.dart';
import 'types.dart';

typedef PredicateDescriptor = Map<String, dynamic>;

class Predicate {
  static PredicateDescriptor predicateForSamples({
    required DateTime withStart,
    required DateTime end,
    bool? strictStartDate,
    bool? strictEndDate,
  }) =>
      {
        'code': 'predicateForSamples',
        'withStart': withStart.millisecondsSinceEpoch / 1000,
        'end': end.millisecondsSinceEpoch / 1000,
        if (strictStartDate != null) 'strictStartDate': strictStartDate,
        if (strictEndDate != null) 'strictEndDate': strictEndDate,
      };

  static PredicateDescriptor predicateForObjectsWithMetadataKey({
    required String key,
    required OperatorType operator,
    required dynamic value,
  }) =>
      {
        'code': 'predicateForObjectsWithMetadataKey',
        'key': key,
        'operatorType': operator.code,
        'value': value,
      };

  static PredicateDescriptor predicateForObjectsAssociated({
    required SampleTypeId type,
    required String uuid,
  }) =>
      {
        'code': 'predicateForObjectsAssociated',
        'sampleType': type.identifier,
        'uuid': uuid,
      };

  static PredicateDescriptor or(
    Iterable<PredicateDescriptor> predicates,
  ) =>
      {
        'code': 'or',
        'predicates': predicates.toList(),
      };

  static PredicateDescriptor and(
    Iterable<PredicateDescriptor> predicates,
  ) =>
      {
        'code': 'and',
        'predicates': predicates.toList(),
      };
}
