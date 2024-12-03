import 'dart:typed_data';

import 'package:camera/camera.dart';
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
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
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
  CameraController? controller;
  late Future<void> _initializeControllerFuture;
  Uint8List? data;
  List exifDatas = [];

  Future<void> _initializeCamera() async {
    var res = await Permission.camera.request();
    if (!res.isGranted) return;
    final cameras = await availableCameras();
    controller = CameraController(
      cameras.first,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    // controller?.setDescription(CameraDescription(name: name, lensDirection: lensDirection, sensorOrientation: sensorOrientation))

    _initializeControllerFuture = controller!.initialize().then((value) async {
      controller!.setFlashMode(FlashMode.off);
      controller!.startImageStream((image) {});
      setState(() {});

    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _initializeCamera();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body:  Column(
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
                    child: controller == null
                        ? Container()
                        : CameraPreview(
                            controller!,
                          ),
                  ),
                  Column(
                    children: [
                      TextButton(onPressed: () => takePhoto(), child: Text('拍照')),
                      TextButton(onPressed: () => getExif(), child: Text('获取exif')),
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

  takePhoto() async {
    var images = await controller!.takePicture();
    data = await images.readAsBytes();
    final exifData = await readExifFromBytes(data as List<int>);
    for (final entry in exifData.entries) {
      debugPrint("${entry.key}: ${entry.value}");
    }
    await ImageGallerySaver.saveFile(images.path, isReturnPathOfIOS: true);
  }

  getExif() async {
    var images = await controller!.takePicture();
    data = await images.readAsBytes();
    exifDatas.clear();
    final exifData = await readExifFromBytes(data as List<int>);
    for (final entry in exifData.entries) {
      debugPrint("${entry.key}: ${entry.value}");
      exifDatas.add("${entry.key}: ${entry.value}");
    }
    setState(() {});
  }
}
