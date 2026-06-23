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
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF0F2027),
        scaffoldBackgroundColor: const Color(0xFF203A43),
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
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('TIDAL STREAM WORLDWIDE'),
          backgroundColor: const Color(0xFF0F2027),
          bottom: const TabBar(
            tabs: [
              Tab(text: "HEIGHT"),
              Tab(text: "DRIFT/GRAPH"),
              Tab(text: "ADVANCED"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _HeightTabContent(),
            _DriftGraphTabContent(),
            _AdvancedTabContent(),
          ],
        ),
      ),
    );
  }
}

// TAB 1: HEIGHT (Purely Meters)
class _HeightTabContent extends StatelessWidget {
  const _HeightTabContent();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(decoration: const InputDecoration(labelText: "HW Height (meters)")),
          TextField(decoration: const InputDecoration(labelText: "LW Height (meters)")),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: () {}, child: const Text("COMPUTE HEIGHT")),
        ],
      ),
    );
  }
}

// TAB 2: DRIFT/GRAPH (Original layout preserved)
class _DriftGraphTabContent extends StatelessWidget {
  const _DriftGraphTabContent();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(children: [
            Expanded(child: TextField(decoration: const InputDecoration(labelText: "HW Rate (kts)"))),
            Expanded(child: TextField(decoration: const InputDecoration(labelText: "LW Rate (kts)"))),
          ]),
          const SizedBox(height: 20),
          const Text("INTERPOLATION LIVE GRAPH"),
          // Dito ang graph na gusto mong manatili
          Container(height: 150, color: Colors.black45), 
        ],
      ),
    );
  }
}

// TAB 3: ADVANCED (Layout exactly as approved)
class _AdvancedTabContent extends StatelessWidget {
  const _AdvancedTabContent();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const Text("1. TIDE TABLE HEIGHTS (METERS)"),
          TextField(decoration: const InputDecoration(labelText: "Today HW Height")),
          TextField(decoration: const InputDecoration(labelText: "Today LW Height")),
          const SizedBox(height: 20),
          const Text("2. STREAM TABLE VELOCITIES (KNOTS)"),
          TextField(decoration: const InputDecoration(labelText: "Max Spring Rate")),
          TextField(decoration: const InputDecoration(labelText: "Max Neap Rate")),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: () {}, child: const Text("COMPUTE INTERPOLATED STREAM")),
        ],
      ),
    );
  }
}
