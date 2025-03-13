class Plant {
  final String nama;
  final String deskripsi;
  final String waktuPanen;
  final List<String> perawatan;
  final List<String> keuntungan;

  Plant({
    required this.nama,
    required this.deskripsi,
    required this.waktuPanen,
    required this.perawatan,
    required this.keuntungan,
  });

  factory Plant.fromJson(Map<String, dynamic> json) {
    return Plant(
      nama: json['tanaman'],
      deskripsi: json['deskripsi'],
      waktuPanen: json['waktu_panen'],
      perawatan: List<String>.from(json['perawatan']),
      keuntungan: List<String>.from(json['keuntungan']),
    );
  }
}
