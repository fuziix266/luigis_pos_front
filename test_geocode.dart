
import 'package:dio/dio.dart';

void main() async {
  String $address = 'Cancha Rayada 4367';
  final url = 'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent("$address, Arica, Chile")}&format=json&limit=1';
  print('URL: ' + url);
  final dio = Dio();
  final response = await dio.get(url, options: Options(headers: {'User-Agent': 'LuigisPosApp/2.0'}));
  print(response.data);
}

