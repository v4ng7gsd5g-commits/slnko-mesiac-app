import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:motion_sensors/motion_sensors.dart';
import 'dart:math' as math;

// ... (ponechaj globálne premenné a main funkciu z minula)

class _SunToMoonAppState extends State<SunToMoonApp> {
  // Senzory
  double _azimuth = 0; // Smer (kompas)
  double _pitch = 0;   // Sklon (hore/dole)
  
  // Výpočet fázy mesiaca (veľmi zjednodušene pre demo)
  String getMoonPhaseUrl() {
    // V reálnej appke by sme použili knižnicu na presný výpočet fázy
    // Teraz použijeme PNG s priehľadným pozadím pre realizmus
    return "https://upload.wikimedia.org/wikipedia/commons/2/20/Moon_Illumination_67%25.png";
  }

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    
    // Sledovanie pohybu telefónu
    motionSensors.absoluteOrientation.listen((AbsoluteOrientationEvent event) {
      setState(() {
        _azimuth = event.yaw;   // Otáčanie okolo vlastnej osi
        _pitch = event.pitch;   // Náklon vpred/vzad
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // ... (základná kontrola kamery)

    // Výpočet pozície Mesiaca na obrazovke podľa senzorov
    // 0.05 je mierka citlivosti, aby sa Mesiac hýbal prirodzene
    double screenX = MediaQuery.of(context).size.width / 2 + (math.tan(_azimuth) * 500);
    double screenY = MediaQuery.of(context).size.height / 2 + (math.tan(_pitch) * 500);

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: CameraPreview(controller!)),

          // REALISTICKÝ MESIAC
          Positioned(
            left: screenX - 25, // Malá realistická veľkosť (50px)
            top: screenY - 25,
            child: Opacity(
              opacity: 0.9,
              child: Image.network(
                getMoonPhaseUrl(),
                width: 50, // Realistická veľkosť na oblohe
                height: 50,
              ),
            ),
          ),
          
          // ... (tlačidlo)
        ],
      ),
    );
  }
}