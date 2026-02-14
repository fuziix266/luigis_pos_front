import 'package:go_router/go_router.dart';
import '../pages/login_page.dart';
import '../pages/home_page.dart';
import '../pages/new_order_page.dart';
import '../pages/orders_page.dart';
import '../pages/kitchen_page.dart';
import '../pages/delivery_page.dart';
import '../pages/history_page.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
    GoRoute(path: '/', builder: (_, __) => const HomePage()),
    GoRoute(path: '/new-order', builder: (_, __) => const NewOrderPage()),
    GoRoute(path: '/orders', builder: (_, __) => const OrdersPage()),
    GoRoute(path: '/kitchen', builder: (_, __) => const KitchenPage()),
    GoRoute(path: '/delivery', builder: (_, __) => const DeliveryPage()),
    GoRoute(path: '/history', builder: (_, __) => const HistoryPage()),
  ],
);
