/// Fleet records shared by the vehicle page, the Drivers, Documents and
/// Maintenance screens: models matching `contracts/openapi/vms-api.yaml`
/// (backend repo), their repositories, and the widgets that show them
/// (expiry pill, upload / maintenance / assign-driver dialogs).
///
/// Owners: Fleet Compliance (documents) and Fleet Operations (maintenance, drivers).
library;

export 'src/documents.dart';
export 'src/drivers.dart';
export 'src/expiry.dart';
export 'src/maintenance.dart';
export 'src/money.dart';
export 'src/paged.dart';
export 'src/widgets/assign_driver_dialog.dart';
export 'src/widgets/document_dialog.dart';
export 'src/widgets/expiry_pill.dart';
export 'src/widgets/maintenance_dialog.dart';
