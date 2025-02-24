import 'package:flutter/material.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img; // Resmi işlemek için
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Interpreter interpreter;
  File? _image;
  final picker = ImagePicker();
  List<String> labels = [];
  List<String> detectedObjects = [];
  bool isModelLoaded = false;

  @override
  void initState() {
    super.initState();
    loadModel().then((_) {
      setState(() {
        isModelLoaded = true;
      });
    });
    loadLabels();
  }

  /// 📌 TensorFlow Lite Modelini Yükleme
  Future<void> loadModel() async {
    try {
      var interpreterOptions = InterpreterOptions();
      interpreter = await Interpreter.fromAsset(
        'assets/mobilenet_ssd.tflite',
        options: interpreterOptions,
      );

      print('✅ Model başarıyla yüklendi!');
      print('📌 Model giriş şekli: ${interpreter.getInputTensor(0).shape}');
      print('📌 Model çıkış şekli: ${interpreter.getOutputTensor(0).shape}');
      print('📌 Model giriş tipi: ${interpreter.getInputTensor(0).type}');
    } catch (e) {
      print('❌ Model yüklenirken hata oluştu: $e');
    }
  }

  /// 📌 Label Dosyasını Yükleme
  Future<void> loadLabels() async {
    final labelsTxt = await rootBundle.loadString('assets/labelmap.txt');
    final lines = labelsTxt.split('\n');
    labels = lines.map((e) => e.trim()).toList();
    print('✅ Label dosyası yüklendi: $labels');
  }

  /// 📸 Kullanıcının Kamera veya Galeriden Fotoğraf Seçmesini Sağlama
  Future<void> pickImage(ImageSource source) async {
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });

      if (isModelLoaded) {
        analyzeImage(_image!);
      }
    }
  }

  /// 📊 Fotoğrafı TensorFlow Lite Modeline Gönderip Analiz Etme
  /// 📊 Fotoğrafı TensorFlow Lite Modeline Gönderip Analiz Etme
Future<void> analyzeImage(File image) async {
  if (!isModelLoaded || interpreter == null) {
    print("⚠️ Model henüz yüklenmedi veya interpreter null!");
    return;
  }

  print("📸 Resim başarıyla seçildi. Analiz başlatılıyor...");

  // 📌 Resmi yükle ve uygun formata getir
  var imageBytes = image.readAsBytesSync();
  img.Image? imageInput = img.decodeImage(imageBytes);
  if (imageInput == null) {
    print("⚠️ Görüntü decode edilemedi!");
    return;
  }

  print("📌 Görüntü başarıyla decode edildi.");

  // 📌 Modelin giriş boyutuna uygun yeniden boyutlandırma
  img.Image resizedImage = img.copyResize(imageInput, width: 300, height: 300);
  print("📌 Görüntü 300x300 boyutuna küçültüldü.");

  // 📌 TensorFlow Lite için uygun format: [1, 300, 300, 3]
  List<List<List<List<int>>>> input = List.generate(1, (i) =>
      List.generate(300, (j) =>
          List.generate(300, (k) => List.filled(3, 128))));  // 128 çünkü modelin sıfır noktası bu.

  // 📌 Resmin piksellerini giriş dizisine aktar
  // 📌 Resmin piksellerini giriş dizisine aktar
for (int y = 0; y < 300; y++) {
  for (int x = 0; x < 300; x++) {
    final pixel = resizedImage.getPixel(x, y);
    input[0][y][x][0] = pixel.r.toInt(); // Kırmızı kanal
    input[0][y][x][1] = pixel.g.toInt(); // Yeşil kanal
    input[0][y][x][2] = pixel.b.toInt();  // Mavi kanal
  }
} // ❗ Eksik olan kapatma süslü parantezi eklendi

print("📌 Model giriş verisi hazır.");

  // 📌 Modelin çıkış formatını hazırla
  var output = List.generate(1, (i) =>
      List.generate(10, (j) => List.filled(4, 0.0)));  // ✅ Model çıkışı: [1, 10, 4]

  // 📌 Modeli çalıştır ve tahminleri al
  try {
    interpreter.run(input, output);
    print("✅ Model çalıştırıldı! Sonuçlar alındı.");
  } catch (e) {
    print("❌ Model çalıştırılırken hata oluştu: $e");
    return;
  }

  setState(() {
    detectedObjects = output[0]
        .map((obj) => "Nesne: ${obj[0]}, Güven: ${obj[1]}")  // İlk sütun nesne kimliği, ikinci sütun güven skoru
        .toList();
  });

  print('🎯 Algılanan nesneler: $detectedObjects');
}





  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: Text("TensorFlow Lite Ürün Algılama")),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _image == null
                ? Text("Henüz bir fotoğraf seçilmedi.", style: TextStyle(fontSize: 16))
                : Image.file(_image!, height: 300),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  icon: Icon(Icons.camera),
                  label: Text("Kamerayı Aç"),
                  onPressed: isModelLoaded ? () => pickImage(ImageSource.camera) : null,
                ),
                SizedBox(width: 20),
                ElevatedButton.icon(
                  icon: Icon(Icons.photo_library),
                  label: Text("Galeriden Seç"),
                  onPressed: isModelLoaded ? () => pickImage(ImageSource.gallery) : null,
                ),
              ],
            ),
            SizedBox(height: 20),
            detectedObjects.isEmpty
                ? Text("⚠️ Nesne algılanamadı.", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))
                : Column(
                    children: detectedObjects
                        .map((obj) => Text("🟢 Algılanan: $obj", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)))
                        .toList(),
                  ),
          ],
        ),
      ),
    );
  }
}
