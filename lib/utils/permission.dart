import 'package:permission_handler/permission_handler.dart';

Future<bool> checkPermission(List<Permission> permissionKeys) async {
  Map<Permission, PermissionStatus> permissions = await permissionKeys.request();
  for (var permissionKey in permissionKeys) {
    if (permissions[permissionKey] != PermissionStatus.granted) {
      return false;
    }
  }
  return true;
}