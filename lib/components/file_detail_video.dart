import 'package:flutter/material.dart';
import '../database/data.dart' as data;
import 'package:video_player/video_player.dart';
import 'dart:io';
import '../utils/iconfonts.dart';
import '../utils/colors.dart';

class FileDetailVideo extends StatefulWidget {
  final data.File fileData;

  FileDetailVideo({Key key, @required this.fileData}):super(key: key);

  @override
  State createState() {
    return _FileDetailVideoState();
  }
}

class _FileDetailVideoState extends State<FileDetailVideo> {
  VideoPlayerController _controller;
  double progress = 0;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.fileData.uri))..initialize().then((_) {
      setState(() {});
    });
    _controller.setLooping(false);
    _controller.addListener(() {
      setState(() {
        progress = 100 * _controller.value.position.inSeconds / _controller.value.duration.inSeconds;
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final leftDuration = _controller.value.initialized ? _controller.value.duration - _controller.value.position : Duration();
    return Container(
      color: Colors.black,
      child: Column(
        children: [
          Container(height: 3,),
          Expanded(
            flex: 1,
            child: _controller.value.initialized ? AspectRatio(aspectRatio: _controller.value.aspectRatio, child: VideoPlayer(_controller)) : Container(),
          ),
          Container(
            height: 40,
            child: Row(
              children: [
                InkWell(
                  child: Container(
                    height: 40,
                    width: 40,
                    child: Icon(
                      _controller.value.isPlaying ? IconFonts.pause : IconFonts.play,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  onTap: () {
                    setState(() {
                      _controller.value.isPlaying
                          ? _controller.pause()
                          : _controller.play();
                    });
                  },
                ),
                Expanded(
                  flex: 1,
                  child: Slider(
                    value: progress,
                    max: 100,
                    min: 0,
                    activeColor: Colors.white,
                    inactiveColor: Colors.grey[900],
                    onChanged: (double val) {
                      setState(() {
                        if (!_controller.value.initialized) return;
                        progress = val;
                        _controller.seekTo(Duration(seconds: progress * _controller.value.duration.inSeconds ~/ 100));
                        _controller.play();
                      });
                    },
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(right: 5),
                  child: Text(
                    "${leftDuration.inMinutes.toString().padLeft(2, '0')}:${(leftDuration.inSeconds % 60).toString().padLeft(2, '0')}",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
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