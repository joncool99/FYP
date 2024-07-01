import 'dart:convert';
import 'package:http/http.dart' as http;

class VisionApi {
  final String apiKey = 'AIzaSyAhn64pt_dCPncx3gWoAQW9NUFlnieu52c';

  Future<List<dynamic>> detectFaces(String imageUrl) async {
    final url = 'https://vision.googleapis.com/v1/images:annotate?key=$apiKey';
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'requests': [
          {
            'image': {
              'source': {
                'imageUri': imageUrl,
              },
            },
            'features': [
              {
                'type': 'FACE_DETECTION',
                'maxResults': 10,
              },
            ],
          },
        ],
      }),
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      final faces = jsonResponse['responses'][0]['faceAnnotations'];
      return faces;
    } else {
      throw Exception('Failed to detect faces');
    }
  }
}
