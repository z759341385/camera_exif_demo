import 'dart:async';
import 'dart:typed_data';

import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:camerawesome/pigeon.dart';
import 'package:exif/exif.dart';
import 'package:flutter/material.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Future<void> _initializeControllerFuture;
  Uint8List? data;
  List exifDatas = [];
  final _imageStreamController = StreamController<AnalysisImage>();

  @override
  void activate() {
    // TODO: implement deactivate
    super.activate();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _imageStreamController.stream.listen((AnalysisImage event) async {
        JpegImage jpegImage = await (event as Bgra8888Image).toJpeg();

        exifDatas.clear();
        final exifData = await readExifFromBytes(jpegImage.bytes as List<int>);
        for (final entry in exifData.entries) {
          debugPrint("${entry.key}: ${entry.value}");
          exifDatas.add("${entry.key}: ${entry.value}");
        }
        setState(() {});
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          SizedBox(
            width: double.maxFinite,
            height: 300,
            child: Row(
              children: [
                Container(
                  width: 300,
                  height: 300,
                  child: CameraAwesomeBuilder.awesome(
                    previewPadding: const EdgeInsets.all(20),
                    previewAlignment: Alignment.center, saveConfig: SaveConfig.photo(),

                    onImageForAnalysis: (img) async => _imageStreamController.add(img),
                    imageAnalysisConfig: AnalysisConfig(
                      androidOptions: const AndroidAnalysisOptions.yuv420(
                        width: 150,
                      ),
                      maxFramesPerSecond: 10,
                    ),
                    // Other parameters
                  ),
                ),
                Column(
                  children: [
                    TextButton(onPressed: () {}, child: Text('拍照')),
                    // TextButton(onPressed: () => getExif(), child: Text('获取exif')),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemBuilder: (c, i) {
                return Text(exifDatas[i]);
              },
              itemCount: exifDatas.length,
            ),
          )
        ],
      ),
    );
  }

  //
  // takePhoto() async {
  //   var images = await controller!.takePicture();
  //   data = await images.readAsBytes();
  //   final exifData = await readExifFromBytes(data as List<int>);
  //   for (final entry in exifData.entries) {
  //     debugPrint("${entry.key}: ${entry.value}");
  //   }
  //   await ImageGallerySaver.saveFile(images.path, isReturnPathOfIOS: true);
  // }
  //
  // getExif() async {
  //   var images = await controller!.takePicture();
  //   data = await images.readAsBytes();
  //   exifDatas.clear();
  //   final exifData = await readExifFromBytes(data as List<int>);
  //   for (final entry in exifData.entries) {
  //     debugPrint("${entry.key}: ${entry.value}");
  //     exifDatas.add("${entry.key}: ${entry.value}");
  //   }
  //   setState(() {});
  // }
}
