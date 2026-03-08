import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:apsl_sun_calc/apsl_sun_calc.dart';

// Globálna premenná pre zoznam kamier
late List<CameraDescription> _cameras;

Future<void> main() async {
  // Inicializácia Flutteru a kamier pred spustením appky
  WidgetsFlutterBinding.ensureInitialized();
  _cameras = await availableCameras();
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

  @override
  void initState() {
    super.initState();
    // Použijeme zadnú kameru (index 0)
    controller = CameraController(_cameras[0], ResolutionPreset.high);
    controller!.initialize().then((_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  // Funkcia na "výmenu" slnka za mesiac
  Future<void> swapSunForMoon() async {
    // 1. Získaj povolenie a GPS polohu
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) return;

    Position pos = await Geolocator.getCurrentPosition();
    
    // 2. Vypočítaj polohu slnka (vráti azimut a výšku)
    var sunPos = SunCalc.getSunPosition(DateTime.now(), pos.latitude, pos.longitude);

    // 3. Logika umiestnenia na obrazovku 
    // Poznámka: Pre úplnú presnosť by sme potrebovali kompas (senzor orientácie)
    // Pre túto verziu umiestnime mesiac do stredu, kde predpokladáme slnko
    setState(() {
      moonX = MediaQuery.of(context).size.width / 2;
      moonY = MediaQuery.of(context).size.height / 3;
      isMoonVisible = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (controller == null || !controller!.value.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Stack(
        children: [
          // Živý náhľad z kamery cez celú obrazovku
          Positioned.fill(
            child: CameraPreview(controller!),
          ),

          // Zobrazíme obrázok mesiaca, ak bol aktivovaný
          if (isMoonVisible)
            Positioned(
              left: moonX - 75, // Centrovanie (polovica šírky obrázka)
              top: moonY - 75,
              child: Image.network(
                'https://upload.wikimedia.org/wikipedia/commons/e/e1/FullMoon2010.jpg',
                width: 150,
                height: 150,
              ),
            ),

          // Ovládacie tlačidlo
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