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
  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();
  
  // Tab 1 & Tab 2 Location Controllers
  final _locationController = TextEditingController(text: "San Bernardino Strait");
  final _locationController2 = TextEditingController(text: "New Orleans Approach");
  
  // Manual Position Coordinates (Shared or independent)
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

  // Tab 2 Advanced Tidal Table Inputs
  final _tableHwHeightController = TextEditingController(text: "5.0");
  final _tableLwHeightController = TextEditingController(text: "1.0");
  final _msrController = TextEditingController(text: "4.2"); // Mean Spring Range
  final _mnpController = TextEditingController(text: "1.8"); // Mean Neap Range
  final _tab2HwRateController = TextEditingController(text: "4.0");
  final _tab2LwRateController = TextEditingController(text: "1.0");
  String _harmonicType = "Semi-Diurnal"; // Dropdown options: Semi-Diurnal, Diurnal

  double? calculatedRate;
  double? calculatedDirection;
  
  double? advancedCalculatedRate;
  String advancedInterpolationMethod = "";

  List<Map<String, String>> calculationLog = [];

  final List<Map<String, dynamic>> presets = [
    {"name": "San Bernardino Strait", "latDeg": "12", "latMin": "30.75", "latSign": "N", "lngDeg": "124", "lngMin": "17.12", "lngSign": "E", "hw": "5.2", "lw": "0.8", "dir": "125"},
    {"name": "Singapore Strait (Eastern)", "latDeg": "01", "latMin": "16.80", "latSign": "N", "lngDeg": "104", "lngMin": "06.00", "lngSign": "E", "hw": "4.2", "lw": "1.1", "dir": "075"},
    {"name": "English Channel (Dover)", "latDeg": "51", "latMin": "07.67", "latSign": "N", "lngDeg": "001", "lngMin": "18.79", "lngSign": "E", "hw": "3.8", "lw": "0.5", "dir": "240"},
    {"name": "Malacca Strait", "latDeg": "02", "latMin": "30.00", "latSign": "N", "lngDeg": "101", "lngMin": "30.00", "lngSign": "E", "hw": "2.5", "lw": "0.4", "dir": "310"},
  ];

  void _loadPreset(Map<String, dynamic> preset) {
    setState(() {
      _locationController.text = preset["name"]!;
      _latDegController.text = preset["latDeg"]!;
      _latMinController.text = preset["latMin"]!;
      _latSign = preset["latSign"]!;
      _lngDegController.text = preset["lngDeg"]!;
      _lngMinController.text = preset["lngMin"]!;
      _lngSign = preset["lngSign"]!;
      _hwRateController.text = preset["hw"]!;
      _lwRateController.text = preset["lw"]!;
      _directionController.text = preset["dir"]!;
    });
  }

  void _calculateStandardTidalStream() {
    if (_formKey1.currentState!.validate() && _locationController.text.isNotEmpty) {
      double hwRate = double.parse(_hwRateController.text);
      double lwRate = double.parse(_lwRateController.text);
      double timeFromHW = double.parse(_timeFromHWController.text);
      double direction = double.parse(_directionController.text);

      double angle = (timeFromHW.clamp(0.0, 6.0) / 6.0) * pi;
      double factor = (cos(angle) + 1) / 2;
      
      setState(() {
        calculatedRate = lwRate + (factor * (hwRate - lwRate));
        calculatedDirection = direction;

        String posReadout = "${_latDegController.text}° ${_latMinController.text}' $_latSign | ${_lngDegController.text}° ${_lngMinController.text}' $_lngSign";

        calculationLog.insert(0, {
          "id": DateTime.now().millisecondsSinceEpoch.toString(),
          "loc": _locationController.text,
          "pos": posReadout,
          "rate": "${calculatedRate!.toStringAsFixed(2)} kts",
          "dir": "${calculatedDirection!.toStringAsFixed(0)}°",
          "time": "${timeFromHW.toStringAsFixed(1)}h from HW (Std)"
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
      double tab2HwRate = double.parse(_tab2HwRateController.text);
      double tab2LwRate = double.parse(_tab2LwRateController.text);
      double timeFromHW = double.parse(_timeFromHWController.text);
      double direction = double.parse(_directionController.text);

      // Calculate Current Range
      double currentRange = (hwHeight - lwHeight).abs();
      
      // Interpolate between Mean Spring Range (MSR) and Mean Neap Range (MNP)
      double rangeFactor = 0.5; // Default middle factor
      if ((msr - mnp).abs() > 0.01) {
        rangeFactor = ((currentRange - mnp) / (msr - mnp)).clamp(0.0, 1.0);
      }
      
      // Calculate Base Tidal Factor (Harmonic/Cosine Semicone Method)
      // For Diurnal tides, the cycle period changes, we adjust factor mapping
      double periodDivider = _harmonicType == "Diurnal" ? 12.0 : 6.0;
      double angle = (timeFromHW.clamp(0.0, periodDivider) / periodDivider) * pi;
      double timeFactor = (cos(angle) + 1) / 2;

      // Combine Range Interpolation with Curve Estimation
      double interpolatedMaxRate = tab2LwRate + (rangeFactor * (tab2HwRate - tab2LwRate));
      
      setState(() {
        advancedCalculatedRate = tab2LwRate + (timeFactor * (interpolatedMaxRate - tab2LwRate));
        advancedInterpolationMethod = "MSR/MNP Weight: ${(rangeFactor * 100).toStringAsFixed(0)}% Spring";

        String posReadout = "${_latDegController.text}° ${_latMinController.text}' $_latSign | ${_lngDegController.text}° ${_lngMinController.text}' $_lngSign";

        calculationLog.insert(0, {
          "id": DateTime.now().millisecondsSinceEpoch.toString(),
          "loc": _locationController2.text,
          "pos": posReadout,
          "rate": "${advancedCalculatedRate!.toStringAsFixed(2)} kts",
          "dir": "${direction.toStringAsFixed(0)}°",
          "time": "${timeFromHW.toStringAsFixed(1)}h | $_harmonicType"
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
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'TIDAL STREAM WORLDWIDE',
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Color(0xFFF2C94C)),
          ),
          centerTitle: true,
          backgroundColor: const Color(0xFF0F2027),
          elevation: 10,
          bottom: const TabBar(
            indicatorColor: Color(0xFFF2C94C),
            labelColor: Color(0xFFF2C94C),
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(icon: Icon(Icons.stacked_line_chart), text: "STANDARD GRAPH"),
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
              // TAB 1: STANDARD GRAPH VIEW
              SingleChildScrollView(padding: const EdgeInsets.all(16.0), child: _buildStandardTab()),
              
              // TAB 2: ADVANCED TABLES VIEW (MSR, MNP & HARMONICS)
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
                    return DropdownMenuItem<Map<String, dynamic>>(value: preset, child: Text(preset["name"]!));
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) _loadPreset(value);
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildInputField(controller: _locationController, label: "Location / Voyage Leg", icon: Icons.map, isText: true),
          const SizedBox(height: 16),
          _buildVesselPositionBlock(),
          const SizedBox(height: 16),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("COMPUTE & RECORD", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          if (calculatedRate != null) ...[
            const SizedBox(height: 20),
            _buildGraphOutputBlock(calculatedRate!, calculatedDirection ?? 0.0),
          ],
          _buildLogbookBlock(),
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
          _buildInputField(controller: _locationController2, label: "Admiralty Table Reference / Port", icon: Icons.gavel, isText: true),
          const SizedBox(height: 16),
          _buildVesselPositionBlock(), // Constant shared entry approach
          const SizedBox(height: 16),
          const Text("TIDE TABLE EXTRACTS", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.cyanAccent, letterSpacing: 1)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildInputField(controller: _tableHwHeightController, label: "Today HW Height (m)", icon: Icons.height)),
              const SizedBox(width: 12),
              Expanded(child: _buildInputField(controller: _tableLwHeightController, label: "Today LW Height (m)", icon: Icons.vertical_align_bottom)),
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
          const Text("STREAM RATE VALUES", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.cyanAccent, letterSpacing: 1)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildInputField(controller: _tab2HwRateController, label: "Max Spring Rate (kts)", icon: Icons.speed)),
              const SizedBox(width: 12),
              Expanded(child: _buildInputField(controller: _tab2LwRateController, label: "Max Neap Rate (kts)", icon: Icons.shutter_speed)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey),
                  ),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("COMPUTE WITH HARMONIC WEIGHTS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ),
          if (advancedCalculatedRate != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.cyanAccent, width: 1),
              ),
              child: Column(
                children: [
                  Text(advancedInterpolationMethod, style: const TextStyle(fontSize: 12, color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildResultItem("ESTIMATED DRIFT", "${advancedCalculatedRate!.toStringAsFixed(2)} kts", Colors.white),
                      _buildResultItem("HARMONIC TYPE", _harmonicType, const Color(0xFFF2C94C)),
                    ],
                  ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text("POSITION SPECIFICATION (MANUAL)", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.cyanAccent, letterSpacing: 1)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(flex: 3, child: _buildInputField(controller: _latDegController, label: "Lat Deg (°)", icon: Icons.explore)),
            const SizedBox(width: 8),
            Expanded(flex: 4, child: _buildInputField(controller: _latMinController, label: "Lat Min (')", icon: Icons.timer_outlined)),
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _latSign,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF0F2027),
                    items: ["N", "S"].map((val) => DropdownMenuItem(value: val, child: Text(val, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFF2C94C))))).toList(),
                    onChanged: (val) => setState(() => _latSign = val!),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(flex: 3, child: _buildInputField(controller: _lngDegController, label: "Long Deg (°)", icon: Icons.explore_outlined)),
            const SizedBox(width: 8),
            Expanded(flex: 4, child: _buildInputField(controller: _lngMinController, label: "Long Min (')", icon: Icons.timer_outlined)),
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _lngSign,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF0F2027),
                    items: ["E", "W"].map((val) => DropdownMenuItem(value: val, child: Text(val, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFF2C94C))))).toList(),
                    onChanged: (val) => setState(() => _lngSign = val!),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGraphOutputBlock(double rate, double dir) {
    return Container(
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
              _buildResultItem("ESTIMATED DRIFT", "${rate.toStringAsFixed(2)} kts", Colors.white),
              _buildResultItem("SET DIRECTION", "${dir.toStringAsFixed(0)}°", const Color(0xFFF2C94C)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLogbookBlock() {
    if (calculationLog.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),
        const Text("BRIDGE LOGBOOK RECORD", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 8),
        Container(
          constraints: const BoxConstraints(maxHeight: 200),
          decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(8)),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: calculationLog.length,
            itemBuilder: (context, index) {
              final log = calculationLog[index];
              return ListTile(
                dense: true,
                leading: const Icon(Icons.assignment, color: Color(0xFFF2C94C)),
                title: Text(log["loc"]!, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Pos: ${log["pos"]}", style: const TextStyle(color: Colors.cyanAccent, fontSize: 11, fontFamily: 'monospace')),
                    Text("${log["time"]} | Dir: ${log["dir"]}"),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(log["rate"]!, style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 14)),
                    IconButton(
                      icon: const Icon(Icons.delete_sweep, color: Colors.redAccent, size: 20),
                      onPressed: () => _deleteLogItem(log["id"]!),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildInputField({required TextEditingController controller, required String label, required IconData icon, bool isText = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: isText ? TextInputType.text : const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFFF2C94C), size: 18),
        contentPadding: const EdgeInsets.symmetric(vertical: 11, horizontal: 10),
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
