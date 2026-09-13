
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:pi/Pages/loading_screen.dart';

import '../services/ml_service.dart';

class CameraScanScreen extends StatefulWidget {
  const CameraScanScreen({super.key});

  @override
  State<CameraScanScreen> createState() => _CameraScanScreenState();
}

class _CameraScanScreenState extends State<CameraScanScreen> {
  CameraController? _cameraController;
  late final FaceDetector _faceDetector;
  final MLService _mlService = MLService();

  bool _isDetecting = false;
  bool _isProcessingImage = false;
  bool _modeCahaya = false;
  int _frameWajahStabil = 0;
  bool _isLoading = true;
  bool _mataPernahTutup = false;

  @override
  void initState() {
    super.initState();
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.fast,
        enableClassification: true
      ),
    );
    _initKameraDanML();
  }

  Future<void> _initKameraDanML() async {
    try {
      await _mlService.initialize();

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw Exception('Tidak ada kamera yang terdeteksi.');
      }

      final camera = cameras.firstWhere(
        (item) => item.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.nv21,
      );

      _cameraController = controller;
      await controller.initialize();
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      await controller.startImageStream(_prosesFrameKamera);
    } catch (e) {
      debugPrint('Gagal inisialisasi kamera: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal membuka kamera: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _prosesFrameKamera(CameraImage image) {
    if (_isDetecting || _isProcessingImage) return;
    _isDetecting = true;
    _deteksiWajah(image);
  }

  InputImage? _konversiKeInputImage(CameraImage image) {
  try {
    final camera = _cameraController!.description;
    final rotation = InputImageRotationValue.fromRawValue(camera.sensorOrientation)
        ?? InputImageRotation.rotation0deg;

    final bytesBuffer = WriteBuffer();
    for (final plane in image.planes) {
      bytesBuffer.putUint8List(plane.bytes);
    }

    return InputImage.fromBytes(
      bytes: bytesBuffer.done().buffer.asUint8List(),
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: InputImageFormat.nv21,
        bytesPerRow: image.planes.first.bytesPerRow,
      ),
    );
  } catch (e) {
    debugPrint('Gagal mengubah frame kamera: $e');
    return null;
  }
}
Future<void> _deteksiWajah(CameraImage image) async {
    try {
      final inputImage = _konversiKeInputImage(image);
      if (inputImage == null) return;

      final faces = await _faceDetector.processImage(inputImage);

      if (faces.length == 1) {
        _frameWajahStabil++;
        
        if (_frameWajahStabil < 5) {
          _isDetecting = false;
          return; 
        }

        final face = faces.first;
        final leftEye = face.leftEyeOpenProbability ?? 1.0;
        final rightEye = face.rightEyeOpenProbability ?? 1.0;

        if (leftEye < 0.2 && rightEye < 0.2) {
          _mataPernahTutup = true;
        }

        if (_mataPernahTutup && leftEye > 0.8 && rightEye > 0.8) {
          if (_isProcessingImage) return; // Jangan double eksekusi
          
          _isProcessingImage = true; // Kunci gerbang UI
          if (mounted) setState(() {});

          Future(() async {
            try {
              final controller = _cameraController;
              if (controller == null) return;

              await controller.stopImageStream();
              
              await Future.delayed(const Duration(milliseconds: 500)); 
              
              final foto = await controller.takePicture();
              final vektorWajah = await _mlService.processFace(foto.path);

              if (mounted) {
                Navigator.pop(context, vektorWajah);
              }
            } catch (e) {
              debugPrint("Error jepret: $e");
            }
          });
          
          return;
        }
      } else {
        _frameWajahStabil = 0;
        _mataPernahTutup = false; 
      }
    } catch (e) {
      debugPrint('Gagal memproses wajah: $e');
    } finally {
      _isDetecting = false; 
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const LottieLoadingScreen();
    }
    final controller = _cameraController;

    if (controller == null || !controller.value.isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(controller),
          CustomPaint(
            painter: FaceGuidePainter(modeCahaya: _modeCahaya),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton.filled(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back),
                        style: IconButton.styleFrom(backgroundColor: Colors.black54),
                      ),
                      IconButton.filled(
                        tooltip: _modeCahaya
                            ? 'Matikan mode cahaya'
                            : 'Aktifkan mode cahaya',
                        onPressed: () {
                          setState(() => _modeCahaya = !_modeCahaya);
                        },
                        icon: Icon(
                          _modeCahaya
                              ? Icons.light_mode
                              : Icons.light_mode_outlined,
                        ),
                        style: IconButton.styleFrom(backgroundColor: Colors.black54),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 100),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    "- Posisikan wajah di dalam oval.\n- Kedipkan mata Anda untuk memverifikasi.\n- Lepaskan kacamata atau topi jika perlu.",
                    textAlign: TextAlign.justify,
                    style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.normal),
                  ),
                ),
              ],
            ),
          ),
          if (_isProcessingImage)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.green),
                    SizedBox(height: 16),
                    Text(
                      'Memproses biometrik...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class FaceGuidePainter extends CustomPainter {
  const FaceGuidePainter({required this.modeCahaya});

  final bool modeCahaya;

  @override
  void paint(Canvas canvas, Size size) {
    final oval = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.45),
      width: math.min(size.width * 0.72, 320),
      height: math.min(size.height * 0.48, 430),
    );

    canvas.saveLayer(Offset.zero & size, Paint());
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..color = modeCahaya
            ? Colors.white
            : Colors.black.withOpacity(0.58),
    );
    canvas.drawOval(
      oval,
      Paint()..blendMode = BlendMode.clear,
    );
    canvas.restore();

    canvas.drawOval(
      oval,
      Paint()
        ..color = modeCahaya ? Colors.blue : Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(covariant FaceGuidePainter oldDelegate) {
    return oldDelegate.modeCahaya != modeCahaya;
  }
}