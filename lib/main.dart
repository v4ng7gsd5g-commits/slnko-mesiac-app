import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:motion_sensors/motion_sensors.dart';
import 'dart:math' as math;

// Globálna premenná pre kamery
late List<CameraDescription> _cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _cameras = await availableCameras();
  runApp(const SunToMoonApp());
}

// TOTO TI CHÝBALO - Definícia hlavnej triedy appky
class SunToMoonApp extends StatefulWidget {
  const SunToMoonApp({super.key});

  @override
  State<SunToMoonApp> createState() => _SunToMoonAppState();
}

class _SunToMoonAppState extends State<SunToMoonApp> {
  // TOTO TI CHÝBALO - Premenná pre kameru
  CameraController? controller;

  // Senzory
  double _azimuth = 0; // Smer (kompas)
  double _pitch = 0;   // Sklon (hore/dole)
  
  // Výpočet fázy mesiaca
  String getMoonPhaseUrl() {
    return "https://upload.wikimedia.org/wikipedia/commons/2/20/Moon_Illumination_67%25.png";
  }

  // TOTO TI CHÝBALO - Metóda na zapnutie kamery
  void _initializeCamera() {
    if (_cameras.isEmpty) return;
    controller = CameraController(_cameras[0], ResolutionPreset.max);
    controller!.initialize().then((_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void initState() {
    super.initState();
    _initializeCamera(); // Teraz už Xcode túto metódu nájde
    
    // Sledovanie pohybu telefónu
    motionSensors.absoluteOrientation.listen((AbsoluteOrientationEvent event) {
      setState(() {
        _azimuth = event.yaw;   // Otáčanie okolo vlastnej osi
        _pitch = event.pitch;   // Náklon vpred/vzad
      });
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Základná kontrola kamery, aby appka nespadla
    if (controller == null || !controller!.value.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Výpočet pozície Mesiaca na obrazovke podľa senzorov
    double screenX = MediaQuery.of(context).size.width / 2 + (math.tan(_azimuth) * 500);
    double screenY = MediaQuery.of(context).size.height / 2 + (math.tan(_pitch) * 500);

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: CameraPreview(controller!)),

          // REALISTICKÝ MESIAC
          Positioned(
            left: screenX - 25, 
            top: screenY - 25,
            child: Opacity(
              opacity: 0.9,
              child: Image.network(
                getMoonPhaseUrl(),
                width: 50, 
                height: 50,
              ),
            ),
          ),
          
          // Informačný text
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(10),
                color: Colors.black54,
                child: const Text('Hľadaj Mesiac pohybom telefónu', style: TextStyle(color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}