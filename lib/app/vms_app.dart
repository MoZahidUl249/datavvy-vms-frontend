import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:vms_core/vms_core.dart';
import 'package:vms_design_system/vms_design_system.dart';

import 'router.dart';

class VmsApp extends StatefulWidget {
  const VmsApp({super.key, required this.session, required this.features});

  final AuthSession session;
  final List<FeatureModule> features;

  @override
  State<VmsApp> createState() => _VmsAppState();
}

class _VmsAppState extends State<VmsApp> {
  late final GoRouter _router = buildRouter(session: widget.session, features: widget.features);

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Fleet Console · Datavvy VMS',
      debugShowCheckedModeBanner: false,
      theme: buildVmsTheme(),
      routerConfig: _router,
    );
  }
}
