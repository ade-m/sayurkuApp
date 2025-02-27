# SayurkuApp Deteksi Tanaman dengan Flutter dan TFLite

Aplikasi ini adalah proyek Flutter yang menggunakan **TensorFlow Lite (TFLite)** yang dibuat melalui MobileNetv3 untuk mendeteksi jenis tanaman berdasarkan gambar yang diberikan.

## 🚀 Fitur Utama
- **Deteksi tanaman** menggunakan model **MobileNetV3** yang telah dikonversi ke TFLite.
- **Inferensi model secara lokal** tanpa memerlukan koneksi internet.
- **UI sederhana** dengan dukungan kamera dan galeri untuk memilih gambar.

## 📌 Persyaratan
Pastikan Anda sudah menginstal:
- **Flutter** (versi terbaru) → [Flutter SDK](https://flutter.dev/docs/get-started/install)
- **Dart** (termasuk dalam Flutter SDK)
- **Android Studio** atau **VS Code**
- **Perangkat atau Emulator Android/iOS**

## 📂 Struktur Proyek
```
.
├── lib
│   ├── main.dart             # Entry point aplikasi
│   ├── home_page.dart        # UI utama aplikasi
│   ├── tflite_service.dart   # Fungsi untuk menjalankan model TFLite
├── assets
│   ├── mobilenetv3_tanaman.tflite  # Model yang digunakan
│   └── labels.txt                  # Label untuk model klasifikasi
├── pubspec.yaml                # Dependencies proyek
└── README.md                   # Dokumentasi proyek ini
```

## 🔧 Instalasi
1. Clone repository ini:
   ```sh
   git clone https://github.com/ade-m/flutter-tflite-deteksi-tanaman.git
   cd flutter-tflite-deteksi-tanaman
   ```

2. Install dependensi:
   ```sh
   flutter pub get
   ```

3. Tambahkan model ke dalam **assets** (jika belum ada):
    - **mobilenetv3_tanaman.tflite** (model deteksi tanaman)
    - **labels.txt** (label untuk tiap kelas tanaman)

4. Pastikan konfigurasi assets ada di **pubspec.yaml**:
   ```yaml
   flutter:
     assets:
       - assets/mobilenetv3_tanaman.tflite
       - assets/labels.txt
   ```

5. Jalankan aplikasi:
   ```sh
   flutter run
   ```

## 🛠️ Cara Kerja
1. Pengguna memilih gambar dari galeri atau kamera.
2. Gambar diproses dan dikirim ke **TFLite**.
3. Model mengembalikan prediksi berupa **label** dan **akurasi**.
4. Hasil ditampilkan di UI aplikasi.

## 🏗️ Penggunaan Model TFLite
Pastikan file **mobilenetv3_tanaman.tflite** dimuat dengan benar di dalam kode:
```dart
import 'package:tflite/tflite.dart';

class TFLiteService {
  Future<void> loadModel() async {
    await Tflite.loadModel(
      model: "assets/mobilenetv3_tanaman.tflite",
      labels: "assets/labels.txt",
    );
  }

  Future<List?> runModel(Uint8List imageBytes) async {
    return await Tflite.runModelOnImage(
      bytesList: imageBytes,
      imageMean: 127.5,
      imageStd: 127.5,
      numResults: 5,
      threshold: 0.4,
    );
  }
}
```

## 📱 Screenshot

## 📝 Lisensi
Proyek ini dirilis di bawah lisensi **MIT**.

---
📌 **Dibuat oleh Ade Maulana**  
📷 **Instagram:** [@ademaulana_](https://www.instagram.com/ademaulana_)  
🎵 **TikTok:** [@ademaulana_4](https://www.tiktok.com/@ademaulana_4)  
💻 **GitHub:** [ade-m](https://github.com/ade-m)  
