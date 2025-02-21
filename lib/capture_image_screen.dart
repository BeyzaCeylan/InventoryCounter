import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class CaptureImageScreen extends StatefulWidget {
  @override
  _CaptureImageScreenState createState() => _CaptureImageScreenState();
}

class _CaptureImageScreenState extends State<CaptureImageScreen> {
  File? _selectedImage;  // Seçilen fotoğrafı saklayacak değişken
  final picker = ImagePicker();  // ImagePicker nesnesi oluştur

  /// 📸 Kamera ile fotoğraf çek veya galeriden seç
  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Fotoğraf Çek & Yükle")),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _selectedImage == null
              ? Text("Henüz bir fotoğraf seçilmedi.", style: TextStyle(fontSize: 16))
              : Image.file(_selectedImage!, height: 300), // Seçilen fotoğrafı göster
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                icon: Icon(Icons.camera),
                label: Text("Kamerayı Aç"),
                onPressed: () => _pickImage(ImageSource.camera),
              ),
              SizedBox(width: 20),
              ElevatedButton.icon(
                icon: Icon(Icons.photo_library),
                label: Text("Galeriden Seç"),
                onPressed: () => _pickImage(ImageSource.gallery),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
