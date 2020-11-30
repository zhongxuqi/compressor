import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/colors.dart';

class FormTextInput extends StatefulWidget {
  final String keyName;
  final String value;
  final int maxLines;
  final ValueChanged<String> onChange;
  final String hintText;
  final List<TextInputFormatter> inputFormatters;

  FormTextInput({
    Key key,
    @required this.keyName,
    @required this.value,
    @required this.hintText,
    this.maxLines = 1,
    @required this.onChange,
    this.inputFormatters,
  }): super(key: key);

  @override
  State<StatefulWidget> createState() => FormTextInputState(
    value: this.value,
    hintText: this.hintText,
  );
}

class FormTextInputState extends State<FormTextInput> {
  String value;
  final textCtl = TextEditingController();
  bool isShow = false;
  final String hintText;

  FormTextInputState({@required this.value, @required this.hintText});

  @override
  void initState() {
    super.initState();
    textCtl.text = value;
  }

  void setValue(String v) {
    setState(() {
      value = v;
      textCtl.text = value;
    });
  }

  String _textError = "";
  setTextError(String value) {
    setState(() {
      _textError = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: <Widget>[
          widget.keyName.length>0?Row(
            children: <Widget>[
              Expanded(
                flex: 1,
                child: Container(
                  margin: EdgeInsets.only(top: 8.0, bottom: 8.0),
                  child: Text(
                    widget.keyName,
                    style: TextStyle(
                      color: ColorUtils.textColor,
                      fontSize: 15.0,
                    ),
                  ),
                ),
              ),
            ],
          ):Container(),
          Container(
            decoration: BoxDecoration(
              color: ColorUtils.formBackground,
              borderRadius: BorderRadius.all(
                Radius.circular(5.0),
              ),
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  flex: 1,
                  child: Container(
                    height: 36,
                    child: TextField(
                      controller: textCtl,
                      maxLines: widget.maxLines,
                      minLines: widget.maxLines==null?2:1,
                      scrollPadding: EdgeInsets.all(0),
                      inputFormatters: widget.inputFormatters,
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(0),
                          gapPadding: 0,
                          borderSide: BorderSide(
                              color: Colors.transparent,
                              width: 0,
                              style: BorderStyle.none
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(0),
                          gapPadding: 0,
                          borderSide: BorderSide(
                              color: Colors.transparent,
                              width: 0,
                              style: BorderStyle.none
                          ),
                        ),
                        fillColor: Colors.transparent,
                        hintText: hintText,
                        hintStyle: TextStyle(
                          color: Colors.grey,
                          fontSize: 15.0,
                          textBaseline: TextBaseline.alphabetic,
                        ),
                      ),
                      style: TextStyle(
                        color: ColorUtils.textColor,
                        fontSize: 15.0,
                        textBaseline: TextBaseline.alphabetic,
                      ),
                      onChanged: widget.onChange,
                    ),
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(right: 5.0),
                  child: Text(
                    _textError,
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 15.0,
                    ),
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