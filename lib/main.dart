import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

// Globálna premenná pre zoznam dostupných kamier
late List<CameraDescription> _cameras;

Future<void> main() async {
  // Musíme zabezpečiť inicializáciu Fluttera pred prístupom ku kamere
  WidgetsFlutterBinding.ensureInitialized();
  
  // Získame zoznam kamier v zariadení
  _cameras = await availableCameras();
  
  runApp(const SunToMoonApp());
}

class SunToMoonApp extends StatelessWidget {
  const SunToMoonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AR Mesiac',
      home: const MoonScreen(),
    );
  }
}

class MoonScreen extends StatefulWidget {
  const MoonScreen({super.key});

  @override
  State<MoonScreen> createState() => _MoonScreenState();
}

class _MoonScreenState extends State<MoonScreen> {
  CameraController? controller;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  // Táto metóda rieši chybu "_initializeCamera isn't defined", ktorú vypísal build
  void _initializeCamera() {
    if (_cameras.isEmpty) return;
    
    controller = CameraController(_cameras[0], ResolutionPreset.max);
    controller!.initialize().then((_) {
      if (!mounted) return;
      setState(() {}); // Prekreslí obrazovku po načítaní kamery
    }).catchError((Object e) {
      if (e is CameraException) {
        print("Chyba kamery: ${e.description}");
      }
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Ak sa kamera ešte načítava, zobrazíme krúžok
    if (controller == null || !controller!.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // Pozadie z kamery (vypĺňa celú obrazovku)
          Positioned.fill(child: CameraPreview(controller!)),
          
          // Vrstva s "AR" Mesiacom v strede
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '🌕', 
                  style: TextStyle(fontSize: 120),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'MESIAC V AR',
                    style: TextStyle(
                      color: Colors.white, 
                      fontSize: 22, 
                      fontWeight: FontWeight.bold
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}