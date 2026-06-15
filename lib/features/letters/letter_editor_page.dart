// lib/features/letters/letter_editor_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/strings.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/glassmorphism.dart';
import '../../shared_widgets/custom_button.dart';
import 'bloc/letters_cubit.dart';
import 'bloc/letters_state.dart';

/// Dedicated page for creating or editing a letter.
///
/// If a [LetterData] is passed as route argument, the page is in edit mode;
/// otherwise it is in create mode.  A glassmorphic character and word counter
/// is displayed at the bottom.
class LetterEditorPage extends StatefulWidget {
  const LetterEditorPage({super.key});

  @override
  State<LetterEditorPage> createState() => _LetterEditorPageState();
}

class _LetterEditorPageState extends State<LetterEditorPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _contentCtrl;
  int _charCount = 0;
  int _wordCount = 0;
  bool _isSaving = false;

  LetterData? _existing;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController();
    _contentCtrl = TextEditingController();
    _titleCtrl.addListener(_updateCounts);
    _contentCtrl.addListener(_updateCounts);

    // Grab the argument after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is LetterData) {
        setState(() {
          _existing = args;
          _titleCtrl.text = _existing!.title;
          _contentCtrl.text = _existing!.content;
        });
        _updateCounts();
      }
    });
  }

  @override
  void dispose() {
    _titleCtrl.removeListener(_updateCounts);
    _contentCtrl.removeListener(_updateCounts);
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  void _updateCounts() {
    final title = _titleCtrl.text;
    final content = _contentCtrl.text;
    final combined = '$title $content';
    setState(() {
      _charCount = combined.length;
      _wordCount = combined.trim().isEmpty
          ? 0
          : combined.trim().split(RegExp(r'\s+')).length;
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);
    final cubit = context.read<LettersCubit>();
    final title = _titleCtrl.text.trim();
    final content = _contentCtrl.text.trim();

    try {
      if (_existing != null) {
        await cubit.update(id: _existing!.id, title: title, content: content);
      } else {
        await cubit.add(title: title, content: content);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save letter.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = _existing != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final glassBg = isDark
        ? AppColors.primary.withOpacity(0.12)
        : AppColors.primary.withOpacity(0.08);

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(isEdit ? Strings.lettersEdit : Strings.lettersAdd),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: CustomButton(
              label: Strings.save,
              icon: Icons.check,
              isLoading: _isSaving,
              onPressed: _submit,
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _titleCtrl,
                      decoration: const InputDecoration(
                        labelText: Strings.lettersTitleField,
                        hintText: 'Dear …',
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty
                              ? Strings.lettersTitleValidation
                              : null,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _contentCtrl,
                      decoration: const InputDecoration(
                        labelText: Strings.lettersContentField,
                        hintText: 'Write your letter…',
                      ),
                      maxLines: null,
                      minLines: 12,
                      keyboardType: TextInputType.multiline,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ],
                ),
              ),
            ),
            // Glassmorphic character / word counter footer
            GlassmorphicContainer(
              backgroundColor: glassBg,
              borderColor: AppColors.primary.withOpacity(0.3),
              borderRadius: BorderRadius.zero, // full width
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.text_fields,
                      size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    '$_charCount characters',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.short_text,
                      size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    '$_wordCount words',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}