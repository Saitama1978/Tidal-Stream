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
      title: 'Tidal Stream Calculator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF0F2027),
        scaffoldBackgroundColor: const Color(0xFF203A43),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFF2C94C), 
          secondary: Color(0xFF2C5364),
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

  double? calculatedRate;
  double? calculatedDirection;

  void _calculateTidalStream() {
    if (_formKey.currentState!.validate()) {
      double hwRate = double.parse(_hwRateController.text);
      double lwRate = double.parse(_lwRateController.text);
      double timeFromHW = double.parse(_timeFromHWController.text);
      double direction = double.parse(_directionController.text);

      double angle = (timeFromHW / 6.0) * pi;
      double factor = (cos(angle) + 1) / 2;
      
      setState(() {
        calculatedRate = lwRate + (factor * (hwRate - lwRate));
        calculatedDirection = direction;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'TIDAL STREAM CALCULATOR',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Color(0xFFF2C94C)),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF0F2027),
        elevation: 8,
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
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  color: Colors.black.withOpacity(0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                    side: const BorderSide(color: Color(0xFFF2C94C), width: 1),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(15.0),
                    child: Row(
                      children: [
                        Icon(Icons.explore, size: 40, color: Color(0xFFF2C94C)),
                        SizedBox(width: 15),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("PASSAGE PLANNING TOOL", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                            Text("Tidal Interpolation Engine", style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _buildInputField(controller: _hwRateController, label: "High Water (HW) Rate (knots)", icon: Icons.trending_up),
                const SizedBox(height: 15),
                _buildInputField(controller: _lwRateController, label: "Low Water (LW) Rate (knots)", icon: Icons.trending_down),
                const SizedBox(height: 15),
                _buildInputField(controller: _timeFromHWController, label: "Time from HW (hours)", icon: Icons.access_time),
                const SizedBox(height: 15),
                _buildInputField(controller: _directionController, label: "Stream Direction (degrees)", icon: Icons.navigation),
                const SizedBox(height: 25),
                ElevatedButton(
                  onPressed: _calculateTidalStream,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF2C94C),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text("COMPUTE STREAM", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 30),
                if (calculatedRate != null) ...[
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.greenAccent, width: 1.5),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildResultColumn("ESTIMATED RATE", "${calculatedRate!.toStringAsFixed(2)} kts"),
                        _buildResultColumn("SET / DIRECTION", "${calculatedDirection!.toStringAsFixed(0)}°"),
                      ],
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

  Widget _buildInputField({required TextEditingController controller, required String label, required IconData icon}) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: const Color(0xFFF2C94C)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.grey)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFF2C94C), width: 2)),
        filled: true,
        fillColor: Colors.black.withOpacity(0.2),
      ),
    );
  }

  Widget _buildResultColumn(String title, String value) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 5),
        Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
      ],
    );
  }
}
