import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class CloudinaryService {
  final String cloudName = 'dui2duhbv';
  final String uploadPreset = 'campus_preset';

  Future<String?> uploadImage(XFile imageFile) async {
    final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
    
    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    final response = await request.send();

    if (response.statusCode == 200) {
      final responseData = await response.stream.bytesToString();
      final jsonResponse = jsonDecode(responseData);
      return jsonResponse['secure_url'];
    } else {
      print('Failed to upload image. Status code: ${response.statusCode}');
      return null;
    }
  }
}
