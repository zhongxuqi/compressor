import 'package:flutter/material.dart';
import 'utils/iconfonts.dart';
import './utils/colors.dart';
import './localization/localization.dart';

class CompressorPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _CompressorPageState();
  }
}

class _CompressorPageState extends State<CompressorPage> {
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
        child: Column(
          children: <Widget>[
            Container(
              height: 45.0,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 45,
                    height: 45,
                    child: Icon(
                      IconFonts.back,
                      color: ColorUtils.themeColor,
                      size: 20.0,
                    ),
                  ),
                  Container(
                    width: 45,
                    height: 45,
                    alignment: Alignment.center,
                    child: Icon(
                      IconFonts.zip,
                      color: Colors.black,
                      size: 25.0,
                    ),
                  ),
                  Expanded(
                    child: Container(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        AppLocalizations.of(context)
                            .getLanguageText('compress_title'),
                        style: TextStyle(
                          color: ColorUtils.textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 45,
                    height: 45,
                    child: Icon(
                      IconFonts.right,
                      color: ColorUtils.themeColor,
                      size: 20.0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}