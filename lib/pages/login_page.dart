import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../blocs/auth/auth_bloc.dart';
import '../config/theme.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _usernameController = TextEditingController(text: 'admin');
  final _passwordController = TextEditingController(text: 'password');
  bool _obscurePassword = true;
  late AnimationController _animController;
  ui.Image? _pizzaImage;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();
    _loadIcon();
  }

  Future<void> _loadIcon() async {
    final data = await rootBundle.load('assets/images/iconopizza.png');
    final bytes = data.buffer.asUint8List();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    if (mounted) {
      setState(() {
        _pizzaImage = frame.image;
      });
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          context.go('/');
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            // Gradient Background
            Container(
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
            ),
            // Animated Staggered Pattern Background
            AnimatedBuilder(
              animation: _animController,
              builder: (context, child) {
                return Positioned.fill(
                  child: Opacity(
                    opacity: 0.22, // Mayor visibilidad
                    child: _pizzaImage == null
                        ? const SizedBox.shrink()
                        : CustomPaint(
                            painter: _PatternPainter(
                              animationValue: _animController.value,
                              image: _pizzaImage!,
                            ),
                          ),
                  ),
                );
              },
            ),
            // Login Card
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Card(
                    elevation: 12,
                    shadowColor: Colors.black38,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Logo
                          Image.asset(
                            'assets/images/LogoPizzeria.png',
                            height: 120,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 16),
                          const SizedBox(height: 4),
                          Text(
                            'Sistema POS',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 32),

                          // Username
                          TextField(
                            controller: _usernameController,
                            decoration: const InputDecoration(
                              labelText: 'Usuario',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Password
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Contraseña',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Login Button
                          BlocBuilder<AuthBloc, AuthState>(
                            builder: (context, state) {
                              return SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: state is AuthLoading
                                      ? null
                                      : () {
                                          context.read<AuthBloc>().add(
                                                LoginRequested(
                                                  _usernameController.text,
                                                  _passwordController.text,
                                                ),
                                              );
                                        },
                                  child: state is AuthLoading
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text('Iniciar Sesión'),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PatternPainter extends CustomPainter {
  final double animationValue;
  final ui.Image image;

  _PatternPainter({required this.animationValue, required this.image});

  @override
  void paint(Canvas canvas, Size size) {
    const double iconSize = 90.0;
    const double spacing = 120.0;

    // El desplazamiento solo llega hasta un 'spacing' completo para que el loop sea invisible
    final double offsetX = animationValue * spacing;

    // Dibujamos un área ligeramente más grande que la pantalla para cubrir los bordes al moverse
    for (double y = -spacing; y < size.height + spacing; y += spacing) {
      final int rowIdx = (y / spacing).round();
      // Lógica de intercalado (Staggered)
      final double rowShift = (rowIdx % 2 != 0) ? spacing / 2 : 0;

      for (double x = -spacing * 2; x < size.width + spacing; x += spacing) {
        final double drawX = x + rowShift + offsetX;

        canvas.drawImageRect(
          image,
          Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
          Rect.fromLTWH(drawX, y, iconSize, iconSize),
          Paint()..filterQuality = FilterQuality.medium,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PatternPainter oldDelegate) => true;
}
