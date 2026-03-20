import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'config/theme.dart';
import 'config/router.dart';
import 'data/api_client.dart';
import 'blocs/auth/auth_bloc.dart';
import 'blocs/catalog/catalog_bloc.dart';
import 'blocs/orders/orders_bloc.dart';

import 'services/sound_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LuigisPosApp());
}

class LuigisPosApp extends StatelessWidget {
  const LuigisPosApp({super.key});

  @override
  Widget build(BuildContext context) {
    final apiClient = ApiClient();
    final soundService = SoundService();

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AuthBloc(apiClient)),
        BlocProvider(create: (_) => CatalogBloc(apiClient)..add(LoadCatalog())),
        BlocProvider(create: (_) => OrdersBloc(apiClient, soundService)),
      ],
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Guard orientation calls to avoid infinite loops and catch unsupported platforms
          final isNarrow = constraints.maxWidth < 900;

          Future.microtask(() async {
            try {
              if (isNarrow) {
                await SystemChrome.setPreferredOrientations([
                  DeviceOrientation.portraitUp,
                  DeviceOrientation.portraitDown,
                ]);
              } else {
                await SystemChrome.setPreferredOrientations([
                  DeviceOrientation.landscapeLeft,
                  DeviceOrientation.landscapeRight,
                ]);
              }
            } catch (e) {
              // Silently fail on platforms that don't support orientation locking (like desktop web)
            }
          });

          return MaterialApp.router(
            title: "Luigi's Pizza POS",
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            scrollBehavior: const AppScrollBehavior(),
            routerConfig: appRouter,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('es', 'ES'),
              Locale('en', 'US'),
            ],
          );
        },
      ),
    );
  }
}

class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
      };
}
