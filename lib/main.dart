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
      title: 'Tidal Stream Worldwide',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF0F2027),
        scaffoldBackgroundColor: const Color(0xFF14262E),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFF2C94C),
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
  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();
  final _formKey3 = GlobalKey<FormState>();

  // --- TAB 1 CONTROLLERS (HEIGHT) ---
  final _locHeightController = TextEditingController(text: "Manila Harbor");
  final _hwHeightController = TextEditingController(text: "2.5");
  final _lwHeightController = TextEditingController(text: "0.4");
  final _timeHeightController = TextEditingController(text: "3.5");

  // --- TAB 2 CONTROLLERS (STANDARD GRAPH) ---
  final _locationController = TextEditingController(text: "Singapore Strait (Eastern)");
  final _latDegController = TextEditingController(text: "01");
  final _latMinController = TextEditingController(text: "16.80");
  String _latDir = "N";
  final _longDegController = TextEditingController(text: "104");
  final _longMinController = TextEditingController(text: "06.00");
  String _longDir = "E";
  final _hwRateController = TextEditingController(text: "2.5");
  final _lwRateController = TextEditingController(text: "1.0");
  final _timeFromHWController = TextEditingController(text: "3.5");
  final _directionController = TextEditingController(text: "075");

  // --- TAB 3 CONTROLLERS (ADVANCED TABLES) ---
  final _tableStationController = TextEditingController(text: "Port Reference Table");
  final _tableHwHeightController = TextEditingController(text: "5.0");
  final _tableLwHeightController = TextEditingController(text: "1.0");
  final _msrController = TextEditingController(text: "4.2");
  final _mnpController = TextEditingController(text: "1.8");
  final _streamSpringMaxController = TextEditingController(text: "3.5");
  final _streamNeapMaxController = TextEditingController(text: "1.5");

  // Calculation Results
  double? estimatedHeight;
  double? estimatedDrift;
  double? setDirection;
  double? advancedCalculatedRate;
  double? advancedSpringFactor;

  void _calculateHeight() {
    if (_formKey1.currentState!.validate()) {
      double hw = double.parse(_hwHeightController.text);
      double lw = double.parse(_lwHeightController.text);
      double duration = double.parse(_timeHeightController.text);
      double factor = (cos((duration.clamp(0.0, 6.0) / 6.0) * pi) + 1) / 2;
      setState(() {
        estimatedHeight = lw + (factor * (hw - lw));
      });
    }
  }

  void _calculateStandardDrift() {
    if (_formKey2.currentState!.validate()) {
      double hw = double.parse(_hwRateController.text);
      double lw = double.parse(_lwRateController.text);
      double duration = double.parse(_timeFromHWController.text);
      double factor = (cos((duration.clamp(0.0, 6.0) / 6.0) * pi) + 1) / 2;
      setState(() {
        estimatedDrift = lw + (factor * (hw - lw));
        setDirection = double.tryParse(_directionController.text) ?? 0.0;
      });
    }
  }

  void _calculateAdvancedStream() {
    if (_formKey3.currentState!.validate()) {
      double hwHeight = double.parse(_tableHwHeightController.text);
      double lwHeight = double.parse(_tableLwHeightController.text);
      double msr = double.parse(_msrController.text);
      double mnp = double.parse(_mnpController.text);
      double springMaxRate = double.parse(_streamSpringMaxController.text);
      double neapMaxRate = double.parse(_streamNeapMaxController.text);

      double currentRange = (hwHeight - lwHeight).abs();
      double rangeFactor = 0.5;
      if ((msr - mnp).abs() > 0.01) {
        rangeFactor = ((currentRange - mnp) / (msr - mnp)).clamp(0.0, 1.0);
      }
      setState(() {
        advancedSpringFactor = rangeFactor * 100;
        advancedCalculatedRate = neapMaxRate + (rangeFactor * (springMaxRate - neapMaxRate));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      initialIndex: 1, // Default sa Tab 2 para bubukas agad sa Standard Graph mo
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'TIDAL STREAM WORLDWIDE',
            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFF2C94C), letterSpacing: 1.2),
          ),
          centerTitle: true,
          backgroundColor: const Color(0xFF0F2027),
          elevation: 0,
          bottom: const TabBar(
            indicatorColor: Color(0xFFF2C94C),
            labelColor: Color(0xFFF2C94C),
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: "HEIGHT"),
              Tab(text: "STANDARD GRAPH"),
              Tab(text: "ADVANCED TABLES"),
            ],
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0F2027), Color(0xFF14262E)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: TabBarView(
            children: [
              SingleChildScrollView(padding: const EdgeInsets.all(16.0), child: _buildHeightTab()),
              SingleChildScrollView(padding: const EdgeInsets.all(16.0), child: _buildStandardGraphTab()),
              SingleChildScrollView(padding: const EdgeInsets.all(16.0), child: _buildAdvancedTablesTab()),
            ],
          ),
        ),
      ),
    );
  }

  // ================= TAB 1: HEIGHT TAB =================
  Widget _buildHeightTab() {
    return Form(
      key: _formKey1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildInputWrapper(
            label: "Location / Voyage Leg",
            child: TextFormField(
              controller: _locHeightController,
              decoration: const InputDecoration(border: InputBorder.none, icon: Icon(Icons.map, color: Color(0xFFF2C94C))),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInputWrapper(
                  label: "HW Height (m)",
                  child: TextFormField(
                    controller: _hwHeightController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(border: InputBorder.none, icon: Icon(Icons.trending_up, color: Color(0xFFF2C94C))),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInputWrapper(
                  label: "LW Height (m)",
                  child: TextFormField(
                    controller: _lwHeightController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(border: InputBorder.none, icon: Icon(Icons.trending_down, color: Color(0xFFF2C94C))),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInputWrapper(
            label: "Time fr. HW (hours)",
            child: TextFormField(
              controller: _timeHeightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(border: InputBorder.none, icon: Icon(Icons.access_time, color: Color(0xFFF2C94C))),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _calculateHeight,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF2C94C),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("COMPUTE HEIGHT", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          if (estimatedHeight != null) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF0F2027).withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF2C94C).withOpacity(0.4)),
              ),
              child: Column(
                children: [
                  const Text("ESTIMATED TIDAL HEIGHT", style: TextStyle(fontSize: 12, color: Colors.grey, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  Text("${estimatedHeight!.toStringAsFixed(2)} m", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
                ],
              ),
            ),
          ]
        ],
      ),
    );
  }

  // ================= TAB 2: STANDARD GRAPH (PRESERVED MATCHING 1000370543) =================
  Widget _buildStandardGraphTab() {
    return Form(
      key: _formKey2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildInputWrapper(
            label: "Location / Voyage Leg",
            child: TextFormField(
              controller: _locationController,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: const InputDecoration(border: InputBorder.none, icon: Icon(Icons.map, color: Color(0xFFF2C94C))),
            ),
          ),
          const SizedBox(height: 14),
          const Text("POSITION SPECIFICATION", style: TextStyle(fontSize: 12, color: Colors.cyanAccent, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildInputWrapper(
                  label: "Lat...",
                  child: TextFormField(controller: _latDegController, decoration: const InputDecoration(border: InputBorder.none, icon: Icon(Icons.explore, color: Color(0xFFF2C94C), size: 16))),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildInputWrapper(
                  label: "Lat Min (')",
                  child: TextFormField(controller: _latMinController, decoration: const InputDecoration(border: InputBorder.none, icon: Icon(Icons.access_time, color: Color(0xFFF2C94C), size: 16))),
                ),
              ),
              const SizedBox(width: 8),
              _buildDropdownWrapper(
                child: DropdownButton<String>(
                  value: _latDir,
                  items: ["N", "S"].map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(color: Color(0xFFF2C94C))))).toList(),
                  onChanged: (v) => setState(() => _latDir = v!),
                  underline: const SizedBox(),
                  dropdownColor: const Color(0xFF0F2027),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildInputWrapper(
                  label: "Lo...",
                  child: TextFormField(controller: _longDegController, decoration: const InputDecoration(border: InputBorder.none, icon: Icon(Icons.explore, color: Color(0xFFF2C94C), size: 16))),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildInputWrapper(
                  label: "Long Mi...",
                  child: TextFormField(controller: _longMinController, decoration: const InputDecoration(border: InputBorder.none, icon: Icon(Icons.access_time, color: Color(0xFFF2C94C), size: 16))),
                ),
              ),
              const SizedBox(width: 8),
              _buildDropdownWrapper(
                child: DropdownButton<String>(
                  value: _longDir,
                  items: ["E", "W"].map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(color: Color(0xFFF2C94C))))).toList(),
                  onChanged: (v) => setState(() => _longDir = v!),
                  underline: const SizedBox(),
                  dropdownColor: const Color(0xFF0F2027),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildInputWrapper(
                  label: "HW Rate (kts)",
                  child: TextFormField(controller: _hwRateController, decoration: const InputDecoration(border: InputBorder.none, icon: Icon(Icons.trending_up, color: Color(0xFFF2C94C), size: 16))),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInputWrapper(
                  label: "LW Rate (kts)",
                  child: TextFormField(controller: _lwRateController, decoration: const InputDecoration(border: InputBorder.none, icon: Icon(Icons.trending_down, color: Color(0xFFF2C94C), size: 16))),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildInputWrapper(
                  label: "Time fr. HW (h...",
                  child: TextFormField(controller: _timeFromHWController, decoration: const InputDecoration(border: InputBorder.none, icon: Icon(Icons.access_time, color: Color(0xFFF2C94C), size: 16))),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInputWrapper(
                  label: "Direction (°)",
                  child: TextFormField(controller: _directionController, decoration: const InputDecoration(border: InputBorder.none, icon: Icon(Icons.navigation, color: Color(0xFFF2C94C), size: 16))),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: _calculateStandardDrift,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF2C94C),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("COMPUTE & RECORD", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.5)),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black24,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF2E4E58)),
            ),
            child: Column(
              children: [
                const Text("INTERPOLATION LIVE GRAPH", style: TextStyle(fontSize: 11, color: Colors.grey, letterSpacing: 0.8)),
                const SizedBox(height: 16),
                CustomPaint(
                  size: const Size(double.infinity, 90),
                  painter: TidalSinusoidalPainter(double.tryParse(_timeFromHWController.text) ?? 0.0),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Text("ESTIMATED DRIFT", style: TextStyle(fontSize: 11, color: Colors.grey)),
                        const SizedBox(height: 4),
                        Text(estimatedDrift != null ? "${estimatedDrift!.toStringAsFixed(2)} kts" : "2.25 kts", style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
                      ],
                    ),
                    Column(
                      children: [
                        const Text("SET DIRECTION", style: TextStyle(fontSize: 11, color: Colors.grey)),
                        const SizedBox(height: 4),
                        Text(setDirection != null ? "${setDirection!.toStringAsFixed(0)}°" : "75°", style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFFF2C94C))),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= TAB 3: ADVANCED TABLES (MATCHING 1000370555) =================
  Widget _buildAdvancedTablesTab() {
    return Form(
      key: _formKey3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildInputWrapper(
            label: "Tide Station Reference",
            child: TextFormField(
              controller: _tableStationController,
              decoration: const InputDecoration(border: InputBorder.none, icon: Icon(Icons.chrome_reader_mode, color: Color(0xFFF2C94C))),
            ),
          ),
          const SizedBox(height: 16),
          const Text("1. TIDE TABLE HEIGHTS (METERS)", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.cyanAccent)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildInputWrapper(
                  label: "Today HW Hei...",
                  child: TextFormField(controller: _tableHwHeightController, decoration: const InputDecoration(border: InputBorder.none, icon: Icon(Icons.arrow_upward, color: Color(0xFFF2C94C), size: 16))),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInputWrapper(
                  label: "Today LW Hei...",
                  child: TextFormField(controller: _tableLwHeightController, decoration: const InputDecoration(border: InputBorder.none, icon: Icon(Icons.arrow_downward, color: Color(0xFFF2C94C), size: 16))),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildInputWrapper(
                  label: "Mean Spring R...",
                  child: TextFormField(controller: _msrController, decoration: const InputDecoration(border: InputBorder.none, icon: Icon(Icons.waves, color: Color(0xFFF2C94C), size: 16))),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInputWrapper(
                  label: "Mean Neap Ra...",
                  child: TextFormField(controller: _mnpController, decoration: const InputDecoration(border: InputBorder.none, icon: Icon(Icons.waves_outlined, color: Color(0xFFF2C94C), size: 16))),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text("2. STREAM TABLE VELOCITIES (KNOTS)", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.cyanAccent)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildInputWrapper(
                  label: "Max Spring Ra...",
                  child: TextFormField(controller: _streamSpringMaxController, decoration: const InputDecoration(border: InputBorder.none, icon: Icon(Icons.bolt, color: Color(0xFFF2C94C), size: 16))),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInputWrapper(
                  label: "Max Neap Rat...",
                  child: TextFormField(controller: _streamNeapMaxController, decoration: const InputDecoration(border: InputBorder.none, icon: Icon(Icons.directions_run, color: Color(0xFFF2C94C), size: 16))),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _calculateAdvancedStream,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.cyanAccent,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            child: const Text("COMPUTE INTERPOLATED STREAM", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0F2027),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.cyan.shade800),
            ),
            child: Column(
              children: [
                Text(
                  "Spring Factor: ${advancedSpringFactor?.toStringAsFixed(0) ?? "92"}%",
                  style: const TextStyle(fontSize: 12, color: Colors.alluvial, color: Colors.yellowAccent, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 6),
                const Text("CALCULATED CURRENT SPEED", style: TextStyle(fontSize: 11, color: Colors.grey)),
                const SizedBox(height: 4),
                Text(
                  advancedCalculatedRate != null ? "${advancedCalculatedRate!.toStringAsFixed(2)} kts" : "1.24 kts",
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper Custom Containers matching screen borders
  Widget _buildInputWrapper({required String label, required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF4F5D65)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          SizedBox(height: 32, child: child),
        ],
      ),
    );
  }

  Widget _buildDropdownWrapper({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF4F5D65)),
      ),
      child: Center(child: child),
    );
  }
}

// Sine wave graph matching exact visual interpolation curve
class TidalSinusoidalPainter extends CustomPainter {
  final double time;
  TidalSinusoidalPainter(this.time);

  @override
  void paint(Canvas canvas, Size size) {
    final paintCurve = Paint()
      ..color = Colors.tealAccent.shade400
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final paintDot = Paint()
      ..color = const Color(0xFFFF5252)
      ..style = PaintingStyle.fill;

    final path = Path();
    for (double x = 0; x <= size.width; x++) {
      double normalizedX = x / size.width;
      // Generates a proper smooth tide curve trajectory
      double y = (cos(normalizedX * pi) + 1) / 2 * (size.height - 20) + 10;
      if (x == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paintCurve);

    // Precise coordinates for the dynamic indicator red dot
    double ratio = (time.clamp(0.0, 6.0) / 6.0);
    double dotX = ratio * size.width;
    double dotY = (cos(ratio * pi) + 1) / 2 * (size.height - 20) + 10;
    canvas.drawCircle(Offset(dotX, dotY), 5.5, paintDot);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
