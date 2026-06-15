// lib/features/settings/settings_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/strings.dart';
import '../../shared_widgets/loading_indicator.dart';
import '../auth/bloc/auth_cubit.dart';
import '../auth/widgets/pin_input_widget.dart';
import 'bloc/settings_cubit.dart';
import 'bloc/settings_state.dart';
import 'widgets/settings_section.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text(Strings.settingsTitle),
      ),
      body: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          if (state.isSaving &&
              state.yourName.isEmpty &&
              state.partnerName.isEmpty) {
            return const LoadingIndicator(message: Strings.loading);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(0, 16, 0, 40),
            child: Column(
              children: [
                _buildProfileSection(context, state),
                _buildBirthdaysSection(context, state),
                _buildLoveLanguagesSection(context, state),
                _buildThemeSection(context, state),
                _buildRelationshipSection(context, state),
                _buildSecuritySection(context),
                _buildDataSection(context, state),
              ],
            ),
          );
        },
      ),
    );
  }

  // ---------- Profile section ----------
  Widget _buildProfileSection(BuildContext context, SettingsState state) {
    return SettingsSection(
      title: 'Profile',
      children: [
        ListTile(
          leading: const Icon(Icons.person),
          title: const Text(Strings.settingsYourName),
          subtitle: Text(state.yourName.isEmpty ? 'Not set' : state.yourName),
          onTap: () => _editText(
            context,
            initialValue: state.yourName,
            label: Strings.settingsYourName,
            onSave: (v) => context.read<SettingsCubit>().updateYourName(v),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.favorite_outline),
          title: const Text(Strings.settingsPartnerName),
          subtitle:
              Text(state.partnerName.isEmpty ? 'Not set' : state.partnerName),
          onTap: () => _editText(
            context,
            initialValue: state.partnerName,
            label: Strings.settingsPartnerName,
            onSave: (v) => context.read<SettingsCubit>().updatePartnerName(v),
          ),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.wc),
          title: const Text(Strings.settingsYourGender),
          subtitle:
              Text(state.yourGender.isEmpty ? 'Not set' : state.yourGender),
          onTap: () => _selectGender(
            context,
            current: state.yourGender,
            onSelected: (g) => context.read<SettingsCubit>().updateYourGender(g),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.wc_outlined),
          title: const Text(Strings.settingsPartnerGender),
          subtitle: Text(
              state.partnerGender.isEmpty ? 'Not set' : state.partnerGender),
          onTap: () => _selectGender(
            context,
            current: state.partnerGender,
            onSelected: (g) =>
                context.read<SettingsCubit>().updatePartnerGender(g),
          ),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.camera_alt),
          title: const Text(Strings.settingsProfilePicture),
          subtitle: const Text('Tap to change your profile picture'),
          onTap: () =>
              context.read<SettingsCubit>().updateProfilePicture('your'),
        ),
        ListTile(
          leading: const Icon(Icons.camera_alt_outlined),
          title: const Text(Strings.settingsPartnerProfilePicture),
          subtitle: const Text('Tap to change partner picture'),
          onTap: () =>
              context.read<SettingsCubit>().updateProfilePicture('partner'),
        ),
      ],
    );
  }

  // ---------- Birthdays section ----------
  Widget _buildBirthdaysSection(BuildContext context, SettingsState state) {
    return SettingsSection(
      title: 'Birthdays',
      children: [
        ListTile(
          leading: const Icon(Icons.cake),
          title: const Text('Your Birthday'),
          subtitle: Text(state.yourBirthday == null
              ? 'Not set'
              : '${_monthName(state.yourBirthday!.month)} ${state.yourBirthday!.day}'),
          onTap: () => _pickBirthday(context, isYour: true),
        ),
        ListTile(
          leading: const Icon(Icons.cake_outlined),
          title: const Text('Partner\'s Birthday'),
          subtitle: Text(state.partnerBirthday == null
              ? 'Not set'
              : '${_monthName(state.partnerBirthday!.month)} ${state.partnerBirthday!.day}'),
          onTap: () => _pickBirthday(context, isYour: false),
        ),
      ],
    );
  }

  // ---------- Love Languages section ----------
  Widget _buildLoveLanguagesSection(BuildContext context, SettingsState state) {
    final display = state.loveLanguages.isEmpty
        ? 'Not set'
        : state.loveLanguages.join(', ');
    return SettingsSection(
      title: 'Love Languages',
      children: [
        ListTile(
          leading: const Icon(Icons.favorite),
          title: const Text('Edit Love Languages'),
          subtitle: Text(display),
          onTap: () => _openLoveLanguagesEditor(context),
        ),
      ],
    );
  }

  // ---------- Theme section ----------
  Widget _buildThemeSection(BuildContext context, SettingsState state) {
    return SettingsSection(
      title: 'Appearance',
      children: [
        RadioListTile<ThemeMode>(
          title: const Text('System Default'),
          value: ThemeMode.system,
          groupValue: state.themeMode,
          onChanged: (mode) {
            if (mode != null)
              context.read<SettingsCubit>().updateThemeMode(mode);
          },
          activeColor: Theme.of(context).colorScheme.primary,
        ),
        RadioListTile<ThemeMode>(
          title: const Text('Light'),
          value: ThemeMode.light,
          groupValue: state.themeMode,
          onChanged: (mode) {
            if (mode != null)
              context.read<SettingsCubit>().updateThemeMode(mode);
          },
          activeColor: Theme.of(context).colorScheme.primary,
        ),
        RadioListTile<ThemeMode>(
          title: const Text('Dark'),
          value: ThemeMode.dark,
          groupValue: state.themeMode,
          onChanged: (mode) {
            if (mode != null)
              context.read<SettingsCubit>().updateThemeMode(mode);
          },
          activeColor: Theme.of(context).colorScheme.primary,
        ),
      ],
    );
  }

  // ---------- Relationship section ----------
  Widget _buildRelationshipSection(BuildContext context, SettingsState state) {
    final startDate = state.relationshipStart;
    final formatted =
        startDate == DateTime.fromMillisecondsSinceEpoch(0, isUtc: true)
            ? 'Not set'
            : '${startDate.day}/${startDate.month}/${startDate.year}';

    return SettingsSection(
      title: 'Relationship',
      children: [
        ListTile(
          leading: const Icon(Icons.date_range),
          title: const Text('Start Date'),
          subtitle: Text(formatted),
          onTap: () => _pickDate(context, startDate),
        ),
      ],
    );
  }

  // ---------- Security section ----------
  Widget _buildSecuritySection(BuildContext context) {
    return SettingsSection(
      title: 'Security',
      children: [
        ListTile(
          leading: const Icon(Icons.lock_outline),
          title: const Text(Strings.settingsChangePin),
          subtitle: const Text('Change your 4‑digit PIN'),
          onTap: () => _showPinChangeDialog(context),
        ),
      ],
    );
  }

  // ---------- Data section ----------
  Widget _buildDataSection(BuildContext context, SettingsState state) {
    return SettingsSection(
      title: 'Data',
      children: [
        if (state.exportMessage != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              state.exportMessage!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: state.exportMessage!.contains('success')
                        ? Colors.green
                        : Colors.red,
                  ),
            ),
          ),
        ListTile(
          leading: const Icon(Icons.file_download_outlined),
          title: const Text(Strings.settingsExportData),
          subtitle: const Text(Strings.settingsExportWarning),
          onTap: () => _confirmExport(context),
        ),
      ],
    );
  }

  // -------- Helper dialogs --------
  void _editText(
    BuildContext context, {
    required String initialValue,
    required String label,
    required ValueChanged<String> onSave,
  }) {
    showDialog<String>(
      context: context,
      builder: (ctx) => _EditTextDialog(
        initialValue: initialValue,
        label: label,
      ),
    ).then((result) {
      if (result != null && result.isNotEmpty) {
        onSave(result);
      }
    });
  }

  Future<void> _selectGender(
    BuildContext context, {
    required String current,
    required ValueChanged<String> onSelected,
  }) async {
    final genders = [
      'Male',
      'Female',
      'Non‑binary',
      'Other',
      'Prefer not to say'
    ];
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Select Gender'),
        children: genders.map((g) {
          return SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, g),
            child: Row(
              children: [
                if (g == current)
                  const Icon(Icons.check, size: 18)
                else
                  const SizedBox(width: 18),
                const SizedBox(width: 12),
                Text(g),
              ],
            ),
          );
        }).toList(),
      ),
    );
    if (result != null) {
      onSelected(result);
    }
  }

  Future<void> _pickDate(BuildContext context, DateTime current) async {
    final initialDate =
        current == DateTime.fromMillisecondsSinceEpoch(0, isUtc: true)
            ? DateTime.now()
            : current;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1950),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && context.mounted) {
      context.read<SettingsCubit>().updateRelationshipStart(picked);
    }
  }

  Future<void> _pickBirthday(BuildContext context,
      {required bool isYour}) async {
    final cubit = context.read<SettingsCubit>();
    final state = cubit.state;
    final current = isYour ? state.yourBirthday : state.partnerBirthday;

    final now = DateTime.now();
    final initialDate = current != null
        ? DateTime(now.year, current.month, current.day)
        : DateTime(now.year, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      helpText: isYour ? 'Your Birthday' : 'Partner\'s Birthday',
    );
    if (picked != null && context.mounted) {
      // Store the full picked date (including real year) for age calculations.
      // The homepage will only display the month and day.
      if (isYour) {
        cubit.updateYourBirthday(picked);
      } else {
        cubit.updatePartnerBirthday(picked);
      }
    }
  }

  void _showPinChangeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => _PinChangeDialog(),
    );
  }

  void _openLoveLanguagesEditor(BuildContext context) {
    final cubit = context.read<SettingsCubit>();
    showDialog(
      context: context,
      builder: (ctx) => _LoveLanguagesEditorDialog(
        selectedLanguages: List<String>.from(cubit.state.loveLanguages),
        onSave: (languages) {
          cubit.updateLoveLanguages(languages);
        },
      ),
    );
  }

  void _confirmExport(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(Strings.settingsExportData),
        content: const Text(Strings.settingsExportWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(Strings.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<SettingsCubit>().exportData();
            },
            child: const Text(Strings.save),
          ),
        ],
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month];
  }
}

// ---------- Reusable edit-text dialog ----------
class _EditTextDialog extends StatefulWidget {
  const _EditTextDialog({required this.initialValue, required this.label});
  final String initialValue;
  final String label;

  @override
  State<_EditTextDialog> createState() => _EditTextDialogState();
}

class _EditTextDialogState extends State<_EditTextDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.label),
      content: TextField(
        controller: _controller,
        decoration: InputDecoration(hintText: 'Enter ${widget.label}…'),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(Strings.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _controller.text.trim()),
          child: const Text(Strings.save),
        ),
      ],
    );
  }
}

// ---------- PIN change dialog ----------
class _PinChangeDialog extends StatefulWidget {
  @override
  State<_PinChangeDialog> createState() => _PinChangeDialogState();
}

class _PinChangeDialogState extends State<_PinChangeDialog> {
  int _step = 0;
  String _oldPin = '';
  String _newPin = '';
  String? _error;

  void _onPinComplete(String pin) {
    setState(() => _error = null);
    if (_step == 0) {
      _oldPin = pin;
      setState(() => _step = 1);
    } else if (_step == 1) {
      _newPin = pin;
      setState(() => _step = 2);
    } else {
      if (_newPin != pin) {
        setState(() => _error = 'PINs do not match.');
        return;
      }
      final authCubit = context.read<AuthCubit>();
      authCubit.changePin(
        oldPin: _oldPin,
        newPin: _newPin,
        confirmNewPin: pin,
      );
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN changed successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    String title;
    switch (_step) {
      case 0:
        title = 'Enter current PIN';
        break;
      case 1:
        title = 'Enter new PIN';
        break;
      default:
        title = 'Confirm new PIN';
        break;
    }

    return AlertDialog(
      contentPadding: EdgeInsets.zero,
      content: PinInputWidget(
        title: title,
        errorMessage: _error,
        onPinComplete: _onPinComplete,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(Strings.cancel),
        ),
      ],
    );
  }
}

// ---------- Love languages editor dialog – checkbox list ----------
class _LoveLanguagesEditorDialog extends StatefulWidget {
  const _LoveLanguagesEditorDialog({
    required this.selectedLanguages,
    required this.onSave,
  });

  final List<String> selectedLanguages;
  final ValueChanged<List<String>> onSave;

  @override
  State<_LoveLanguagesEditorDialog> createState() =>
      _LoveLanguagesEditorDialogState();
}

class _LoveLanguagesEditorDialogState
    extends State<_LoveLanguagesEditorDialog> {
  late List<String> _selected;

  static const _allLanguages = [
    'Words of Affirmation',
    'Acts of Service',
    'Receiving Gifts',
    'Quality Time',
    'Physical Touch',
  ];

  @override
  void initState() {
    super.initState();
    _selected = List<String>.from(widget.selectedLanguages);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Love Languages'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _allLanguages.map((lang) {
            final isChecked = _selected.contains(lang);
            return CheckboxListTile(
              title: Text(lang),
              value: isChecked,
              onChanged: (checked) {
                setState(() {
                  if (checked == true) {
                    _selected.add(lang);
                  } else {
                    _selected.remove(lang);
                  }
                });
              },
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(Strings.cancel),
        ),
        ElevatedButton(
          onPressed: () {
            final ordered = _allLanguages
                .where((l) => _selected.contains(l))
                .toList();
            widget.onSave(ordered);
            Navigator.pop(context);
          },
          child: const Text(Strings.save),
        ),
      ],
    );
  }
}