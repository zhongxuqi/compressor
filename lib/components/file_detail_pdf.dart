import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../database/data.dart' as data;
import 'package:native_pdf_renderer/native_pdf_renderer.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'dart:ui' as ui show Codec;
import 'package:synchronized/synchronized.dart';
import 'package:photo_view/photo_view.dart';

final lock = new Lock();

class FileDetailPDF extends StatefulWidget {
  final data.File fileData;

  FileDetailPDF({Key key, @required this.fileData}):super(key: key);

  @override
  State createState() {
    return _FileDetailPDFState();
  }
}

class _FileDetailPDFState extends State<FileDetailPDF> {
  PdfDocument pdfContent;
  final pageController = PageController(initialPage: 0);

  @override
  void initState() {
    super.initState();
    readPDFContent();
  }

  void readPDFContent() async {
    if (pdfContent != null) return;
    pdfContent = await PdfDocument.openFile(widget.fileData.uri);
    setState(() {
      print("${pdfContent.pagesCount}");
    });
  }

  @override
  void dispose() {
    super.dispose();
    if (pdfContent != null) {
      pdfContent.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    // return Container(
    //   child: pdfContent != null ? PhotoViewGallery.builder(
    //     scrollPhysics: const BouncingScrollPhysics(),
    //     gaplessPlayback: true,
    //     itemCount: pdfContent.pagesCount,
    //     scrollDirection: Axis.horizontal,
    //     backgroundDecoration: const BoxDecoration(
    //       color: Colors.black,
    //     ),
    //     pageController: pageController,
    //     builder: (BuildContext context, int index) {
    //       return PhotoViewGalleryPageOptions(
    //         imageProvider: CustomImageProvider(pdfContent: pdfContent, index: index),
    //         heroAttributes: PhotoViewHeroAttributes(tag: index),
    //       );
    //     },
    //   ):Container(),
    // );
    return Container(
      color: Colors.black,
      child: pdfContent != null ? PageView.builder(
        itemBuilder: (context, index){
          return PhotoView(
            imageProvider: CustomImageProvider(pdfContent: pdfContent, index: index),
          );
        },
        itemCount: pdfContent.pagesCount,
      ):Container(),
    );
  }
}

class PDFPage {
  final PdfDocument pdfContent;
  final int index;

  PDFPage({@required this.pdfContent, @required this.index});
}

class CustomImageProvider extends ImageProvider<CustomImageProvider> {
  final PdfDocument pdfContent;
  final int index;
  Uint8List bytes;

  CustomImageProvider({@required this.pdfContent, @required this.index});

  @override
  ImageStreamCompleter load(CustomImageProvider key, DecoderCallback decode) {
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, decode),
      scale: 1.0,
      informationCollector: () sync* {
        yield ErrorDescription('load fail');
      },
    );
  }

  Future<ui.Codec> _loadAsync(CustomImageProvider key, DecoderCallback decode) async {
    return await lock.synchronized(() async {
      if (bytes == null) {
        final pageData = await pdfContent.getPage(index + 1);
        final pageImage = await pageData.render(
          width: pageData.width * 2,
          height: pageData.height * 2,
          format: PdfPageFormat.JPEG,
          backgroundColor: '#ffffff',
        );
        pageData.close();
        bytes = pageImage.bytes;
      }
      if (bytes.lengthInBytes == 0) {
        // The file may become available later.
        throw StateError('page is empty and cannot be loaded as an image.');
      }
      return await decode(bytes);
    });
  }

  @override
  Future<CustomImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<CustomImageProvider>(this);
  }
}