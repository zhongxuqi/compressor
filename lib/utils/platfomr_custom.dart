import 'package:flutter/services.dart';

const platform = const MethodChannel('com.musketeer.compressor');

Future<String> pickFile() async {
  try {
    var result = await platform.invokeMethod('pick_file', {});
    return result.toString();
  } on PlatformException catch (e) {
    print("error: ${e.message}.");
  }
}