import 'package:flutter/material.dart';
import '../utils/iconfonts.dart';
import '../utils/colors.dart';

class Location extends StatelessWidget {
  final List<String> directories;
  final VoidCallback goBack;

  Location({Key key, @required this.directories, @required this.goBack}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final items = <String>[];
    items.add('/');
    for (var directory in directories) {
      items.add(directory);
      items.add('/');
    }
    return Container(
      height: 34,
      alignment: Alignment.center,
      padding: EdgeInsets.all(3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            child: Container(
              alignment: Alignment.center,
              height: 28,
              width: 40,
              decoration: BoxDecoration(
                color: ColorUtils.formBackground,
                borderRadius: BorderRadius.all(Radius.circular(5)),
              ),
              child: Icon(
                IconFonts.arrowLeft,
                color: ColorUtils.themeColor,
                size: 22.0,
              ),
            ),
            onTap: () {
              goBack();
            },
          ),
          Expanded(
            flex: 1,
            child: CustomScrollView(
              scrollDirection: Axis.horizontal,
              slivers: <Widget>[
                SliverList(
                  delegate: SliverChildListDelegate(
                    items.map((e) {
                      return e=='/'?Container(
                        padding: EdgeInsets.symmetric(vertical: 0, horizontal: 3),
                        child: Text(
                          '/',
                          style: TextStyle(
                            color: ColorUtils.textColor,
                            fontSize: 20,
                          ),
                        ),
                      ):Container(
                        alignment: Alignment.center,
                        height: 28,
                        padding: EdgeInsets.symmetric(vertical: 0, horizontal: 8),
                        decoration: BoxDecoration(
                          color: ColorUtils.formBackground,
                          borderRadius: BorderRadius.all(Radius.circular(5)),
                        ),
                        child: Text(
                          e,
                          style: TextStyle(
                            color: ColorUtils.textColor,
                            fontSize: 15,
                          ),
                        ),
                      );
                    }).toList()
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
