import 'package:dio/dio.dart';

void main() async {
  final dio = Dio();
  const url =
      'https://nominatim.openstreetmap.org/search?q=Cancha+Rayada+4367,+Arica,+Chile&format=json&limit=1';
  final response = await dio.get(
    url,
    options: Options(headers: {'User-Agent': 'LuigisPosApp/2.0'}),
  );
  if (response.data is List && (response.data as List).isNotEmpty) {
    print('lat: ${response.data[0]['lat']}');
    print('lon: ${response.data[0]['lon']}');
  } else {
    print('no results');
  }
}
