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
  
  final _locationController = TextEditingController(text: "San Bernardino Strait");
  final _locationController2 = TextEditingController(text: "Admiralty Port Reference");
  
  // Position Coordinates
  final _latDegController = TextEditingController(text: "12");
  final _latMinController = TextEditingController(text: "30.75");
  String _latSign = "N";
  final _lngDegController = TextEditingController(text: "124");
  final _lngMinController = TextEditingController(text: "17.12");
  String _lngSign = "E";

  // Tab 1 Standard Inputs (Stream Rates)
  final _hwRateController = TextEditingController(text: "4.5");
  final _lwRateController = TextEditingController(text: "1.2");
  final _timeFromHWController = TextEditingController(text: "3.5");
  final _directionController = TextEditingController(text: "045");

  // Tab 2 Tide Table Inputs (Heights and Ranges)
  final _tableHwHeightController = TextEditingController(text: "5.0");
  final _tableLwHeightController = TextEditingController(text: "1.0");
  final _msrController = TextEditingController(text: "4.2"); 
  final _mnpController = TextEditingController(text: "1.8"); 
  String _harmonicType = "Semi-Diurnal"; 

  double? calculatedRate;
  double? calculatedDirection;
  
  double? advancedCalculatedHeight;
  String advancedInterpolationMethod = "";

  List<Map<String, String>> calculationLog = [];

  final List<Map<String, dynamic>> presets = [
    {"name": "San Bernardino Strait", "latDeg": "12", "latMin": "30.75", "latSign": "N", "lngDeg": "124", "lngMin": "17.12", "lngSign": "E", "hw": "5.2", "lw": "0.8", "dir": "125"},
    {"name": "Singapore Strait (Eastern)", "latDeg": "01", "latMin": "16.80", "latSign": "N", "lngDeg": "104", "lngMin": "06.00", "lngSign": "E", "hw": "4.2", "lw": "1.1", "dir": "075"},
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
          "result": "${calculatedRate!.toStringAsFixed(2)} kts (Drift)",
          "time": "${timeFromHW.toStringAsFixed(1)}h fr HW"
        });
      });
    }
  }

  void _calculateAdvancedTidalHeight() {
    if (_formKey2.currentState!.validate()) {
      double hwHeight = double.parse(_tableHwHeightController.text);
      double lwHeight = double.parse(_tableLwHeightController.text);
      double msr = double.parse(_msrController.text);
      double mnp = double.parse(_mnpController.text);
      double timeFromHW = double.parse(_timeFromHWController.text);

      double currentRange = (hwHeight - lwHeight).abs();
      
      double rangeFactor = 0.5; 
      if ((msr - mnp).abs() > 0.01) {
        rangeFactor = ((currentRange - mnp) / (msr - mnp)).clamp(0.0, 1.0);
      }
      
      double periodDivider = _harmonicType == "Diurnal" ? 12.0 : 6.0;
      double angle = (timeFromHW.clamp(0.0, periodDivider) / periodDivider) * pi;
      double timeFactor = (cos(angle) + 1) / 2;

      setState(() {
        advancedCalculatedHeight = lwHeight + (timeFactor * (hwHeight - lwHeight));
        advancedInterpolationMethod = "Range: ${currentRange.toStringAsFixed(1)}m (${(rangeFactor * 100).toStringAsFixed(0)}% Spring Factor)";

        String posReadout = "${_latDegController.text}° ${_latMinController.text}' $_latSign | ${_lngDegController.text}° ${_lngMinController.text}' $_lngSign";

        calculationLog.insert(0, {
          "id": DateTime.now().millisecondsSinceEpoch.toString(),
          "loc": _locationController2.text,
          "pos": posReadout,
          "result": "${advancedCalculatedHeight!.toStringAsFixed(2)} m (Height)",
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
          bottom: const TabBar(
            indicatorColor: Color(0xFFF2C94C),
            labelColor: Color(0xFFF2C94C),
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(icon: Icon(Icons.waves), text: "STREAM RATE (KTS)"),
              Tab(icon: Icon(Icons.layers), text: "TIDE TABLE HEIGHT (M)"),
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
              Expanded(child: _buildInputField(controller: _hwRateController, label: "HW Stream Rate (kts)", icon: Icons.trending_up)),
              const SizedBox(width: 12),
              Expanded(child: _buildInputField(controller: _lwRateController, label: "LW Stream Rate (kts)", icon: Icons.trending_down)),
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
            child: const Text("COMPUTE STREAM VELOCITY", style: TextStyle(fontWeight: FontWeight.bold)),
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
          _buildInputField(controller: _locationController2, label: "Tide Table Port / Reference", icon: Icons.book, isText: true),
          const SizedBox(height: 16),
          _buildVesselPositionBlock(), 
          const SizedBox(height: 16),
          const Text("TIDE TABLE HEIGHT ENTRIES", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.cyanAccent, letterSpacing: 1)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildInputField(controller: _tableHwHeightController, label: "HW Height (meters)", icon: Icons.arrow_upward)),
              const SizedBox(width: 12),
              Expanded(child: _buildInputField(controller: _tableLwHeightController, label: "LW Height (meters)", icon: Icons.arrow_downward)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildInputField(controller: _msrController, label: "Mean Spring Range (MSR)", icon: Icons.shutter_speed)),
              const SizedBox(width: 12),
              Expanded(child: _buildInputField(controller: _mnpController, label: "Mean Neap Range (MNP)", icon: Icons.shutter_speed_outlined)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
            onPressed: _calculateAdvancedTidalHeight,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: Colors.cyanAccent,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("COMPUTE TIDAL HEIGHT (HARMONIC)", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          if (advancedCalculatedHeight != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.cyanAccent, width: 1)),
              child: Column(
                children: [
                  Text(advancedInterpolationMethod, style: const TextStyle(fontSize: 12, color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildResultItem("PREDICTED HEIGHT", "${advancedCalculatedHeight!.toStringAsFixed(2)} m", Colors.white),
                      _buildResultItem("CYCLE TYPE", _harmonicType, const Color(0xFFF2C94C)),
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
        Row(
          children: [
            Expanded(flex: 3, child: _buildInputField(controller: _latDegController, label: "Lat Deg", icon: Icons.explore)),
            const SizedBox(width: 8),
            Expanded(flex: 4, child: _buildInputField(controller: _latMinController, label: "Lat Min", icon: Icons.timer_outlined)),
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
                    items: ["N", "S"].map((val) => DropdownMenuItem(value: val, child: Text(val, style: const TextStyle(color: Colors.white)))).toList(),
                    onChanged: (val) => setState(() => _latSign = val!),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(flex: 3, child: _buildInputField(controller: _lngDegController, label: "Long Deg", icon: Icons.explore_outlined)),
            const SizedBox(width: 8),
            Expanded(flex: 4, child: _buildInputField(controller: _lngMinController, label: "Long Min", icon: Icons.timer_outlined)),
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
                    items: ["E", "W"].map((val) => DropdownMenuItem(value: val, child: Text(val, style: const TextStyle(color: Colors.white)))).toList(),
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
    return Column(
      children: [
        CustomPaint(size: const Size(double.infinity, 60), painter: TidalCurvePainter(double.tryParse(_timeFromHWController.text) ?? 0.0)),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildResultItem("ESTIMATED DRIFT", "${rate.toStringAsFixed(2)} kts", Colors.white),
            _buildResultItem("SET DIRECTION", "${dir.toStringAsFixed(0)}°", const Color(0xFFF2C94C)),
          ],
        ),
      ],
    );
  }

  Widget _buildLogbookBlock() {
    if (calculationLog.isEmpty) return const SizedBox.shrink();
    return Container(
      constraints: const BoxConstraints(maxHeight: 150),
      margin: const EdgeInsets.topRight(0),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: calculationLog.length,
        itemBuilder: (context, index) {
          final log = calculationLog[index];
          return ListTile(
            dense: true,
            title: Text(log["loc"]!),
            subtitle: Text("${log["pos"]}\n${log["time"]}"),
            trailing: Text(log["result"]!, style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
          );
        },
      ),
    );
  }

  Widget _buildInputField({required TextEditingController controller, required String label, required IconData icon, bool isText = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: isText ? TextInputType.text : const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFFF2C94C), size: 18),
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
        Text(val, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}

class TidalCurvePainter extends CustomPainter {
  final double timeFromHW;
  TidalCurvePainter(this.timeFromHW);

  @override
  void paint(Canvas canvas, Size size) {
    final paintCurve = Paint()..color = Colors.cyanAccent.withOpacity(0.5)..style = PaintingStyle.stroke..strokeWidth = 3;
    final paintDot = Paint()..color = Colors.redAccent..style = PaintingStyle.fill;
    final path = Path();
    for (double x = 0; x <= size.width; x++) {
      double t = (x / size.width) * 6.0;
      double y = (cos((t / 6.0) * pi) + 1) / 2 * size.height;
      if (x == 0) { path.moveTo(x, size.height - y); } else { path.lineTo(x, size.height - y); }
    }
    canvas.drawPath(path, paintCurve);
    double dotX = (timeFromHW.clamp(0.0, 6.0) / 6.0) * size.width;
    double dotY = (cos((timeFromHW.clamp(0.0, 6.0) / 6.0) * pi) + 1) / 2 * size.height;
    canvas.drawCircle(Offset(dotX, size.height - dotY), 5, paintDot);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
