import 'package:flutter/material.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img; // Resmi yeniden boyutlandırmak için
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
  List<String> labels = []; // Label dosyasındaki nesne isimleri
  List<String> detectedObjects = []; // Algılanan nesneler burada tutulacak
  bool isModelLoaded = false; // Modelin yüklenip yüklenmediğini takip etmek için

  @override
  void initState() {
    super.initState();
    loadModel().then((_) {
      setState(() {
        isModelLoaded = true; // Model başarıyla yüklendiğinde UI'ı güncelle
      });
    });
    loadLabels();
  }

  /// 📌 TensorFlow Lite Modelini Yükleme Fonksiyonu
  Future<void> loadModel() async {
    try {
      interpreter = await Interpreter.fromAsset('assets/mobilenet_ssd.tflite');
      print('✅ Model başarıyla yüklendi!');
    } catch (e) {
      print('❌ Model yüklenirken hata oluştu: $e');
    }
  }

  /// 📌 Label Dosyasını Yükleme Fonksiyonu
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
  Future<void> analyzeImage(File image) async {
    if (!isModelLoaded) {
      print("⚠️ Model henüz yüklenmedi!");
      return;
    }

    // 📌 Resmi yükle ve TensorFlow Lite için uygun boyuta getir (224x224)
    var imageBytes = image.readAsBytesSync();
    img.Image? imageInput = img.decodeImage(imageBytes);
    if (imageInput == null) {
      print("⚠️ Görüntü decode edilemedi!");
      return;
    }

    // 📌 Modelin beklediği giriş boyutu: 224x224
    img.Image resizedImage = img.copyResize(imageInput, width: 224, height: 224);

    // 📌 Görüntüyü normalize et (0-1 arasına getir)
    List<List<List<List<double>>>> input = List.generate(1, (i) => 
      List.generate(224, (j) => 
        List.generate(224, (k) => List.filled(3, 0.0))));

    for (int y = 0; y < 224; y++) {
    for (int x = 0; x < 224; x++) {
      final pixel = resizedImage.getPixel(x, y);
      input[0][y][x][0] = pixel.r / 255.0; // R (Kırmızı)
      input[0][y][x][1] = pixel.g / 255.0; // G (Yeşil)
      input[0][y][x][2] = pixel.b / 255.0; // B (Mavi)
    }
  }

    var output = List.generate(1, (i) => List.filled(labels.length, 0.0));

    interpreter.run(input, output);

    setState(() {
      detectedObjects = output[0]
          .asMap()
          .entries
          .where((entry) => entry.value > 0.5) // %50 eşik değeri
          .map((entry) => labels[entry.key])
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
                : Image.file(_image!, height: 300), // Seçilen fotoğrafı göster
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  icon: Icon(Icons.camera),
                  label: Text("Kamerayı Aç"),
                  onPressed: isModelLoaded ? () => pickImage(ImageSource.camera) : null, // Model yüklenene kadar buton devre dışı
                ),
                SizedBox(width: 20),
                ElevatedButton.icon(
                  icon: Icon(Icons.photo_library),
                  label: Text("Galeriden Seç"),
                  onPressed: isModelLoaded ? () => pickImage(ImageSource.gallery) : null, // Model yüklenene kadar devre dışı
                ),
              ],
            ),
            SizedBox(height: 20),
            detectedObjects.isEmpty
                ? Text("Henüz analiz yapılmadı.")
                : Column(
                    children: detectedObjects
                        .map((obj) => Text(obj, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)))
                        .toList(),
                  ),
          ],
        ),
      ),
    );
  }
}

