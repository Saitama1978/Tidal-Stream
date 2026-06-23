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
  
  final _locationController = TextEditingController(text: "Malacca Strait");
  final _locationController2 = TextEditingController(text: "Port Reference Table");

  // Tab 1 Standard Inputs (Speed in knots)
  final _hwRateController = TextEditingController(text: "2.5");
  final _lwRateController = TextEditingController(text: "0.4");
  final _timeFromHWController = TextEditingController(text: "3.5");
  final _directionController = TextEditingController(text: "310");

  // Tab 2 Advanced Inputs
  final _tableHwHeightController = TextEditingController(text: "5.0"); 
  final _tableLwHeightController = TextEditingController(text: "1.0"); 
  final _msrController = TextEditingController(text: "4.2");            
  final _mnpController = TextEditingController(text: "1.8");            
  final _streamSpringMaxController = TextEditingController(text: "3.5"); 
  final _streamNeapMaxController = TextEditingController(text: "1.5");   
  String _harmonicType = "Semi-Diurnal"; 

  double? calculatedRate;
  double? calculatedDirection;
  double? advancedCalculatedRate;
  String advancedInterpolationMethod = "";

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

      double currentRange = (hwHeight - lwHeight).abs();
      double rangeFactor = 0.5; 
      if ((msr - mnp).abs() > 0.01) {
        rangeFactor = ((currentRange - mnp) / (msr - mnp)).clamp(0.0, 1.0);
      }
      
      double periodDivider = _harmonicType == "Diurnal" ? 12.0 : 6.0;
      double angle = (timeFromHW.clamp(0.0, periodDivider) / periodDivider) * pi;
      double timeFactor = (cos(angle) + 1) / 2;

      double maxRateForToday = neapMaxRate + (rangeFactor * (springMaxRate - neapMaxRate));

      setState(() {
        advancedCalculatedRate = maxRateForToday * timeFactor;
        advancedInterpolationMethod = "Spring Factor: ${(rangeFactor * 100).toStringAsFixed(0)}%";
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
            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFF2C94C)),
          ),
          centerTitle: true,
          backgroundColor: const Color(0xFF0F2027),
          bottom: const TabBar(
            indicatorColor: Color(0xFFF2C94C),
            labelColor: Color(0xFFF2C94C),
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(icon: Icon(Icons.show_chart), text: "STANDARD GRAPH"),
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
            child: const Text("COMPUTE & RECORD", style: TextStyle(fontWeight: FontWeight.bold)),
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
          const Text("1. TIDE TABLE HEIGHTS (METERS)", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.cyanAccent)),
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
