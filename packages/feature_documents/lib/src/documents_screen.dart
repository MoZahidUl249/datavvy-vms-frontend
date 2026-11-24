import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:vms_core/vms_core.dart';
import 'package:vms_design_system/vms_design_system.dart';
import 'package:vms_fleet_records/vms_fleet_records.dart';

import 'documents_view_model.dart';

/// Every vehicle document in one list, opening on "Needs attention"
/// (expired + expiring soon) so renewals don't slip.
class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key, required this.createViewModel});

  final DocumentsViewModel Function() createViewModel;

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  late final DocumentsViewModel _vm = widget.createViewModel()..load();
  final _search = TextEditingController();

  @override
  void dispose() {
    _vm.dispose();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        final s = _vm.stats;
        return VmsPage(
          crumbs: const [Crumb('Documents')],
          title: 'Documents',
          subtitle: s.total == 0
              ? 'Registration, tax token, insurance and fitness papers of every vehicle.'
              : '${s.total} documents · ${s.expired} expired · ${s.expiringSoon} expiring in the next ${s.expiringSoonDays} days',
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _toolbar(),
              const SizedBox(height: VmsSpace.s4),
              if (_vm.error != null) ...[
                ErrorBanner(message: _vm.error!.message, actionLabel: 'Try again', onAction: _vm.load),
                const SizedBox(height: VmsSpace.s4),
              ],
              VmsCard(child: _table(context)),
              if ((_vm.page?.totalPages ?? 0) > 1) _pager(_vm.page!),
            ],
          ),
        );
      },
    );
  }

  Widget _toolbar() {
    final q = _vm.query;
    return Wrap(
      spacing: VmsSpace.s3,
      runSpacing: VmsSpace.s3,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        VmsSegmented<ExpiryFilter>(
          semanticLabel: 'Expiry',
          selected: _vm.filter,
          onChanged: _vm.setFilter,
          segments: [
            for (final f in ExpiryFilter.values) VmsSegment(value: f, label: f.label, count: f.countIn(_vm.stats)),
          ],
        ),
        SizedBox(
          width: 260,
          child: VmsTextField(
            label: 'Search documents',
            showLabel: false,
            controller: _search,
            hint: 'Vehicle number or document no.',
            prefixIcon: Icons.search,
            textInputAction: TextInputAction.search,
            onChanged: _vm.setSearch,
          ),
        ),
        SizedBox(
          width: 210,
          child: VmsSelect<DocumentType?>(
            small: true,
            hint: 'All types',
            value: q.type,
            options: [
              const VmsOption<DocumentType?>(null, 'All types'),
              for (final t in DocumentType.values) VmsOption<DocumentType?>(t, t.label),
            ],
            onChanged: _vm.setType,
          ),
        ),
        SizedBox(
          width: 210,
          child: VmsSelect<String>(
            small: true,
            value: q.sort,
            options: [for (final o in DocumentsViewModel.sorts) VmsOption(o.$1, o.$2)],
            onChanged: (s) {
              if (s != null) _vm.setSort(s);
            },
          ),
        ),
      ],
    );
  }

  static const _vehicleW = 220.0, _expiryW = 170.0, _pillW = 140.0, _actionsW = 96.0;

  Widget _table(BuildContext context) {
    final page = _vm.page;
    if (page != null && page.items.isEmpty && !_vm.loading) {
      final attention = _vm.filter == ExpiryFilter.attention && _vm.query.search.trim().isEmpty;
      return EmptyState(
        icon: attention ? Icons.verified_outlined : Icons.search_off,
        title: attention ? 'Nothing needs attention' : 'No documents match',
        message: attention
            ? 'No document is expired or expiring in the next ${_vm.stats.expiringSoonDays} days.'
            : 'Try another filter or clear the search.',
        actionLabel: 'Show all documents',
        onAction: () {
          _search.clear();
          _vm
            ..setSearch('')
            ..setFilter(ExpiryFilter.all);
        },
      );
    }
    const fixed = _vehicleW + _expiryW + _pillW + _actionsW + 48;
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth > fixed + 240 ? constraints.maxWidth : fixed + 240;
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                decoration: const BoxDecoration(
                  color: VmsColors.surfaceSubtle,
                  border: Border(bottom: BorderSide(color: VmsColors.divider)),
                ),
                child: const Row(
                  children: [
                    SizedBox(width: _vehicleW, child: Text('VEHICLE', style: VmsText.th)),
                    Expanded(child: Text('DOCUMENT', style: VmsText.th)),
                    SizedBox(width: _expiryW, child: Text('EXPIRY', style: VmsText.th)),
                    SizedBox(width: _pillW, child: Text('STATUS', style: VmsText.th)),
                    SizedBox(width: _actionsW, child: Text('FILE', style: VmsText.th, textAlign: TextAlign.right)),
                  ],
                ),
              ),
              if (page == null)
                for (var i = 0; i < 5; i++)
                  const Padding(padding: EdgeInsets.fromLTRB(24, 18, 24, 18), child: Skeleton(height: 18))
              else
                for (final d in page.items) _row(context, d),
            ],
          ),
        ),
      );
    });
  }

  Widget _row(BuildContext context, VehicleDocument d) {
    return Container(
      height: VmsSize.row,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: VmsColors.divider))),
      child: Row(
        children: [
          SizedBox(
            width: _vehicleW,
            child: Align(
              alignment: Alignment.centerLeft,
              child: PlateBadge(
                number: d.vehicleNumber ?? 'Vehicle ${d.vehicleId}',
                onTap: () => context.go(AppRoutes.vehicleSection(d.vehicleId, 'documents')),
              ),
            ),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(d.displayName, style: VmsText.section, overflow: TextOverflow.ellipsis),
                if (d.documentNumber != null)
                  Text(d.documentNumber!, style: VmsText.tabular(VmsText.secondary), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          SizedBox(
            width: _expiryW,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(d.expiryDate == null ? '—' : formatDate(d.expiryDate), style: VmsText.tabular(VmsText.table)),
                Text(describeExpiry(d.expiryStatus, d.daysUntilExpiry), style: VmsText.meta),
              ],
            ),
          ),
          SizedBox(
            width: _pillW,
            child: Align(
              alignment: Alignment.centerLeft,
              child: ExpiryPill(status: d.expiryStatus, daysLeft: d.daysUntilExpiry),
            ),
          ),
          SizedBox(
            width: _actionsW,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                VmsIconButton(
                  icon: Icons.visibility_outlined,
                  tooltip: 'View ${d.displayName}',
                  bordered: false,
                  onPressed: () => _file(d, download: false),
                ),
                VmsIconButton(
                  icon: Icons.download_outlined,
                  tooltip: 'Download ${d.fileName}',
                  bordered: false,
                  onPressed: () => _file(d, download: true),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _file(VehicleDocument d, {required bool download}) async {
    final result = await _vm.fileOf(d);
    if (!mounted) return;
    switch (result) {
      case Ok(:final value):
        if (download) {
          saveBytes(value, fileName: d.fileName, contentType: d.contentType);
        } else {
          openBytes(value, contentType: d.contentType);
        }
      case Err(:final error):
        showVmsToast(context, error.message);
    }
  }

  Widget _pager(Paged<VehicleDocument> page) => Padding(
        padding: const EdgeInsets.only(top: VmsSpace.s4),
        child: Row(
          children: [
            Expanded(child: Text(page.rangeLabel, style: VmsText.tabular(VmsText.meta))),
            VmsButton(
              label: 'Previous',
              small: true,
              variant: VmsButtonVariant.secondary,
              onPressed: page.hasPrevious ? _vm.previousPage : null,
            ),
            const SizedBox(width: 8),
            VmsButton(
              label: 'Next',
              small: true,
              variant: VmsButtonVariant.secondary,
              onPressed: page.hasNext ? _vm.nextPage : null,
            ),
          ],
        ),
      );
}
