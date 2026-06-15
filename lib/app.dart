import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/heart_text.dart';
import 'data/database/database.dart';
import 'data/local_storage/secure_storage_service.dart';
import 'data/local_storage/shared_prefs_service.dart';
import 'data/repositories/gallery_repository.dart';
import 'data/repositories/info_repository.dart';
import 'data/repositories/letter_repository.dart';
import 'data/repositories/reminder_repository.dart';
import 'data/repositories/settings_repository.dart';
import 'features/auth/bloc/auth_cubit.dart';
import 'features/auth/bloc/auth_state.dart';
import 'features/auth/pin_screen.dart';
import 'features/gallery/album_detail_page.dart';
import 'features/gallery/bloc/gallery_cubit.dart';
import 'features/gallery/gallery_page.dart';
import 'features/home/bloc/home_cubit.dart';
import 'features/home/home_page.dart';
import 'features/info/bloc/info_cubit.dart';
import 'features/info/info_add_page.dart';
import 'features/info/info_detail_page.dart';
import 'features/info/info_list_page.dart';
import 'features/letters/bloc/letters_cubit.dart';
import 'features/letters/letter_editor_page.dart';
import 'features/letters/letters_page.dart';
import 'features/lyric_video/lyric_video_page.dart';
import 'features/plans/bloc/plans_cubit.dart';
import 'features/plans/plans_page.dart';
import 'features/reminders/bloc/reminders_cubit.dart';
import 'features/reminders/reminders_page.dart';
import 'features/settings/bloc/settings_cubit.dart';
import 'features/settings/bloc/settings_state.dart';
import 'features/settings/settings_page.dart';
import 'shared_widgets/petal_background.dart';

class OurHeartApp extends StatefulWidget {
  const OurHeartApp({
    super.key,
    required this.database,
    required this.secureStorage,
    required this.sharedPrefs,
  });

  final AppDatabase database;
  final SecureStorageService secureStorage;
  final SharedPrefsService sharedPrefs;

  @override
  State<OurHeartApp> createState() => _OurHeartAppState();
}

class _OurHeartAppState extends State<OurHeartApp> with WidgetsBindingObserver {
  late final SettingsRepository _settingsRepo;
  late final AuthCubit _authCubit;
  DateTime? _backgroundTimestamp;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _settingsRepo = SettingsRepository(prefs: widget.sharedPrefs);
    _authCubit = AuthCubit(secureStorage: widget.secureStorage);
    _authCubit.initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authCubit.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _backgroundTimestamp = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      if (_backgroundTimestamp != null) {
        final elapsed =
            DateTime.now().difference(_backgroundTimestamp!).inSeconds;
        if (elapsed > AppConstants.authTimeoutSeconds) {
          _authCubit.lock();
        }
        _backgroundTimestamp = null;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AppDatabase>.value(value: widget.database),
        RepositoryProvider<SettingsRepository>.value(value: _settingsRepo),
        RepositoryProvider<SharedPrefsService>.value(
            value: widget.sharedPrefs),
        RepositoryProvider(
          create: (_) => InfoRepository(db: widget.database),
        ),
        RepositoryProvider(
          create: (_) => GalleryRepository(db: widget.database),
        ),
        RepositoryProvider(
          create: (_) => ReminderRepository(db: widget.database),
        ),
        RepositoryProvider(
          create: (_) => LetterRepository(db: widget.database),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthCubit>.value(value: _authCubit),
          BlocProvider(
            create: (ctx) => HomeCubit(
              settingsRepo: ctx.read<SettingsRepository>(),
            )..initialize(),
          ),
          BlocProvider(
            create: (ctx) => SettingsCubit(
              settingsRepo: ctx.read<SettingsRepository>(),
              database: ctx.read<AppDatabase>(),
              prefs: ctx.read<SharedPrefsService>(),
            )..load(),
          ),
          BlocProvider(
            create: (ctx) => InfoCubit(
              repository: ctx.read<InfoRepository>(),
            ),
          ),
          BlocProvider(
            create: (ctx) => PlansCubit(
              db: ctx.read<AppDatabase>(),
            ),
          ),
          BlocProvider(
            create: (ctx) => RemindersCubit(
              repository: ctx.read<ReminderRepository>(),
            ),
          ),
          BlocProvider(
            create: (ctx) => GalleryCubit(
              repository: ctx.read<GalleryRepository>(),
            ),
          ),
          BlocProvider(
            create: (ctx) => LettersCubit(
              repository: ctx.read<LetterRepository>(),
            ),
          ),
        ],
        child: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, authState) {
            final themeMode = context.select<SettingsCubit, ThemeMode>(
              (cubit) => cubit.state.themeMode,
            );

            return MaterialApp(
              title: AppConstants.appName,
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: themeMode,
              home: PetalBackground(child: _buildHome(authState)),
              onGenerateRoute: (settings) {
                final page = _getRoute(settings);
                if (page == null) return null;
                return MaterialPageRoute(
                  builder: (_) => PetalBackground(child: page),
                  settings: settings,
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildHome(AuthState authState) {
    if (authState.status == AuthStatus.authenticated) {
      return const HomePage();
    }
    return const PinScreen();
  }

  Widget? _getRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/settings':
        return const SettingsPage();
      case '/reminders':
        return const RemindersPage();
      case '/letters':
        return const LettersPage();
      case '/letters/add':
        return const LetterEditorPage();
      case '/letters/edit':
        return const LetterEditorPage();
      case '/info':
        return const InfoListPage();
      case '/info/detail':
        return const InfoDetailPage();
      case '/info/add':
        return const InfoAddPage();
      case '/plans':
        return const PlansPage();
      case '/gallery':
        return const GalleryPage();
      case '/gallery/album':
        return const AlbumDetailPage();
      case '/lyric_video':
        return const LyricVideoPage();
      default:
        return null;
    }
  }
}