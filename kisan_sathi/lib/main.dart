// lib/main.dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_tts/flutter_tts.dart';


import 'services/api_service.dart';

/// ------------------------------------------------------------
///  Recent responses model & local storage (SharedPreferences)
/// ------------------------------------------------------------

class RecentItem {
  final String question; // user ka sawaal
  final String answer; // assistant ka jawaab
  final DateTime timestamp;

  RecentItem({
    required this.question,
    required this.answer,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'q': question,
        'a': answer,
        'ts': timestamp.toIso8601String(),
      };

  factory RecentItem.fromJson(Map<String, dynamic> json) => RecentItem(
        question: json['q'] as String,
        answer: json['a'] as String,
        timestamp:
            DateTime.tryParse(json['ts'] as String? ?? '') ?? DateTime.now(),
      );
}

class RecentStorage {
  static const _prefsKey = 'recent_items_v1';

  /// Naya item add karo (max 50, latest upar)
  static Future<void> addItem(String question, String answer) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_prefsKey) ?? [];

    final item = RecentItem(
      question: question,
      answer: answer,
      timestamp: DateTime.now(),
    );

    list.insert(0, jsonEncode(item.toJson())); // newest at index 0
    if (list.length > 50) {
      list.removeRange(50, list.length);
    }

    await prefs.setStringList(_prefsKey, list);
  }

  /// Saare stored items read karo
  static Future<List<RecentItem>> getItems() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_prefsKey) ?? [];
    return list
        .map((s) => RecentItem.fromJson(jsonDecode(s)))
        .toList(growable: false);
  }

  /// Purana history clear
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }
}

/// ------------------------------------------------------------
///  App entry
/// ------------------------------------------------------------

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const KisanSathiApp());
}

class KisanSathiApp extends StatelessWidget {
  const KisanSathiApp({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF0B7A5A);
    const darkGreen = Color(0xFF065C42);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kisan Sathi',
      theme: ThemeData(
        primaryColor: primaryGreen,
        scaffoldBackgroundColor: primaryGreen,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryGreen,
          primary: primaryGreen,
          secondary: darkGreen,
        ),
        textTheme: GoogleFonts.robotoTextTheme(
          Theme.of(context).textTheme,
        ).apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryGreen,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

/// ------------------------------------------------------------
///  Side Drawer (menu)
/// ------------------------------------------------------------



class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: const Color(0xFF065C42),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ---------- Header ----------
              DrawerHeader(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    SizedBox(height: 8),
                    Text(
                      'किसान साथी',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Farmer Voice Assistant',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),

              // ---------- Menu Items ----------
              ListTile(
                leading: const Icon(Icons.home, color: Colors.white),
                title: const Text('होम'),
                textColor: Colors.white,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const HomeScreen(),
                    ),
                    (route) => false,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.history, color: Colors.white),
                title: const Text('हाल के सवाल'),
                textColor: Colors.white,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RecentResponsesScreen(),
                    ),
                  );
                },
              ),

              const Spacer(),
              const Divider(color: Colors.white24, height: 1),

              // ---------- Developer Credit (Perfectly Balanced) ----------
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B7A5A),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.eco, // 🌿 Leaf icon
                          size: 18,
                          color: Colors.lightGreenAccent,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Developed by MCA Students',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


/// ------------------------------------------------------------
///  Home Screen
/// ------------------------------------------------------------
///  Home Screen
/// ------------------------------------------------------------

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF0B7A5A);
    const cardGreen = Color(0xFF075D44);

    return Scaffold(
      backgroundColor: bg,
      drawer: const AppDrawer(),
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        title: const Text(
          'किसान साथी',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ---------- किसान इमेज कार्ड ----------
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Container(
                height: 210,
                decoration: BoxDecoration(
                  color: cardGreen,
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Image.asset(
                      'assets/images/farmer.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ---------- टाइटल ----------
            const Center(
              child: Text(
                'बोलने के लिए टैप करें',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            const SizedBox(height: 14),

            // ---------- माइक बटन → VoiceQueryScreen ----------
            Center(
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const VoiceQueryScreen(),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(80),
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      )
                    ],
                  ),
                  child: const Icon(
                    Icons.mic,
                    size: 48,
                    color: bg,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // ---------- इंग्लिश हेल्पर टेक्स्ट ----------
            const Center(
              child: Text(
                'Tap the mic and ask your question',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white70,
                ),
              ),
            ),

            // बीच में थोड़ा खाली space ताकि कार्ड नीचे अच्छे दिखें
            const Spacer(),

            // ---------- तीन फीचर कार्ड ----------
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  // मंडी भाव → TextQueryScreen
                  Expanded(
                    child: _FeatureCard(
                      icon: Icons.currency_rupee,
                      titleHi: 'मंडी भाव',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TextQueryScreen(
                              title: 'मंडी भाव',
                              hint: 'उदाहरण: सोलापुर में गेहूँ का भाव बताओ',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),

                  // मौसम → TextQueryScreen
                  Expanded(
                    child: _FeatureCard(
                      icon: Icons.cloud,
                      titleHi: 'मौसम',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TextQueryScreen(
                              title: 'मौसम',
                              hint: 'उदाहरण: आज मुंबई का मौसम कैसा रहेगा',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),

                  // पास की मंडी → NearbyMarketScreen
                  Expanded(
                    child: _FeatureCard(
                      icon: Icons.location_on,
                      titleHi: 'पास की मंडी',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const NearbyMarketScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}



class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String titleHi;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.icon,
    required this.titleHi,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const cardColor = Color(0xFF075D44);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 86,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 6),
            Text(
              titleHi,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// ------------------------------------------------------------
///  Voice query screen (ASR -> backend -> answer screen)
/// ------------------------------------------------------------

class VoiceQueryScreen extends StatefulWidget {
  const VoiceQueryScreen({super.key});

  @override
  State<VoiceQueryScreen> createState() => _VoiceQueryScreenState();
}

class _VoiceQueryScreenState extends State<VoiceQueryScreen> {
  final ApiService _api = ApiService();
  final AudioRecorder _recorder = AudioRecorder();

  bool _isRecording = false;
  bool _isProcessing = false;
  String? _status;
  String? _error;
  String? _tempPath; // temporary wav path

  /// Backend se safest question pick karne ke liye helper
  String _pickQuestion(Map<String, dynamic> resp) {
    final candidates = [
      'transcription',
      'Transcription',
      'text',
      'Text',
      'user_text',
      'userText',
      'query',
      'question',
      'input',
      'utterance',
    ];

    for (final key in candidates) {
      final val = resp[key];
      if (val != null && val.toString().trim().isNotEmpty) {
        return val.toString().trim();
      }
    }
    return 'Voice query';
  }

  /// Backend se safest answer pick karne ke liye helper
  String _pickAnswer(Map<String, dynamic> resp) {
    final candidates = [
      'final_reply',
      'finalReply',
      'reply_text',
      'replyText',
      'answer',
      'response',
      'reply',
      'bot_answer',
      'botAnswer',
      'bot_text',
      'botText',
    ];

    for (final key in candidates) {
      final val = resp[key];
      if (val != null && val.toString().trim().isNotEmpty) {
        return val.toString().trim();
      }
    }
    return 'जवाब प्राप्त हुआ।';
  }

  /// Mic tap par record start/stop
  Future<void> _toggleRecording() async {
    if (_isRecording) {
      // --------------- STOP & SEND ------------------
      final stopPath = await _recorder.stop();
      final path = stopPath ?? _tempPath;

      setState(() {
        _isRecording = false;
        _isProcessing = true;
        _status = 'आवाज़ प्रोसेस की जा रही है...';
        _error = null;
      });

      if (path == null) {
        setState(() {
          _isProcessing = false;
          _status = 'रिकॉर्डिंग नहीं मिली।';
        });
        return;
      }

      try {
        final bytes = await File(path).readAsBytes();
        final resp = await _api.sendVoiceQuery(bytes);

        // Debug ke liye print (terminal me dikhega)
        // ignore: avoid_print
        print('VOICE RESP MAP: $resp');
        // ignore: avoid_print
        print('VOICE RESP KEYS: ${resp.keys.toList()}');

        final question = _pickQuestion(resp);
        final answer = _pickAnswer(resp);

        await RecentStorage.addItem(question, answer);

        if (!mounted) return;
        setState(() {
          _isProcessing = false;
          _status = null;
        });

        // Nice answer screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AnswerDetailScreen(
              question: question,
              answer: answer,
            ),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _isProcessing = false;
          _error = e.toString();
        });
      }
    } else {
      // --------------- START RECORDING ---------------
      if (!await _recorder.hasPermission()) {
        setState(() {
          _status = 'कृपया माइक की permission दें।';
        });
        return;
      }

      final dir = await getTemporaryDirectory();
      final filePath =
          '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.wav';

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          bitRate: 128000,
        ),
        path: filePath,
      );

      setState(() {
        _isRecording = true;
        _status = 'रिकॉर्डिंग चालू है...';
        _isProcessing = false;
        _error = null;
        _tempPath = filePath;
      });
    }
  }

  @override
  void dispose() {
    _recorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFF0B7A5A);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text('आवाज़ से पूछें'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Text(
                'माइक को टैप करके अपना सवाल हिंदी में बोलें।\n'
                'दुबारा टैप करने पर रिकॉर्डिंग बंद होगी और जवाब दिखेगा।',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.white),
              ),
              const SizedBox(height: 32),
              InkWell(
                onTap: _isProcessing ? null : _toggleRecording,
                borderRadius: BorderRadius.circular(80),
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isRecording ? Colors.red : Colors.white,
                  ),
                  child: Icon(
                    Icons.mic,
                    size: 50,
                    color: _isRecording ? Colors.white : background,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_status != null)
                Text(
                  _status!,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              const SizedBox(height: 12),
              if (_isProcessing) const CircularProgressIndicator(),
              const SizedBox(height: 12),
              if (_error != null)
                Text(
                  'Error: $_error',
                  style: const TextStyle(color: Colors.redAccent),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ------------------------------------------------------------
///  Text-query screen (for मौसम / पास की मंडी only)
/// ------------------------------------------------------------

/// ------------------------------------------------------------
///  Text-query screen
///  - "मंडी भाव"  : city + crop dropdown  → query auto-build
///  - "मौसम"     : city name textbox     → "आज <city> का मौसम कैसा रहेगा"
///  - "पास की मंडी": free text (as before)
/// ------------------------------------------------------------

class TextQueryScreen extends StatefulWidget {
  final String title; // स्क्रीन का नाम (मंडी भाव / मौसम / पास की मंडी)
  final String hint;  // सिर्फ पास की मंडी वाले textbox के लिए

  const TextQueryScreen({
    super.key,
    required this.title,
    required this.hint,
  });

  @override
  State<TextQueryScreen> createState() => _TextQueryScreenState();
}

class _TextQueryScreenState extends State<TextQueryScreen> {
  final ApiService _api = ApiService();

  /// पास की मंडी वाले normal textbox के लिए
  final TextEditingController _freeTextController = TextEditingController();

  /// मौसम वाले स्क्रीन पर शहर का नाम
  final TextEditingController _cityController = TextEditingController();

  bool _isLoading = false;
  String? _error;

  // --- Mandi Bhav ke liye dropdown lists ---
  final List<String> _cities = const [
    'सोलापुर',
    'पुणे',
    'नागपुर',
    'नाशिक',
    'जलगांव',
    'अहमदनगर',
    'सातारा',
    'कोल्हापुर',
    'औरंगाबाद',
    'लातूर',
  ];

  final List<String> _crops = const [
    // 5 pulses
    'चना',
    'तूर दाल',
    'मूंग दाल',
    'मसूर दाल',
    'उड़द दाल',
    // 5 vegetables
    'टमाटर',
    'प्याज',
    'आलू',
    'भिंडी',
    'पत्ता गोभी',
  ];

  String? _selectedCity;
  String? _selectedCrop;

  bool get _isMandiScreen => widget.title == 'मंडी भाव';
  bool get _isWeatherScreen => widget.title == 'मौसम';

  @override
  void initState() {
    super.initState();
    if (_isMandiScreen) {
      // default selection so dropdown kabhi null na rahe
      _selectedCity = _cities.first;
      _selectedCrop = _crops.first;
    }
  }

  @override
  void dispose() {
    _freeTextController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    String text;

    if (_isMandiScreen) {
      // ---------- मंडी भाव : dropdown से query ----------
      if (_selectedCity == null || _selectedCrop == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('कृपया शहर और फसल चुनें।')),
        );
        return;
      }
      text = '${_selectedCity!} में $_selectedCrop का भाव बताओ';
    } else if (_isWeatherScreen) {
      // ---------- मौसम : सिर्फ शहर का नाम ----------
      final city = _cityController.text.trim();
      if (city.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('कृपया शहर का नाम लिखें।')),
        );
        return;
      }
      text = 'आज $city का मौसम कैसा रहेगा';
    } else {
      // ---------- पास की मंडी : free text ----------
      final typed = _freeTextController.text.trim();
      if (typed.isEmpty) return;
      text = typed;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final resp = await _api.sendTextQuery(text);
      final answer = resp['final_reply']?.toString() ??
          resp['reply_text']?.toString() ??
          'जवाब प्राप्त हुआ।';

      await RecentStorage.addItem(text, answer);

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AnswerDetailScreen(
            question: text,
            answer: answer,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFF0B7A5A);
    const cardColor = Color(0xFF075D44);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              if (_isMandiScreen) ...[
                // ---------- फसल dropdown ----------
                DropdownButtonFormField<String>(
                  initialValue: _selectedCrop,
                  items: _crops
                      .map(
                        (c) => DropdownMenuItem(
                          value: c,
                          child: Text(
                            c,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      )
                      .toList(),
                  dropdownColor: cardColor,
                  decoration: InputDecoration(
                    labelText: 'फसल चुनें',
                    labelStyle: const TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: cardColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (val) {
                    setState(() => _selectedCrop = val);
                  },
                ),
                const SizedBox(height: 16),

                // ---------- शहर (जिला) dropdown ----------
                DropdownButtonFormField<String>(
                  initialValue: _selectedCity,
                  items: _cities
                      .map(
                        (c) => DropdownMenuItem(
                          value: c,
                          child: Text(
                            c,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      )
                      .toList(),
                  dropdownColor: cardColor,
                  decoration: InputDecoration(
                    labelText: 'मंडी (जिला) चुनें',
                    labelStyle: const TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: cardColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (val) {
                    setState(() => _selectedCity = val);
                  },
                ),
              ] else if (_isWeatherScreen) ...[
                // ---------- मौसम : शहर का textbox ----------
                TextField(
                  controller: _cityController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'शहर का नाम लिखें',
                    labelStyle: const TextStyle(color: Colors.white70),
                    hintText: 'उदाहरण: पुणे / मुंबई / नाशिक',
                    hintStyle:
                        const TextStyle(color: Colors.white70, fontSize: 14),
                    filled: true,
                    fillColor: cardColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ] else ...[
                // ---------- पास की मंडी : free text ----------
                TextField(
                  controller: _freeTextController,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: widget.hint,
                    hintStyle:
                        const TextStyle(color: Colors.white70, fontSize: 14),
                    filled: true,
                    fillColor: cardColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _send,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade400,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'भेजें',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              if (_error != null)
                Text(
                  'Error: $_error',
                  style: const TextStyle(color: Colors.redAccent),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ------------------------------------------------------------
///  Answer detail screen
/// ------------------------------------------------------------

/// ------------------------------------------------------------
///  Answer detail screen  +  TTS (auto play + slower speed)
/// ------------------------------------------------------------

class AnswerDetailScreen extends StatefulWidget {
  final String question;
  final String answer;

  const AnswerDetailScreen({
    super.key,
    required this.question,
    required this.answer,
  });

  @override
  State<AnswerDetailScreen> createState() => _AnswerDetailScreenState();
}

class _AnswerDetailScreenState extends State<AnswerDetailScreen> {
  final FlutterTts _tts = FlutterTts();
  bool _isSpeaking = false;

  @override
  void initState() {
    super.initState();
    _initTtsAndSpeakOnce();
  }

  Future<void> _initTtsAndSpeakOnce() async {
    // Hindi language
    await _tts.setLanguage("hi-IN");

    // Normal pitch
    await _tts.setPitch(1.0);

    // 👇 Slow speech (0.3–0.5 is good; try 0.35)
    await _tts.setSpeechRate(0.35);

    // Optional handlers to update icon
    _tts.setStartHandler(() {
      setState(() => _isSpeaking = true);
    });
    _tts.setCompletionHandler(() {
      setState(() => _isSpeaking = false);
    });
    _tts.setErrorHandler((msg) {
      setState(() => _isSpeaking = false);
    });

    // Small delay so UI builds first, then auto-speak
    await Future.delayed(const Duration(milliseconds: 300));
    await _speakAnswer();
  }

  Future<void> _speakAnswer() async {
    final text = widget.answer.trim();
    if (text.isEmpty) return;

    await _tts.stop();      // stop old speech
    await _tts.speak(text); // speak new answer
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFF0B7A5A);
    const cardColor = Color(0xFF075D44);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text('जवाब'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'आपने पूछा:',
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.person, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.question,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'सहायक का जवाब:',
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.smart_toy, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.answer,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // 🔁 Button only for replay now
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _speakAnswer,
                  icon: Icon(
                    _isSpeaking ? Icons.volume_up : Icons.play_arrow,
                  ),
                  label: const Text('जवाब फिर से सुनें'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade400,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.arrow_back, color: Colors.white70),
                  label: const Text(
                    'नया सवाल पूछें',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


/// ------------------------------------------------------------
///  Recent responses list screen
/// ------------------------------------------------------------

class RecentResponsesScreen extends StatefulWidget {
  const RecentResponsesScreen({super.key});

  @override
  State<RecentResponsesScreen> createState() => _RecentResponsesScreenState();
}

class _RecentResponsesScreenState extends State<RecentResponsesScreen> {
  List<RecentItem> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await RecentStorage.getItems();
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFF0B7A5A);
    const cardColor = Color(0xFF075D44);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text('हाल के सवाल'),
        actions: [
          if (!_loading && _items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                await RecentStorage.clear();
                await _load();
              },
            ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _items.isEmpty
                ? const Center(
                    child: Text(
                      'अभी कोई पुराना सवाल नहीं है।',
                      style: TextStyle(color: Colors.white70),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return Card(
                        color: cardColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          title: Text(
                            item.question,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            '${item.timestamp}',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                            ),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AnswerDetailScreen(
                                  question: item.question,
                                  answer: item.answer,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
/// ------------------------------------------------------------
///  Nearby Market Screen
///  - Detect button: current location -> open Google Maps
///  - Manual city input: show list of 3 markets with map icon
///    (click -> open Google Maps for that market)
/// ------------------------------------------------------------

class _MarketItem {
  final String name;
  final String description;
  final String mapUrl;

  _MarketItem({
    required this.name,
    required this.description,
    required this.mapUrl,
  });
}

/// ------------------------------------------------------------
///  Nearby Market Screen
///  - Detect button: current location -> open Google Maps
///  - Manual city input: show list of nearby mandis with map icons
/// ------------------------------------------------------------
class NearbyMarketScreen extends StatefulWidget {
  const NearbyMarketScreen({super.key});

  @override
  State<NearbyMarketScreen> createState() => _NearbyMarketScreenState();
}

class _NearbyMarketScreenState extends State<NearbyMarketScreen> {
  final TextEditingController _placeController = TextEditingController();

  bool _isDetecting = false;
  bool _isSearching = false;
  String? _error;
  List<_MarketItem> _results = [];

  // ---------------- Permission helper ----------------
  Future<bool> _ensureLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('कृपया location permission allow करें।'),
          ),
        );
      }
      return false;
    }
    return true;
  }

  // ---------------- Detect button: open map directly ----------------
  Future<void> _detectAndOpenMaps() async {
    setState(() {
      _isDetecting = true;
      _error = null;
    });

    try {
      if (!await _ensureLocationPermission()) {
        setState(() => _isDetecting = false);
        return;
      }

      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('कृपया अपने फोन की location (GPS) चालू करें।'),
          ),
        );
        setState(() => _isDetecting = false);
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final lat = pos.latitude;
      final lng = pos.longitude;

      final uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent("mandi near $lat,$lng")}',
      );

      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isDetecting = false;
      });
    }
  }

  // ---------------- Manual search: list of markets ----------------
  Future<void> _searchByPlace() async {
    final place = _placeController.text.trim();
    if (place.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('कृपया कोई जगह / शहर का नाम लिखें।')),
      );
      return;
    }

    setState(() {
      _isSearching = true;
      _error = null;
      _results = [];
    });

    try {
      final encodedPlace = Uri.encodeComponent(place);

      final markets = <_MarketItem>[
        _MarketItem(
          name: '$place मुख्य सब्जी मंडी',
          description: '$place के पास मुख्य सब्जी मंडी (Google Maps पर देखें)',
          mapUrl:
              'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent("$place sabzi mandi")}',
        ),
        _MarketItem(
          name: '$place कृषि उपज मंडी',
          description: '$place के पास कृषि उपज मंडी',
          mapUrl:
              'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent("$place krishi upaj mandi")}',
        ),
        _MarketItem(
          name: '$place फल एवं सब्जी बाजार',
          description: '$place के पास फल-सब्जी मार्केट',
          mapUrl:
              'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent("$place vegetable market")}',
        ),
      ];

      setState(() {
        _results = markets;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  Future<void> _openMapUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  void dispose() {
    _placeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFF0B7A5A);
    const cardColor = Color(0xFF075D44);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text('पास की मंडी'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // ---------- Detect current location button ----------
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isDetecting ? null : _detectAndOpenMaps,
                  icon: const Icon(Icons.my_location),
                  label: Text(
                    _isDetecting
                        ? 'लोकेशन डिटेक्ट हो रही है...'
                        : 'मेरे पास की मंडी दिखाओ (मैप में)',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade400,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ---------- Manual input ----------
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'या शहर / जगह का नाम लिखें:',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ),
              const SizedBox(height: 8),

              TextField(
                controller: _placeController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'उदाहरण: पुणे, सोलापुर, कराड...',
                  hintStyle:
                      const TextStyle(color: Colors.white70, fontSize: 14),
                  filled: true,
                  fillColor: cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search, color: Colors.white70),
                    onPressed: _isSearching ? null : _searchByPlace,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Error: $_error',
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),

              // ---------- Results ----------
              Expanded(
                child: _isSearching
                    ? const Center(child: CircularProgressIndicator())
                    : _results.isEmpty
                        ? const Center(
                            child: Text(
                              'अभी कोई मंडी लिस्ट नहीं है। ऊपर से जगह लिखकर खोजें।',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _results.length,
                            itemBuilder: (context, index) {
                              final m = _results[index];
                              return Card(
                                color: cardColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: ListTile(
                                  leading: const Icon(
                                    Icons.store_mall_directory,
                                    color: Colors.white,
                                  ),
                                  title: Text(
                                    m.name,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  subtitle: Text(
                                    m.description,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(
                                      Icons.map,
                                      color: Colors.white,
                                    ),
                                    onPressed: () => _openMapUrl(m.mapUrl),
                                  ),
                                  onTap: () => _openMapUrl(m.mapUrl),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
