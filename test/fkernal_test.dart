import 'package:flutter_test/flutter_test.dart';
import 'package:fkernal/fkernal.dart';

// ignore: unused_element
class TestUser implements FKernalModel {
  final String name;

  TestUser(this.name);

  @override
  Map<String, dynamic> toJson() => {'name': name};

  @override
  void validate() {
    if (name.isEmpty) {
      throw FKernalError.validation(message: 'Name cannot be empty');
    }
  }
}

void main() {
  test('FKernalModel validation works', () {
    final user = TestUser('');
    expect(() => user.validate(), throwsA(isA<FKernalError>()));

    final validUser = TestUser('Alice');
    // Should not throw
    validUser.validate();
  });
}
