import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class DocumentDetector extends StatefulWidget {
  final bool isCardDetected;

  const DocumentDetector({Key? key, required this.isCardDetected})
    : super(key: key);

  @override
  _DocumentDetectorState createState() => _DocumentDetectorState();
}

class _DocumentDetectorState extends State<DocumentDetector> {
  late CameraController _cameraController;
  late List<CameraDescription> _cameras;
  bool isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    initializeCamera();
  }

  Future<void> initializeCamera() async {
    try {
      _cameras = await availableCameras();
      _cameraController = CameraController(
        _cameras.first,
        ResolutionPreset.medium, // Орточо сапатты колдонот
      );
      await _cameraController.initialize();
      if (mounted) {
        setState(() {
          isCameraInitialized = true;
        });
      }
    } catch (e) {
      print("Камераны инициализациялоодо ката кетти: $e");
    }
  }

  void captureImage() async {
    if (_cameraController.value.isInitialized) {
      try {
        final file = await _cameraController.takePicture();
        print('Сүрөт тартылды: ${file.path}');
      } catch (e) {
        print("Сүрөт тартууда ката кетти: $e");
      }
    }
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return isCameraInitialized
        ? Stack(
          children: [
            CameraPreview(_cameraController), // Камеранын алдын ала көрүнүшү
            if (widget.isCardDetected)
              Positioned(
                bottom: 50,
                left: MediaQuery.of(context).size.width * 0.5 - 75,
                child: ElevatedButton(
                  onPressed: captureImage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF007AFF),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Сүрөт тартып алуу',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        )
        : const Center(
          child: CircularProgressIndicator(),
        ); // Инициализация бүткүчө индикатор
  }
}
