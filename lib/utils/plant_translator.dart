// lib/utils/plant_translator.dart
Map<String, String> _plantTranslations = {
  "aloevera": "Lidah Buaya",
  "banana": "Pisang",
  "bilimbi": "Belimbing Wuluh",
  "cantaloupe": "Melon Jingga",
  "cassava": "Singkong",
  "coconut": "Kelapa",
  "corn": "Jagung",
  "cucumber": "Mentimun",
  "curcuma": "Temulawak",
  "eggplant": "Terong",
  "eggplant": "Terung",
  "galangal": "Lengkuas",
  "ginger": "Jahe",
  "guava": "Jambu Biji",
  "kangkung": "Kangkung",
  "longbeans": "Kacang Panjang",
  "mango": "Mangga",
  "melon": "Melon",
  "orange": "Jeruk",
  "paddy": "Padi",
  "papaya": "Pepaya",
  "peperchili": "Cabai Rawit",
  "pineapple": "Nanas",
  "pomelo": "Jeruk Bali",
  "shallot": "Bawang Merah",
  "soybeans": "Kedelai",
  "spinach": "Bayam",
  "sweetpotatoes": "Ubi Jalar",
  "tobacco": "Tembakau",
  "waterapple": "Jambu Air",
  "watermelon": "Semangka",
};
String reverseTranslatePlantName(String namaTanaman) {
  print("Menerjemahkan: $namaTanaman"); // Debugging

  if (_reversePlantTranslations.containsKey(namaTanaman)) {
    return _reversePlantTranslations[namaTanaman]!;
  } else {
    print("Tidak ditemukan: $namaTanaman"); // Debugging
    return "default";
  }
}

String translatePlantName(String classifiedPlantName) {
  return _plantTranslations[classifiedPlantName.toLowerCase()] ?? classifiedPlantName;
}

Map<String, String> _reversePlantTranslations = {
  for (var entry in _plantTranslations.entries) entry.value: entry.key
};




