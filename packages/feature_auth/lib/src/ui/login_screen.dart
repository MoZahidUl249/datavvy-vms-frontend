import 'package:material_ui/material_ui.dart';
import 'package:vms_design_system/vms_design_system.dart';

import 'login_view_model.dart';

const _isRelease = bool.fromEnvironment('dart.vm.product');

/// Centered 400 px card: email, password (Show/Hide), one primary action.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.createViewModel});

  final LoginViewModel Function() createViewModel;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final LoginViewModel _vm = widget.createViewModel();
  final _passwordFocus = FocusNode();
  bool _showPassword = false;

  @override
  void dispose() {
    _vm.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VmsColors.page,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(VmsSpace.s5),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: ListenableBuilder(
              listenable: _vm,
              builder: (context, _) => AutofillGroup(child: _card()),
            ),
          ),
        ),
      ),
    );
  }

  Widget _card() {
    return VmsCard(
      padding: const EdgeInsets.all(VmsSpace.s6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: VmsColors.nav, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.local_shipping_outlined, color: Colors.white),
            ),
          ),
          const SizedBox(height: VmsSpace.s5),
          Semantics(header: true, child: const Text('Sign in to Fleet Console', style: VmsText.title)),
          const SizedBox(height: 6),
          const Text('Manage every vehicle in your fleet.', style: TextStyle(fontSize: 15, color: VmsColors.textMeta)),
          const SizedBox(height: VmsSpace.s5),
          if (_vm.sessionExpired && _vm.bannerError == null) ...[
            const ErrorBanner(message: 'Your session ended. Sign in again to continue.'),
            const SizedBox(height: VmsSpace.s4),
          ],
          if (_vm.bannerError != null) ...[
            ErrorBanner(message: _vm.bannerError!),
            const SizedBox(height: VmsSpace.s4),
          ],
          VmsTextField(
            label: 'Email',
            hint: 'name@company.com',
            autofocus: true,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            error: _vm.emailError,
            onChanged: _vm.setEmail,
            onSubmitted: (_) => _passwordFocus.requestFocus(),
          ),
          const SizedBox(height: VmsSpace.s2),
          VmsTextField(
            label: 'Password',
            focusNode: _passwordFocus,
            obscureText: !_showPassword,
            autofillHints: const [AutofillHints.password],
            textInputAction: TextInputAction.done,
            error: _vm.passwordError,
            onChanged: _vm.setPassword,
            onSubmitted: (_) => _vm.submit(),
            suffix: Padding(
              padding: const EdgeInsets.only(right: 4),
              child: TextButton(
                onPressed: () => setState(() => _showPassword = !_showPassword),
                child: Text(_showPassword ? 'Hide' : 'Show'),
              ),
            ),
          ),
          const SizedBox(height: VmsSpace.s3),
          VmsButton(label: 'Sign in', expand: true, loading: _vm.submitting, onPressed: _vm.submit),
          if (!_isRelease) ...[
            const SizedBox(height: VmsSpace.s4),
            const Text(
              'Demo: admin@datavvy.com / Admin@12345',
              textAlign: TextAlign.center,
              style: VmsText.meta,
            ),
          ],
        ],
      ),
    );
  }
}
