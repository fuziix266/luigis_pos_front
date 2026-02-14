import 'package:dio/dio.dart';

class ApiClient {
  static const String baseUrl = 'http://localhost:3001';
  late final Dio _dio;
  String? _token;

  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_token != null) {
            options.headers['Authorization'] = 'Bearer $_token';
          }
          return handler.next(options);
        },
      ),
    );
  }

  void setToken(String token) => _token = token;
  void clearToken() => _token = null;

  // ===== AUTH =====
  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await _dio.post(
      '/api/auth/login',
      data: {'username': username, 'password': password},
    );
    return response.data;
  }

  Future<Map<String, dynamic>> getMe() async {
    final response = await _dio.get('/api/auth/me');
    return response.data;
  }

  // ===== CATALOG =====
  Future<List<dynamic>> getPizzas() async {
    final response = await _dio.get('/api/catalog/pizzas');
    return response.data['data'] ?? [];
  }

  Future<Map<String, dynamic>> getPizzaById(int id) async {
    final response = await _dio.get('/api/catalog/pizzas/$id');
    return response.data['data'] ?? {};
  }

  Future<List<dynamic>> getIngredients() async {
    final response = await _dio.get('/api/catalog/ingredients');
    return response.data['data'] ?? [];
  }

  Future<List<dynamic>> getDrinks() async {
    final response = await _dio.get('/api/catalog/drinks');
    return response.data['data'] ?? [];
  }

  Future<List<dynamic>> getSides() async {
    final response = await _dio.get('/api/catalog/sides');
    return response.data['data'] ?? [];
  }

  Future<List<dynamic>> getSizes() async {
    final response = await _dio.get('/api/catalog/sizes');
    return response.data['data'] ?? [];
  }

  Future<List<dynamic>> getPromos() async {
    final response = await _dio.get('/api/catalog/promos');
    return response.data['data'] ?? [];
  }

  Future<Map<String, dynamic>?> getPromoToday() async {
    final response = await _dio.get('/api/catalog/promos/today');
    return response.data['data'];
  }

  // ===== ORDERS =====
  Future<List<dynamic>> getActiveOrders() async {
    final response = await _dio.get('/api/orders');
    return response.data['data'] ?? [];
  }

  Future<Map<String, dynamic>> getOrderById(int id) async {
    final response = await _dio.get('/api/orders/$id');
    return response.data['data'] ?? {};
  }

  Future<Map<String, dynamic>> createOrder(Map<String, dynamic> data) async {
    final response = await _dio.post('/api/orders', data: data);
    return response.data['data'] ?? {};
  }

  Future<Map<String, dynamic>> updateOrder(
    int id,
    Map<String, dynamic> data,
  ) async {
    final response = await _dio.put('/api/orders/$id', data: data);
    return response.data['data'] ?? {};
  }

  Future<void> deleteOrder(int id) async {
    await _dio.delete('/api/orders/$id');
  }

  Future<Map<String, dynamic>> updateOrderStatus(int id, String status) async {
    final response = await _dio.patch(
      '/api/orders/$id/status',
      data: {'status': status},
    );
    return response.data['data'] ?? {};
  }

  // ===== SPECIALIZED VIEWS =====
  Future<List<dynamic>> getKitchenOrders() async {
    final response = await _dio.get('/api/orders/kitchen');
    return response.data['data'] ?? [];
  }

  Future<List<dynamic>> getDeliveryOrders() async {
    final response = await _dio.get('/api/orders/delivery');
    return response.data['data'] ?? [];
  }

  Future<List<dynamic>> getScheduledOrders() async {
    final response = await _dio.get('/api/orders/scheduled');
    return response.data['data'] ?? [];
  }

  Future<Map<String, dynamic>> getHistory({
    String? status,
    String? paymentMethod,
    String? deliveryType,
    String? date,
  }) async {
    final params = <String, dynamic>{};
    if (status != null) params['status'] = status;
    if (paymentMethod != null) params['payment_method'] = paymentMethod;
    if (deliveryType != null) params['delivery_type'] = deliveryType;
    if (date != null) params['date'] = date;

    final response = await _dio.get(
      '/api/orders/history',
      queryParameters: params,
    );
    return response.data['data'] ?? {};
  }

  // ===== DELIVERY & ESTIMATION =====
  Future<Map<String, dynamic>> geocodeAddress(String address) async {
    final response = await _dio.post(
      '/api/delivery/geocode',
      data: {'address': address},
    );
    return response.data['data'] ?? {};
  }

  Future<Map<String, dynamic>> getTimeEstimation() async {
    final response = await _dio.get('/api/estimation/time');
    return response.data['data'] ?? {};
  }

  // ===== CONFIG =====
  Future<Map<String, dynamic>> getConfig() async {
    final response = await _dio.get('/api/config');
    return response.data['data'] ?? {};
  }

  Future<void> updateConfig(String key, String value) async {
    await _dio.put('/api/config/$key', data: {'value': value});
  }
}
