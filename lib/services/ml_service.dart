
import 'dart:io';
import 'dart:ui';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class MLService {
  late Interpreter _interpreter;
  final int _inputSize = 112;
  final FaceDetector _fileFaceDetector = FaceDetector(
    options: FaceDetectorOptions(performanceMode: FaceDetectorMode.fast),
  );

  Future<void> initialize() async {
    _interpreter = await Interpreter.fromAsset('assets/models/mobilefacenet.tflite');
  }

  Future<List<double>?> processFace(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final faces = await _fileFaceDetector.processImage(inputImage);
    
    if (faces.isEmpty) {
      print("ML_SERVICE: Tidak ada wajah terdeteksi pada gambar.");
      return null;
    }
    
    final Rect lokasiWajahAkurat = faces.first.boundingBox;

    final imageBytes = await File(imagePath).readAsBytes();
    final originalImage = img.decodeImage(imageBytes);
    if (originalImage == null) return null;

    final croppedImage = _cropFace(originalImage, lokasiWajahAkurat);

    return _extractEmbedding(croppedImage);
  }

  img.Image _cropFace(img.Image originalImage, Rect boundingBox) {
    int x = boundingBox.left.toInt().clamp(0, originalImage.width);
    int y = boundingBox.top.toInt().clamp(0, originalImage.height);
    int width = boundingBox.width.toInt().clamp(0, originalImage.width - x);
    int height = boundingBox.height.toInt().clamp(0, originalImage.height - y);

    return img.copyCrop(originalImage, x: x, y: y, width: width, height: height);
  }

  List<double> _extractEmbedding(img.Image faceImage) {
    img.Image resizedImage = img.copyResize(faceImage, width: _inputSize, height: _inputSize);

    var input = List.generate(
      1,
      (i) => List.generate(
        _inputSize,
        (y) => List.generate(
          _inputSize,
          (x) {
            final pixel = resizedImage.getPixel(x, y);
            return [
              (pixel.r - 127.5) / 127.5,
              (pixel.g - 127.5) / 127.5,
              (pixel.b - 127.5) / 127.5
            ];
          },
        ),
      ),
    );

    var output = List.generate(1, (i) => List.filled(192, 0.0));
    _interpreter.run(input, output);
    return output[0];
  }
  
  void dispose() {
    _fileFaceDetector.close();
    _interpreter.close();
  }
}