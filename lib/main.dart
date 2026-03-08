import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:apsl_sun_calc/apsl_sun_calc.dart';

// Globálna premenná pre zoznam kamier - inicializujeme ju ako prázdny zoznam
List<CameraDescription> _cameras = [];

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    _cameras = await availableCameras();
  } catch (e) {
    debugPrint("Chyba pri inicializácii kamier: $e");
  }
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: SunToMoonApp(),
  ));
}

class SunToMoonApp extends StatefulWidget {
  const SunToMoonApp({super.key});

  @override
  State<SunToMoonApp> createState() => _SunToMoonAppState();
}

class _SunToMoonAppState extends State<SunToMoonApp> {
  CameraController? controller;
  bool isMoonVisible = false;
  double moonX = 0;
  double moonY = 0;
  String errorMessage = "";

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  // Bezpečná inicializácia kamery
  Future<void> _initializeCamera() async {
    if (_cameras.isEmpty) {
      setState(() => errorMessage = "Nenašli sa žiadne kamery.");
      return;
    }

    controller = CameraController(
      _cameras[0], 
      ResolutionPreset.high,
      enableAudio: false, // Vypnutie audia často predchádza pádom
    );

    try {
      await controller!.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        setState(() => errorMessage = "Chyba kamery: $e");
      }
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  Future<void> swapSunForMoon() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.deniedForever) {
        setState(() => errorMessage = "Povoľte GPS v nastaveniach.");
        return;
      }

      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low
      );
      
      // Výpočet (zatiaľ len orientačný pre stred obrazovky)
      setState(() {
        moonX = MediaQuery.of(context).size.width / 2;
        moonY = MediaQuery.of(context).size.height / 3;
        isMoonVisible = true;
      });
    } catch (e) {
      debugPrint("Chyba GPS: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ak nastala chyba, zobrazíme ju namiesto pádu
    if (errorMessage.isNotEmpty) {
      return Scaffold(body: Center(child: Text(errorMessage, textAlign: TextAlign.center)));
    }

    // Ak sa kamera ešte načítava
    if (controller == null || !controller!.value.isInitialized) {
      return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: CameraPreview(controller!),
          ),

          if (isMoonVisible)
            Positioned(
              left: moonX - 75,
              top: moonY - 75,
              child: Image.network(
                'https://upload.wikimedia.org/wikipedia/commons/e/e1/FullMoon2010.jpg',
                width: 150,
                height: 150,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.nightlight_round, size: 100, color: Colors.yellow),
              ),
            ),

          Positioned(
            bottom: 50,
            left: 50,
            right: 50,
            child: ElevatedButton.icon(
              onPressed: swapSunForMoon,
              icon: const Icon(Icons.auto_awesome),
              label: const Text("ZAMEŇ SLNKO ZA MESIAC"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(15),
                backgroundColor: Colors.white.withOpacity(0.8),
                foregroundColor: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}