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
  
  final _locationController = TextEditingController(text: "San Bernardino Strait");
  final _locationController2 = TextEditingController(text: "Malacca Strait Entry");
  
  // Position Coordinates (Shared Bridge Data)
  final _latDegController = TextEditingController(text: "12");
  final _latMinController = TextEditingController(text: "30.75");
  String _latSign = "N";
  final _lngDegController = TextEditingController(text: "124");
  final _lngMinController = TextEditingController(text: "17.12");
  String _lngSign = "E";

  // Tab 1 Standard Inputs
  final _hwRateController = TextEditingController(text: "4.5");
  final _lwRateController = TextEditingController(text: "1.2");
  final _timeFromHWController = TextEditingController(text: "3.5");
  final _directionController = TextEditingController(text: "045");

  // Tab 2 Advanced Dual-Interpolation Inputs (Tide Tables + Stream Tables)
  final _tableHwHeightController = TextEditingController(text: "5.0"); // Ngayong araw (Meters)
  final _tableLwHeightController = TextEditingController(text: "1.0"); // Ngayong araw (Meters)
  final _msrController = TextEditingController(text: "4.2");            // Mean Spring Range (Meters)
  final _mnpController = TextEditingController(text: "1.8");            // Mean Neap Range (Meters)
  final _streamSpringMaxController = TextEditingController(text: "3.5"); // Max Spring Stream (Knots)
  final _streamNeapMaxController = TextEditingController(text: "1.5");   // Max Neap Stream (Knots)
  String _harmonicType = "Semi-Diurnal"; 

  double? calculatedRate;
  double? calculatedDirection;
  
  double? advancedCalculatedRate;
  String advancedInterpolationMethod = "";

  List<Map<String, String>> calculationLog = [];

  void _calculateStandardTidalStream() {
    if (_formKey1.currentState!.validate()) {
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
          "result": "${calculatedRate!.toStringAsFixed(2)} kts",
          "type": "Standard Curve"
        });
      });
    }
  }

  void _calculateAdvancedTidalStream() {
    if (_formKey2.currentState!.validate()) {
      double hwHeight = double.parse(_tableHwHeightController.text);
      double lwHeight = double.parse(_tableLwHeightController.text);
      double msr = double.parse(_msrController.text);
      double mnp = double.parse(_mnpController.text);
      double springMaxRate = double.parse(_streamSpringMaxController.text);
      double neapMaxRate = double.parse(_streamNeapMaxController.text);
      double timeFromHW = double.parse(_timeFromHWController.text);
      double direction = double.parse(_directionController.text);

      // Step 1: Alamin ang range ng tide ngayong araw sa lugar
      double currentRange = (hwHeight - lwHeight).abs();
      
      // Step 2: Interpolate gamit ang MSR at MNP kung nasaan tayo sa pagitan ng Spring at Neap
      double rangeFactor = 0.5; 
      if ((msr - mnp).abs() > 0.01) {
        rangeFactor = ((currentRange - mnp) / (msr - mnp)).clamp(0.0, 1.0);
      }
      
      // Makuha ang Factor base sa Harmonic type ng cycle (Semi-diurnal = 6h, Diurnal = 12h)
      double periodDivider = _harmonicType == "Diurnal" ? 12.0 : 6.0;
      double angle = (timeFromHW.clamp(0.0, periodDivider) / periodDivider) * pi;
      double timeFactor = (cos(angle) + 1) / 2;

      // Step 3: Compute ng Target Maximum Stream Rate para sa araw na ito
      double maxRateForToday = neapMaxRate + (rangeFactor * (springMaxRate - neapMaxRate));

      setState(() {
        // Step 4: Isalang sa Cosine Factor ng Oras para makuha ang Live Hourly Drift
        advancedCalculatedRate = maxRateForToday * timeFactor;
        advancedInterpolationMethod = "Spring weight: ${(rangeFactor * 100).toStringAsFixed(0)}% | Factor: ${timeFactor.toStringAsFixed(2)}";

        calculationLog.insert(0, {
          "id": DateTime.now().millisecondsSinceEpoch.toString(),
          "loc": _locationController2.text,
          "result": "${advancedCalculatedRate!.toStringAsFixed(2)} kts",
          "type": "MSR/MNP Harmonic"
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'TIDAL STREAM WORLDWIDE',
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Color(0xFFF2C94C)),
          ),
          centerTitle: true,
          backgroundColor: const Color(0xFF0F2027),
          bottom: const TabBar(
            indicatorColor: Color(0xFFF2C94C),
            labelColor: Color(0xFFF2C94C),
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(icon: Icon(Icons.stacked_line_chart), text: "STANDARD GRAPH"),
              Tab(icon: Icon(Icons.領収書), text: "ADVANCED TABLES"),
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
              SingleChildScrollView(padding: const EdgeInsets.all(16.0), child: _buildStandardTab()),
              SingleChildScrollView(padding: const EdgeInsets.all(16.0), child: _buildAdvancedTab()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStandardTab() {
    return Form(
      key: _formKey1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildInputField(controller: _locationController, label: "Location / Voyage Leg", icon: Icons.map, isText: true),
          const SizedBox(height: 16),
          _buildVesselPositionBlock(),
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
              Expanded(child: _buildInputField(controller: _timeFromHWController, label: "Time fr. HW (hrs)", icon: Icons.access_time)),
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
            child: const Text("COMPUTE STANDARD DRIFT", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          if (calculatedRate != null) ...[
            const SizedBox(height: 20),
            _buildResultItem("ESTIMATED DRIFT", "${calculatedRate!.toStringAsFixed(2)} kts", Colors.greenAccent),
          ]
        ],
      ),
    );
  }

  Widget _buildAdvancedTab() {
    return Form(
      key: _formKey2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildInputField(controller: _locationController2, label: "Tide Station Reference", icon: Icons.book, isText: true),
          const SizedBox(height: 16),
          const Text("1. TIDE TABLE VERTICAL HEIGHTS (METERS)", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.cyanAccent)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildInputField(controller: _tableHwHeightController, label: "Today HW Height (m)", icon: Icons.arrow_upward)),
              const SizedBox(width: 12),
              Expanded(child: _buildInputField(controller: _tableLwHeightController, label: "Today LW Height (m)", icon: Icons.arrow_downward)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildInputField(controller: _msrController, label: "Mean Spring Range (MSR)", icon: Icons.waves)),
              const SizedBox(width: 12),
              Expanded(child: _buildInputField(controller: _mnpController, label: "Mean Neap Range (MNP)", icon: Icons.waves_outlined)),
            ],
          ),
          const SizedBox(height: 16),
          const Text("2. STREAM TABLE VELOCITIES (KNOTS)", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.cyanAccent)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildInputField(controller: _streamSpringMaxController, label: "Max Spring Rate (kts)", icon: Icons.bolt)),
              const SizedBox(width: 12),
              Expanded(child: _buildInputField(controller: _streamNeapMaxController, label: "Max Neap Rate (kts)", icon: Icons.directions_run)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildInputField(controller: _timeFromHWController, label: "Time from HW (hrs)", icon: Icons.access_time)),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _harmonicType,
                      isExpanded: true,
                      dropdownColor: const Color(0xFF0F2027),
                      items: ["Semi-Diurnal", "Diurnal"].map((val) => DropdownMenuItem(value: val, child: Text(val, style: const TextStyle(color: Colors.white)))).toList(),
                      onChanged: (val) => setState(() => _harmonicType = val!),
                    ),
                  ),
                ),
              ),
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
                  Text(advancedInterpolationMethod, style: const TextStyle(fontSize: 12, color: Colors.yellowAccent)),
                  const SizedBox(height: 8),
                  _buildResultItem("CALCULATED CURRENT SPEED", "${advancedCalculatedRate!.toStringAsFixed(2)} kts", Colors.white),
                ],
              ),
            ),
          ],
          _buildLogbookBlock(),
        ],
      ),
    );
  }

  Widget _buildVesselPositionBlock() {
    return Row(
      children: [
        Expanded(child: _buildInputField(controller: _latDegController, label: "Lat", icon: Icons.explore)),
        const SizedBox(width: 8),
        Expanded(child: _buildInputField(controller: _lngDegController, label: "Long", icon: Icons.explore_outlined)),
      ],
    );
  }

  Widget _buildLogbookBlock() {
    if (calculationLog.isEmpty) return const SizedBox.shrink();
    return Container(
      constraints: const BoxConstraints(maxHeight: 120),
      margin: const EdgeInsets.topNavigator(0),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: calculationLog.length,
        itemBuilder: (context, index) => ListTile(
          dense: true,
          title: Text(calculationLog[index]["loc"]!),
          subtitle: Text(calculationLog[index]["type"]!),
          trailing: Text(calculationLog[index]["result"]!, style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
        ),
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
