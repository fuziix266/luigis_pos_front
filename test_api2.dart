
import 'package:dio/dio.dart';

void main() async {
  final dio = Dio();
  final url = 'https://nominatim.openstreetmap.org/search?q=Cancha+Rayada+4367,+Arica,+Chile&format=json&limit=1';
  final response = await dio.get(
    url,
    options: Options(headers: {'User-Agent': 'LuigisPosApp/2.0'}),
  );
  if (response.data is List && (response.data as List).isNotEmpty) {
    print('lat: ' + response.data[0]['lat'].toString());
    print('lon: ' + response.data[0]['lon'].toString());
  } else {
    print('no results');
  }
}

