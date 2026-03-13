// lib/mandi_bhav_screen.dart
import 'package:flutter/material.dart';

/// One mandi-price record (demo data)
class MandiRecord {
  final String cityKey;      // e.g. solapur
  final String districtHi;   // e.g. सोलापुर
  final String districtEn;   // e.g. Solapur
  final String commodityHi;  // e.g. गेहूँ
  final String commodityEn;  // e.g. Wheat
  final String category;     // दलहन / सब्जी
  final String unit;         // क्विंटल
  final int minPrice;
  final int maxPrice;
  final int avgPrice;
  final String dateHi;       // display date

  MandiRecord({
    required this.cityKey,
    required this.districtHi,
    required this.districtEn,
    required this.commodityHi,
    required this.commodityEn,
    required this.category,
    required this.unit,
    required this.minPrice,
    required this.maxPrice,
    required this.avgPrice,
    required this.dateHi,
  });
}

/// ---- 10 जिलों के नाम (Hi + En) ----
const List<String> _districtsHi = [
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

const List<String> _districtsEn = [
  'Solapur',
  'Pune',
  'Nagpur',
  'Nashik',
  'Jalgaon',
  'Ahmednagar',
  'Satara',
  'Kolhapur',
  'Aurangabad',
  'Latur',
];

/// 5 pulses + 5 vegetables – base prices (approx)
class _CropDef {
  final String hi;
  final String en;
  final String category; // दलहन / सब्जी
  final int base;
  const _CropDef({
    required this.hi,
    required this.en,
    required this.category,
    required this.base,
  });
}

const List<_CropDef> _pulses = [
  _CropDef(hi: 'चना',        en: 'Chickpea',   category: 'दलहन', base: 4400),
  _CropDef(hi: 'तूर दाल',     en: 'Tur Dal',    category: 'दलहन', base: 5200),
  _CropDef(hi: 'मूंग दाल',    en: 'Moong Dal',  category: 'दलहन', base: 6000),
  _CropDef(hi: 'मसूर दाल',    en: 'Masoor Dal', category: 'दलहन', base: 4800),
  _CropDef(hi: 'उड़द दाल',    en: 'Urad Dal',   category: 'दलहन', base: 5500),
];

const List<_CropDef> _vegetables = [
  _CropDef(hi: 'टमाटर',     en: 'Tomato',   category: 'सब्जी', base: 1600),
  _CropDef(hi: 'प्याज',     en: 'Onion',    category: 'सब्जी', base: 2000),
  _CropDef(hi: 'आलू',       en: 'Potato',   category: 'सब्जी', base: 1800),
  _CropDef(hi: 'भिंडी',     en: 'Bhindi',   category: 'सब्जी', base: 2600),
  _CropDef(hi: 'पत्ता गोभी', en: 'Cabbage', category: 'सब्जी', base: 1400),
];

/// Demo data – 10 जिलों × 10 फसलें = 100 entries (prices are synthetic)
final List<MandiRecord> kDemoMandiData = _buildDemoData();

List<MandiRecord> _buildDemoData() {
  final List<MandiRecord> out = [];
  const String dateHi = '26 Nov 2025';
  const String unit = 'क्विंटल';

  for (int i = 0; i < _districtsHi.length; i++) {
    final distHi = _districtsHi[i];
    final distEn = _districtsEn[i];
    final cityKey = distEn.toLowerCase();

    // Pulses
    for (int j = 0; j < _pulses.length; j++) {
      final c = _pulses[j];
      final min = c.base - 200 + i * 15;
      final max = c.base + 200 + i * 15;
      final avg = (min + max) ~/ 2;
      out.add(
        MandiRecord(
          cityKey: cityKey,
          districtHi: distHi,
          districtEn: distEn,
          commodityHi: c.hi,
          commodityEn: c.en,
          category: c.category,
          unit: unit,
          minPrice: min,
          maxPrice: max,
          avgPrice: avg,
          dateHi: dateHi,
        ),
      );
    }

    // Vegetables
    for (int j = 0; j < _vegetables.length; j++) {
      final c = _vegetables[j];
      final min = c.base - 150 + i * 10;
      final max = c.base + 150 + i * 10;
      final avg = (min + max) ~/ 2;
      out.add(
        MandiRecord(
          cityKey: cityKey,
          districtHi: distHi,
          districtEn: distEn,
          commodityHi: c.hi,
          commodityEn: c.en,
          category: c.category,
          unit: unit,
          minPrice: min,
          maxPrice: max,
          avgPrice: avg,
          dateHi: dateHi,
        ),
      );
    }
  }

  return out;
}

/// ------------------------------------------------------------
///  Mandi Bhav Screen (search + district dropdown + list)
/// ------------------------------------------------------------

class MandiBhavScreen extends StatefulWidget {
  const MandiBhavScreen({super.key});

  @override
  State<MandiBhavScreen> createState() => _MandiBhavScreenState();
}

class _MandiBhavScreenState extends State<MandiBhavScreen> {
  String? _selectedDistrictHi; // null = सभी मंडी
  String _searchText = '';

  List<MandiRecord> get _filteredRecords {
    return kDemoMandiData.where((r) {
      final matchesDistrict =
          _selectedDistrictHi == null || r.districtHi == _selectedDistrictHi;

      final q = _searchText.trim();
      if (q.isEmpty) return matchesDistrict;

      final qLower = q.toLowerCase();
      final matchesCrop = r.commodityHi.contains(q) ||
          r.commodityEn.toLowerCase().contains(qLower);

      return matchesDistrict && matchesCrop;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFF0B7A5A);
    const cardColor = Color(0xFF075D44);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text('मंडी भाव'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // ---- फसल सर्च बॉक्स ----
              TextField(
                onChanged: (value) {
                  setState(() {
                    _searchText = value;
                  });
                },
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'फसल का नाम डालें...',
                  hintStyle:
                      const TextStyle(color: Colors.white70, fontSize: 14),
                  prefixIcon: const Icon(Icons.search, color: Colors.white70),
                  filled: true,
                  fillColor: cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ---- मंडी (जिला) dropdown ----
              DropdownButtonFormField<String>(
                value: _selectedDistrictHi,
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text(
                      'सभी मंडी (Maharashtra)',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  ..._districtsHi.map(
                    (d) => DropdownMenuItem<String>(
                      value: d,
                      child: Text(
                        d,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
                dropdownColor: cardColor,
                iconEnabledColor: Colors.white,
                decoration: InputDecoration(
                  labelText: 'मंडी चुनें',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (val) {
                  setState(() {
                    _selectedDistrictHi = val;
                  });
                },
              ),
              const SizedBox(height: 16),

              // ---- List of cards ----
              Expanded(
                child: _filteredRecords.isEmpty
                    ? const Center(
                        child: Text(
                          'कोई डेटा नहीं मिला।\nफसल का नाम या मंडी बदलकर देखें।',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white70),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredRecords.length,
                        itemBuilder: (context, index) {
                          final rec = _filteredRecords[index];
                          return _MandiCard(record: rec);
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

/// Card widget ek mandi record dikhane ke liye
class _MandiCard extends StatelessWidget {
  final MandiRecord record;

  const _MandiCard({required this.record});

  @override
  Widget build(BuildContext context) {
    const cardColor = Color(0xFF075D44);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title line: गेहूँ (Wheat)
          Text(
            '${record.commodityHi} (${record.commodityEn})',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'न्यूनतम भाव: ₹${record.minPrice} / ${record.unit}',
            style: const TextStyle(color: Colors.white70),
          ),
          Text(
            'अधिकतम भाव: ₹${record.maxPrice} / ${record.unit}',
            style: const TextStyle(color: Colors.white70),
          ),
          Text(
            'औसत भाव: ₹${record.avgPrice} / ${record.unit}',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 4),
          Text(
            'मंडी: ${record.districtHi} (${record.districtEn})',
            style: const TextStyle(color: Colors.white70),
          ),
          Text(
            'तिथि: ${record.dateHi}',
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
