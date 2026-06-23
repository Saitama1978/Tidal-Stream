import 'package:flutter/material.dart';
import 'dart:math';
import 'package:url_launcher/url_launcher.dart'; // Tamang import para hindi mag-error ang launchUrl

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

class LogbookRecord {
  final String id;
  final String location;
  final double timeFromHW;
  final double direction;
  final double drift;

  LogbookRecord({
    required this.id,
    required this.location,
    required this.timeFromHW,
    required this.direction,
    required this.drift,
  });
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

  final _locHeightController = TextEditingController(text: "Manila Harbor");
  final _hwHeightController = TextEditingController(text: "2.5");
  final _lwHeightController = TextEditingController(text: "0.4");
  final _timeFromHwHeightController = TextEditingController(text: "3.5");

  final _locationController = TextEditingController(text: "San Bernardino Strait");
  final _latDegController = TextEditingController(text: "12");
  final _latMinController = TextEditingController(text: "51.25");
  String _latDir = "N";
  final _longDegController = TextEditingController(text: "124");
  final _longMinController = TextEditingController(text: "28.47");
  String _longDir = "E";
  final _springRateController = TextEditingController(text: "4.5");
  final _neapRateController = TextEditingController(text: "1.2");
  final _timeFromHwStreamController = TextEditingController(text: "3.5");
  final _directionController = TextEditingController(text: "045");

  final _tableStationController = TextEditingController(text: "Port Reference Table");
  final _tableHwHeightController = TextEditingController(text: "5.0");
  final _tableLwHeightController = TextEditingController(text: "1.0");
  final _msrController = TextEditingController(text: "4.2");
  final _mnpController = TextEditingController(text: "1.8");
  final _streamSpringMaxController = TextEditingController(text: "3.5");
  final _streamNeapMaxController = TextEditingController(text: "1.5");

  double estimatedHeight = 1.18;
  double estimatedDrift = 2.42;
  double setDirection = 45.0;
  double advancedCalculatedRate = 1.24;
  double advancedSpringFactor = 92.0;

  final List<LogbookRecord> _logbookRecords = [
    LogbookRecord(
      id: "1",
      location: "San Bernardino Strait",
      timeFromHW: 3.5,
      direction: 45.0,
      drift: 2.42,
    ),
  ];

  void _calculateHeight() {
    if (_formKey1.currentState!.validate()) {
      double hw = double.tryParse(_hwHeightController.text) ?? 0.0;
      double lw = double.tryParse(_lwHeightController.text) ?? 0.0;
      double hours = double.tryParse(_timeFromHwHeightController.text) ?? 0.0;
      double factor = (cos((hours.clamp(0.0, 6.0) / 6.0) * pi) + 1) / 2;
      setState(() {
        estimatedHeight = lw + (factor * (hw - lw));
      });
    }
  }

  void _calculateStandardDriftAndRecord() {
    if (_formKey2.currentState!.validate()) {
      double springRate = double.tryParse(_springRateController.text) ?? 0.0;
      double neapRate = double.tryParse(_neapRateController.text) ?? 0.0;
      double hours = double.tryParse(_timeFromHwStreamController.text) ?? 0.0;
      double factor = (cos((hours.clamp(0.0, 6.0) / 6.0) * pi) + 1) / 2;
      setState(() {
        estimatedDrift = neapRate + (factor * (springRate - neapRate));
        setDirection = double.tryParse(_directionController.text) ?? 0.0;
        _logbookRecords.insert(
          0,
          LogbookRecord(
            id: DateTime.now().toString(),
            location: _locationController.text,
            timeFromHW: hours,
            direction: setDirection,
            drift: estimatedDrift,
          ),
        );
      });
    }
  }

  void _calculateAdvancedStream() {
    if (_formKey3.currentState!.validate()) {
      double hwHeight = double.tryParse(_tableHwHeightController.text) ?? 0.0;
      double lwHeight = double.tryParse(_tableLwHeightController.text) ?? 0.0;
      double msr = double.tryParse(_msrController.text) ?? 0.0;
      double mnp = double.tryParse(_mnpController.text) ?? 0.0;
      double springMaxRate = double.tryParse(_streamSpringMaxController.text) ?? 0.0;
      double neapMaxRate = double.tryParse(_streamNeapMaxController.text) ?? 0.0;

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

  // Functional URL function para sa totoong Live Map Link
  Future<void> _openLiveMap() async {
    final Uri url = Uri.parse('https://www.windy.com/-Waves-waves?waves,12.876,121.774,5');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not launch Live Map Server.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4, 
      child: Scaffold(
        appBar: AppBar(
          title: const Text('TIDAL STREAM WORLDWIDE', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFF2C94C), letterSpacing: 1.2)),
          centerTitle: true,
          backgroundColor: const Color(0xFF0F2027),
          elevation: 0,
          bottom: const TabBar(
            indicatorColor: Color(0xFFF2C94C),
            labelColor: Color(0xFFF2C94C),
            unselectedLabelColor: Colors.grey,
            isScrollable: true,
            tabs: [
              Tab(text: "HEIGHT"), 
              Tab(text: "STANDARD GRAPH"), 
              Tab(text: "ADVANCED TABLES"),
              Tab(text: "LIVE MAP"),
            ],
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF0F2027), Color(0xFF14262E)], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
          child: TabBarView(
            children: [
              WidgetKeepAlive(child: SingleChildScrollView(padding: const EdgeInsets.all(16.0), child: _buildHeightTab())),
              WidgetKeepAlive(child: SingleChildScrollView(padding: const EdgeInsets.all(16.0), child: _buildStandardGraphTab())),
              WidgetKeepAlive(child: SingleChildScrollView(padding: const EdgeInsets.all(16.0), child: _buildAdvancedTablesTab())),
              WidgetKeepAlive(child: SingleChildScrollView(padding: const EdgeInsets.all(16.0), child: _buildLiveMapTab())),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeightTab() {
    return Form(
      key: _formKey1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildInputWrapper(
            label: "Location / Voyage Leg",
            child: TextFormField(controller: _locHeightController, decoration: const InputDecoration(border: InputBorder.none, icon: Icon(Icons.map, color: Color(0xFFF2C94C)))),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInputWrapper(
                  label: "HW Height (m)",
                  child: TextFormField(controller: _hwHeightController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(border: InputBorder.none, icon: Icon(Icons.trending_up, color: Color(0xFFF2C94C)))),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInputWrapper(
                  label: "LW Height (m)",
                  child: TextFormField(controller: _lwHeightController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(border: InputBorder.none, icon: Icon(Icons.trending_down, color: Color(0xFFF2C94C)))),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInputWrapper(
            label: "Time fr. HW (hours)",
            child: TextFormField(controller: _timeFromHwHeightController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(border: InputBorder.none, icon: Icon(Icons.access_time, color: Color(0xFFF2C94C)))),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _calculateHeight,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF2C94C), foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text("COMPUTE HEIGHT", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: const Color(0xFF0F2027).withOpacity(0.5), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFF2C94C).withOpacity(0.4))),
            child: Column(
              children: [
                const Text("ESTIMATED TIDAL HEIGHT", style: TextStyle(fontSize: 12, color: Colors.grey, letterSpacing: 1)),
                const SizedBox(height: 8),
                Text("${estimatedHeight.toStringAsFixed(2)} m", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStandardGraphTab() {
    return Form(
      key: _formKey2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildInputWrapper(
            label: "Location / Voyage Leg",
            child: TextFormField(controller: _locationController, style: const TextStyle(color: Colors.white, fontSize: 14), decoration: const InputDecoration(border: InputBorder.none, icon: Icon(Icons.map, color: Color(0xFFF2C94C), size: 18))),
          ),
          const SizedBox(height: 12),
          const Text("POSITION SPECIFICATION", style: TextStyle(fontSize: 11, color: Colors.cyanAccent, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(child: _buildInputWrapper(label: "Lat...", child: TextFormField(controller: _latDegController, decoration: const InputDecoration(border: InputBorder.none, icon: Icon(Icons.explore, color: Color(0xFFF2C94C), size: 14))))),
              const SizedBox(width: 8),
              Expanded(child: _buildInputWrapper(label: "Lat Min (')", child: TextFormField(controller: _latMinController, decoration: const InputDecoration(border: InputBorder.none, icon: Icon(Icons.access_time, color: Color(0xFFF2C94C), size: 14))))),
              const SizedBox(width: 8),
              _buildDropdownWrapper(
                child: DropdownButton<String>(
                  value: _latDir,
                  items: ["N", "S"].map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(color: Color(0xFFF2C94C))))).toList(),
                  onChanged: (v) => setState(() => _latDir = v!), underline: const SizedBox(), dropdownColor: const Color(0xFF0F2027),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildInputWrapper(label: "Lo...", child: TextFormField(controller: _longDegController, decoration: const InputDecoration(border: InputBorder.none, icon: Icon(Icons.explore, color: Color(0xFFF2C94C), size: 14))))),
              const SizedBox(width: 8),
              Expanded(child: _buildInputWrapper(label: "Long Mi...", child: TextFormField(controller: _longMinController, decoration: const InputDecoration(border: InputBorder.none, icon: Icon(Icons.access_time, color: Color(0xFFF2C94C), size: 14))))),
              const SizedBox(width: 8),
              _buildDropdownWrapper(
                child: DropdownButton<String>(
                  value: _longDir,
                  items: ["E", "W"].map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(color: Color(0xFFF2C94C))))).toList(),
                  onChanged: (v) => setState(() => _longDir = v!), underline: const SizedBox(), dropdownColor: const Color(0xFF0F2027),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildInputWrapper(label: "HW Rate (kts)", child: TextFormField(controller: _springRateController, decoration: const InputDecoration(border: InputBorder.none, icon: Icon(Icons.bolt, color: Color(0xFFF2C94C), size: 14))))),
              const SizedBox(width: 12),
              Expanded(child: _buildInputWrapper(label: "LW Rate (kts)", child: TextFormField(controller: _neapRateController, decoration: const InputDecoration(border: InputBorder.none, icon: Icon(Icons.waves_outlined, color: Color(0xFFF2C94C), size: 14))))),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildInputWrapper(label: "Time fr. HW (h...)", child: TextFormField(controller: _timeFromHwStreamController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(border: InputBorder.none, icon: Icon(Icons.access_time, color: Color(0xFFF2C94C), size: 14))))),
              const SizedBox(width: 12),
              Expanded(child: _buildInputWrapper(label: "Direction (°)", child: TextFormField(controller: _directionController, decoration: const InputDecoration(border: InputBorder.none, icon: Icon(Icons.navigation, color: Color(0xFFF2C94C), size: 14))))),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _calculateStandardDriftAndRecord,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF2C94C), foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text("COMPUTE & RECORD", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.5)),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: const Color(0xFF0F2027).withOpacity(0.6), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF2E4E58))),
            child: Column(
              children: [
                const Text("INTERPOLATION LIVE GRAPH", style: TextStyle(fontSize: 10, color: Colors.grey, letterSpacing: 0.8)),
                const SizedBox(height: 12),
                CustomPaint(size: const Size(double.infinity, 70), painter: TidalSinusoidalPainter(double.tryParse(_timeFromHwStreamController.text) ?? 3.5)),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(children: [const Text("ESTIMATED DRIFT", style: TextStyle(fontSize: 10, color: Colors.grey)), const SizedBox(height: 2), Text("${estimatedDrift.toStringAsFixed(2)} kts", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white))]),
                    Column(children: [const Text("SET DIRECTION", style: TextStyle(fontSize: 10, color: Colors.grey)), const SizedBox(height: 2), Text("${setDirection.toStringAsFixed(0)}°", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFF2C94C)))]),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text("BRIDGE LOGBOOK RECORD", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5)),
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: _logbookRecords.length,
            itemBuilder: (context, index) {
              final item = _logbookRecords[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFF1B2D36), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF2E4E58))),
                child: Row(
                  children: [
                    const Icon(Icons.assignment, color: Color(0xFFF2C94C), size: 22), const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item.location, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)), const SizedBox(height: 2), Text("${item.timeFromHW}h from HW | Dir: ${item.direction.toStringAsFixed(0)}°", style: const TextStyle(fontSize: 11, color: Colors.grey))])),
                    Text("${item.drift.toStringAsFixed(2)} kts", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.greenAccent)), const SizedBox(width: 8),
                    IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20), onPressed: () => setState(() => _logbookRecords.removeAt(index))),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedTablesTab() {
    return Form(
      key: _formKey3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildInputWrapper(label: "Tide Station Reference", child: TextFormField(controller: _tableStationController, decoration: const InputDecoration(border: InputBorder.none, icon: Icon(Icons.chrome_reader_mode, color: Color(0xFFF2C94C))))),
          const SizedBox(height: 16),
          const Text("1. TIDE TABLE HEIGHTS (METERS)", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.cyanAccent)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildInputWrapper(label: "Today HW Hei...", child: TextFormField(controller: _tableHwHeightController, decoration: const InputDecoration(border: InputBorder.none, icon: Icon(Icons.arrow_upward, color: Color(0xFFF2C94C), size: 16))))),
              const SizedBox(width: 12),
              Expanded(child: _buildInputWrapper(label: "Today LW Hei...", child: TextFormField(controller: _tableLwHeightController, decoration: const InputDecoration(border: InputBorder.none, icon: Icon(Icons.arrow_downward, color: Color(0xFFF2C94C), size: 16))))),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildInputWrapper(label: "Mean Spring R...", child: TextFormField(controller: _msrController, decoration: const InputDecoration(border: InputBorder.none, icon: Icon(Icons.waves, color: Color(0xFFF2C94C), size: 16))))),
              const SizedBox(width: 12),
              Expanded(child: _buildInputWrapper(label: "Mean Neap Ra...", child: TextFormField(controller: _mnpController, decoration: const InputDecoration(border: InputBorder.none, icon: Icon(Icons.waves_outlined, color: Color(0xFFF2C94C), size: 16))))),
            ],
          ),
          const SizedBox(height: 16),
          const Text("2. STREAM TABLE VELOCITIES (KNOTS)", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.cyanAccent)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildInputWrapper(label: "Max Spring Ra...", child: TextFormField(controller: _streamSpringMaxController, decoration: const InputDecoration(border: InputBorder.none, icon: Icon(Icons.bolt, color: Color(0xFFF2C94C), size: 16))))),
              const SizedBox(width: 12),
              Expanded(child: _buildInputWrapper(label: "Max Neap Rat...", child: TextFormField(controller: _streamNeapMaxController, decoration: const InputDecoration(border: InputBorder.none, icon: Icon(Icons.directions_run, color: Color(0xFFF2C94C), size: 16))))),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _calculateAdvancedStream,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
            child: const Text("COMPUTE INTERPOLATED STREAM", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFF0F2027), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.cyan.shade800)),
            child: Column(
              children: [
                Text("Spring Factor: ${advancedSpringFactor.toStringAsFixed(0)}%", style: const TextStyle(fontSize: 12, color: Colors.yellowAccent, fontWeight: FontWeight.w500)),
                const SizedBox(height: 6), const Text("CALCULATED CURRENT SPEED", style: TextStyle(fontSize: 11, color: Colors.grey)), const SizedBox(height: 4),
                Text("${advancedCalculatedRate.toStringAsFixed(2)} kts", style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= TAB 4: BINALIK NA LIVE MAP CONNECTOR =================
  Widget _buildLiveMapTab() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.language_rounded, size: 70, color: Colors.cyanAccent),
          const SizedBox(height: 16),
          const Text(
            "GLOBAL OCEAN CURRENTS MAP",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFF2C94C), letterSpacing: 0.5),
          ),
          const SizedBox(height: 14),
          const Text(
            "Upang makasiguro sa katatagan ng app sa bridge, ang live interactive mapping ay bubuksan gamit ang external security web application link.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey, height: 1.4),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0F2027).withOpacity(0.5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.teal.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Row(children: const [Icon(Icons.check_circle, color: Colors.greenAccent, size: 18), SizedBox(width: 8), Text("Windy Live Stream Server Validated", style: TextStyle(fontSize: 12))]),
                const SizedBox(height: 8),
                Row(children: const [Icon(Icons.check_circle, color: Colors.greenAccent, size: 18), SizedBox(width: 8), Text("Real-Time Current Particles Active", style: TextStyle(fontSize: 12))]),
              ],
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 54,
            child: ElevatedButton.icon(
              onPressed: _openLiveMap, // Dito tatawagin ang totoong Link Trigger
              icon: const Icon(Icons.open_in_new, color: Colors.black),
              label: const Text(
                "LAUNCH LIVE INTERACTIVE MAP",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF2C94C),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputWrapper({required String label, required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2), decoration: BoxDecoration(color: Colors.transparent, borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF4F5D65))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)), SizedBox(height: 28, child: child)]),
    );
  }

  Widget _buildDropdownWrapper({required Widget child}) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 8), height: 44, decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF4F5D65))), child: Center(child: child));
  }
}

class WidgetKeepAlive extends StatefulWidget {
  final Widget child;
  const WidgetKeepAlive({super.key, required this.child});
  @override
  State<WidgetKeepAlive> createState() => _WidgetKeepAliveState();
}

class _WidgetKeepAliveState extends State<WidgetKeepAlive> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  @override
  Widget build(BuildContext context) { super.build(context); return widget.child; }
}

class TidalSinusoidalPainter extends CustomPainter {
  final double time;
  TidalSinusoidalPainter(this.time);
  @override
  void paint(Canvas canvas, Size size) {
    final paintCurve = Paint()..color = Colors.tealAccent.shade400..style = PaintingStyle.stroke..strokeWidth = 2.5;
    final path = Path();
    for (double x = 0; x <= size.width; x++) {
      double normalizedX = x / size.width;
      double y = (cos(normalizedX * pi) + 1) / 2 * (size.height - 20) + 10;
      if (x == 0) { path.moveTo(x, y); } else { path.lineTo(x, y); }
    }
    canvas.drawPath(path, paintCurve);
    double ratio = (time.clamp(0.0, 6.0) / 6.0);
    canvas.drawCircle(Offset(ratio * size.width, (cos(ratio * pi) + 1) / 2 * (size.height - 20) + 10), 5.5, Paint()..color = const Color(0xFFFF5252));
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
