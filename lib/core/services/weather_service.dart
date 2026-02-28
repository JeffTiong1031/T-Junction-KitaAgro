import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  final String apiKey = '10790a7ee7e0a845f83a65708fae3d67'; // Replace with your key

  Future<Map<String, dynamic>> getWindData(double lat, double lon) async {
    final String url = 
        'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'speed': data['wind']['speed'] ?? 0.0, // Wind speed in meters/sec
          'deg': (data['wind']['deg'] ?? 0).toDouble(), // Wind direction in degrees
        };
      } else {
        return {'speed': 0.0, 'deg': 0.0};
      }
    } catch (e) {
      print("Weather fetch error: $e");
      return {'speed': 0.0, 'deg': 0.0};
    }
  }
}
