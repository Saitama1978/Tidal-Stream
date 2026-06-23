class _TidalCalculatorHomePageState extends State<TidalCalculatorHomePage> {
  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();
  final _formKey3 = GlobalKey<FormState>();

  // --- TAB 1: HEIGHT CONTROLLERS & STATES ---
  final _locHeightController = TextEditingController(text: "Manila Harbor");
  final _hwHeightController = TextEditingController(text: "2.5");
  final _lwHeightController = TextEditingController(text: "0.4");
  
  // Mga Baguhang Time States para sa Height Tab
  TimeOfDay? _hwTime = const TimeOfDay(hour: 10, minute: 0);
  TimeOfDay? _lwTime = const TimeOfDay(hour: 16, minute: 15);
  TimeOfDay? _targetTime = const TimeOfDay(hour: 13, minute: 30);

  // --- TAB 2 & 3 CONTROLLERS (Mananatiling pareho) ---
  final _locationController = TextEditingController(text: "San Bernardino Strait");
  final _latDegController = TextEditingController(text: "12");
  final _latMinController = TextEditingController(text: "51.25");
  String _latDir = "N";
  final _longDegController = TextEditingController(text: "124");
  final _longMinController = TextEditingController(text: "28.47");
  String _longDir = "E";
  final _hwRateController = TextEditingController(text: "4.5");
  final _lwRateController = TextEditingController(text: "1.2");
  final _timeFromHWController = TextEditingController(text: "3.5");
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
    LogbookRecord(id: "1", location: "San Bernardino Strait", timeFromHW: 3.5, direction: 45.0, drift: 2.42),
  ];

  // Helper para sa pagpili ng oras
  Future<void> _selectTime(BuildContext context, String type) async {
    TimeOfDay initialTime = const TimeOfDay(hour: 12, minute: 0);
    if (type == 'HW') initialTime = _hwTime ?? initialTime;
    if (type == 'LW') initialTime = _lwTime ?? initialTime;
    if (type == 'TARGET') initialTime = _targetTime ?? initialTime;

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (picked != null) {
      setState(() {
        if (type == 'HW') _hwTime = picked;
        if (type == 'LW') _lwTime = picked;
        if (type == 'TARGET') _targetTime = picked;
      });
    }
  }

  // Helper para makuha ang kabuuang minuto mula sa simula ng araw
  int _timeToMinutes(TimeOfDay time) => (time.hour * 60) + time.minute;

  void _calculateHeight() {
    if (_formKey1.currentState!.validate() && _hwTime != null && _lwTime != null && _targetTime != null) {
      double hwHeight = double.tryParse(_hwHeightController.text) ?? 0.0;
      double lwHeight = double.tryParse(_lwHeightController.text) ?? 0.0;

      int hwMin = _timeToMinutes(_hwTime!);
      int lwMin = _timeToMinutes(_lwTime!);
      int targetMin = _timeToMinutes(_targetTime!);

      // Kalkulahin ang kabuuang duration ng tide cycle (HW hanggang LW)
      int totalTideDuration = (hwMin - lwMin).abs();
      if (totalTideDuration == 0) return; // Iwasan ang division by zero

      // Kalkulahin ang agwat ng Target Time mula sa HW
      int timeFromHW = (targetMin - hwMin).abs();

      // Sinusoidal factor batay sa totoong duration ng tide
      double factor = (cos((timeFromHW / totalTideDuration) * pi) + 1) / 2;

      setState(() {
        estimatedHeight = lwHeight + (factor * (hwHeight - lwHeight));
      });
    }
  }

  // --- CODES PARA SA TAB 2, TAB 3 & USER GUIDE (Mananatili gaya ng sa iyo) ---
  void _calculateStandardDriftAndRecord() { /* pareho pa rin */ }
  void _calculateAdvancedStream() { /* pareho pa rin */ }
  void _showUserGuide(BuildContext context) { /* pareho pa rin */ }
  Widget _buildManualSection({required String title, required String body}) { return const SizedBox(); }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      initialIndex: 0, // Iniba ko sa 0 para bumukas agad sa HEIGHT tab
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

  // ================= UPGRADED HEIGHT TAB =================
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
          // Row para sa HW Height at HW Time Input
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
                  time: _hwTime,
                  onTap: () => _selectTime(context, 'HW'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Row para sa LW Height at LW Time Input
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
                  time: _lwTime,
                  onTap: () => _selectTime(context, 'LW'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Target Time Field (Dito icocompute kung anong taas ng tubig sa oras na ito)
          _buildTimeSelectorWrapper(
            label: "Target Time for Calculation (hh:mm)",
            time: _targetTime,
            onTap: () => _selectTime(context, 'TARGET'),
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

  // Wrapper Widget para sa Custom Time Picker UI
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

  // --- IPADUGTONG ANG MGA NATITIRANG WIDGETS AT PAINTERS SA IYONG CODE ---
  Widget _buildStandardGraphTab() { return const SizedBox(); /* Iwanan ang iyong lumang code dito */ }
  Widget _buildAdvancedTablesTab() { return const SizedBox(); /* Iwanan ang iyong lumang code dito */ }
  Widget _buildInputWrapper({required String label, required Widget child}) { return const SizedBox(); /* Iwanan ang iyong lumang code dito */ }
  Widget _buildDropdownWrapper({required Widget child}) { return const SizedBox(); /* Iwanan ang iyong lumang code dito */ }
}
