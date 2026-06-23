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

  // --- TAB 1: HEIGHT CONTROLLERS & STATES ---
  final _locHeightController = TextEditingController(text: "Manila Harbor");
  final _hwHeightController = TextEditingController(text: "2.5");
  final _lwHeightController = TextEditingController(text: "0.4");
  
  TimeOfDay? _hwTimeTab1 = const TimeOfDay(hour: 10, minute: 0);
  TimeOfDay? _lwTimeTab1 = const TimeOfDay(hour: 16, minute: 15);
  TimeOfDay? _targetTimeTab1 = const TimeOfDay(hour: 13, minute: 30);

  // --- TAB 2: STANDARD GRAPH CONTROLLERS & STATES ---
  final _locationController = TextEditingController(text: "San Bernardino Strait");
  final _latDegController = TextEditingController(text: "12");
  final _latMinController = TextEditingController(text: "51.25");
  String _latDir = "N";
  final _longDegController = TextEditingController(text: "124");
  final _longMinController = TextEditingController(text: "28.47");
  String _longDir = "E";
  final _springRateController = TextEditingController(text: "4.5"); // Dati ay _hwRateController
  final _neapRateController = TextEditingController(text: "1.2");   // Dati ay _lwRateController
  final _directionController = TextEditingController(text: "045");

  TimeOfDay? _hwTimeTab2 = const TimeOfDay(hour: 10, minute: 0);
  TimeOfDay? _targetTimeTab2 = const TimeOfDay(hour: 13, minute: 30);
  double _calculatedTimeFromHWTab2 = 3.5;

  // --- TAB 3: ADVANCED TABLES CONTROLLERS ---
  final _tableStationController = TextEditingController(text: "Port Reference Table");
  final _tableHwHeightController = TextEditingController(text: "5.0");
  final _tableLwHeightController = TextEditingController(text: "1.0");
  final _msrController = TextEditingController(text: "4.2");
  final _mnpController = TextEditingController(text: "1.8");
  final _streamSpringMaxController = TextEditingController(text: "3.5");
  final _streamNeapMaxController = TextEditingController(text: "1.5");

  // Default States
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

  Future<void> _selectTime(BuildContext context, String tabAndType) async {
    TimeOfDay initialTime = const TimeOfDay(hour: 12, minute: 0);
    
    if (tabAndType == 'T1_HW') initialTime = _hwTimeTab1 ?? initialTime;
    if (tabAndType == 'T1_LW') initialTime = _lwTimeTab1 ?? initialTime;
    if (tabAndType == 'T1_TARGET') initialTime = _targetTimeTab1 ?? initialTime;
    if (tabAndType == 'T2_HW') initialTime = _hwTimeTab2 ?? initialTime;
    if (tabAndType == 'T2_TARGET') initialTime = _targetTimeTab2 ?? initialTime;

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (picked != null) {
      setState(() {
        if (tabAndType == 'T1_HW') _hwTimeTab1 = picked;
        if (tabAndType == 'T1_LW') _lwTimeTab1 = picked;
        if (tabAndType == 'T1_TARGET') _targetTimeTab1 = picked;
        if (tabAndType == 'T2_HW') _hwTimeTab2 = picked;
        if (tabAndType == 'T2_TARGET') _targetTimeTab2 = picked;
      });
    }
  }

  int _timeToMinutes(TimeOfDay time) => (time.hour * 60) + time.minute;

  void _calculateHeight() {
    if (_formKey1.currentState!.validate() && _hwTimeTab1 != null && _lwTimeTab1 != null && _targetTimeTab1 != null) {
      double hw = double.tryParse(_hwHeightController.text) ?? 0.0;
      double lw = double.tryParse(_lwHeightController.text) ?? 0.0;

      int hwMin = _timeToMinutes(_hwTimeTab1!);
      int lwMin = _timeToMinutes(_lwTimeTab1!);
      int targetMin = _timeToMinutes(_targetTimeTab1!);

      int totalTideDuration = (hwMin - lwMin).abs();
      if (totalTideDuration == 0) return; 

      int timeFromHW = (targetMin - hwMin).abs();
      double factor = (cos((timeFromHW / totalTideDuration) * pi) + 1) / 2;
      
      setState(() {
        estimatedHeight = lw + (factor * (hw - lw));
      });
    }
  }

  void _calculateStandardDriftAndRecord() {
    if (_formKey2.currentState!.validate() && _hwTimeTab2 != null && _targetTimeTab2 != null) {
      double springRate = double.tryParse(_springRateController.text) ?? 0.0;
      double neapRate = double.tryParse(_neapRateController.text) ?? 0.0;
      
      int hwMin = _timeToMinutes(_hwTimeTab2!);
      int targetMin = _timeToMinutes(_targetTimeTab2!);

      int diffInMinutes = (targetMin - hwMin).abs();
      double durationInHours = diffInMinutes / 60.0;

      _calculatedTimeFromHWTab2 = durationInHours;

      double factor = (cos((durationInHours.clamp(0.0, 6.0) / 6.0) * pi) + 1) / 2;
      
      setState(() {
        estimatedDrift = neapRate + (factor * (springRate - neapRate));
        setDirection = double.tryParse(_directionController.text) ?? 0.0;

        _logbookRecords.insert(
          0,
          LogbookRecord(
            id: DateTime.now().toString(),
            location: _locationController.text,
            timeFromHW: double.parse(durationInHours.toStringAsFixed(1)),
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

  void _showUserGuide(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F2027),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: ListView(
                controller: scrollController,
                physics: const ClampingScrollPhysics(),
                children: [
                  const SizedBox(height: 12),
                  Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey.shade600, borderRadius: BorderRadius.circular(10)))),
                  const SizedBox(height: 20),
                  const Row(
                    children: [
                      Icon(Icons.menu_book, color: Color(0xFFF2C94C), size: 24),
                      SizedBox(width: 12),
                      Text("BRIDGE USER MANUAL", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFF2C94C))),
                    ],
                  ),
                  const Divider(color: Colors.grey, height: 24),
                  _buildManualSection(
                    title: "1. HEIGHT TAB (Meters Calculation)",
                    body: "Gagamitin para sa pagkuha ng Tidal Height (m) sa tiyak na oras para sa Under Keel Clearance (UKC).\n\n"
                          "• Ipasok ang Location, HW Height, at LW Height sa unit na metro.\n"
                          "• Piliin ang HW Time, LW Time, at Target Time gamit ang orasan.\n"
                          "• I-click ang COMPUTE HEIGHT para makita ang pinal na resulta.",
                  ),
                  _buildManualSection(
                    title: "2. STANDARD GRAPH TAB (Drift & Set)",
                    body: "Pangunahing visual guide para sa pagkalkula ng bilis (Drift) at direksyon (Set) ng agos.\n\n"
                          "• Ipasok ang Lat/Long at Cardinal directions (N/S/E/W).\n"
                          "• I-encode ang Max Spring at Max Neap Rates mula sa Tidal Stream Atlas / Chart Table.\n"
                          "• Ipasok ang HW Time at Target (ETA) Time upang awtomatikong makuha ang agwat ng oras.\n"
                          "• I-click ang COMPUTE & RECORD upang mag-save sa Bridge Logbook.",
                  ),
                  _buildManualSection(
                    title: "3. ADVANCED TABLES (Dual-Interpolation)",
                    body: "Para sa tumpak na pag-compute gamit ang Range values (Mean Spring/Neap Range).\n\n"
                          "• Ilagay ang kasalukuyang HW/LW Heights kasama ang MSR at MNP mula sa bungad ng Tide Tables.\n"
                          "• I-encode ang Max Spring/Neap rates at i-click ang COMPUTE upang makuha ang Spring Factor (%) at Calculated Current Speed.",
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.redAccent.withOpacity(0.4))),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 20),
                        SizedBox(width: 10),
                        Expanded(child: Text("BABALA: Ang app ay gumagamit ng sinusoidal approximations. Palaging i-cross-check ang resulta sa opisyal na Admiralty TotalTide (ATT) o manual charts sa panahon ng bridge watch.", style: TextStyle(fontSize: 12, color: Colors.grey))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildManualSection({required String title, required String body}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.cyanAccent)),
          const SizedBox(height: 6),
          Text(body, style: const TextStyle(fontSize: 12, color: Colors.white70, height: 1.4)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      initialIndex: 0,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('TIDAL STREAM WORLDWIDE', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFF2C94C), letterSpacing: 1.2)),
          centerTitle: true,
          backgroundColor: const Color(0xFF0F2027),
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.help_outline, color: Color(0xFFF2C94C)),
              tooltip: 'User Manual',
              onPressed: () => _showUserGuide(context),
            )
          ],
          bottom: const TabBar(
            indicatorColor: Color(0xFFF2C94C),
            labelColor: Color(0xFFF2C94C),
            unselectedLabelColor: Colors.grey,
            tabs: [Tab(text: "HEIGHT"), Tab(text: "STANDARD GRAPH"), Tab(text: "ADVANCED TABLES")],
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF0F2027), Color(0xFF14262E)], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
          child: TabBarView(
            children: [
              WidgetKeepAlive(child: SingleChildScrollView(padding: const EdgeInsets.all(16.0), child: _buildHeightTab())),
              WidgetKeepAlive(child: SingleChildScrollView(padding: const EdgeInsets.all(16.0), child: _buildStandardGraphTab())),
              WidgetKeepAlive(child: SingleChildScrollView(padding: const EdgeInsets.all(16.0), child: _buildAdvancedTablesTab())),
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
                child: _buildTimeSelectorWrapper(
                  label: "HW Time (hh:mm)",
                  time: _hwTimeTab1,
                  onTap: () => _selectTime(context, 'T1_HW'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
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
              const SizedBox(width: 12),
              Expanded(
                child: _buildTimeSelectorWrapper(
                  label: "LW Time (hh:mm)",
                  time: _lwTimeTab1,
                  onTap: () => _selectTime(context, 'T1_LW'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTimeSelectorWrapper(
            label: "Target Time for Calculation (hh:mm)",
            time: _targetTimeTab1,
            onTap: () => _selectTime(context, 'T1_TARGET'),
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
                Text("${estimatedHeight.toStringAsFixed(2)} m", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= TAB 2: STANDARD GRAPH (UPDATED LABELS) =================
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
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: const InputDecoration(border: InputBorder.none, icon: Icon(Icons.map, color: Color(0xFFF2C94C), size: 18)),
            ),
          ),
          const SizedBox(height: 12),
          const Text("POSITION SPECIFICATION", style: TextStyle(fontSize: 11, color: Colors.cyanAccent, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _buildInputWrapper(
                  label: "Lat...",
                  child: TextFormField(controller: _latDegController, decoration: const InputDecoration(border: InputBorder.none, icon: Icon(Icons.explore, color: Color(0xFFF2C94C), size: 14))),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildInputWrapper(
                  label: "Lat Min (')",
                  child: TextFormField(controller: _latMinController, decoration: const InputDecoration(border: InputBorder.none, icon: Icon(Icons.access_time, color: Color(0xFFF2C94C), size: 14))),
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
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildInputWrapper(
                  label: "Lo...",
                  child: TextFormField(controller: _longDegController, decoration: const InputDecoration(border: InputBorder.none, icon: Icon(Icons.explore, color: Color(0xFFF2C94C), size: 14))),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildInputWrapper(
                  label: "Long Mi...",
                  child: TextFormField(controller: _longMinController, decoration: const InputDecoration(border: InputBorder.none, icon: Icon(Icons.access_time, color: Color(0xFFF2C94C), size: 14))),
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
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildInputWrapper(
                  label: "Max Spring Rate (kts) [Mula sa Atlas/Chart]", // PINALITAN ANG LABEL DITO CHIEF
                  child: TextFormField(controller: _springRateController, decoration: const InputDecoration(border: InputBorder.none, icon: Icon(Icons.bolt, color: Color(0xFFF2C94C), size: 14))),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInputWrapper(
                  label: "Max Neap Rate (kts) [Mula sa Atlas/Chart]",  // PINALITAN ANG LABEL DITO CHIEF
                  child: TextFormField(controller: _neapRateController, decoration: const InputDecoration(border: InputBorder.none, icon: Icon(Icons.waves_outlined, color: Color(0xFFF2C94C), size: 14))),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTimeSelectorWrapper(
                  label: "HW Time (hh:mm)",
                  time: _hwTimeTab2,
                  onTap: () => _selectTime(context, 'T2_HW'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTimeSelectorWrapper(
                  label: "Target Time / ETA (hh:mm)",
                  time: _targetTimeTab2,
                  onTap: () => _selectTime(context, 'T2_TARGET'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInputWrapper(
            label: "Direction (°)",
            child: TextFormField(controller: _directionController, decoration: const InputDecoration(border: InputBorder.none, icon: Icon(Icons.navigation, color: Color(0xFFF2C94C), size: 14))),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _calculateStandardDriftAndRecord,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF2C94C),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("COMPUTE & RECORD", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.5)),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF0F2027).withOpacity(0.6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF2E4E58)),
            ),
            child: Column(
              children: [
                const Text("INTERPOLATION LIVE GRAPH", style: TextStyle(fontSize: 10, color: Colors.grey, letterSpacing: 0.8)),
                const SizedBox(height: 12),
                CustomPaint(
                  size: const Size(double.infinity, 70),
                  painter: TidalSinusoidalPainter(_calculatedTimeFromHWTab2),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Text("ESTIMATED DRIFT", style: TextStyle(fontSize: 10, color: Colors.grey)),
                        const SizedBox(height: 2),
                        Text("${estimatedDrift.toStringAsFixed(2)} kts", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                      ],
                    ),
                    Column(
                      children: [
                        const Text("SET DIRECTION", style: TextStyle(fontSize: 10, color: Colors.grey)),
                        const SizedBox(height: 2),
                        Text("${setDirection.toStringAsFixed(0)}°", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFF2C94C))),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text("BRIDGE LOGBOOK RECORD", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5)),
          const SizedBox(height: 8),
          _logbookRecords.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: Text("No records available.", style: TextStyle(color: Colors.grey, fontSize: 12))),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _logbookRecords.length,
                  itemBuilder: (context, index) {
                    final item = _logbookRecords[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B2D36),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF2E4E58)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.assignment, color: Color(0xFFF2C94C), size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.location, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                                const SizedBox(height: 2),
                                Text("${item.timeFromHW}h from HW | Dir: ${item.direction.toStringAsFixed(0)}°", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                              ],
                            ),
                          ),
                          Text("${item.drift.toStringAsFixed(2)} kts", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.greenAccent)),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                            onPressed: () {
                              setState(() {
                                _logbookRecords.removeAt(index);
                              });
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  // ================= TAB 3: ADVANCED TABLES =================
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
                  "Spring Factor: ${advancedSpringFactor.toStringAsFixed(0)}%",
                  style: const TextStyle(fontSize: 12, color: Colors.yellowAccent, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 6),
                const Text("CALCULATED CURRENT SPEED", style: TextStyle(fontSize: 11, color: Colors.grey)),
                const SizedBox(height: 4),
                Text(
                  "${advancedCalculatedRate.toStringAsFixed(2)} kts",
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputWrapper({required String label, required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF4F5D65)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          SizedBox(height: 28, child: child),
        ],
      ),
    );
  }

  Widget _buildDropdownWrapper({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF4F5D65)),
      ),
      child: Center(child: child),
    );
  }

  Widget _buildTimeSelectorWrapper({required String label, required TimeOfDay? time, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF4F5D65)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.access_time, color: Color(0xFFF2C94C), size: 20),
                const SizedBox(width: 8),
                Text(
                  time != null ? time.format(context) : "--:--",
                  style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
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
      if (x == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paintCurve);

    double ratio = (time.clamp(0.0, 6.0) / 6.0);
    canvas.drawCircle(Offset(ratio * size.width, (cos(ratio * pi) + 1) / 2 * (size.height - 20) + 10), 5.5, Paint()..color = const Color(0xFFFF5252));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
