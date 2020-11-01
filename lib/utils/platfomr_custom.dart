import 'package:flutter/services.dart';
import 'dart:convert';

const platform = const MethodChannel('com.musketeer.compressor');

Future<List<dynamic>> pickFile() async {
  try {
    var result = await platform.invokeMethod('pick_file', {});
    return json.decode(result.toString());
  } on PlatformException catch (e) {
    print("error: ${e.message}.");
  }
}