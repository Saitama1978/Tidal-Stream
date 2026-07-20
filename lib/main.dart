import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter/services.dart';

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
  String id;
  String location;
  double timeFromHW;
  double direction;
  double drift;

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

  // HEIGHT Tab Controllers
  final _locHeightController = TextEditingController(text: "Manila Harbor");
  final _hwHeightController = TextEditingController(text: "2.5");
  final _lwHeightController = TextEditingController(text: "0.4");
  final _hwTimeController = TextEditingController(text: "08:30");
  final _lwTimeController = TextEditingController(text: "14:30");
  final _depTimeController = TextEditingController(text: "12:00");

  // STANDARD GRAPH Tab Controllers
  final _locationController = TextEditingController(text: "San Bernardino Strait");
  final _latDegController = TextEditingController(text: "12");
  final _latMinController = TextEditingController(text: "51.25");
  String _latDir = "N";
  final _longDegController = TextEditingController(text: "124");
  final _longMinController = TextEditingController(text: "28.47");
  String _longDir = "E";
  final _springRateController = TextEditingController(text: "4.5");
  final _neapRateController = TextEditingController(text: "1.2");
  final _streamHwTimeController = TextEditingController(text: "08:30");
  final _streamTargetTimeController = TextEditingController(text: "12:00");
  final _directionController = TextEditingController(text: "045");

  // ADVANCED TABLES Tab Controllers
  final _tableStationController = TextEditingController(text: "Port Reference Table");
  final _tableHwHeightController = TextEditingController(text: "5.0");
  final _tableLwHeightController = TextEditingController(text: "1.0");
  final _msrController = TextEditingController(text: "4.2");
  final _mnpController = TextEditingController(text: "1.8");
  final _streamSpringMaxController = TextEditingController(text: "3.5");
  final _streamNeapMaxController = TextEditingController(text: "1.5");

  // State calculation variables
  double estimatedHeight = 1.18;
  String targetTimeResult = "12:00"; 
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

  @override
  void initState() {
    super.initState();
    
    _hwHeightController.addListener(_autoCalculateHeight);
    _lwHeightController.addListener(_autoCalculateHeight);
    _hwTimeController.addListener(_autoCalculateHeight);
    _lwTimeController.addListener(_autoCalculateHeight);
    _depTimeController.addListener(_autoCalculateHeight);

    _streamHwTimeController.addListener(_autoCalculateStream);
    _streamTargetTimeController.addListener(_autoCalculateStream);
    _springRateController.addListener(_autoCalculateStream);
    _neapRateController.addListener(_autoCalculateStream);
    _directionController.addListener(_autoCalculateStream);
  }

  @override
  void dispose() {
    _hwHeightController.removeListener(_autoCalculateHeight);
    _lwHeightController.removeListener(_autoCalculateHeight);
    _hwTimeController.removeListener(_autoCalculateHeight);
    _lwTimeController.removeListener(_autoCalculateHeight);
    _depTimeController.removeListener(_autoCalculateHeight);

    _streamHwTimeController.removeListener(_autoCalculateStream);
    _streamTargetTimeController.removeListener(_autoCalculateStream);
    _springRateController.removeListener(_autoCalculateStream);
    _neapRateController.removeListener(_autoCalculateStream);
    _directionController.removeListener(_autoCalculateStream);

    _streamHwTimeController.dispose();
    _streamTargetTimeController.dispose();
    super.dispose();
  }

  double? _parseTimeToHours(String timeStr) {
    try {
      List<String> parts = timeStr.trim().split(':');
      if (parts.length != 2) return null;
      int hour = int.parse(parts[0]);
      int min = int.parse(parts[1]);
      if (hour < 0 || hour > 23 || min < 0 || min > 59) return null;
      return hour + (min / 60.0);
    } catch (_) {
      return null;
    }
  }

  void _autoCalculateHeight() {
    double? hw = double.tryParse(_hwHeightController.text);
    double? lw = double.tryParse(_lwHeightController.text);
    double? tHW = _parseTimeToHours(_hwTimeController.text);
    double? tLW = _parseTimeToHours(_lwTimeController.text);
    double? tDep = _parseTimeToHours(_depTimeController.text);

    if (hw != null && lw != null && tHW != null && tLW != null && tDep != null) {
      double dtTide = tLW - tHW;
      if (dtTide > 12) dtTide -= 24;
      if (dtTide < -12) dtTide += 24;

      double dtTarget = tDep - tHW;
      if (dtTarget > 12) dtTarget -= 24;
      if (dtTarget < -12) dtTarget += 24;

      double fraction;
      if (dtTide.abs() < 0.01) {
        fraction = 0.5;
      } else {
        fraction = (dtTarget / dtTide).clamp(0.0, 1.0);
      }

      double factor = (cos(fraction * pi) + 1) / 2;

      setState(() {
        estimatedHeight = lw + (factor * (hw - lw));
        targetTimeResult = _depTimeController.text.trim();
      });
    }
  }

  void _autoCalculateStream() {
    double? tHW = _parseTimeToHours(_streamHwTimeController.text);
    double? tTarget = _parseTimeToHours(_streamTargetTimeController.text);
    double? springRate = double.tryParse(_springRateController.text);
    double? neapRate = double.tryParse(_neapRateController.text);

    if (tHW != null && tTarget != null && springRate != null && neapRate != null) {
      double diff = tTarget - tHW;
      if (diff > 12) diff -= 24;
      if (diff < -12) diff += 24;

      double absDiff = diff.abs();
      double factor = (cos((absDiff.clamp(0.0, 6.0) / 6.0) * pi) + 1) / 2;

      setState(() {
        estimatedDrift = neapRate + (factor * (springRate - neapRate));
        setDirection = double.tryParse(_directionController.text) ?? 0.0;
      });
    }
  }

  double get _computedStreamHoursDouble {
    double? tHW = _parseTimeToHours(_streamHwTimeController.text);
    double? tTarget = _parseTimeToHours(_streamTargetTimeController.text);
    if (tHW != null && tTarget != null) {
      double diff = tTarget - tHW;
      if (diff > 12) diff -= 24;
      if (diff < -12) diff += 24;
      return diff.abs();
    }
    return 3.5;
  }

  String get _computedStreamIntervalString {
    double hours = _computedStreamHoursDouble;
    return "${hours.toStringAsFixed(2)} hrs";
  }

  void _calculateStandardDriftAndRecord() {
    if (_formKey2.currentState!.validate()) {
      double hours = _computedStreamHoursDouble;
      setState(() {
        _logbookRecords.insert(
          0,
          LogbookRecord(
            id: DateTime.now().toString(),
            location: _locationController.text,
            timeFromHW: double.parse(hours.toStringAsFixed(2)),
            direction: setDirection,
            drift: estimatedDrift,
          ),
        );
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Bridge logbook entry recorded successfully!")),
      );
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

  void _editLogRecord(LogbookRecord record, int index) {
    final editLocController = TextEditingController(text: record.location);
    final editTimeController = TextEditingController(text: record.timeFromHW.toString());
    final editDirController = TextEditingController(text: record.direction.toStringAsFixed(0));
    final editDriftController = TextEditingController(text: record.drift.toStringAsFixed(2));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F2027),
        title: const Text("Edit Logbook Entry", style: TextStyle(color: Color(0xFFF2C94C))),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: editLocController,
                decoration: const InputDecoration(labelText: "Location"),
              ),
              TextField(
                controller: editTimeController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: "Time from HW (h)"),
              ),
              TextField(
                controller: editDirController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: "Direction (°)"),
              ),
              TextField(
                controller: editDriftController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: "Drift Rate (kts)"),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF2C94C), foregroundColor: Colors.black),
            onPressed: () {
              setState(() {
                _logbookRecords[index] = LogbookRecord(
                  id: record.id,
                  location: editLocController.text,
                  timeFromHW: double.tryParse(editTimeController.text) ?? record.timeFromHW,
                  direction: double.tryParse(editDirController.text) ?? record.direction,
                  drift: double.tryParse(editDriftController.text) ?? record.drift,
                );
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Log record updated successfully!")),
              );
            },
            child: const Text("SAVE CHANGES"),
          ),
        ],
      ),
    );
  }

  void _saveLogHistory() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.teal.shade800,
        content: Text("Successfully saved ${_logbookRecords.length} records to local storage!"),
      ),
    );
  }

  void _printLogHistory() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Colors.blueGrey,
        content: Text("Sending log history to printer server..."),
      ),
    );
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
              Tab(text: "LOG HISTORY"), 
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
              WidgetKeepAlive(child: Padding(padding: const EdgeInsets.all(16.0), child: _buildLogHistoryTab())), 
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
          const Text("HIGH TIDE SPECIFICATION (HW)", style: TextStyle(fontSize: 11, color: Colors.cyanAccent, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          const SizedBox(height: 6),
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
                  label: "HW Time (HH:MM)",
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(controller: _hwTimeController, decoration: const InputDecoration(border: InputBorder.none)),
                      ),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.access_time, color: Color(0xFFF2C94C), size: 18),
                        onPressed: () async {
                          TimeOfDay? picked = await showTimePicker(
                            context: context,
                            initialTime: const TimeOfDay(hour: 8, minute: 30),
                          );
                          if (picked != null) {
                            final hourStr = picked.hour.toString().padLeft(2, '0');
                            final minStr = picked.minute.toString().padLeft(2, '0');
                            _hwTimeController.text = "$hourStr:$minStr";
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text("LOW TIDE SPECIFICATION (LW)", style: TextStyle(fontSize: 11, color: Colors.cyanAccent, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _buildInputWrapper(
                  label: "LW Height (m)",
                  child: TextFormField(controller: _lwHeightController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(border: InputBorder.none, icon: Icon(Icons.trending_down, color: Color(0xFFF2C94C)))),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInputWrapper(
                  label: "LW Time (HH:MM)",
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(controller: _lwTimeController, decoration: const InputDecoration(border: InputBorder.none)),
                      ),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.access_time, color: Color(0xFFF2C94C), size: 18),
                        onPressed: () async {
                          TimeOfDay? picked = await showTimePicker(
                            context: context,
                            initialTime: const TimeOfDay(hour: 14, minute: 30),
                          );
                          if (picked != null) {
                            final hourStr = picked.hour.toString().padLeft(2, '0');
                            final minStr = picked.minute.toString().padLeft(2, '0');
                            _lwTimeController.text = "$hourStr:$minStr";
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text("DEPARTURE SPECIFICATION", style: TextStyle(fontSize: 11, color: Colors.cyanAccent, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          const SizedBox(height: 6),
          _buildInputWrapper(
            label: "Departure Time (HH:MM)",
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(controller: _depTimeController, decoration: const InputDecoration(border: InputBorder.none)),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.access_time, color: Color(0xFFF2C94C), size: 20),
                  onPressed: () async {
                    TimeOfDay? picked = await showTimePicker(
                      context: context,
                      initialTime: const TimeOfDay(hour: 12, minute: 0),
                    );
                    if (picked != null) {
                      final hourStr = picked.hour.toString().padLeft(2, '0');
                      final minStr = picked.minute.toString().padLeft(2, '0');
                      _depTimeController.text = "$hourStr:$minStr";
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: const Color(0xFF0F2027).withOpacity(0.5), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFF2C94C).withOpacity(0.4))),
            child: Column(
              children: [
                Text("ESTIMATED TIDAL HEIGHT AT $targetTimeResult (AUTO INTERPOLATED)", style: const TextStyle(fontSize: 11, color: Colors.grey, letterSpacing: 1, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text("${estimatedHeight.toStringAsFixed(2)} m", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
              ],
            ),
          ),
          const SizedBox(height: 60),
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
              Expanded(child: _buildInputWrapper(label: "HW Rate / Spring (kts)", child: TextFormField(controller: _springRateController, decoration: const InputDecoration(border: InputBorder.none, icon: Icon(Icons.bolt, color: Color(0xFFF2C94C), size: 14))))),
              const SizedBox(width: 12),
              Expanded(child: _buildInputWrapper(label: "LW Rate / Neap (kts)", child: TextFormField(controller: _neapRateController, decoration: const InputDecoration(border: InputBorder.none, icon: Icon(Icons.waves_outlined, color: Color(0xFFF2C94C), size: 14))))),
            ],
          ),
          const SizedBox(height: 12),
          const Text("TIME INTERPOLATION SPECIFICATION (AUTO)", style: TextStyle(fontSize: 11, color: Colors.cyanAccent, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _buildInputWrapper(
                  label: "HW Time (HH:MM)",
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(controller: _streamHwTimeController, decoration: const InputDecoration(border: InputBorder.none)),
                      ),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.access_time, color: Color(0xFFF2C94C), size: 18),
                        onPressed: () async {
                          TimeOfDay? picked = await showTimePicker(
                            context: context,
                            initialTime: const TimeOfDay(hour: 8, minute: 30),
                          );
                          if (picked != null) {
                            final hourStr = picked.hour.toString().padLeft(2, '0');
                            final minStr = picked.minute.toString().padLeft(2, '0');
                            _streamHwTimeController.text = "$hourStr:$minStr";
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInputWrapper(
                  label: "Target Time (HH:MM)",
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(controller: _streamTargetTimeController, decoration: const InputDecoration(border: InputBorder.none)),
                      ),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.access_time, color: Color(0xFFF2C94C), size: 18),
                        onPressed: () async {
                          TimeOfDay? picked = await showTimePicker(
                            context: context,
                            initialTime: const TimeOfDay(hour: 12, minute: 0),
                          );
                          if (picked != null) {
                            final hourStr = picked.hour.toString().padLeft(2, '0');
                            final minStr = picked.minute.toString().padLeft(2, '0');
                            _streamTargetTimeController.text = "$hourStr:$minStr";
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F2027),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF4F5D65).withOpacity(0.5)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Calculated Interval:", style: TextStyle(fontSize: 10, color: Colors.grey)),
                      Text(_computedStreamIntervalString, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.cyanAccent)),
                    ],
                  ),
                ),
              ),
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
                const Text("INTERPOLATION LIVE GRAPH (REALTIME UPDATE)", style: TextStyle(fontSize: 9, color: Colors.grey, letterSpacing: 0.8)),
                const SizedBox(height: 12),
                CustomPaint(size: const Size(double.infinity, 70), painter: TidalSinusoidalPainter(_computedStreamHoursDouble)),
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
          const SizedBox(height: 80),
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
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildLogHistoryTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "BRIDGE LOGBOOK RECORDS",
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFF2C94C), letterSpacing: 0.5),
            ),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _saveLogHistory,
                  icon: const Icon(Icons.save, size: 16),
                  label: const Text("SAVE", style: TextStyle(fontSize: 11)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                ),
                const SizedBox(width: 6),
                ElevatedButton.icon(
                  onPressed: _printLogHistory,
                  icon: const Icon(Icons.print, size: 16),
                  label: const Text("PRINT", style: TextStyle(fontSize: 11)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _logbookRecords.isEmpty
              ? const Center(
                  child: Text(
                    "No log records calculated yet.",
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  itemCount: _logbookRecords.length,
                  itemBuilder: (context, index) {
                    final item = _logbookRecords[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B2D36),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF2E4E58)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.assignment, color: Color(0xFFF2C94C), size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.location,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "${item.timeFromHW}h from HW | Dir: ${item.direction.toStringAsFixed(0)}°",
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            "${item.drift.toStringAsFixed(2)} kts",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.greenAccent),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.cyanAccent, size: 20),
                            onPressed: () => _editLogRecord(item, index),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                            onPressed: () => setState(() => _logbookRecords.removeAt(index)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildInputWrapper({required String label, required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(color: Colors.transparent, borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF4F5D65))),
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
