import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:vms_catalog/vms_catalog.dart';
import 'package:vms_core/vms_core.dart';
import 'package:vms_design_system/vms_design_system.dart';

import '../../data/vehicle_models.dart';
import 'filter_panel.dart';
import 'vehicle_list_view_model.dart';
import 'vehicle_table.dart';

class VehicleListScreen extends StatefulWidget {
  const VehicleListScreen({
    super.key,
    required this.createViewModel,
    required this.catalog,
    required this.preferences,
    required this.canManage,
  });

  final VehicleListViewModel Function() createViewModel;
  final CatalogRepository catalog;
  final UiPreferences preferences;
  final bool canManage;

  @override
  State<VehicleListScreen> createState() => _VehicleListScreenState();
}

class _VehicleListScreenState extends State<VehicleListScreen> {
  late final VehicleListViewModel _vm = widget.createViewModel()..load();
  late final TextEditingController _search = TextEditingController(text: _vm.query.search);

  @override
  void initState() {
    super.initState();
    widget.catalog.loadAll();
  }

  @override
  void dispose() {
    _vm.dispose();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_vm, widget.preferences, widget.catalog]),
      builder: (context, _) {
        final f = _vm.facets;
        return VmsPage(
          crumbs: const [Crumb('Vehicles')],
          title: 'Vehicles',
          subtitle: f.all == 0
              ? 'Every vehicle in your fleet.'
              : '${f.all} vehicles · ${f.active} active · ${f.maintenance} in maintenance',
          actions: [
            if (widget.canManage)
              VmsButton(label: 'Register vehicle', icon: Icons.add, onPressed: () => context.go(AppRoutes.vehicleNew)),
          ],
          body: _vm.isFirstRun ? _firstRun(context) : _content(context),
        );
      },
    );
  }

  Widget _firstRun(BuildContext context) {
    return VmsCard(
      child: EmptyState(
        icon: Icons.local_shipping_outlined,
        title: 'Register your first vehicle',
        message: "You'll need the vehicle number, company, type, brand, model and status.",
        actionLabel: widget.canManage ? 'Register vehicle' : null,
        onAction: () => context.go(AppRoutes.vehicleNew),
      ),
    );
  }

  Widget _content(BuildContext context) {
    final page = _vm.page;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _toolbar(context),
        if (!_vm.query.filters.isEmpty) ...[const SizedBox(height: VmsSpace.s3), _chips()],
        const SizedBox(height: VmsSpace.s4),
        if (_vm.error != null) ...[
          ErrorBanner(message: _vm.error!.message, actionLabel: 'Try again', onAction: _vm.load),
          const SizedBox(height: VmsSpace.s4),
        ],
        VmsCard(
          child: page != null && page.items.isEmpty && !_vm.loading
              ? _noResults()
              : VehicleTable(
                  vehicles: page?.items ?? const [],
                  loading: _vm.loading,
                  columns: widget.preferences.visibleColumns,
                  sort: _vm.query.sort,
                  onSort: _vm.sortBy,
                  canManage: widget.canManage,
                  highlightId: _vm.highlightId,
                  onOpen: (v) => context.go(AppRoutes.vehicleEdit(v.id)),
                  onDelete: (v) => _confirmDelete(context, v),
                ),
        ),
        if (page != null && page.totalPages > 1) _pager(page),
      ],
    );
  }

  Widget _toolbar(BuildContext context) {
    final f = _vm.facets;
    final q = _vm.query;
    final sortPreset = VehicleSort.presets.any((p) => p.$1 == q.sort) ? q.sort : null;
    return Wrap(
      spacing: VmsSpace.s3,
      runSpacing: VmsSpace.s3,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        VmsSegmented<StatusFilter>(
          semanticLabel: 'Status',
          selected: q.status,
          onChanged: _vm.setStatus,
          segments: [
            VmsSegment(value: StatusFilter.all, label: 'All', count: f.all),
            VmsSegment(value: StatusFilter.active, label: 'Active', count: f.active),
            VmsSegment(value: StatusFilter.inactive, label: 'Inactive', count: f.inactive),
            VmsSegment(value: StatusFilter.maintenance, label: 'Maintenance', count: f.maintenance),
          ],
        ),
        SizedBox(
          width: 280,
          child: VmsTextField(
            label: 'Search vehicles',
            showLabel: false,
            controller: _search,
            hint: 'Search number, company, brand…',
            prefixIcon: Icons.search,
            textInputAction: TextInputAction.search,
            onChanged: _vm.setSearch,
          ),
        ),
        SizedBox(
          width: 190,
          child: VmsSelect<VehicleSort>(
            small: true,
            hint: 'Custom sort',
            value: sortPreset,
            options: [for (final p in VehicleSort.presets) VmsOption(p.$1, p.$2)],
            onChanged: (s) {
              if (s != null) _vm.setSort(s);
            },
          ),
        ),
        VmsIconButton(
          icon: Icons.filter_list,
          tooltip: q.filters.isEmpty ? 'Filters' : 'Filters (${q.filters.count} applied)',
          badgeCount: q.filters.count,
          onPressed: () => _openFilters(context),
        ),
        VmsIconButton(
          icon: Icons.view_column_outlined,
          tooltip: 'Choose columns',
          onPressed: () => context.go(AppRoutes.settingsSection('columns')),
        ),
      ],
    );
  }

  Future<void> _openFilters(BuildContext context) async {
    final result = await showFilterPanel(
      context,
      current: _vm.query.filters,
      types: widget.catalog.items(CatalogKind.vehicleType),
      facets: _vm.facets,
      countFor: _vm.countFor,
    );
    if (result != null) _vm.applyFilters(result);
  }

  Widget _chips() {
    final f = _vm.query.filters;
    final chips = <Widget>[
      for (final t in f.types)
        VmsChip(label: t, onRemove: () => _vm.applyFilters(f.copyWith(types: {...f.types}..remove(t)))),
      for (final c in f.companies)
        VmsChip(label: c, onRemove: () => _vm.applyFilters(f.copyWith(companies: {...f.companies}..remove(c)))),
      for (final b in f.brands)
        VmsChip(label: b, onRemove: () => _vm.applyFilters(f.copyWith(brands: {...f.brands}..remove(b)))),
      if (f.updatedOn != null)
        VmsChip(
          label: 'Updated ${formatDate(f.updatedOn)}',
          onRemove: () => _vm.applyFilters(f.copyWith(updatedOn: () => null)),
        ),
      if (f.addedOn != null)
        VmsChip(
          label: 'Added ${formatDate(f.addedOn)}',
          onRemove: () => _vm.applyFilters(f.copyWith(addedOn: () => null)),
        ),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ...chips,
        VmsButton(label: 'Clear all', small: true, variant: VmsButtonVariant.text, onPressed: _vm.clearFilters),
      ],
    );
  }

  Widget _noResults() {
    final q = _vm.query;
    final parts = <String>[
      if (q.search.trim().isNotEmpty) '"${q.search.trim()}"',
      if (q.status != StatusFilter.all) q.status.label.toLowerCase(),
      if (!q.filters.isEmpty) '${q.filters.count} filter${q.filters.count == 1 ? '' : 's'}',
    ];
    return EmptyState(
      icon: Icons.search_off,
      title: 'No vehicles match',
      message: parts.isEmpty
          ? 'Nothing to show on this page.'
          : 'Nothing matches ${parts.join(' with ')}. Clear the search and filters to see every vehicle.',
      actionLabel: 'Show all vehicles',
      onAction: () {
        _search.clear();
        _vm
          ..setStatus(StatusFilter.all)
          ..setSearch('')
          ..clearFilters();
      },
    );
  }

  Widget _pager(VehiclePage page) {
    final from = page.page * page.size + 1;
    final to = from + page.items.length - 1;
    return Padding(
      padding: const EdgeInsets.only(top: VmsSpace.s4),
      child: Row(
        children: [
          Expanded(child: Text('Showing $from–$to of ${page.total}', style: VmsText.tabular(VmsText.meta))),
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

  Future<void> _confirmDelete(BuildContext context, Vehicle v) async {
    final ok = await showVmsConfirm(
      context,
      title: 'Delete ${v.vehicleNumber}?',
      message: 'The vehicle is removed permanently from the list and dashboard.',
      confirmLabel: 'Delete',
    );
    if (!ok || !context.mounted) return;
    final result = await _vm.delete(v);
    if (!context.mounted) return;
    switch (result) {
      case Ok():
        showVmsToast(context, '${v.vehicleNumber} deleted.');
      case Err(:final error):
        showVmsToast(context, error.message);
    }
  }
}
