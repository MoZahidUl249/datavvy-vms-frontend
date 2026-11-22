import 'package:flutter_test/flutter_test.dart';
import 'package:vms_core/vms_core.dart';

const _user = SessionUser(id: 2, email: 'manager@datavvy.com', displayName: 'Fleet Manager', role: 'FLEET_MANAGER');

void main() {
  group('AuthSession persistence', () {
    test('a new session restores what the previous one stored (page reload)', () {
      final store = MemorySessionStore();
      AuthSession(store: store).signIn(token: 'abc', user: _user, expiresInSeconds: 3600);

      final reloaded = AuthSession(store: store);

      expect(reloaded.isSignedIn, isTrue);
      expect(reloaded.token, 'abc');
      expect(reloaded.user!.email, 'manager@datavvy.com');
      expect(reloaded.user!.canManageFleet, isTrue);
    });

    test('sign-out clears the store', () {
      final store = MemorySessionStore();
      final session = AuthSession(store: store)..signIn(token: 'abc', user: _user, expiresInSeconds: 3600);

      session.signOut();

      expect(store.read(), isNull);
      expect(AuthSession(store: store).isSignedIn, isFalse);
    });

    test('an expired stored session is discarded', () {
      final store = MemorySessionStore()
        ..write('{"token":"abc","expiresAt":"2000-01-01T00:00:00.000Z",'
            '"user":{"id":2,"email":"m@x.com","displayName":"M","role":"VIEWER"}}');

      final session = AuthSession(store: store);

      expect(session.isSignedIn, isFalse);
      expect(store.read(), isNull);
    });

    test('a corrupt stored value is discarded, not thrown', () {
      final store = MemorySessionStore()..write('not json');

      final session = AuthSession(store: store);

      expect(session.isSignedIn, isFalse);
      expect(store.read(), isNull);
    });
  });
}
