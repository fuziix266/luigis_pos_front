import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../blocs/auth/auth_bloc.dart';
import '../config/theme.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // 16:9 usually means landscape/desktop. 9:16 means portrait/mobile.
    // Adjusted breakpoint to 900 to ensure 4 columns only show on wider screens.
    final isWide = MediaQuery.of(context).size.width > 900;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthInitial) context.go('/login');
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF5A3C8C),
                Color(0xFF452D72),
                Color(0xFF301E50),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Header
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Image.asset(
                            'assets/images/LogoPizzeria.png',
                            height: 50,
                            fit: BoxFit.contain,
                          ),
                          Text(
                            'Sistema POS',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: Colors.white70),
                          ),
                        ],
                      ),
                      const Spacer(),
                      BlocBuilder<AuthBloc, AuthState>(
                        builder: (context, state) {
                          if (state is AuthAuthenticated) {
                            return Chip(
                              avatar: const Icon(Icons.person, size: 18),
                              label: Text(state.user['full_name'] ?? ''),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.logout, color: AppColors.error),
                        onPressed: () =>
                            context.read<AuthBloc>().add(LogoutRequested()),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Nuevo Pedido (botón grande)
                  _buildMainButton(context, isWide),

                  const SizedBox(height: 24),

                  // Grid de menú
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: isWide ? 4 : 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: isWide ? 1.0 : 0.85,
                      children: [
                        _menuCard(
                          context,
                          isWide,
                          Icons.receipt_long,
                          'Pedidos',
                          'Ver activos',
                          AppColors.info,
                          '/orders',
                        ),
                        _menuCard(
                          context,
                          isWide,
                          Icons.restaurant,
                          'Cocina',
                          'Monitor',
                          AppColors.error,
                          '/kitchen',
                        ),
                        _menuCard(
                          context,
                          isWide,
                          Icons.delivery_dining,
                          'Delivery',
                          'En camino',
                          AppColors.success,
                          '/delivery',
                        ),
                        _menuCard(
                          context,
                          isWide,
                          Icons.history,
                          'Historial',
                          'Ventas',
                          AppColors.warning,
                          '/history',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainButton(BuildContext context, bool isWide) {
    return Material(
      borderRadius: BorderRadius.circular(20),
      elevation: 4,
      shadowColor: AppColors.primary.withValues(alpha: 0.3),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.go('/new-order'),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            vertical: isWide ? 28 : 20,
            horizontal: 24,
          ),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_circle_outline, color: Colors.white, size: 32),
              SizedBox(width: 12),
              Text(
                'NUEVO PEDIDO',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menuCard(
    BuildContext context,
    bool isWide,
    IconData icon,
    String title,
    String subtitle,
    Color color,
    String route,
  ) {
    return Material(
      color:
          const Color(0xFF2D1B4E).withOpacity(0.4), // Morado muy oscuro y sutil
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => context.go(route),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Padding(
            padding: EdgeInsets.all(isWide ? 20 : 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, size: 32, color: color),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
