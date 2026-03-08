import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:motion_sensors/motion_sensors.dart';
import 'package:apsl_sun_calc/apsl_sun_calc.dart';
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
  double _azimuth = 0.0;
  double _elevation = 0.0;
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
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) return;

    _currentPosition = await Geolocator.getCurrentPosition();
    
    // Prístup k mape pomocou ['kľúča'] podľa tvojho logu
    final moonPos = SunCalc.getMoonPosition(
      DateTime.now(),
      _currentPosition!.latitude,
      _currentPosition!.longitude,
    );

    setState(() {
      _azimuth = moonPos['azimuth']?.toDouble() ?? 0.0;
      _elevation = moonPos['altitude']?.toDouble() ?? 0.0;
    });
  }

  void _initializeSensors() {
    // OPRAVENÝ RIADOK 72: Používame .orientation namiesto .relativeOrientation
    _sensorsSubscription = motionSensors.orientation.listen((event) {
      setState(() {
        _deviceYaw = event.x; // Yaw
        _devicePitch = event.y; // Pitch
      });
    });
  }

  Future<void> _takePicture() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized || _isTakingPicture) return;
    try {
      setState(() => _isTakingPicture = true);
      final XFile picture = await _cameraController!.takePicture();
      if (!mounted) return;
      Share.shareXFiles([picture], text: 'Môj Mesiac v AR!');
    } catch (e) {
      debugPrint("Chyba: $e");
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

    final size = MediaQuery.of(context).size;
    
    // Výpočet pozície Mesiaca na obrazovke
    double moonX = (size.width / 2) + ((_azimuth - _deviceYaw) * 800);
    double moonY = (size.height / 2) - ((_elevation - _devicePitch) * 800);

    return Scaffold(
      body: Stack(
        children: [
          // Pozadie kamery
          Positioned.fill(child: CameraPreview(_cameraController!)),
          
          // AR Mesiac
          Positioned(
            left: moonX - 60,
            top: moonY - 60,
            child: const Text('🌕', style: TextStyle(fontSize: 120)),
          ),
          
          // Tlačidlo fotoaparátu
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: IconButton(
                icon: const Icon(Icons.camera_alt, color: Colors.white, size: 60),
                onPressed: _takePicture,
              ),
            ),
          ),
        ],
      ),
    );
  }
}