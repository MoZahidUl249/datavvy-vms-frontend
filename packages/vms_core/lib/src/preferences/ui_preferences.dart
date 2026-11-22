import 'package:flutter/foundation.dart';

/// Optional columns of the vehicle list (the plate number is always shown).
enum VehicleColumn {
  status('Status'),
  type('Type'),
  company('Company'),
  brand('Brand'),
  model('Model'),
  added('Added'),
  updated('Last updated');

  const VehicleColumn(this.label);
  final String label;
}

/// Optional dashboard cards (KPI cards are always shown).
enum DashboardCard {
  byType('Vehicles by type'),
  byBrand('Vehicles by brand'),
  recentlyUpdated('Recently updated'),
  inMaintenance('In maintenance');

  const DashboardCard(this.label);
  final String label;
}

/// Per-user display preferences edited on the Settings screen and read by the
/// vehicle list and dashboard. Changes apply immediately.
///
/// Kept in memory for now; persisting them (server-side per user) is on the
/// roadmap and only changes this class.
class UiPreferences extends ChangeNotifier {
  final Set<VehicleColumn> _columns = {
    VehicleColumn.status,
    VehicleColumn.type,
    VehicleColumn.company,
    VehicleColumn.updated,
  };
  final Set<DashboardCard> _cards = DashboardCard.values.toSet();

  bool showsColumn(VehicleColumn column) => _columns.contains(column);

  /// Visible columns in display order.
  List<VehicleColumn> get visibleColumns =>
      VehicleColumn.values.where(_columns.contains).toList();

  bool showsCard(DashboardCard card) => _cards.contains(card);

  void setColumn(VehicleColumn column, bool visible) {
    final changed = visible ? _columns.add(column) : _columns.remove(column);
    if (changed) notifyListeners();
  }

  void setCard(DashboardCard card, bool visible) {
    final changed = visible ? _cards.add(card) : _cards.remove(card);
    if (changed) notifyListeners();
  }
}
