import 'package:flutter/material.dart';
import '../models/patient_data.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'result_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _FieldSpec {
  final String key;
  final String label;
  final String hint;
  const _FieldSpec(this.key, this.label, this.hint);
}

class _HomeScreenState extends State<HomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  String _sex = 'M';
  bool _loading = false;

  final List<_FieldSpec> _fields = const [
    _FieldSpec('age', 'Usia (tahun)', 'contoh: 45'),
    _FieldSpec('haematocrit', 'Haematocrit (%)', 'contoh: 40.0'),
    _FieldSpec('haemoglobins', 'Haemoglobins (g/dL)', 'contoh: 13.5'),
    _FieldSpec('erythrocyte', 'Erythrocyte (juta/µL)', 'contoh: 4.8'),
    _FieldSpec('leucocyte', 'Leucocyte (ribu/µL)', 'contoh: 7.5'),
    _FieldSpec('thrombocyte', 'Thrombocyte (ribu/µL)', 'contoh: 250'),
    _FieldSpec('mch', 'MCH (pg)', 'contoh: 29'),
    _FieldSpec('mchc', 'MCHC (g/dL)', 'contoh: 33'),
    _FieldSpec('mcv', 'MCV (fL)', 'contoh: 88'),
  ];

  @override
  void initState() {
    super.initState();
    for (final f in _fields) {
      _controllers[f.key] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final data = PatientData(
        age: double.parse(_controllers['age']!.text),
        sex: _sex,
        haematocrit: double.parse(_controllers['haematocrit']!.text),
        haemoglobins: double.parse(_controllers['haemoglobins']!.text),
        erythrocyte: double.parse(_controllers['erythrocyte']!.text),
        leucocyte: double.parse(_controllers['leucocyte']!.text),
        thrombocyte: double.parse(_controllers['thrombocyte']!.text),
        mch: double.parse(_controllers['mch']!.text),
        mchc: double.parse(_controllers['mchc']!.text),
        mcv: double.parse(_controllers['mcv']!.text),
      );

      final result = await ApiService.predict(data);

      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ResultScreen(result: result)),
      );
    } on ApiException catch (e) {
      _showError(e.toString());
    } catch (e) {
      _showError('Terjadi kesalahan tak terduga. Coba lagi.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.inap),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prediksi Perawatan Pasien'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              _headerCard(),
              const SizedBox(height: 20),
              _sectionLabel('Data Umum'),
              const SizedBox(height: 10),
              _buildTextField(_fields[0]),
              const SizedBox(height: 14),
              _buildSexDropdown(),
              const SizedBox(height: 20),
              _sectionLabel('Hasil Laboratorium'),
              const SizedBox(height: 10),
              for (final f in _fields.skip(1)) ...[
                _buildTextField(f),
                const SizedBox(height: 14),
              ],
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _submit,
                  icon: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : const Icon(Icons.search_rounded),
                  label: Text(_loading ? 'Memproses...' : 'Prediksi Sekarang'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(Icons.favorite_rounded, color: Colors.white, size: 32),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Isi data EHR pasien untuk memprediksi apakah pasien perlu Rawat Inap atau cukup Rawat Jalan.',
              style: TextStyle(color: Colors.white.withOpacity(0.95), fontSize: 13.5, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: AppColors.textDark,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildTextField(_FieldSpec f) {
    return TextFormField(
      controller: _controllers[f.key],
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: f.label,
        hintText: f.hint,
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Wajib diisi';
        }
        final parsed = double.tryParse(value);
        if (parsed == null) {
          return 'Masukkan angka yang valid';
        }
        if (parsed < 0) {
          return 'Nilai tidak boleh negatif';
        }
        return null;
      },
    );
  }

  Widget _buildSexDropdown() {
    return DropdownButtonFormField<String>(
      value: _sex,
      decoration: const InputDecoration(labelText: 'Jenis Kelamin'),
      items: const [
        DropdownMenuItem(value: 'M', child: Text('Laki-laki')),
        DropdownMenuItem(value: 'F', child: Text('Perempuan')),
      ],
      onChanged: (value) {
        if (value != null) setState(() => _sex = value);
      },
    );
  }
}
