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
      title: 'Tidal Stream Pro Worldwide',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF0F2027),
        scaffoldBackgroundColor: const Color(0xFF203A43),
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
  
  final _locationController1 = TextEditingController(text: "Malacca Strait");
  final _locationController2 = TextEditingController(text: "Singapore Strait");
  final _locationController3 = TextEditingController(text: "Port Reference Table");

  // Tab 1: Standard Height Inputs (Meters)
  final _hwHeightController = TextEditingController(text: "2.5");
  final _lwHeightController = TextEditingController(text: "0.4");
  final _timeFromHWController1 = TextEditingController(text: "3.5");

  // Tab 2: Standard Drift Inputs (Knots) - Binalik ang Live Graph at Direction dito
  final _hwRateController = TextEditingController(text: "4.2");
  final _lwRateController = TextEditingController(text: "1.1");
  final _timeFromHWController2 = TextEditingController(text: "3.5");
  final _directionController = TextEditingController(text: "075");

  // Tab 3: Advanced Tables Setup
  final _tableHwHeightController = TextEditingController(text: "5.0"); 
  final _tableLwHeightController = TextEditingController(text: "1.0"); 
  final _msrController = TextEditingController(text: "4.2");            
  final _mnpController = TextEditingController(text: "1.8");            
  final _streamSpringMaxController = TextEditingController(text: "3.5"); 
  final _streamNeapMaxController = TextEditingController(text: "1.5");   

  // Outputs
  double? calculatedHeight;
  double? calculatedRate;
  double? calculatedDirection;
  double? advancedCalculatedRate;
  double? advancedSpringFactor;

  void _calculateStandardTidalHeight() {
    if (_formKey1.currentState!.validate()) {
      double hw = double.parse(_hwHeightController.text);
      double lw = double.parse(_lwHeightController.text);
      double time = double.parse(_timeFromHWController1.text);

      double angle = (time.clamp(0.0, 6.0) / 6.0) * pi;
      double factor = (cos(angle) + 1) / 2;
      
      setState(() {
        calculatedHeight = lw + (factor * (hw - lw));
      });
    }
  }

  void _calculateStandardTidalStream() {
    if (_formKey2.currentState!.validate()) {
      double hwRate = double.parse(_hwRateController.text);
      double lwRate = double.parse(_lwRateController.text);
      double time = double.parse(_timeFromHWController2.text);
      double direction = double.parse(_directionController.text);

      double angle = (time.clamp(0.0, 6.0) / 6.0) * pi;
      double factor = (cos(angle) + 1) / 2;
      
      setState(() {
        calculatedRate = lwRate + (factor * (hwRate - lwRate));
        calculatedDirection = direction;
      });
    }
  }

  void _calculateAdvancedTidalStream() {
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
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'TIDAL STREAM WORLDWIDE',
            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFF2C94C)),
          ),
          centerTitle: true,
          backgroundColor: const Color(0xFF0F2027),
          bottom: const TabBar(
            indicatorColor: Color(0xFFF2C94C),
            labelColor: Color(0xFFF2C94C),
            unselectedLabelColor: Colors.grey,
            isScrollable: true,
            tabs: [
              Tab(icon: Icon(Icons.waves), text: "STANDARD HEIGHT"),
              Tab(icon: Icon(Icons.show_chart), text: "STANDARD DRIFT"),
              Tab(icon: Icon(Icons.table_chart), text: "ADVANCED TABLES"),
            ],
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: TabBarView(
            children: [
              SingleChildScrollView(padding: const EdgeInsets.all(16.0), child: _buildHeightTab()),
              SingleChildScrollView(padding: const EdgeInsets.all(16.0), child: _buildDriftTab()),
              SingleChildScrollView(padding: const EdgeInsets.all(16.0), child: _buildAdvancedTab()),
            ],
          ),
        ),
      ),
    );
  }

  // --- TAB 1: HEIGHT TAB ---
  Widget _buildHeightTab() {
    return Form(
      key: _formKey1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildInputField(controller: _locationController1, label: "Location / Voyage Leg", icon: Icons.map, isText: true),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildInputField(controller: _hwHeightController, label: "HW Height (m)", icon: Icons.arrow_upward)),
              const SizedBox(width: 12),
              Expanded(child: _buildInputField(controller: _lwHeightController, label: "LW Height (m)", icon: Icons.arrow_downward)),
            ],
          ),
          const SizedBox(height: 12),
          _buildInputField(controller: _timeFromHWController1, label: "Time fr. HW (h)", icon: Icons.access_time),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _calculateStandardTidalHeight,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: const Color(0xFFF2C94C),
              foregroundColor: Colors.black,
            ),
            child: const Text("COMPUTE HEIGHT", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          if (calculatedHeight != null) ...[
            const SizedBox(height: 20),
            Card(
              color: Colors.black35,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildResultItem("ESTIMATED TIDAL HEIGHT", "${calculatedHeight!.toStringAsFixed(2)} m", Colors.greenAccent),
              ),
            ),
          ]
        ],
      ),
    );
  }

  // --- TAB 2: DRIFT TAB (May Live Graph at Direction) ---
  Widget _buildDriftTab() {
    return Form(
      key: _formKey2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildInputField(controller: _locationController2, label: "Location / Voyage Leg", icon: Icons.map, isText: true),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildInputField(controller: _hwRateController, label: "HW Rate (kts)", icon: Icons.speed)),
              const SizedBox(width: 12),
              Expanded(child: _buildInputField(controller: _lwRateController, label: "LW Rate (kts)", icon: Icons.shutter_speed)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildInputField(controller: _timeFromHWController2, label: "Time fr. HW (h)", icon: Icons.access_time)),
              const SizedBox(width: 12),
              Expanded(child: _buildInputField(controller: _directionController, label: "Direction (°)", icon: Icons.navigation)),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _calculateStandardTidalStream,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: const Color(0xFFF2C94C),
              foregroundColor: Colors.black,
            ),
            child: const Text("COMPUTE & RECORD", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          if (calculatedRate != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black35, 
                borderRadius: BorderRadius.circular(12), 
                border: Border.all(color: Colors.cyanAccent.withOpacity(0.5))
              ),
              child: Column(
                children: [
                  const Text("INTERPOLATION LIVE GRAPH", style: TextStyle(fontSize: 12, color: Colors.grey, letterSpacing: 1)),
                  const SizedBox(height: 15),
                  CustomPaint(
                    size: const Size(double.infinity, 80),
                    painter: TidalCurvePainter(double.tryParse(_timeFromHWController2.text) ?? 0.0),
                  ),
                  const SizedBox(height: 20),
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
          ]
        ],
      ),
    );
  }

  // --- TAB 3: ADVANCED TABLES (Unchanged) ---
  Widget _buildAdvancedTab() {
    return Form(
      key: _formKey3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildInputField(controller: _locationController3, label: "Tide Station Reference", icon: Icons.book, isText: true),
          const SizedBox(height: 16),
          const Text("1. TIDE TABLE HEIGHTS (METERS)", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.cyanAccent)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildInputField(controller: _tableHwHeightController, label: "Today HW Height", icon: Icons.arrow_upward)),
              const SizedBox(width: 12),
              Expanded(child: _buildInputField(controller: _tableLwHeightController, label: "Today LW Height", icon: Icons.arrow_downward)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildInputField(controller: _msrController, label: "Mean Spring Range", icon: Icons.waves)),
              const SizedBox(width: 12),
              Expanded(child: _buildInputField(controller: _mnpController, label: "Mean Neap Range", icon: Icons.waves_outlined)),
            ],
          ),
          const SizedBox(height: 16),
          const Text("2. STREAM TABLE VELOCITIES (KNOTS)", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.cyanAccent)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildInputField(controller: _streamSpringMaxController, label: "Max Spring Rate", icon: Icons.bolt)),
              const SizedBox(width: 12),
              Expanded(child: _buildInputField(controller: _streamNeapMaxController, label: "Max Neap Rate", icon: Icons.directions_run)),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _calculateAdvancedTidalStream,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: Colors.cyanAccent,
              foregroundColor: Colors.black,
            ),
            child: const Text("COMPUTE INTERPOLATED STREAM", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          if (advancedCalculatedRate != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.cyanAccent)),
              child: Column(
                children: [
                  Text("Spring Factor: ${advancedSpringFactor!.toStringAsFixed(0)}%", style: const TextStyle(fontSize: 12, color: Colors.yellowAccent)),
                  const SizedBox(height: 8),
                  _buildResultItem("CALCULATED CURRENT SPEED", "${advancedCalculatedRate!.toStringAsFixed(2)} kts", Colors.white),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInputField({required TextEditingController controller, required String label, required IconData icon, bool isText = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: isText ? TextInputType.text : const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFFF2C94C), size: 16),
        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
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
        Text(val, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}

class TidalCurvePainter extends CustomPainter {
  final double timeFromHW;
  TidalCurvePainter(this.timeFromHW);

  @override
  void paint(Canvas canvas, Size size) {
    final paintCurve = Paint()..color = Colors.cyanAccent.withOpacity(0.6)..style = PaintingStyle.stroke..strokeWidth = 3;
    final paintDot = Paint()..color = Colors.redAccent..style = PaintingStyle.fill;
    final path = Path();
    
    for (double x = 0; x <= size.width; x++) {
      double t = (x / size.width) * 6.0;
      double y = (cos((t / 6.0) * pi) + 1) / 2 * (size.height - 10);
      if (x == 0) { path.moveTo(x, size.height - y - 5); } else { path.lineTo(x, size.height - y - 5); }
    }
    canvas.drawPath(path, paintCurve);
    
    double dotX = (timeFromHW.clamp(0.0, 6.0) / 6.0) * size.width;
    double dotY = (cos((timeFromHW.clamp(0.0, 6.0) / 6.0) * pi) + 1) / 2 * (size.height - 10);
    canvas.drawCircle(Offset(dotX, size.height - dotY - 5), 5, paintDot);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
