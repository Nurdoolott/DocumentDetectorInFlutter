import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Программаны портрет режиминде иштетүү
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
            // Эгер камера кыйшак ачылып жатса, quarterTurns параметрин өзгөртүңүз.
            return RotatedBox(
              quarterTurns:
                  0, // Эгер 90 градуска кыйшак болсо, quarterTurns: 1 же 3 колдонуп көрүңүз
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
  // GlobalKey менен капталган RepaintBoundary аркылуу экран сүрөтүн тартып анализдейбиз
  GlobalKey _previewContainerKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _controller = CameraController(widget.camera, ResolutionPreset.medium);
    _initializeControllerFuture = _controller.initialize().then((_) {
      if (mounted) setState(() {});
    });

    // Ар 500 мс сайын экрандагы аймакты анализдеп, документ туура жайгашканын текшеребиз
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

  // RepaintBoundary аркылуу скриншот тартып, аны анализдеп, isCardDetected абалын жаңыртат
  Future<void> captureAndAnalyze() async {
    try {
      RenderRepaintBoundary boundary =
          _previewContainerKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary;
      // Сүрөттү тартып алуу
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
      // Бул жерде сурөттү кайра өзгөртүүдөн өтсөк да болот,
      // бирок демо максатында жөнөкөй анализ жүргүзүп, 50% учурларда документ аныкталат.
      bool detected = analyzeImage();
      setState(() {
        isCardDetected = detected;
      });
    } catch (e) {
      print("Сүрөт тартып анализдөөдө ката: $e");
      setState(() {
        isCardDetected = false;
      });
    }
  }

  // Симуляцияланган анализ – 50% ыкма менен true кайтарат.
  bool analyzeImage() {
    return Random().nextBool();
  }

  // Акыркы сүрөттү тартып алуу функциясы, кнопкага басылган учурда аткарылат.
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
      // Бул жерде сүрөттү сактоо же серверге жиберүү иштери аткарылышы мүмкүн.
      // Демо катары, диалог терезеде билдиребиз.
      showDialog(
        context: context,
        builder:
            (_) => AlertDialog(
              title: Text("Сүрөт тартып алынды"),
              content: Text("Сүрөт ийгиликтүү тартып алынды."),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("OK"),
                ),
              ],
            ),
      );
    } catch (e) {
      print("Акыркы сүрөттү тартып алууда ката: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Экран туурасынын 80% ээсин колдонуңуз жана анын пропорциясы 0.65 катары эсептелет.
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
                // Камеранын алдын ала көрүнүшү RepaintBoundary менен капталат,
                // андан скриншот тартып анализ жүргүзөбүз.
                RepaintBoundary(
                  key: _previewContainerKey,
                  child: CameraPreview(_controller),
                ),
                // Жогорку тексттер
                Positioned(
                  top: 20,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
                      Text(
                        "Документти туура жайгаштырыңыз...",
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                      SizedBox(height: 10),
                      Text(
                        "Түзмөктү тынч кармаңыз",
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                // Экрандын ортосунда документти жайгаштырууга арналган чек аймак
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
                // Эгер документ туура аныкталса, экрандын аягында сүрөт тартуу кнопкасы пайда болот.
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
                      child: Text("Сүрөт тартуу"),
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
