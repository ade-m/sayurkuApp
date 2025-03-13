import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class TFLiteService {
  late Interpreter _interpreter;
  List<String> _labels = [];

  /// Memuat model TensorFlow Lite dan label
  Future<void> loadModel() async {
    _interpreter = await Interpreter.fromAsset('assets/mobilenetv3_tanaman.tflite');
    _labels = await _loadLabels('assets/labels.txt');
    print('✅ Model & Label loaded successfully');
  }

  /// Menjalankan model dengan gambar dari galeri
  Future<String> runModelWithImage(String imagePath) async {
    final File imageFile = File(imagePath);
    if (!await imageFile.exists()) {
      return "❌ Gambar tidak ditemukan!";
    }

    var inputTensor = await _loadAndPreprocessImage(imageFile);
    if (inputTensor == null) {
      return "❌ Gagal memproses gambar";
    }

    var outputBuffer = List.filled(_labels.length, 0.0).reshape([1, _labels.length]);
    _interpreter.run(inputTensor, outputBuffer);

    List<double> outputList = outputBuffer[0].cast<double>();
    int predictedIndex = outputList.indexOf(outputList.reduce((a, b) => a > b ? a : b));

    return predictedIndex >= 0 && predictedIndex < _labels.length
        ? "${_labels[predictedIndex]}"
        : "Tidak dikenali";
  }

  /// **Memuat dan Memproses Gambar**
  Future<Uint8List?> _loadAndPreprocessImage(File imageFile) async {
    try {
      List<int> bytes = await imageFile.readAsBytes();
      img.Image? image = img.decodeImage(Uint8List.fromList(bytes));
      if (image == null) return null;

      // Resize gambar ke 224x224 (cocok dengan model)
      img.Image resizedImage = img.copyResize(image, width: 224, height: 224);

      // Konversi gambar menjadi format yang kompatibel
      List<double> inputTensor = _imageToByteList(resizedImage);

      return _convertToTensor(inputTensor);
    } catch (e) {
      print('❌ Error loading image: $e');
      return null;
    }
  }

  /// **Mengubah gambar menjadi array float32**
  List<double> _imageToByteList(img.Image image) {
    List<double> convertedBytes = [];
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        convertedBytes.add(img.getRed(pixel) / 255.0);   // Normalisasi nilai pixel
        convertedBytes.add(img.getGreen(pixel) / 255.0);
        convertedBytes.add(img.getBlue(pixel) / 255.0);
      }
    }
    return convertedBytes;
  }

  /// **Konversi List<double> ke Uint8List**
  Uint8List _convertToTensor(List<double> input) {
    var buffer = Float32List.fromList(input);
    return buffer.buffer.asUint8List();
  }

  /// **Memuat Label dari File**
  Future<List<String>> _loadLabels(String labelPath) async {
    final String labelData = await rootBundle.loadString(labelPath);
    return labelData.split('\n');
  }

  /// **Menutup Model**
  void close() {
    _interpreter.close();
  }
}
