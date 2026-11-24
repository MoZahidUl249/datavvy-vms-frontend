import 'dart:typed_data';

import 'package:vms_core/vms_core.dart';

import 'expiry.dart';
import 'paged.dart';

/// `DocumentType` in the contract.
enum DocumentType {
  registration('REGISTRATION', 'Registration certificate'),
  taxToken('TAX_TOKEN', 'Tax token'),
  insurance('INSURANCE', 'Insurance'),
  fitness('FITNESS', 'Fitness certificate'),
  routePermit('ROUTE_PERMIT', 'Route permit'),
  other('OTHER', 'Other');

  const DocumentType(this.apiValue, this.label);
  final String apiValue;
  final String label;

  static DocumentType fromApi(Object? value) =>
      DocumentType.values.firstWhere((t) => t.apiValue == value, orElse: () => DocumentType.other);

  /// Renewed periodically, so the API requires an expiry date.
  bool get expires => this == taxToken || this == insurance || this == fitness || this == routePermit;
}

/// `Document` schema.
class VehicleDocument {
  const VehicleDocument({
    required this.id,
    required this.vehicleId,
    required this.vehicleNumber,
    required this.type,
    required this.title,
    required this.documentNumber,
    required this.issueDate,
    required this.expiryDate,
    required this.expiryStatus,
    required this.daysUntilExpiry,
    required this.notes,
    required this.fileName,
    required this.contentType,
    required this.sizeBytes,
    required this.updatedAt,
    required this.updatedBy,
    required this.version,
  });

  factory VehicleDocument.fromJson(Map<String, dynamic> j) => VehicleDocument(
        id: asInt(j['id']),
        vehicleId: asInt(j['vehicleId']),
        vehicleNumber: asStringOrNull(j['vehicleNumber']),
        type: DocumentType.fromApi(j['type']),
        title: asStringOrNull(j['title']),
        documentNumber: asStringOrNull(j['documentNumber']),
        issueDate: asDate(j['issueDate']),
        expiryDate: asDate(j['expiryDate']),
        expiryStatus: ExpiryStatus.fromApi(j['expiryStatus']),
        daysUntilExpiry: asIntOrNull(j['daysUntilExpiry']),
        notes: asStringOrNull(j['notes']),
        fileName: asString(j['fileName'], 'document'),
        contentType: asString(j['contentType'], 'application/octet-stream'),
        sizeBytes: asInt(j['sizeBytes']),
        updatedAt: asDateTime(j['updatedAt']),
        updatedBy: asStringOrNull(j['updatedBy']),
        version: asInt(j['version']),
      );

  final int id;
  final int vehicleId;
  final String? vehicleNumber;
  final DocumentType type;
  final String? title;
  final String? documentNumber;
  final DateTime? issueDate;
  final DateTime? expiryDate;
  final ExpiryStatus expiryStatus;
  final int? daysUntilExpiry;
  final String? notes;
  final String fileName;
  final String contentType;
  final int sizeBytes;
  final DateTime? updatedAt;
  final String? updatedBy;
  final int version;

  /// The title for OTHER, otherwise the type's name.
  String get displayName => (title != null && title!.isNotEmpty) ? title! : type.label;

  bool get isImage => contentType.startsWith('image/');
}

/// `DocumentStats` schema (also inside the dashboard summary).
class DocumentStats {
  const DocumentStats({
    required this.total,
    required this.valid,
    required this.expiringSoon,
    required this.expired,
    required this.noExpiry,
    required this.expiringSoonDays,
  });

  factory DocumentStats.fromJson(Map<String, dynamic> j) => DocumentStats(
        total: asInt(j['total']),
        valid: asInt(j['valid']),
        expiringSoon: asInt(j['expiringSoon']),
        expired: asInt(j['expired']),
        noExpiry: asInt(j['noExpiry']),
        expiringSoonDays: asInt(j['expiringSoonDays'], 30),
      );

  static const empty =
      DocumentStats(total: 0, valid: 0, expiringSoon: 0, expired: 0, noExpiry: 0, expiringSoonDays: 30);

  final int total;
  final int valid;
  final int expiringSoon;
  final int expired;
  final int noExpiry;
  final int expiringSoonDays;

  int get needingAttention => expired + expiringSoon;
}

/// `DocumentRequest` fields. Sent as multipart fields on upload, JSON on update.
class DocumentDraft {
  const DocumentDraft({
    required this.type,
    this.title,
    this.documentNumber,
    this.issueDate,
    this.expiryDate,
    this.notes,
  });

  factory DocumentDraft.of(VehicleDocument d) => DocumentDraft(
        type: d.type,
        title: d.title,
        documentNumber: d.documentNumber,
        issueDate: d.issueDate,
        expiryDate: d.expiryDate,
        notes: d.notes,
      );

  final DocumentType type;
  final String? title;
  final String? documentNumber;
  final DateTime? issueDate;
  final DateTime? expiryDate;
  final String? notes;

  static String? _clean(String? s) => s == null || s.trim().isEmpty ? null : s.trim();

  Map<String, String> toFields() => {
        'type': type.apiValue,
        if (_clean(title) != null) 'title': _clean(title)!,
        if (_clean(documentNumber) != null) 'documentNumber': _clean(documentNumber)!,
        if (issueDate != null) 'issueDate': isoDate(issueDate!),
        if (expiryDate != null) 'expiryDate': isoDate(expiryDate!),
        if (_clean(notes) != null) 'notes': _clean(notes)!,
      };

  Map<String, Object?> toJson({required int version}) => {
        'type': type.apiValue,
        'title': _clean(title),
        'documentNumber': _clean(documentNumber),
        'issueDate': issueDate == null ? null : isoDate(issueDate!),
        'expiryDate': expiryDate == null ? null : isoDate(expiryDate!),
        'notes': _clean(notes),
        'version': version,
      };
}

/// Fleet-wide document list query (`GET /v1/documents`).
class DocumentQuery {
  const DocumentQuery({
    this.expiry = const {},
    this.type,
    this.search = '',
    this.sort = 'expiryDate,asc',
    this.page = 0,
    this.size = 20,
  });

  final Set<ExpiryStatus> expiry;
  final DocumentType? type;
  final String search;
  final String sort;
  final int page;
  final int size;

  DocumentQuery copyWith({
    Set<ExpiryStatus>? expiry,
    DocumentType? Function()? type,
    String? search,
    String? sort,
    int? page,
  }) =>
      DocumentQuery(
        expiry: expiry ?? this.expiry,
        type: type == null ? this.type : type(),
        search: search ?? this.search,
        sort: sort ?? this.sort,
        page: page ?? this.page,
        size: size,
      );

  Map<String, Object?> toQuery() => {
        'expiry': [for (final e in expiry) e.apiValue],
        'type': type?.apiValue,
        'q': search.trim(),
        'sort': sort,
        'page': page,
        'size': size,
      };
}

/// Talks to the document endpoints (see backend API.md).
class DocumentRepository {
  const DocumentRepository(this._api);

  final ApiClient _api;

  Future<Result<List<VehicleDocument>>> forVehicle(int vehicleId) async =>
      (await _api.get('/v1/vehicles/$vehicleId/documents'))
          .map((j) => asList(j).map((e) => VehicleDocument.fromJson(asMap(e))).toList());

  Future<Result<Paged<VehicleDocument>>> search(DocumentQuery query) async =>
      (await _api.get('/v1/documents', query: query.toQuery()))
          .map((j) => Paged.fromJson(asMap(j), VehicleDocument.fromJson));

  Future<Result<DocumentStats>> stats() async =>
      (await _api.get('/v1/documents/summary')).map((j) => DocumentStats.fromJson(asMap(j)));

  Future<Result<VehicleDocument>> upload(int vehicleId, DocumentDraft draft, PickedFile file) async =>
      (await _api.upload('/v1/vehicles/$vehicleId/documents',
              bytes: file.bytes, fileName: file.name, fields: draft.toFields()))
          .map((j) => VehicleDocument.fromJson(asMap(j)));

  Future<Result<VehicleDocument>> update(int id, DocumentDraft draft, {required int version}) async =>
      (await _api.put('/v1/documents/$id', body: draft.toJson(version: version)))
          .map((j) => VehicleDocument.fromJson(asMap(j)));

  Future<Result<VehicleDocument>> replaceFile(int id, PickedFile file) async =>
      (await _api.upload('/v1/documents/$id/file', bytes: file.bytes, fileName: file.name))
          .map((j) => VehicleDocument.fromJson(asMap(j)));

  Future<Result<Uint8List>> fileBytes(int id) => _api.download('/v1/documents/$id/file');

  Future<Result<void>> delete(int id) async => (await _api.delete('/v1/documents/$id')).map<void>((_) {});
}

/// `DocumentAlert` schema: an expired or expiring-soon document (dashboard to-do).
class DocumentAlert {
  const DocumentAlert({
    required this.id,
    required this.vehicleId,
    required this.vehicleNumber,
    required this.type,
    required this.title,
    required this.expiryDate,
    required this.expiryStatus,
    required this.daysUntilExpiry,
  });

  factory DocumentAlert.fromJson(Map<String, dynamic> j) => DocumentAlert(
        id: asInt(j['id']),
        vehicleId: asInt(j['vehicleId']),
        vehicleNumber: asStringOrNull(j['vehicleNumber']),
        type: DocumentType.fromApi(j['type']),
        title: asStringOrNull(j['title']),
        expiryDate: asDate(j['expiryDate']),
        expiryStatus: ExpiryStatus.fromApi(j['expiryStatus']),
        daysUntilExpiry: asIntOrNull(j['daysUntilExpiry']),
      );

  final int id;
  final int vehicleId;
  final String? vehicleNumber;
  final DocumentType type;
  final String? title;
  final DateTime? expiryDate;
  final ExpiryStatus expiryStatus;
  final int? daysUntilExpiry;

  String get displayName => (title != null && title!.isNotEmpty) ? title! : type.label;
}
