import 'package:feature_auth/feature_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vms_core/vms_core.dart';

class _FakeRepository implements AuthRepository {
  _FakeRepository(this.result);
  final Result<LoginResult> result;

  @override
  Future<Result<LoginResult>> login({required String email, required String password}) async => result;
}

void main() {
  const user = SessionUser(id: 1, email: 'a@b.co', displayName: 'Saif Mahmud', role: 'ADMIN');

  test('shows field errors and does not call the API when empty', () async {
    final session = AuthSession();
    final vm = LoginViewModel(
      repository: _FakeRepository(const Ok(LoginResult(token: 't', expiresIn: 60, user: user))),
      session: session,
    );
    expect(await vm.submit(), isFalse);
    expect(vm.emailError, isNotNull);
    expect(vm.passwordError, isNotNull);
    expect(session.isSignedIn, isFalse);
  });

  test('signs in on success', () async {
    final session = AuthSession();
    final vm = LoginViewModel(
      repository: _FakeRepository(const Ok(LoginResult(token: 't', expiresIn: 60, user: user))),
      session: session,
    )
      ..setEmail('a@b.co')
      ..setPassword('secret');
    expect(await vm.submit(), isTrue);
    expect(session.isSignedIn, isTrue);
    expect(session.user!.initials, 'SM');
  });

  test('wrong credentials show the banner', () async {
    final vm = LoginViewModel(
      repository: _FakeRepository(const Err(ApiError(status: 401, code: 'INVALID_CREDENTIALS', message: 'x'))),
      session: AuthSession(),
    )
      ..setEmail('a@b.co')
      ..setPassword('wrong');
    expect(await vm.submit(), isFalse);
    expect(vm.bannerError, contains("don't match"));
  });
}
