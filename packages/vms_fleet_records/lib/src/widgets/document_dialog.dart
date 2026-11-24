import 'package:material_ui/material_ui.dart';
import 'package:vms_core/vms_core.dart';
import 'package:vms_design_system/vms_design_system.dart';

import '../documents.dart';

/// Upload a document for a vehicle, or (with [existing]) edit its details —
/// typically a renewal's new expiry date. Resolves to the saved document, or
/// null when cancelled.
Future<VehicleDocument?> showDocumentDialog(
  BuildContext context, {
  required DocumentRepository repository,
  required int vehicleId,
  required String vehicleNumber,
  VehicleDocument? existing,
  DocumentType? initialType,
}) =>
    showDialog<VehicleDocument>(
      context: context,
      builder: (_) => _DocumentDialog(
        repository: repository,
        vehicleId: vehicleId,
        vehicleNumber: vehicleNumber,
        existing: existing,
        initialType: initialType,
      ),
    );

/// Accepted uploads (the API checks the bytes, this only guides the chooser).
const documentFileAccept = '.pdf,.jpg,.jpeg,.png,.webp,application/pdf,image/jpeg,image/png,image/webp';
const _maxBytes = 5 * 1024 * 1024;

class _DocumentDialog extends StatefulWidget {
  const _DocumentDialog({
    required this.repository,
    required this.vehicleId,
    required this.vehicleNumber,
    required this.existing,
    required this.initialType,
  });

  final DocumentRepository repository;
  final int vehicleId;
  final String vehicleNumber;
  final VehicleDocument? existing;
  final DocumentType? initialType;

  @override
  State<_DocumentDialog> createState() => _DocumentDialogState();
}

class _DocumentDialogState extends State<_DocumentDialog> {
  late DocumentType? _type = widget.existing?.type ?? widget.initialType;
  late final _title = TextEditingController(text: widget.existing?.title ?? '');
  late final _number = TextEditingController(text: widget.existing?.documentNumber ?? '');
  late final _notes = TextEditingController(text: widget.existing?.notes ?? '');
  late DateTime? _issue = widget.existing?.issueDate;
  late DateTime? _expiry = widget.existing?.expiryDate;
  PickedFile? _file;
  bool _saving = false;
  Map<String, String> _errors = const {};
  String? _formError;

  bool get _isEdit => widget.existing != null;

  @override
  void dispose() {
    _title.dispose();
    _number.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _chooseFile() async {
    final picked = await pickFile(accept: documentFileAccept);
    if (picked == null || !mounted) return;
    setState(() {
      _file = picked;
      _errors = {..._errors}..remove('file');
      if (picked.size > _maxBytes) {
        _errors = {..._errors, 'file': 'This file is ${formatFileSize(picked.size)}. Keep it under 5 MB.'};
      }
    });
  }

  /// Checks the server would reject anyway, so the user sees them at once.
  Map<String, String> _localErrors() {
    final e = <String, String>{};
    if (_type == null) e['type'] = 'Choose the document type.';
    if (_type == DocumentType.other && _title.text.trim().isEmpty) {
      e['title'] = 'Name this document, like Smoke emission certificate.';
    }
    if (_type != null && _type!.expires && _expiry == null) {
      e['expiryDate'] = 'Enter the expiry date printed on the paper.';
    } else if (_issue != null && _expiry != null && _expiry!.isBefore(_issue!)) {
      e['expiryDate'] = 'The expiry date must be on or after the issue date.';
    }
    if (!_isEdit && _file == null) {
      e['file'] = 'Choose a PDF or a photo of the document.';
    } else if (!_isEdit && _file!.size > _maxBytes) {
      e['file'] = 'Keep the file under 5 MB.';
    }
    return e;
  }

  Future<void> _save() async {
    final local = _localErrors();
    if (local.isNotEmpty) {
      setState(() => _errors = local);
      return;
    }
    setState(() {
      _saving = true;
      _errors = const {};
      _formError = null;
    });
    final draft = DocumentDraft(
      type: _type!,
      title: _title.text,
      documentNumber: _number.text,
      issueDate: _issue,
      expiryDate: _expiry,
      notes: _notes.text,
    );
    final result = _isEdit
        ? await widget.repository.update(widget.existing!.id, draft, version: widget.existing!.version)
        : await widget.repository.upload(widget.vehicleId, draft, _file!);
    if (!mounted) return;
    switch (result) {
      case Ok(:final value):
        Navigator.of(context).pop(value);
      case Err(:final error):
        setState(() {
          _saving = false;
          _errors = error.fieldErrors;
          _formError = switch (error.code) {
            'VALIDATION_FAILED' => null,
            'STALE_VERSION' => 'Someone else changed this document. Close and open it again.',
            'FILE_TOO_LARGE' => 'The file is too large. Upload a scan or photo under 5 MB.',
            _ => error.message,
          };
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    return VmsDialog(
      title: _isEdit ? 'Edit ${widget.existing!.displayName}' : 'Upload document',
      subtitle: widget.vehicleNumber,
      actions: [
        VmsButton(
          label: 'Cancel',
          variant: VmsButtonVariant.secondary,
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
        ),
        VmsButton(label: _isEdit ? 'Save changes' : 'Upload', loading: _saving, onPressed: _saving ? null : _save),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_formError != null) ...[
            ErrorBanner(message: _formError!),
            const SizedBox(height: VmsSpace.s4),
          ],
          VmsSelect<DocumentType>(
            label: 'Document type',
            hint: 'Choose a type',
            value: _type,
            error: _errors['type'],
            options: [for (final t in DocumentType.values) VmsOption(t, t.label)],
            onChanged: _saving ? null : (t) => setState(() => _type = t),
          ),
          if (_type == DocumentType.other) ...[
            const SizedBox(height: VmsSpace.s3),
            VmsTextField(
              label: 'Title',
              controller: _title,
              hint: 'Smoke emission certificate',
              error: _errors['title'],
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
          const SizedBox(height: VmsSpace.s3),
          VmsTextField(
            label: 'Document number',
            optional: true,
            controller: _number,
            hint: 'As printed, e.g. GDIC/MV/2026/88412',
            error: _errors['documentNumber'],
          ),
          const SizedBox(height: VmsSpace.s3),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: VmsDateField(
                  label: 'Issue date',
                  optional: true,
                  value: _issue,
                  lastDate: today,
                  error: _errors['issueDate'],
                  onChanged: (d) => setState(() => _issue = d),
                ),
              ),
              const SizedBox(width: VmsSpace.s3),
              Expanded(
                child: VmsDateField(
                  label: 'Expiry date',
                  optional: !(_type?.expires ?? false),
                  value: _expiry,
                  error: _errors['expiryDate'],
                  helper: (_type?.expires ?? false) ? 'Needed to warn you before it runs out.' : null,
                  onChanged: (d) => setState(() => _expiry = d),
                ),
              ),
            ],
          ),
          const SizedBox(height: VmsSpace.s3),
          VmsTextField(
            label: 'Notes',
            optional: true,
            controller: _notes,
            hint: 'Anything the next person should know',
            error: _errors['notes'],
            textInputAction: TextInputAction.done,
          ),
          if (!_isEdit) ...[
            const SizedBox(height: VmsSpace.s3),
            const FieldLabel(text: 'File'),
            Row(
              children: [
                VmsButton(
                  label: _file == null ? 'Choose file' : 'Choose another',
                  icon: Icons.attach_file,
                  variant: VmsButtonVariant.secondary,
                  onPressed: _saving ? null : _chooseFile,
                ),
                const SizedBox(width: VmsSpace.s3),
                Expanded(
                  child: Text(
                    _file == null ? 'PDF, JPG, PNG or WEBP, up to 5 MB' : '${_file!.name} · ${formatFileSize(_file!.size)}',
                    style: _file == null ? VmsText.meta : VmsText.secondary,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            FieldMessage(error: _errors['file']),
          ],
        ],
      ),
    );
  }
}
