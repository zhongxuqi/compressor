import 'package:shared_preferences/shared_preferences.dart';
import '../common/data.dart';

class StoreUtils {
  static final hasOpenedKey = 'has-opened';
  static void setHasOpened(bool hasOpened) async {
    var sharedPreference = await SharedPreferences.getInstance();
    await sharedPreference.setBool(hasOpenedKey, hasOpened);
  }
  static Future<bool> hasOpened() async {
    var sharedPreference = await SharedPreferences.getInstance();
    return sharedPreference.getBool(hasOpenedKey) == true;
  }

  static final SortByKey = 'sort-by';
  static void setSortByKey(SortBy sortBy) async {
    var sharedPreference = await SharedPreferences.getInstance();
    switch (sortBy) {
      case SortBy.name:
        sharedPreference.setInt(SortByKey, 1);
        break;
      case SortBy.time:
        sharedPreference.setInt(SortByKey, 2);
        break;
    }
  }
  static Future<SortBy> getSortByKey() async {
    var sharedPreference = await SharedPreferences.getInstance();
    switch (sharedPreference.getInt(SortByKey)) {
      case 1:
        return SortBy.name;
      case 2:
        return SortBy.time;
    }
    return SortBy.name;
  }

  static final SortTypeKey = 'sort-type';
  static setSortTypeKey(SortType sortType) async {
    var sharedPreference = await SharedPreferences.getInstance();
    switch (sortType) {
      case SortType.asc:
        sharedPreference.setInt(SortTypeKey, 1);
        break;
      case SortType.desc:
        sharedPreference.setInt(SortTypeKey, 2);
        break;
    }
  }
  static Future<SortType> getSortTypeKey() async {
    var sharedPreference = await SharedPreferences.getInstance();
    switch (sharedPreference.getInt(SortTypeKey)) {
      case 1:
        return SortType.asc;
      case 2:
        return SortType.desc;
    }
    return SortType.asc;
  }
}