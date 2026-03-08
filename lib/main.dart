import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:motion_sensors/motion_sensors.dart';
import 'package:apsl_sun_calc/apsl_sun_calc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

late List<CameraDescription> _cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _cameras = await availableCameras();
  runApp(const MaterialApp(home: MoonARScreen(), debugShowCheckedModeBanner: false));
}

class MoonARScreen extends StatefulWidget {
  const MoonARScreen({super.key});

  @override
  State<MoonARScreen> createState() => _MoonARScreenState();
}

class _MoonARScreenState extends State<MoonARScreen> {
  CameraController? _cameraController;
  Position? _currentPosition;
  double _azimuth = 0.0; // Poloha voči severu
  double _elevation = 0.0; // Výška nad horizontom
  double _deviceYaw = 0.0;
  double _devicePitch = 0.0;
  StreamSubscription? _sensorsSubscription;
  bool _isTakingPicture = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _getLocationAndCalculateMoon();
    _initializeSensors();
  }

  void _initializeCamera() {
    _cameraController = CameraController(_cameras[0], ResolutionPreset.max, enableAudio: false);
    _cameraController!.initialize().then((_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  Future<void> _getLocationAndCalculateMoon() async {
    // 1. Vypýtame si povolenie na GPS
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) return;

    // 2. Zistíme GPS polohu
    _currentPosition = await Geolocator.getCurrentPosition();
    
    // 3. Vypočítame polohu Mesiaca (Azimut a Elevácia)
    final moonPos = SunCalc.getMoonPosition(
      DateTime.now(),
      _currentPosition!.latitude,
      _currentPosition!.longitude,
    );

    setState(() {
      _azimuth = moonPos.azimuth; // v radiánoch
      _elevation = moonPos.altitude; // v radiánoch (apsl používa altitude ako eleváciu)
    });
  }

  void _initializeSensors() {
    motionSensors.relativeOrientationUpdateInterval = Duration.millisecondsPerSecond ~/ 60;
    _sensorsSubscription = motionSensors.relativeOrientation.listen((RelativeOrientationEvent event) {
      setState(() {
        _deviceYaw = event.yaw; // Radiány
        _devicePitch = event.pitch; // Radiány
      });
    });
  }

  Future<void> _takePicture() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized || _isTakingPicture) return;

    try {
      setState(() => _isTakingPicture = true);
      
      // Spravíme fotku
      final XFile picture = await _cameraController!.takePicture();
      
      // Ukážeme dialóg s možnosťou zdieľania
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Fotka hotová!'),
          content: Image.file(File(picture.path), height: 200),
          actions: [
            TextButton(onPressed: () => Share.shareXFiles([picture]), child: const Text('Zdieľať')),
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Zavrieť')),
          ],
        ),
      );
    } catch (e) {
      debugPrint("Chyba pri fotení: $e");
    } finally {
      setState(() => _isTakingPicture = false);
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _sensorsSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized || _currentPosition == null) {
      return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator(color: Colors.white)));
    }

    // AR VÝPOČET POZÍCIE NA OBRAZOVKE
    final size = MediaQuery.of(context).size;
    
    // Rozdiel medzi tým, kde je Mesiac a kam sa pozerá mobil
    double diffYaw = _azimuth - _deviceYaw;
    double diffPitch = _elevation - _devicePitch;

    // Citlivosť prepočtu radiánov na pixely
    double sensitivity = 800; 

    // Výsledná X a Y pozícia na displeji
    double moonX = (size.width / 2) + (diffYaw * sensitivity);
    double moonY = (size.height / 2) - (diffPitch * sensitivity);

    return Scaffold(
      body: Stack(
        children: [
          // 1. Vrstva: Kamera
          Positioned.fill(child: CameraPreview(_cameraController!)),

          // 2. Vrstva: AR Mesiac (pláva v priestore)
          Positioned(
            left: moonX - 60, // 60 je polovica veľkosti emoji
            top: moonY - 60,
            child: const Opacity(
              opacity: 0.8,
              child: Text('🌕', style: TextStyle(fontSize: 120)),
            ),
          ),
          
          // 3. Vrstva: Ovládanie fotoaparátu (dole)
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _takePicture,
                child: Container(
                  height: 80,
                  width: 80,
                  decoration: BoxDecoration(
                    color: Colors.white30,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                  child: _isTakingPicture 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Icon(Icons.camera_alt, color: Colors.white, size: 40),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}