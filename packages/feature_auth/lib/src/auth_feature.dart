import 'package:go_router/go_router.dart';
import 'package:vms_core/vms_core.dart';

import 'data/auth_repository.dart';
import 'ui/login_screen.dart';
import 'ui/login_view_model.dart';

/// Registers `/login`. Redirect logic lives in the app router.
class AuthFeature extends FeatureModule {
  AuthFeature({required ApiClient api, required AuthSession session})
      : _repository = AuthRepository(api),
        _session = session;

  final AuthRepository _repository;
  final AuthSession _session;

  @override
  List<RouteBase> get publicRoutes => [
        GoRoute(
          path: AppRoutes.login,
          pageBuilder: (context, state) => NoTransitionPage(
            child: LoginScreen(
              createViewModel: () => LoginViewModel(repository: _repository, session: _session),
            ),
          ),
        ),
      ];
}
