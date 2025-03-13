import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'PlantDetail.dart';
import 'tflite_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final tfliteService = TFLiteService();
  await tfliteService.loadModel();
  runApp(MyApp(tfliteService));
}

class MyApp extends StatelessWidget {
  final TFLiteService tfliteService;
  MyApp(this.tfliteService);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: CameraScreen(tfliteService),
    );
  }
}

class CameraScreen extends StatefulWidget {
  final TFLiteService tfliteService;
  CameraScreen(this.tfliteService);

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _cameraController;
  File? _image;
  String predictionResult = "Arahkan kamera ke tanaman...";

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    _cameraController = CameraController(cameras[0], ResolutionPreset.medium);
    await _cameraController!.initialize();
    setState(() {});
  }

  Future<void> _captureAndPredict() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    XFile file = await _cameraController!.takePicture();
    _processImage(File(file.path));
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      // Upload gambar ke API Groq
      //_uploadToGroq(File(pickedFile.path));
      _processImage(File(pickedFile.path));
    }
  }

  Future<void> _processImage(File imageFile) async {
    String prediction = await widget.tfliteService.runModelWithImage(imageFile.path);

    setState(() {
      _image = imageFile;
      predictionResult = prediction;
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlantDetail(
          classifiedPlantName: prediction,
          classifiedImagePath: imageFile.path,
        ),
      ),
    );
  }
  final String apiKey = "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";

  Future<void> _uploadToGroq(File imageFile) async {
    try {
      // Konversi gambar ke Base64
      List<int> imageBytes = await imageFile.readAsBytes();
      String base64Image = base64Encode(imageBytes);

      var url = Uri.parse("https://api.groq.com/openai/v1/chat/completions");

      var response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $apiKey",
        },
        body: jsonEncode({
          "model": "llama-3.2-11b-vision-preview", // Model yang mendukung Vision
          "messages": [
            {
              "role": "user",
              "content": [
                {"type": "text", "text": "Apa yang ada dalam gambar ini?"},
                {
                  "type": "image_url",
                  "image_url": {
                    "url": "data:image/jpeg;base64,$base64Image"
                  }
                }
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        print("Response dari Groq: ${jsonResponse['choices'][0]['message']['content']}");
      } else {
        print("Gagal upload gambar: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("About"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("SayurkuApp\nKlasifikasi Tanaman\noleh Ade Maulana"),
              SizedBox(height: 10),
              Row(children: [Icon(Icons.camera_alt, size: 20, color: Colors.purple), SizedBox(width: 10), Text("IG: @ademaulana_")]),
              Row(children: [Icon(Icons.videocam, size: 20, color: Colors.blue), SizedBox(width: 10), Text("TikTok: @ademaulana_4")]),
              Row(children: [
                Icon(Icons.code, size: 20, color: Colors.black),
                SizedBox(width: 10),
                GestureDetector(
                  onTap: () => launchUrl(Uri.parse("https://github.com/ade-m")),
                  child: Text("GitHub: ade-m", style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline)),
                ),
              ]),
            ],
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text("Tutup"))],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[50],
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, // Memisahkan bagian tengah dan bawah
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _image != null
                      ? Image.file(_image!, height: 300, width: 300, fit: BoxFit.cover)
                      : _cameraController != null && _cameraController!.value.isInitialized
                      ? SizedBox(height: 566, width: 400, child: CameraPreview(_cameraController!))
                      : CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text(
                    predictionResult,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green[800]),
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _captureAndPredict,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[700],
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        ),
                        icon: Icon(Icons.camera, color: Colors.white),
                        label: Text("Ambil Foto", style: TextStyle(color: Colors.white)),
                      ),
                      SizedBox(width: 20),
                      ElevatedButton.icon(
                        onPressed: _pickImage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[400],
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        ),
                        icon: Icon(Icons.image, color: Colors.white),
                        label: Text("Pilih Gambar", style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 20.0),
            child: Image.asset(
              'assets/images/sayurku.png',
              height: 100,
              width: 100,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }
}
