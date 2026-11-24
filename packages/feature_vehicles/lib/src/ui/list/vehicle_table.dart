import 'package:material_ui/material_ui.dart';
import 'package:vms_core/vms_core.dart';
import 'package:vms_design_system/vms_design_system.dart';

import '../../data/vehicle_models.dart';

/// Colour + word for each status (never colour alone).
StatusTone statusTone(VehicleStatus status) => switch (status) {
      VehicleStatus.active => StatusTone.success,
      VehicleStatus.inactive => StatusTone.neutral,
      VehicleStatus.maintenance => StatusTone.warning,
    };

/// Column definition: width, header, optional API sort field, cell builder.
class _Col {
  const _Col(this.column, this.label, this.width, this.cell, {this.sortField});

  final VehicleColumn? column;
  final String label;
  final double width;
  final String? sortField;
  final Widget Function(Vehicle v) cell;
}

/// The vehicle table: plate first, configurable columns, actions last.
/// Rows are 68 px; the table scrolls sideways on narrow screens.
class VehicleTable extends StatelessWidget {
  const VehicleTable({
    super.key,
    required this.vehicles,
    required this.columns,
    required this.sort,
    required this.onSort,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
    required this.canManage,
    this.highlightId,
    this.loading = false,
  });

  final List<Vehicle> vehicles;
  final List<VehicleColumn> columns;
  final VehicleSort sort;
  final ValueChanged<String> onSort;
  /// Plate and View: the vehicle page.
  final ValueChanged<Vehicle> onOpen;

  /// Edit: the vehicle form.
  final ValueChanged<Vehicle> onEdit;
  final ValueChanged<Vehicle> onDelete;
  final bool canManage;
  final int? highlightId;
  final bool loading;

  static const _numberMin = 240.0;
  static const _actionsWidth = 176.0;

  List<_Col> _columns() {
    Text t(String s) => Text(s, style: VmsText.table, overflow: TextOverflow.ellipsis);
    Text tab(String s) => Text(s, style: VmsText.tabular(VmsText.table), overflow: TextOverflow.ellipsis);
    final all = <VehicleColumn, _Col>{
      VehicleColumn.status: _Col(
        VehicleColumn.status,
        'Status',
        130,
        (v) => Align(alignment: Alignment.centerLeft, child: StatusPill(label: v.status.label, tone: statusTone(v.status))),
        sortField: 'status',
      ),
      VehicleColumn.type: _Col(VehicleColumn.type, 'Type', 120, (v) => t(v.type), sortField: 'type'),
      VehicleColumn.company: _Col(VehicleColumn.company, 'Company', 170, (v) => t(v.company), sortField: 'company'),
      VehicleColumn.brand: _Col(VehicleColumn.brand, 'Brand', 120, (v) => t(v.brand), sortField: 'brand'),
      VehicleColumn.model: _Col(VehicleColumn.model, 'Model', 140, (v) => t(v.model), sortField: 'model'),
      VehicleColumn.added: _Col(VehicleColumn.added, 'Added', 120, (v) => tab(formatDate(v.createdAt)),
          sortField: 'createdAt'),
      VehicleColumn.updated: _Col(VehicleColumn.updated, 'Last updated', 130, (v) => tab(formatDate(v.updatedAt)),
          sortField: 'updatedAt'),
    };
    return [for (final c in columns) all[c]!];
  }

  @override
  Widget build(BuildContext context) {
    final cols = _columns();
    final fixed = cols.fold<double>(0, (sum, c) => sum + c.width) + _actionsWidth + 48;
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth > fixed + _numberMin ? constraints.maxWidth : fixed + _numberMin;
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _header(cols),
              if (loading && vehicles.isEmpty)
                for (var i = 0; i < 6; i++) _skeletonRow(cols)
              else
                for (final v in vehicles) _row(v, cols),
            ],
          ),
        ),
      );
    });
  }

  Widget _header(List<_Col> cols) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: VmsColors.surfaceSubtle,
        border: Border(bottom: BorderSide(color: VmsColors.divider)),
      ),
      child: Row(
        children: [
          Expanded(child: _headerCell('Vehicle number', 'vehicleNumber')),
          for (final c in cols) SizedBox(width: c.width, child: _headerCell(c.label, c.sortField)),
          const SizedBox(width: _actionsWidth, child: Text('Actions', style: VmsText.th, textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  Widget _headerCell(String label, String? field) {
    final text = Text(label.toUpperCase(), style: VmsText.th);
    if (field == null) return Align(alignment: Alignment.centerLeft, child: text);
    final active = sort.field == field;
    return Align(
      alignment: Alignment.centerLeft,
      child: Semantics(
        button: true,
        label: '$label, ${active ? (sort.ascending ? 'sorted ascending' : 'sorted descending') : 'not sorted'}',
        excludeSemantics: true,
        child: InkWell(
          onTap: () => onSort(field),
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                text,
                if (active) ...[
                  const SizedBox(width: 4),
                  Text(sort.ascending ? '▲' : '▼', style: const TextStyle(fontSize: 9, color: VmsColors.textMeta)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(Vehicle v, List<_Col> cols) {
    // Brand / model that aren't their own columns show under the number.
    final subtitle = [
      if (!columns.contains(VehicleColumn.brand)) v.brand,
      if (!columns.contains(VehicleColumn.model)) v.model,
    ].where((s) => s.isNotEmpty).join(' ');
    final highlighted = v.id == highlightId;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      height: VmsSize.row,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: highlighted ? VmsColors.selectedBg : VmsColors.surface,
        border: const Border(bottom: BorderSide(color: VmsColors.divider)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PlateBadge(number: v.vehicleNumber, onTap: () => onOpen(v)),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(subtitle, style: VmsText.secondary, overflow: TextOverflow.ellipsis),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          for (final c in cols) SizedBox(width: c.width, child: c.cell(v)),
          SizedBox(
            width: _actionsWidth,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: canManage
                  ? [
                      VmsButton(
                        label: 'Edit',
                        small: true,
                        variant: VmsButtonVariant.secondary,
                        onPressed: () => onEdit(v),
                      ),
                      const SizedBox(width: 8),
                      VmsButton(
                        label: 'Delete',
                        small: true,
                        variant: VmsButtonVariant.destructiveText,
                        onPressed: () => onDelete(v),
                      ),
                    ]
                  : [
                      VmsButton(
                        label: 'View',
                        small: true,
                        variant: VmsButtonVariant.secondary,
                        onPressed: () => onOpen(v),
                      ),
                    ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _skeletonRow(List<_Col> cols) {
    return Container(
      height: VmsSize.row,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: VmsColors.divider))),
      child: Row(
        children: [
          const Expanded(child: Align(alignment: Alignment.centerLeft, child: Skeleton(width: 170, height: 26))),
          for (final c in cols)
            SizedBox(
              width: c.width,
              child: Align(alignment: Alignment.centerLeft, child: Skeleton(width: c.width * 0.6)),
            ),
          const SizedBox(width: _actionsWidth, child: Align(alignment: Alignment.centerRight, child: Skeleton(width: 120, height: 30))),
        ],
      ),
    );
  }
}
