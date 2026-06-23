import 'package:flutter/material.dart';
import 'dart:math';

void main() {
  runApp(const TidalStreamApp());
}

class TidalStreamApp extends StatelessWidget {
  const TidalStreamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tidal Stream Calculator Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF0F2027),
        scaffoldBackgroundColor: const Color(0xFF203A43),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFF2C94C), // Marine Gold
          secondary: Colors.cyanAccent,
        ),
      ),
      home: const TidalCalculatorHomePage(),
    );
  }
}

class TidalCalculatorHomePage extends StatefulWidget {
  const TidalCalculatorHomePage({super.key});

  @override
  State<TidalCalculatorHomePage> createState() => _TidalCalculatorHomePageState();
}

class _TidalCalculatorHomePageState extends State<TidalCalculatorHomePage> {
  final _formKey = GlobalKey<FormState>();
  
  final _hwRateController = TextEditingController(text: "4.5");
  final _lwRateController = TextEditingController(text: "1.2");
  final _timeFromHWController = TextEditingController(text: "3.5");
  final _directionController = TextEditingController(text: "045");
  final _locationController = TextEditingController(text: "San Bernardino Strait");

  double? calculatedRate;
  double? calculatedDirection;
  List<Map<String, String>> calculationLog = [];
  
  double currentLat = 12.5125;
  double currentLng = 124.2847;

  final List<Map<String, dynamic>> presets = [
    {"name": "San Bernardino Strait", "hw": "5.2", "lw": "0.8", "dir": "125", "lat": 12.5125, "lng": 124.2847},
    {"name": "Singapore Strait (Eastern)", "hw": "4.2", "lw": "1.1", "dir": "075", "lat": 1.2800, "lng": 104.1000},
    {"name": "English Channel (Dover)", "hw": "3.8", "lw": "0.5", "dir": "240", "lat": 51.1278, "lng": 1.3132},
    {"name": "Malacca Strait", "hw": "2.5", "lw": "0.4", "dir": "310", "lat": 2.5000, "lng": 101.5000},
  ];

  void _loadPreset(Map<String, dynamic> preset) {
    setState(() {
      _locationController.text = preset["name"]!;
      _hwRateController.text = preset["hw"]!;
      _lwRateController.text = preset["lw"]!;
      _directionController.text = preset["dir"]!;
      currentLat = preset["lat"]!;
      currentLng = preset["lng"]!;
    });
  }

  void _calculateTidalStream() {
    if (_formKey.currentState!.validate() && _locationController.text.isNotEmpty) {
      double hwRate = double.parse(_hwRateController.text);
      double lwRate = double.parse(_lwRateController.text);
      double timeFromHW = double.parse(_timeFromHWController.text);
      double direction = double.parse(_directionController.text);

      double angle = (timeFromHW.clamp(0.0, 6.0) / 6.0) * pi;
      double factor = (cos(angle) + 1) / 2;
      
      setState(() {
        calculatedRate = lwRate + (factor * (hwRate - lwRate));
        calculatedDirection = direction;

        calculationLog.insert(0, {
          "id": DateTime.now().millisecondsSinceEpoch.toString(),
          "loc": _locationController.text,
          "rate": "${calculatedRate!.toStringAsFixed(2)} kts",
          "dir": "${calculatedDirection!.toStringAsFixed(0)}°",
          "time": "${timeFromHW.toStringAsFixed(1)}h from HW"
        });
      });
    }
  }

  void _deleteLogItem(String id) {
    setState(() {
      calculationLog.removeWhere((item) => item["id"] == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'TIDAL STREAM WORLDWIDE',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Color(0xFFF2C94C)),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF0F2027),
        elevation: 10,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 🗺️ 1. BUILT-IN RADAR MAP RADIAL MONITOR
                const Text("LIVE POSITION RADAR VIEW", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
                const SizedBox(height: 6),
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.cyanAccent.withOpacity(0.4), width: 1),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: Stack(
                      children: [
                        CustomPaint(
                          size: const Size(double.infinity, 180),
                          painter: MarineRadarPainter(direction: double.tryParse(_directionController.text) ?? 0.0),
                        ),
                        Positioned(
                          top: 10,
                          left: 12,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_locationController.text.isEmpty ? "No Target Selected" : _locationController.text, style: const TextStyle(color: Color(0xFFF2C94C), fontWeight: FontWeight.bold, fontSize: 14)),
                              Text("LAT: ${currentLat.toStringAsFixed(4)}° N", style: const TextStyle(color: Colors.white70, fontSize: 11, fontFamily: 'monospace')),
                              Text("LNG: ${currentLng.toStringAsFixed(4)}° E", style: const TextStyle(color: Colors.white70, fontSize: 11, fontFamily: 'monospace')),
                            ],
                          ),
                        ),
                        const Positioned(
                          bottom: 10,
                          right: 12,
                          child: Row(
                            children: [
                              Icon(Icons.gps_fixed, color: Colors.redAccent, size: 12),
                              SizedBox(width: 4),
                              Text("GPS REF LOCK", style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 15),

                // 2. WORLDWIDE PRESETS DROPDOWN (Naitama na ang typo dito)
                Card(
                  color: Colors.black26,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Colors.cyanAccent, width: 0.5),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<Map<String, dynamic>>(
                        hint: const Row(
                          children: [
                            Icon(Icons.public, color: Colors.cyanAccent),
                            SizedBox(width: 10),
                            Text("Load Worldwide Preset Straits...", style: TextStyle(color: Colors.cyanAccent)),
                          ],
                        ),
                        dropdownColor: const Color(0xFF0F2027),
                        items: presets.map((preset) {
                          return DropdownMenuItem<Map<String, dynamic>>(
                            value: preset,
                            child: Text(preset["name"]!),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) _loadPreset(value);
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Inputs
                _buildInputField(controller: _locationController, label: "Location / Voyage Leg", icon: Icons.map, isText: true),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildInputField(controller: _hwRateController, label: "HW Rate (kts)", icon: Icons.trending_up)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildInputField(controller: _lwRateController, label: "LW Rate (kts)", icon: Icons.trending_down)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildInputField(controller: _timeFromHWController, label: "Time fr. HW (hrs)", icon: Icons.access_time)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildInputField(controller: _directionController, label: "Direction (°)", icon: Icons.navigation, isDirection: true)),
                  ],
                ),
                const SizedBox(height: 15),

                // Calculate Button
                ElevatedButton(
                  onPressed: _calculateTidalStream,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: const Color(0xFFF2C94C),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text("COMPUTE & RECORD", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                
                // Live Graph Result Card
                if (calculatedRate != null) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.greenAccent, width: 1),
                    ),
                    child: Column(
                      children: [
                        const Text("INTERPOLATION LIVE GRAPH", style: TextStyle(fontSize: 12, color: Colors.grey, letterSpacing: 1)),
                        const SizedBox(height: 15),
                        CustomPaint(
                          size: const Size(double.infinity, 80),
                          painter: TidalCurvePainter(double.tryParse(_timeFromHWController.text) ?? 0.0),
                        ),
                        const SizedBox(height: 15),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildResultItem("ESTIMATED DRIFT", "${calculatedRate!.toStringAsFixed(2)} kts", Colors.white),
                            _buildResultItem("SET DIRECTION", "${calculatedDirection!.toStringAsFixed(0)}°", const Color(0xFFF2C94C)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],

                // 3. BRIDGE LOGBOOK RECORD
                if (calculationLog.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Text("BRIDGE LOGBOOK RECORD", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 220),
                    decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(8)),
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const ClampingScrollPhysics(),
                      itemCount: calculationLog.length,
                      itemBuilder: (context, index) {
                        final log = calculationLog[index];
                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.assignment, color: Color(0xFFF2C94C)),
                          title: Text(log["loc"]!, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text("${log["time"]} | Dir: ${log["dir"]}"),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(log["rate"]!, style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 14)),
                              const SizedBox(width: 6),
                              IconButton(
                                icon: const Icon(Icons.delete_sweep, color: Colors.redAccent, size: 22),
                                onPressed: () => _deleteLogItem(log["id"]!),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({required TextEditingController controller, required String label, required IconData icon, bool isText = false, bool isDirection = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: isText ? TextInputType.text : const TextInputType.numberWithOptions(decimal: true),
      onChanged: (val) {
        if (isDirection) {
          setState(() {}); 
        }
      },
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFFF2C94C)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.grey)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFF2C94C))),
        filled: true,
        fillColor: Colors.black12,
      ),
    );
  }

  Widget _buildResultItem(String title, String val, Color color) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        Text(val, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}

class MarineRadarPainter extends CustomPainter {
  final double direction;
  MarineRadarPainter({required this.direction});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) * 0.45;

    final ringPaint = Paint()
      ..color = Colors.cyanAccent.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawCircle(center, radius, ringPaint);
    canvas.drawCircle(center, radius * 0.66, ringPaint);
    canvas.drawCircle(center, radius * 0.33, ringPaint);

    canvas.drawLine(Offset(center.dx - radius, center.dy), Offset(center.dx + radius, center.dy), ringPaint);
    canvas.drawLine(Offset(center.dx, center.dy - radius), Offset(center.dx, center.dy + radius), ringPaint);

    double radians = (direction - 90) * pi / 180;
    final vectorX = center.dx + radius * cos(radians);
    final vectorY = center.dy + radius * sin(radians);

    final streamPaint = Paint()
      ..color = const Color(0xFFF2C94C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawLine(center, Offset(vectorX, vectorY), streamPaint);
    
    final blipPaint = Paint()
      ..color = Colors.redAccent
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 5, blipPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class TidalCurvePainter extends CustomPainter {
  final double timeFromHW;
  TidalCurvePainter(this.timeFromHW);

  @override
  void paint(Canvas canvas, Size size) {
    final paintCurve = Paint()
      ..color = Colors.cyanAccent.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final paintDot = Paint()
      ..color = Colors.redAccent
      ..style = PaintingStyle.fill;

    final path = Path();
    for (double x = 0; x <= size.width; x++) {
      double t = (x / size.width) * 6.0;
      double y = (cos((t / 6.0) * pi) + 1) / 2 * size.height;
      if (x == 0) {
        path.moveTo(x, size.height - y);
      } else {
        path.lineTo(x, size.height - y);
      }
    }
    canvas.drawPath(path, paintCurve);

    double dotX = (timeFromHW.clamp(0.0, 6.0) / 6.0) * size.width;
    double dotY = (cos((timeFromHW.clamp(0.0, 6.0) / 6.0) * pi) + 1) / 2 * size.height;
    canvas.drawCircle(Offset(dotX, size.height - dotY), 6, paintDot);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
