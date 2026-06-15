import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/strings.dart';
import 'bloc/info_cubit.dart';
import 'widgets/info_form.dart';

/// Full‑page form for adding a new Info entry.
/// Pops back to the list after saving.
class InfoAddPage extends StatelessWidget {
  const InfoAddPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text(Strings.infoAddNew),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: InfoForm(
            onSave: (data) {
              context.read<InfoCubit>().add(
                    title: data.title,
                    content: data.content,
                  );
              Navigator.of(context).pop();
            },
          ),
        ),
      ),
    );
  }
}