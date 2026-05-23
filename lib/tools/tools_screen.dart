// lib/tools/tools_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Theme constants (matches the rest of the app)
// ─────────────────────────────────────────────────────────────────────────────

const _kPurple    = Color(0xFF6C63FF);
const _kBg        = Color(0xFFF4F4FB);
const _kDark      = Color(0xFF1A1A2E);
const _kSubtext   = Color(0xFF8888AA);
const _kCard      = Colors.white;
const _kDivider   = Color(0xFFEEEEF5);

// ═════════════════════════════════════════════════════════════════════════════
//  TOOLS SCREEN
// ═════════════════════════════════════════════════════════════════════════════

class ToolsScreen extends StatefulWidget {
  const ToolsScreen({Key? key}) : super(key: key);

  @override
  State<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen> {
  String? _selectedTool;

  static const _toolOptions = [
    _ToolOption('budget',   'Budget Calculator',   Icons.attach_money_rounded),
    _ToolOption('concrete', 'Concrete Calculator', Icons.foundation_rounded),
    _ToolOption('plaster',  'Plaster Calculator',  Icons.layers_rounded),
    _ToolOption('units',    'Unit Converter',       Icons.swap_horiz_rounded),
  ];

  Widget _buildToolView() {
    switch (_selectedTool) {
      case 'budget':   return const _BudgetCalculator();
      case 'concrete': return const _ConcreteCalculator();
      case 'plaster':  return const _PlasterCalculator();
      case 'units':    return const _UnitConverter();
      default:         return const _EmptyToolPlaceholder();
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _kBg,
        body: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Container(
              color: _kCard,
              padding: EdgeInsets.fromLTRB(20, topPad + 16, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Build Tools',
                    style: GoogleFonts.montserrat(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: _kDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Calculators & converters for your project',
                    style: GoogleFonts.montserrat(
                        fontSize: 12.5, color: _kSubtext),
                  ),
                  const SizedBox(height: 16),

                  // ── Tool selector dropdown ───────────────────────────────
                  Text(
                    'Please Select The Tool',
                    style: GoogleFonts.montserrat(
                        fontSize: 12, fontWeight: FontWeight.w600, color: _kDark),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: _selectedTool,
                    hint: Text(
                      'Select a tool...',
                      style: GoogleFonts.montserrat(
                          fontSize: 13.5, color: _kSubtext),
                    ),
                    items: _toolOptions
                        .map((t) => DropdownMenuItem(
                              value: t.key,
                              child: Row(
                                children: [
                                  Icon(t.icon, size: 16, color: _kPurple),
                                  const SizedBox(width: 8),
                                  Text(t.label,
                                      style: GoogleFonts.montserrat(
                                          fontSize: 13.5, color: _kDark)),
                                ],
                              ),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedTool = v),
                    style: GoogleFonts.montserrat(fontSize: 13.5, color: _kDark),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: _kBg,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: _kDivider),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: _kDivider),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: _kPurple, width: 1.5),
                      ),
                    ),
                    dropdownColor: _kCard,
                    borderRadius: BorderRadius.circular(12),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: _kSubtext),
                  ),
                ],
              ),
            ),

            // ── Tool content ─────────────────────────────────────────────
            Expanded(
              child: _buildToolView(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolOption {
  final String key;
  final String label;
  final IconData icon;
  const _ToolOption(this.key, this.label, this.icon);
}

class _EmptyToolPlaceholder extends StatelessWidget {
  const _EmptyToolPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.construction_rounded, size: 56, color: _kPurple.withOpacity(0.25)),
          const SizedBox(height: 14),
          Text(
            'Select a tool above to get started',
            style: GoogleFonts.montserrat(fontSize: 14, color: _kSubtext),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared UI helpers
// ─────────────────────────────────────────────────────────────────────────────

/// Wraps content in a white rounded card
class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x08000000), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: child,
    );
  }
}

/// Section title inside a card
class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Text(
        text,
        style: GoogleFonts.montserrat(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: _kDark,
        ),
      ),
    );
  }
}

/// Labelled text input field
class _Field extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final String? suffix;

  const _Field({
    required this.label,
    required this.hint,
    required this.controller,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.montserrat(
                fontSize: 12, fontWeight: FontWeight.w600, color: _kDark)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: GoogleFonts.montserrat(fontSize: 14, color: _kDark),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.montserrat(fontSize: 13, color: _kSubtext),
            suffixText: suffix,
            suffixStyle:
                GoogleFonts.montserrat(fontSize: 13, color: _kSubtext),
            filled: true,
            fillColor: _kBg,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _kDivider),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _kDivider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _kPurple, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

/// Dropdown selector
class _Dropdown<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _Dropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.montserrat(
                fontSize: 12, fontWeight: FontWeight.w600, color: _kDark)),
        const SizedBox(height: 6),
        DropdownButtonFormField<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          style: GoogleFonts.montserrat(fontSize: 13.5, color: _kDark),
          decoration: InputDecoration(
            filled: true,
            fillColor: _kBg,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _kDivider),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _kDivider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _kPurple, width: 1.5),
            ),
          ),
          dropdownColor: _kCard,
          borderRadius: BorderRadius.circular(12),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _kSubtext),
        ),
      ],
    );
  }
}

/// Calculate button
class _CalcButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;

  const _CalcButton({required this.onPressed, this.label = 'Calculate'});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _kPurple,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: Text(
          label,
          style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

/// Result row inside result card
class _ResultRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _ResultRow(this.label, this.value, {this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.montserrat(
                  fontSize: 13,
                  color: highlight ? _kDark : _kSubtext,
                  fontWeight:
                      highlight ? FontWeight.w600 : FontWeight.w500)),
          Text(value,
              style: GoogleFonts.montserrat(
                  fontSize: 13,
                  color: highlight ? _kPurple : _kDark,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

/// Divider inside result card
class _ResultDivider extends StatelessWidget {
  const _ResultDivider();

  @override
  Widget build(BuildContext context) =>
      const Divider(color: _kDivider, height: 16);
}

/// Result card with purple left border
class _ResultCard extends StatelessWidget {
  final String title;
  final List<Widget> rows;

  const _ResultCard({required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(16),
        border: const Border(left: BorderSide(color: _kPurple, width: 4)),
        boxShadow: const [
          BoxShadow(color: Color(0x08000000), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: _kPurple, size: 16),
                const SizedBox(width: 6),
                Text(title,
                    style: GoogleFonts.montserrat(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _kPurple)),
              ],
            ),
            const SizedBox(height: 10),
            ...rows,
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  1. BUDGET CALCULATOR
// ═════════════════════════════════════════════════════════════════════════════

class _BudgetCalculator extends StatefulWidget {
  const _BudgetCalculator();

  @override
  State<_BudgetCalculator> createState() => _BudgetCalculatorState();
}

class _BudgetCalculatorState extends State<_BudgetCalculator> {
  final _areaCtrl = TextEditingController();
  String _finishType = 'standard';

  static const _finishTypes = {
    'budget':       _FinishInfo('Budget Finishes',          30000),
    'standard':     _FinishInfo('Standard Finishes',        35000),
    'high_end_low': _FinishInfo('High-End Finishes (Low)',  40000),
    'high_end':     _FinishInfo('High-End Finishes',        50000),
  };

  Map<String, dynamic>? _result;
  String? _error;

  void _calculate() {
    FocusScope.of(context).unfocus();
    final area = double.tryParse(_areaCtrl.text.trim());
    if (area == null || area <= 0) {
      setState(() { _error = 'Enter a valid area greater than 0'; _result = null; });
      return;
    }
    final info = _finishTypes[_finishType]!;
    final total = area * info.price;
    setState(() {
      _error = null;
      _result = {
        'finish_name':    info.name,
        'area':           area,
        'price_per_sqm':  info.price,
        'total_cost':     total,
      };
    });
  }

  @override
  void dispose() {
    _areaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info banner
          _InfoBanner(
            icon: Icons.attach_money_rounded,
            text:
                'Estimate your project cost based on floor area and finish quality.',
          ),

          // Inputs
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionTitle('Project Details'),
                _Field(
                  label: 'Floor Area',
                  hint: 'e.g. 120',
                  controller: _areaCtrl,
                  suffix: 'm²',
                ),
                const SizedBox(height: 14),
                _Dropdown<String>(
                  label: 'Finish Type',
                  value: _finishType,
                  items: _finishTypes.entries
                      .map((e) => DropdownMenuItem(
                            value: e.key,
                            child: Text(e.value.name,
                                style: GoogleFonts.montserrat(fontSize: 13.5)),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _finishType = v!),
                ),
                const SizedBox(height: 6),
                // Price hint chips
                Wrap(
                  spacing: 8,
                  children: _finishTypes.entries.map((e) {
                    final sel = e.key == _finishType;
                    return Chip(
                      label: Text(
                        'KES ${(e.value.price / 1000).toStringAsFixed(0)}K/m²',
                        style: GoogleFonts.montserrat(
                            fontSize: 11,
                            color: sel ? Colors.white : _kSubtext,
                            fontWeight: FontWeight.w600),
                      ),
                      backgroundColor: sel ? _kPurple : _kDivider,
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                if (_error != null)
                  _ErrorBanner(_error!),
                _CalcButton(onPressed: _calculate, label: 'Estimate Budget'),
              ],
            ),
          ),

          // Results
          if (_result != null) ...[
            const SizedBox(height: 4),
            _ResultCard(
              title: 'Budget Estimate',
              rows: [
                _ResultRow('Finish Type', _result!['finish_name']),
                _ResultRow('Floor Area',
                    '${_result!['area'].toStringAsFixed(1)} m²'),
                _ResultRow('Rate / m²',
                    'KES ${_formatNum(_result!['price_per_sqm'].toDouble())}'),
                const _ResultDivider(),
                _ResultRow(
                  'Total Estimated Cost',
                  'KES ${_formatNum(_result!['total_cost'])}',
                  highlight: true,
                ),
              ],
            ),
            _FinishCompareCard(area: _result!['area']),
          ],
        ],
      ),
    );
  }
}

class _FinishInfo {
  final String name;
  final double price;
  const _FinishInfo(this.name, this.price);
}

/// Shows all finish types side by side for comparison
class _FinishCompareCard extends StatelessWidget {
  final double area;
  const _FinishCompareCard({required this.area});

  static const _finishTypes = {
    'Budget':          30000.0,
    'Standard':        35000.0,
    'High-End (Low)':  40000.0,
    'High-End':        50000.0,
  };

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('Comparison Table'),
          ..._finishTypes.entries.map((e) {
            final total = e.value * area;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Expanded(
                    child: Text(e.key,
                        style: GoogleFonts.montserrat(
                            fontSize: 12.5, color: _kSubtext)),
                  ),
                  Text('KES ${_formatNum(total)}',
                      style: GoogleFonts.montserrat(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _kDark)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  2. CONCRETE CALCULATOR
// ═════════════════════════════════════════════════════════════════════════════

class _ConcreteCalculator extends StatefulWidget {
  const _ConcreteCalculator();

  @override
  State<_ConcreteCalculator> createState() => _ConcreteCalculatorState();
}

class _ConcreteCalculatorState extends State<_ConcreteCalculator> {
  bool _useVolume = false;

  final _lengthCtrl  = TextEditingController();
  final _widthCtrl   = TextEditingController();
  final _depthCtrl   = TextEditingController();
  final _volumeCtrl  = TextEditingController();

  String _concClass   = 'class_20';
  double _safetyFactor = 1.3;

  static const _classes = {
    'class_15': _MixInfo('Class 15 (1:3:6)', 1, 3, 6),
    'class_20': _MixInfo('Class 20 (1:2:4)', 1, 2, 4),
    'class_25': _MixInfo('Class 25 (1:1.5:3)', 1, 1.5, 3),
    'class_30': _MixInfo('Class 30 (1:1:2)', 1, 1, 2),
  };

  // kg/m³
  static const _densityCement  = 1440.0;
  static const _densitySand    = 1600.0;
  static const _densityBallast = 1520.0;

  Map<String, dynamic>? _result;
  String? _error;

  void _calculate() {
    FocusScope.of(context).unfocus();
    double volume;

    if (_useVolume) {
      final v = double.tryParse(_volumeCtrl.text.trim());
      if (v == null || v <= 0) {
        setState(() { _error = 'Enter a valid volume > 0'; _result = null; });
        return;
      }
      volume = v;
    } else {
      final l = double.tryParse(_lengthCtrl.text.trim());
      final w = double.tryParse(_widthCtrl.text.trim());
      final d = double.tryParse(_depthCtrl.text.trim());
      if (l == null || w == null || d == null || l <= 0 || w <= 0 || d <= 0) {
        setState(() { _error = 'Enter valid dimensions > 0'; _result = null; });
        return;
      }
      volume = l * w * d;
    }

    final mix = _classes[_concClass]!;
    final adjVol = volume * _safetyFactor;
    final totalParts = mix.cement + mix.sand + mix.ballast;

    final cVol = (mix.cement / totalParts) * adjVol;
    final sVol = (mix.sand   / totalParts) * adjVol;
    final bVol = (mix.ballast / totalParts) * adjVol;

    final cKg  = cVol * _densityCement;
    final sKg  = sVol * _densitySand;
    final bKg  = bVol * _densityBallast;

    setState(() {
      _error = null;
      _result = {
        'class_name':       mix.name,
        'volume':           volume,
        'adj_volume':       adjVol,
        'safety_factor':    _safetyFactor,
        'cement_bags':      cKg / 50,
        'cement_kg':        cKg,
        'sand_tonnes':      sKg / 1000,
        'ballast_tonnes':   bKg / 1000,
        'sand_m3':          sVol,
        'ballast_m3':       bVol,
      };
    });
  }

  @override
  void dispose() {
    _lengthCtrl.dispose();
    _widthCtrl.dispose();
    _depthCtrl.dispose();
    _volumeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      child: Column(
        children: [
          _InfoBanner(
            icon: Icons.foundation_rounded,
            text: 'Calculates cement bags, sand & ballast for your concrete mix.',
          ),

          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionTitle('Volume Input'),
                // Toggle: dimensions vs direct volume
                Row(
                  children: [
                    _ToggleChip(
                      label: 'From Dimensions',
                      selected: !_useVolume,
                      onTap: () => setState(() => _useVolume = false),
                    ),
                    const SizedBox(width: 8),
                    _ToggleChip(
                      label: 'Enter Volume',
                      selected: _useVolume,
                      onTap: () => setState(() => _useVolume = true),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (!_useVolume) ...[
                  Row(children: [
                    Expanded(child: _Field(label: 'Length', hint: 'e.g. 5', controller: _lengthCtrl, suffix: 'm')),
                    const SizedBox(width: 10),
                    Expanded(child: _Field(label: 'Width', hint: 'e.g. 4', controller: _widthCtrl, suffix: 'm')),
                    const SizedBox(width: 10),
                    Expanded(child: _Field(label: 'Depth', hint: 'e.g. 0.15', controller: _depthCtrl, suffix: 'm')),
                  ]),
                ] else ...[
                  _Field(label: 'Volume', hint: 'e.g. 3.0', controller: _volumeCtrl, suffix: 'm³'),
                ],
              ],
            ),
          ),

          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionTitle('Mix Settings'),
                _Dropdown<String>(
                  label: 'Concrete Class',
                  value: _concClass,
                  items: _classes.entries
                      .map((e) => DropdownMenuItem(
                            value: e.key,
                            child: Text(e.value.name,
                                style: GoogleFonts.montserrat(fontSize: 13.5)),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _concClass = v!),
                ),
                const SizedBox(height: 14),
                Text('Safety / Shrinkage Factor: ${_safetyFactor.toStringAsFixed(2)}',
                    style: GoogleFonts.montserrat(
                        fontSize: 12, fontWeight: FontWeight.w600, color: _kDark)),
                Slider(
                  value: _safetyFactor,
                  min: 1.0,
                  max: 1.5,
                  divisions: 10,
                  activeColor: _kPurple,
                  inactiveColor: _kDivider,
                  label: _safetyFactor.toStringAsFixed(2),
                  onChanged: (v) => setState(() => _safetyFactor = v),
                ),
                const SizedBox(height: 6),
                if (_error != null) _ErrorBanner(_error!),
                _CalcButton(onPressed: _calculate),
              ],
            ),
          ),

          if (_result != null) ...[
            _ResultCard(
              title: '${_result!['class_name']} Results',
              rows: [
                _ResultRow('Original Volume',
                    '${_result!['volume'].toStringAsFixed(3)} m³'),
                _ResultRow('Adjusted Volume (×${_result!['safety_factor'].toStringAsFixed(2)})',
                    '${_result!['adj_volume'].toStringAsFixed(3)} m³'),
                const _ResultDivider(),
                _ResultRow('Cement',
                    '${_result!['cement_bags'].toStringAsFixed(1)} bags (50 kg)',
                    highlight: true),
                _ResultRow('Cement Weight',
                    '${_result!['cement_kg'].toStringAsFixed(1)} kg'),
                const _ResultDivider(),
                _ResultRow('Sand',
                    '${_result!['sand_m3'].toStringAsFixed(3)} m³',
                    highlight: true),
                _ResultRow('Sand Weight',
                    '${(_result!['sand_tonnes'] * 1000).toStringAsFixed(1)} kg  (${_result!['sand_tonnes'].toStringAsFixed(3)} t)'),
                const _ResultDivider(),
                _ResultRow('Ballast',
                    '${_result!['ballast_m3'].toStringAsFixed(3)} m³',
                    highlight: true),
                _ResultRow('Ballast Weight',
                    '${(_result!['ballast_tonnes'] * 1000).toStringAsFixed(1)} kg  (${_result!['ballast_tonnes'].toStringAsFixed(3)} t)'),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _MixInfo {
  final String name;
  final double cement, sand, ballast;
  const _MixInfo(this.name, this.cement, this.sand, this.ballast);
}

// ═════════════════════════════════════════════════════════════════════════════
//  3. PLASTER CALCULATOR
// ═════════════════════════════════════════════════════════════════════════════

class _PlasterCalculator extends StatefulWidget {
  const _PlasterCalculator();

  @override
  State<_PlasterCalculator> createState() => _PlasterCalculatorState();
}

class _PlasterCalculatorState extends State<_PlasterCalculator> {
  final _areaCtrl      = TextEditingController();
  final _thicknessCtrl = TextEditingController(text: '15');
  String _mixType = 'standard';

  static const _mixes = {
    'standard':   _PlasterMix('Standard (1:4)',   1, 4),
    'structural': _PlasterMix('Structural (1:3)', 1, 3),
  };

  static const _densityCement = 1440.0;
  static const _densitySand   = 1600.0;

  Map<String, dynamic>? _result;
  String? _error;

  void _calculate() {
    FocusScope.of(context).unfocus();
    final area      = double.tryParse(_areaCtrl.text.trim());
    final thickMm   = double.tryParse(_thicknessCtrl.text.trim());

    if (area == null || area <= 0) {
      setState(() { _error = 'Enter a valid area > 0'; _result = null; }); return;
    }
    if (thickMm == null || thickMm <= 0) {
      setState(() { _error = 'Enter a valid thickness > 0'; _result = null; }); return;
    }

    final thickness = thickMm / 1000; // mm → m
    final volume = area * thickness;

    final mix = _mixes[_mixType]!;
    final totalParts = mix.cement + mix.sand;

    final cVol = (mix.cement / totalParts) * volume;
    final sVol = (mix.sand   / totalParts) * volume;

    final cKg  = cVol * _densityCement;
    final sKg  = sVol * _densitySand;

    setState(() {
      _error = null;
      _result = {
        'mix_name':    mix.name,
        'area':        area,
        'thickness_mm': thickMm,
        'volume':      volume,
        'cement_bags': cKg / 50,
        'cement_kg':   cKg,
        'sand_m3':     sVol,
        'sand_kg':     sKg,
        'sand_tonnes': sKg / 1000,
      };
    });
  }

  @override
  void dispose() {
    _areaCtrl.dispose();
    _thicknessCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      child: Column(
        children: [
          _InfoBanner(
            icon: Icons.layers_rounded,
            text: 'Calculate cement and sand needed for plastering walls or slabs.',
          ),

          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionTitle('Wall / Surface Details'),
                _Field(label: 'Surface Area', hint: 'e.g. 80', controller: _areaCtrl, suffix: 'm²'),
                const SizedBox(height: 14),
                _Field(label: 'Plaster Thickness', hint: 'e.g. 15', controller: _thicknessCtrl, suffix: 'mm'),
                const SizedBox(height: 14),
                _Dropdown<String>(
                  label: 'Mix Type',
                  value: _mixType,
                  items: _mixes.entries
                      .map((e) => DropdownMenuItem(
                            value: e.key,
                            child: Text(e.value.name,
                                style: GoogleFonts.montserrat(fontSize: 13.5)),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _mixType = v!),
                ),
                const SizedBox(height: 16),
                if (_error != null) _ErrorBanner(_error!),
                _CalcButton(onPressed: _calculate),
              ],
            ),
          ),

          if (_result != null) ...[
            _ResultCard(
              title: '${_result!['mix_name']} Results',
              rows: [
                _ResultRow('Surface Area', '${_result!['area'].toStringAsFixed(1)} m²'),
                _ResultRow('Thickness', '${_result!['thickness_mm'].toStringAsFixed(0)} mm'),
                _ResultRow('Plaster Volume', '${_result!['volume'].toStringAsFixed(4)} m³'),
                const _ResultDivider(),
                _ResultRow('Cement', '${_result!['cement_bags'].toStringAsFixed(1)} bags (50 kg)', highlight: true),
                _ResultRow('Cement Weight', '${_result!['cement_kg'].toStringAsFixed(1)} kg'),
                const _ResultDivider(),
                _ResultRow('Sand', '${_result!['sand_m3'].toStringAsFixed(4)} m³', highlight: true),
                _ResultRow('Sand Weight', '${_result!['sand_kg'].toStringAsFixed(1)} kg  (${_result!['sand_tonnes'].toStringAsFixed(3)} t)'),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _PlasterMix {
  final String name;
  final double cement, sand;
  const _PlasterMix(this.name, this.cement, this.sand);
}

// ═════════════════════════════════════════════════════════════════════════════
//  4. UNIT CONVERTER
// ═════════════════════════════════════════════════════════════════════════════

class _UnitConverter extends StatefulWidget {
  const _UnitConverter();

  @override
  State<_UnitConverter> createState() => _UnitConverterState();
}

class _UnitConverterState extends State<_UnitConverter> {
  bool _isLength = true;
  final _valueCtrl = TextEditingController();

  // Length units → factor to meters
  static const _lengthUnits = {
    'mm':   0.001,
    'cm':   0.01,
    'm':    1.0,
    'km':   1000.0,
    'in':   0.0254,
    'ft':   0.3048,
    'yd':   0.9144,
    'mile': 1609.34,
  };

  // Area units → factor to m²
  static const _areaUnits = {
    'mm²':    0.000001,
    'cm²':    0.0001,
    'm²':     1.0,
    'km²':    1000000.0,
    'in²':    0.00064516,
    'ft²':    0.092903,
    'yd²':    0.836127,
    'acre':   4046.86,
    'hectare':10000.0,
  };

  String _fromUnit = 'ft';
  String _toUnit   = 'm';

  Map<String, String>? _result;
  String? _error;

  Map<String, double> get _units => _isLength
      ? Map.from(_lengthUnits)
      : Map.from(_areaUnits);

  void _onTypeSwitch(bool isLength) {
    setState(() {
      _isLength = isLength;
      _fromUnit = isLength ? 'ft'  : 'ft²';
      _toUnit   = isLength ? 'm'   : 'm²';
      _result   = null;
      _error    = null;
    });
  }

  void _convert() {
    FocusScope.of(context).unfocus();
    final val = double.tryParse(_valueCtrl.text.trim());
    if (val == null) {
      setState(() { _error = 'Enter a valid number'; _result = null; }); return;
    }
    final units = _units;
    final base   = val * units[_fromUnit]!;
    final result = base / units[_toUnit]!;

    setState(() {
      _error = null;
      _result = {
        'from': '$val $_fromUnit',
        'to':   '${_smartFormat(result)} $_toUnit',
      };
    });
  }

  /// Format result: show up to 8 significant figures, strip trailing zeros
  String _smartFormat(double v) {
    if (v == 0) return '0';
    if (v.abs() >= 1e7 || (v.abs() < 0.0001 && v != 0)) {
      return v.toStringAsExponential(4);
    }
    return double.parse(v.toStringAsFixed(8)).toString();
  }

  @override
  void dispose() {
    _valueCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unitKeys = _units.keys.toList();

    // Ensure selected units are valid after switch
    if (!unitKeys.contains(_fromUnit)) _fromUnit = unitKeys.first;
    if (!unitKeys.contains(_toUnit))   _toUnit   = unitKeys[1];

    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      child: Column(
        children: [
          _InfoBanner(
            icon: Icons.swap_horiz_rounded,
            text: 'Convert construction lengths and areas between any units.',
          ),

          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionTitle('Conversion Type'),
                Row(
                  children: [
                    _ToggleChip(
                      label: 'Length',
                      selected: _isLength,
                      onTap: () => _onTypeSwitch(true),
                    ),
                    const SizedBox(width: 8),
                    _ToggleChip(
                      label: 'Area',
                      selected: !_isLength,
                      onTap: () => _onTypeSwitch(false),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _Field(
                  label: 'Value',
                  hint: 'e.g. 10',
                  controller: _valueCtrl,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _Dropdown<String>(
                        label: 'From',
                        value: _fromUnit,
                        items: unitKeys
                            .map((u) => DropdownMenuItem(
                                  value: u,
                                  child: Text(u,
                                      style: GoogleFonts.montserrat(
                                          fontSize: 13.5)),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => _fromUnit = v!),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 20, 10, 0),
                      child: GestureDetector(
                        onTap: () =>
                            setState(() {
                              final tmp = _fromUnit;
                              _fromUnit = _toUnit;
                              _toUnit   = tmp;
                            }),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _kPurple.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.swap_horiz_rounded,
                              color: _kPurple, size: 20),
                        ),
                      ),
                    ),
                    Expanded(
                      child: _Dropdown<String>(
                        label: 'To',
                        value: _toUnit,
                        items: unitKeys
                            .map((u) => DropdownMenuItem(
                                  value: u,
                                  child: Text(u,
                                      style: GoogleFonts.montserrat(
                                          fontSize: 13.5)),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => _toUnit = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_error != null) _ErrorBanner(_error!),
                _CalcButton(onPressed: _convert, label: 'Convert'),
              ],
            ),
          ),

          if (_result != null) ...[
            _ResultCard(
              title: 'Conversion Result',
              rows: [
                _ResultRow('Input',  _result!['from']!),
                const _ResultDivider(),
                _ResultRow('Result', _result!['to']!, highlight: true),
              ],
            ),
            // Quick reference table
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionTitle('Quick Reference'),
                  ...[1.0, 5.0, 10.0, 50.0, 100.0].map((v) {
                    final base   = v * _units[_fromUnit]!;
                    final conv   = base / _units[_toUnit]!;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('$v $_fromUnit',
                              style: GoogleFonts.montserrat(
                                  fontSize: 12.5, color: _kSubtext)),
                          Text('${_smartFormat(conv)} $_toUnit',
                              style: GoogleFonts.montserrat(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: _kDark)),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  Shared small widgets
// ═════════════════════════════════════════════════════════════════════════════

class _InfoBanner extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoBanner({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kPurple.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kPurple.withOpacity(0.18)),
      ),
      child: Row(
        children: [
          Icon(icon, color: _kPurple, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: GoogleFonts.montserrat(
                    fontSize: 12.5,
                    color: _kPurple,
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner(this.message);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: Colors.red.shade400, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: GoogleFonts.montserrat(
                    fontSize: 12.5, color: Colors.red.shade600)),
          ),
        ],
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ToggleChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _kPurple : _kDivider,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : _kSubtext,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Utility
// ─────────────────────────────────────────────────────────────────────────────

String _formatNum(double v) {
  // Format with commas, 2 decimal places
  final parts = v.toStringAsFixed(2).split('.');
  final intPart = parts[0];
  final decPart = parts[1];
  final buffer  = StringBuffer();
  int count = 0;
  for (int i = intPart.length - 1; i >= 0; i--) {
    buffer.write(intPart[i]);
    count++;
    if (count % 3 == 0 && i != 0) buffer.write(',');
  }
  return '${buffer.toString().split('').reversed.join()}.$decPart';
}
