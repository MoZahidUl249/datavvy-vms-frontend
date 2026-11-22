import 'package:feature_auth/feature_auth.dart';
import 'package:feature_dashboard/feature_dashboard.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vms_app/app/vms_app.dart';
import 'package:vms_core/vms_core.dart';

void main() {
  testWidgets('signed-out users land on the sign-in screen', (tester) async {
    final session = AuthSession();
    final api = ApiClient(config: const AppConfig(apiBaseUrl: 'http://localhost:0/api'), tokens: session);
    await tester.pumpWidget(VmsApp(
      session: session,
      features: [
        AuthFeature(api: api, session: session),
        DashboardFeature(api: api, preferences: UiPreferences(), session: session),
      ],
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Sign in to Fleet Console'), findsOneWidget);
  });
}
