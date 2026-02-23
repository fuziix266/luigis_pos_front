import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'config/theme.dart';
import 'config/router.dart';
import 'data/api_client.dart';
import 'blocs/auth/auth_bloc.dart';
import 'blocs/catalog/catalog_bloc.dart';
import 'blocs/orders/orders_bloc.dart';

import 'services/sound_service.dart';

void main() {
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
      child: MaterialApp.router(
        title: "Luigi's Pizza POS",
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        scrollBehavior: const AppScrollBehavior(),
        routerConfig: appRouter,
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
