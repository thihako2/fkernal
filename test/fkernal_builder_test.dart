import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fkernal/fkernal.dart';

class TestUser implements FKernalModel {
  final int id;
  TestUser(this.id);

  @override
  Map<String, dynamic> toJson() => {'id': id};

  @override
  void validate() {}
}

class MockErrorHandler extends ErrorHandler {
  MockErrorHandler() : super(environment: Environment.development);

  @override
  void handle(FKernalError error) {}
}

void main() {
  testWidgets('FKernalBuilder handles initial state without type error',
      (tester) async {
    final endpoint = Endpoint(
        id: 'getUser',
        path: '/user',
        method: HttpMethod.get,
        parser: (json) => TestUser(1));

    final registry = EndpointRegistry();
    registry.register(endpoint);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          endpointRegistryProvider.overrideWithValue(registry),
          errorHandlerProvider.overrideWithValue(MockErrorHandler()),
        ],
        child: MaterialApp(
          home: FKernalBuilder<TestUser>(
            resource: 'getUser',
            autoFetch: false,
            builder: (context, data) => const Text('Data'),
            loadingWidget: const Text('Loading'),
          ),
        ),
      ),
    );

    expect(find.text('Loading'), findsOneWidget);
  });
}
