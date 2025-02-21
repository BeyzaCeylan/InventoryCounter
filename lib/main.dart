import 'package:flutter/material.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
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

  @override
  void initState() {
    super.initState();
    initializeFirebase();
    loadModel();
  }

  /// Firebase'in düzgün çalıştığını kontrol eden fonksiyon
  Future<void> initializeFirebase() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print("✅ Firebase başarıyla başlatıldı!");
    } catch (e) {
      print("❌ Firebase başlatılırken hata oluştu: $e");
    }
  }

  Future<void> loadModel() async {
    try {
      interpreter = await Interpreter.fromAsset('assets/mobilenet_ssd.tflite');
      print('✅ Model başarıyla yüklendi!');
    } catch (e) {
      print('❌ Model yüklenirken hata oluştu: $e');
    }
  }

  Future<void> pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text("TensorFlow Lite & Firebase Test")),
        body: Column(
          children: [
            _image == null
                ? Text("Henüz bir fotoğraf çekilmedi.")
                : Image.file(_image!),
            ElevatedButton(
              onPressed: pickImage,
              child: Text("Fotoğraf Çek"),
            ),
          ],
        ),
      ),
    );
  }
}
