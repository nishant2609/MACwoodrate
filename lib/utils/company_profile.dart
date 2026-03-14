import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class CompanyProfile {
  static const String _fileName = 'company_profile.json';

  static Future<File> get _localFile async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_fileName');
  }

  static Future<bool> hasProfile() async {
    try {
      final file = await _localFile;
      if (!await file.exists()) return false;
      final contents = await file.readAsString();
      final data = jsonDecode(contents);
      final name = data['companyName'] as String?;
      return name != null && name.trim().isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  static Future<String?> getCompanyName() async {
    try {
      final file = await _localFile;
      if (!await file.exists()) return null;
      final contents = await file.readAsString();
      final data = jsonDecode(contents);
      return data['companyName'] as String?;
    } catch (e) {
      return null;
    }
  }

  static Future<void> saveCompanyName(String name) async {
    final file = await _localFile;
    await file.writeAsString(jsonEncode({'companyName': name.trim()}));
  }

  static Future<void> clearProfile() async {
    final file = await _localFile;
    if (await file.exists()) {
      await file.delete();
    }
  }
}