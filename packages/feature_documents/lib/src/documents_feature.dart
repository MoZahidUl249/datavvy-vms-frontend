import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:vms_core/vms_core.dart';
import 'package:vms_fleet_records/vms_fleet_records.dart';

import 'documents_screen.dart';
import 'documents_view_model.dart';

/// `/documents?expiry=attention|EXPIRED|EXPIRING_SOON|VALID|NO_EXPIRY`
class DocumentsFeature extends FeatureModule {
  DocumentsFeature({required DocumentRepository documents}) : _documents = documents;

  final DocumentRepository _documents;

  @override
  List<RouteBase> get shellRoutes => [
        GoRoute(
          path: AppRoutes.documents,
          pageBuilder: (context, state) => NoTransitionPage(
            key: ValueKey(state.uri.toString()),
            child: DocumentsScreen(
              createViewModel: () => DocumentsViewModel(
                repository: _documents,
                filter: ExpiryFilter.fromQuery(state.uri.queryParameters['expiry']),
              ),
            ),
          ),
        ),
      ];

  @override
  List<NavItem> get navItems => const [
        NavItem(label: 'Documents', icon: Icons.description_outlined, path: AppRoutes.documents, section: 'Fleet', order: 30),
      ];
}
