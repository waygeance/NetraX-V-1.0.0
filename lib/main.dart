import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:flutter_tts/flutter_tts.dart'; // Import the flutter_tts package
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  final firstCamera = cameras.first;
  runApp(MyApp(camera: firstCamera));
}

class MyApp extends StatelessWidget {
  final CameraDescription camera;

  MyApp({required this.camera});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: CameraPreviewScreen(camera: camera),
    );
  }
}

class CameraPreviewScreen extends StatefulWidget {
  final CameraDescription camera;

  CameraPreviewScreen({required this.camera});

  @override
  _CameraPreviewScreenState createState() => _CameraPreviewScreenState();
}

class _CameraPreviewScreenState extends State<CameraPreviewScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  final FlutterTts flutterTts = FlutterTts(); // Initialize FlutterTts

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.high,
    );
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _recognizeText() async {
    try {
      await _initializeControllerFuture;

      // Take a picture and save it to a temporary directory
      final image = await _controller.takePicture();
      final inputImage = InputImage.fromFilePath(image.path);

      // Initialize the text recognizer with Devanagari script
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.devanagiri);
      final recognizedText = await textRecognizer.processImage(inputImage);

      // Collect the recognized text
      String fullText = recognizedText.text;

      // Print the recognized text to the console
      print(fullText);

      // Set the TTS language to Hindi
      await flutterTts.setLanguage("hi-IN");

      // Convert text to speech in Hindi
      await flutterTts.speak(fullText);

      // Clean up resources
      await textRecognizer.close();
    } catch (e) {
      print("Error recognizing text: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Camera Preview')),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return CameraPreview(_controller);
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _recognizeText,
        child: Icon(Icons.camera),
      ),
    );
  }
}
