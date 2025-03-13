import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'dart:io'; // Diperlukan untuk FileImage
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import 'package:sayurkuapp/utils/plant_translator.dart';

class PlantDetail extends StatefulWidget {
  final String classifiedPlantName;
  final String classifiedImagePath;

  PlantDetail({required this.classifiedPlantName, required this.classifiedImagePath});

  @override
  _PlantDetailState createState() => _PlantDetailState();
}

class _PlantDetailState extends State<PlantDetail> {
  String plantDescription = "Mohon Tunggu...";
  String plantDiagnosis ="Silahkan lakukan diagnosa";
  String namaTanaman = "";
  String namaTanamanKlasifikasi="";
  @override
  void initState() {
    super.initState();
    loadPlantImages();
    fetchPlantDescription();
    namaTanaman=translatePlantName(widget.classifiedPlantName??" ");
    namaTanamanKlasifikasi = widget.classifiedPlantName;
  }

  Future<void> fetchPlantDescription() async {
    const String apiKey = "xxx";
    const String apiUrl = "https://api.groq.com/openai/v1/chat/completions";

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $apiKey",
      },
      body: jsonEncode({
        "model": "llama-3.3-70b-versatile",
        "messages": [
          {"role": "user", "content": "Berikan penbjelasan singkat mengenai ${namaTanaman} mencakup deskripsi, lama panen dan perawatan. buat dengan format ## Deskripsi \n Deskripsinya \n ## Lama Panen \n Lama Panennya \n ## Perawatan \n Perawatannya"}
        ]
      }),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      setState(() {
        plantDescription = data['choices'][0]['message']['content'] ?? "No description available.";
      });
    } else {
      setState(() {
        plantDescription = "Failed to load description.";
      });
    }
  }

  final String apiKey = "xxxx";

  Future<Map<String, String>> _uploadToGroq(File imageFile) async {
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
                {
                  "type": "text",
                  "text": "berikut adalah gambar ${namaTanaman} , Analisis gambar ini dan berikan hasil dalam format JSON dengan struktur berikut:\n\n"
                      "{\n"
                      "  \"NamaTanaman\": \"Nama Tanaman\",\n"
                      "  \"NamaPenyakit\": \"Nama penyakit atau 'Normal' jika tidak ada penyakit\",\n"
                      "  \"HasilDiagnosis\": \"Deskripsi singkat penyakit atau 'Tanaman dalam kondisi normal.'\"\n"
                      "}\n\n"
                      "Jika tidak ada penyakit, berikan output:\n\n"
                      "{\n"
                      "  \"NamaTanaman\": \"Nama Tanaman\",\n"
                      "  \"NamaPenyakit\": \"Normal\",\n"
                      "  \"HasilDiagnosis\": \"Tanaman dalam kondisi normal.\"\n"
                      "}\n\n"
                      "Pastikan hanya mengembalikan JSON tanpa teks tambahan."
                },
                {
                  "type": "image_url",
                  "image_url": {"url": "data:image/jpeg;base64,$base64Image"}
                }
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        String rawResponse = jsonResponse['choices'][0]['message']['content'].toString();

        // Parsing JSON dari respons
        Map<String, dynamic> diagnosisResult = jsonDecode(rawResponse);

        return {
          "NamaTanaman": diagnosisResult["NamaTanaman"] ?? "Error",
          "NamaPenyakit": diagnosisResult["NamaPenyakit"] ?? "Error",
          "HasilDiagnosis": diagnosisResult["HasilDiagnosis"] ?? "Gagal mendapatkan hasil."
        };
      } else {
        print("Gagal upload gambar: ${response.statusCode} - ${response.body}");
        return {
          "NamaTanaman": "Error",
          "NamaPenyakit": "Error",
          "HasilDiagnosis": "Gagal menganalisis gambar."
        };
      }
    } catch (e) {
      print("Error: $e");
      return {
        "NamaTanaman": "Error",
        "NamaPenyakit": "Error",
        "HasilDiagnosis": "Terjadi kesalahan saat menganalisis gambar."
      };
    }
  }


  Map<String, String> plantImages = {}; // Mapping nama tanaman ke gambar

  Future<void> loadPlantImages() async {
    try {
      // Baca file label.txt dari assets
      String labels = await rootBundle.loadString('assets/labels.txt');

      // Pisahkan setiap baris dalam file
      List<String> labelList = labels.split('\n');

      // Buat mapping otomatis (misal: 'kangkung' → 'assets/img/kangkung.png')
      for (String label in labelList) {
        String cleanedLabel = label.trim().toLowerCase();
        if (cleanedLabel.isNotEmpty) {
          plantImages[cleanedLabel] = "assets/images/$cleanedLabel.png";
        }
      }

      print("Mapping selesai: $plantImages"); // Debugging
    } catch (e) {
      print("Gagal membaca label.txt: $e");
    }
  }

  ImageProvider _getAssetImage(String plantName) {
    String cleanedName = plantName.toLowerCase().trim();
    return AssetImage(plantImages[cleanedName] ?? "assets/images/${namaTanamanKlasifikasi}.png");
  }
  void _diagnosePlant(BuildContext context, String imagePath) async {
    if (imagePath.isNotEmpty) {
      File imageFile = File(imagePath);

      // Panggil fungsi _uploadToGroq untuk mendapatkan hasil diagnosis
      Map<String, String> result = await _uploadToGroq(imageFile);

      // Tampilkan hasil diagnosis
      // Perbarui state agar UI otomatis berubah
      setState(() {
        namaTanaman = result['NamaTanaman'] ?? "Tidak diketahui";
        namaTanamanKlasifikasi = reverseTranslatePlantName(namaTanaman);
        plantDiagnosis = result['NamaPenyakit'] ?? "Tidak diketahui";
        fetchPlantDescription();
      });
      _showDiagnosisResult(context, result);
    } else {
      print("Gambar belum diklasifikasikan!");
    }
  }

  void _showDiagnosisResult(BuildContext context, Map<String, String> result) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Hasil Diagnosis"),
          content: Text("Nama Penyakit: ${result['NamaPenyakit']}\n"
              "Hasil Diagnosis: ${result['HasilDiagnosis']}"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Tutup"),
            )
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Color(0xFF399D63), // Ubah warna sesuai background utama
      //statusBarIconBrightness: Brightness.light, // Ubah ikon jadi putih
    ));
    return Scaffold(
      backgroundColor: Color(0xFF399D63),
      body: ListView(
        children: <Widget>[
          Stack(
            children: <Widget>[
              Container(
                height: MediaQuery.of(context).size.height,
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(color: Color(0xFF399D63)),
              ),
              Positioned(
                top: MediaQuery.of(context).size.height / 2,
                bottom: 0, // Tambahkan ini agar mengisi layar penuh
                child: Container(
                  height: MediaQuery.of(context).size.height / 2,
                  width: MediaQuery.of(context).size.width,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    color: Colors.white,
                  ),
                ),
              ),
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(left: 25, top: 60),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'HASIL KLASIFIKASI',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF8AC7A4),
                      ),
                    ),
                    Text(
                      namaTanaman,
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 45,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'HASIL DIAGNOSIS',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF8AC7A4),
                      ),
                    ),
                    Text(
                      toBeginningOfSentenceCase(plantDiagnosis) ?? plantDiagnosis,
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 25,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: (MediaQuery.of(context).size.height / 2) - 345,
                left: (MediaQuery.of(context).size.width / 2) + 105,
                child: Image(
                  image: widget.classifiedImagePath.contains("/data/user/0/")
                      ? FileImage(File(widget.classifiedImagePath))
                      : AssetImage(widget.classifiedImagePath) as ImageProvider,
                  fit: BoxFit.cover,
                  height: 80,
                ),
              ),
              Positioned(
                top: (MediaQuery.of(context).size.height / 2) - 200,
                left: (MediaQuery.of(context).size.width / 2) - 170,
                child: Image(
                  image: _getAssetImage(namaTanamanKlasifikasi), // Ambil gambar dari assets
                  fit: BoxFit.cover,
                  height: 250,
                ),
              ),

              Padding(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).size.height - 380,
                  left: 20,
                  right: 15,
                  bottom: 15
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Tentang ${namaTanaman}',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 25,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 12),
                    MarkdownBody(
                      data: plantDescription,
                      styleSheet: MarkdownStyleSheet(
                        p: TextStyle(fontFamily: 'Montserrat', fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color(0xFFEED19C),
        onPressed: () {
          _diagnosePlant(context, widget.classifiedImagePath);
        },
        child: Icon(
          Icons.health_and_safety,
          color: Color(0xFF3FAE92),
        ),
      ),
    );
  }
}
