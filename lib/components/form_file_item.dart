import 'package:compressor/localization/localization.dart';
import 'package:flutter/material.dart';
import '../common/data.dart' as data;
import '../utils/colors.dart';
import '../utils/mime.dart';
import 'form_text_input.dart';

class FormFileItem extends StatefulWidget {
  final data.File fileData;
  final ValueChanged<String> fileNameListener;

  FormFileItem({Key key,
    @required this.fileData,
    this.fileNameListener,
  }) :super(key: key);

  @override
  State createState() {
    return FormFileItemState();
  }
}

class FormFileItemState extends State<FormFileItem> {
  final GlobalKey<FormTextInputState> fileNameInputKey = GlobalKey<FormTextInputState>();
  final fileNameCtl = TextEditingController();

  @override
  void initState() {
    super.initState();
    fileNameCtl.text = widget.fileData.name;
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      child: Container(
        height: 60,
        alignment: Alignment.center,
        child: Row(
          children: [
            Container(
              margin: EdgeInsets.only(right: 8, top: 8, bottom: 8, left: 10),
              child: Image.asset(MimeUtils.getIconByMime(widget.fileData.contentType), height: 40.0, width: 40.0,),
            ),
            Expanded(
              flex: 1,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 1,
                    child: Container(
                      alignment: Alignment.centerLeft,
                      padding: EdgeInsets.only(top: 8, bottom: 8, right: 8),
                      child: FormTextInput(
                        key: fileNameInputKey,
                        keyName: '',
                        value: widget.fileData.name,
                        hintText: AppLocalizations.of(context).getLanguageText('input_file_name_hint'),
                        maxLines: 1,
                        onChange: widget.fileNameListener,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Container(
                          height: 1,
                          color: ColorUtils.divider,
                        ),
                      ),
                    ],
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