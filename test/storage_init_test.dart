import 'package:flutter_test/flutter_test.dart';
import 'package:fkernal/fkernal.dart';

void main() {
  testWidgets('FKernal.init initializes storage successfully', (tester) async {
    // We need to ensure WidgetsFlutterBinding is initialized,
    // which testWidgets does automatically.

    // Use a try-catch to see if it throws HiveError
    try {
      await FKernal.init(
        config: const FKernalConfig(
          baseUrl: 'https://example.com',
          features: FeatureFlags(enableCache: true),
        ),
        endpoints: [],
      );

      expect(FKernal.instance.healthStatus,
          anyOf(KernelHealthStatus.healthy, KernelHealthStatus.degraded));
      // Even if it's degraded, we want to see if the specific HiveError is gone or handled.
    } catch (e) {
      fail('FKernal.init threw an error: $e');
    } finally {
      await FKernal.reset();
    }
  });
}
