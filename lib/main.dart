import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // zapuskat programmu v rejime portreta
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final cameras = await availableCameras();
  runApp(MyApp(camera: cameras.first));
}

class MyApp extends StatelessWidget {
  final CameraDescription camera;

  const MyApp({Key? key, required this.camera}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Камера колдонмо',
      debugShowCheckedModeBanner: false,
      home: CameraScreen(camera: camera),
    );
  }
}

class CameraScreen extends StatefulWidget {
  final CameraDescription camera;

  const CameraScreen({Key? key, required this.camera}) : super(key: key);

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(widget.camera, ResolutionPreset.high);
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Камера")),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return RotatedBox(
              quarterTurns:
                  0, // tut nujno poprobovat 1,3 esli budet oshibka s kameroi
              child: CameraPreview(_controller),
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}

class CardDetectorScreen extends StatefulWidget {
  final CameraDescription camera;

  const CardDetectorScreen({Key? key, required this.camera}) : super(key: key);

  @override
  _CardDetectorScreenState createState() => _CardDetectorScreenState();
}

class _CardDetectorScreenState extends State<CardDetectorScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  bool isCardDetected = false;
  Timer? _timer;

  GlobalKey _previewContainerKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _controller = CameraController(widget.camera, ResolutionPreset.medium);
    _initializeControllerFuture = _controller.initialize().then((_) {
      if (mounted) setState(() {});
    });

    _timer = Timer.periodic(Duration(milliseconds: 500), (timer) {
      captureAndAnalyze();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> captureAndAnalyze() async {
    try {
      RenderRepaintBoundary boundary =
          _previewContainerKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary;

      ui.Image image = await boundary.toImage(pixelRatio: 1.0);
      ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      if (byteData == null) {
        setState(() {
          isCardDetected = false;
        });
        return;
      }

      bool detected = analyzeImage();
      setState(() {
        isCardDetected = detected;
      });
    } catch (e) {
      print("Analizing photo error: $e");
      setState(() {
        isCardDetected = false;
      });
    }
  }

  bool analyzeImage() {
    return Random().nextBool();
  }

  Future<void> captureFinalImage() async {
    try {
      RenderRepaintBoundary boundary =
          _previewContainerKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 1.0);
      ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      if (byteData == null) return;
      showDialog(
        context: context,
        builder:
            (_) => AlertDialog(
              title: Text("The photo is taken"),
              content: Text("Photo is taken successfully"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("OK"),
                ),
              ],
            ),
      );
    } catch (e) {
      print("error while taking a last photo $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final rectangleWidth = screenWidth * 0.8;
    final rectangleHeight = rectangleWidth * 0.65;

    return Scaffold(
      appBar: AppBar(title: Text("Документ аныктоо")),
      body: FutureBuilder(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              children: [
                RepaintBoundary(
                  key: _previewContainerKey,
                  child: CameraPreview(_controller),
                ),

                Positioned(
                  top: 20,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
                      Text(
                        "position the document correctly...",
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                      SizedBox(height: 10),
                      Text(
                        "Hold the device steady",
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ],
                  ),
                ),

                Center(
                  child: Container(
                    width: rectangleWidth,
                    height: rectangleHeight,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isCardDetected ? Colors.green : Colors.white,
                        width: 3,
                      ),
                    ),
                  ),
                ),

                if (isCardDetected)
                  Positioned(
                    bottom: 50,
                    left: (screenWidth / 2) - 50,
                    child: ElevatedButton(
                      onPressed: captureFinalImage,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        backgroundColor: Colors.blue,
                      ),
                      child: Text("Take a photo"),
                    ),
                  ),
              ],
            );
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
