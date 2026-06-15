// lib/features/info/widgets/info_form.dart

import 'package:flutter/material.dart';

import '../../../core/constants/strings.dart';
import '../../../shared_widgets/custom_button.dart';
import '../../../shared_widgets/glassmorphic_card.dart';

/// A form used to create or edit an Info entry.
///
/// Displays title and content fields inside a GlassmorphicCard.
/// If [initialTitle] and [initialContent] are provided, the form is in
/// edit mode; otherwise it is in create mode.
class InfoForm extends StatefulWidget {
  const InfoForm({
    super.key,
    this.initialTitle,
    this.initialContent,
    required this.onSave,
    this.isSaving = false,
  });

  final String? initialTitle;
  final String? initialContent;
  final ValueChanged<({String title, String content})> onSave;
  final bool isSaving;

  @override
  State<InfoForm> createState() => _InfoFormState();
}

class _InfoFormState extends State<InfoForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _contentCtrl;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.initialTitle ?? '');
    _contentCtrl = TextEditingController(text: widget.initialContent ?? '');
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      widget.onSave((
        title: _titleCtrl.text.trim(),
        content: _contentCtrl.text.trim(),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEdit = widget.initialTitle != null;

    return GlassmorphicCard(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isEdit ? Strings.infoEditEntry : Strings.infoAddNew,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: Strings.infoTitleField,
                hintText: 'Enter a title…',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return Strings.infoTitleValidation;
                }
                return null;
              },
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _contentCtrl,
              decoration: const InputDecoration(
                labelText: Strings.infoContentField,
                hintText: 'Write something…',
              ),
              maxLines: 6,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 24),
            CustomButton(
              label: isEdit ? Strings.save : Strings.save,
              icon: Icons.check,
              isLoading: widget.isSaving,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}