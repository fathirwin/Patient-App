class PatientData {
  final double age;
  final String sex; // 'M' or 'F'
  final double haematocrit;
  final double haemoglobins;
  final double erythrocyte;
  final double leucocyte;
  final double thrombocyte;
  final double mch;
  final double mchc;
  final double mcv;

  PatientData({
    required this.age,
    required this.sex,
    required this.haematocrit,
    required this.haemoglobins,
    required this.erythrocyte,
    required this.leucocyte,
    required this.thrombocyte,
    required this.mch,
    required this.mchc,
    required this.mcv,
  });

  Map<String, dynamic> toJson() => {
        'age': age,
        'sex': sex,
        'haematocrit': haematocrit,
        'haemoglobins': haemoglobins,
        'erythrocyte': erythrocyte,
        'leucocyte': leucocyte,
        'thrombocyte': thrombocyte,
        'mch': mch,
        'mchc': mchc,
        'mcv': mcv,
      };
}

class PredictionResult {
  final String label; // 'in' or 'out'
  final String labelText; // 'Rawat Inap' / 'Rawat Jalan'
  final double confidence; // 0-100
  final String modelUsed;

  PredictionResult({
    required this.label,
    required this.labelText,
    required this.confidence,
    required this.modelUsed,
  });

  factory PredictionResult.fromJson(Map<String, dynamic> json) {
    return PredictionResult(
      label: json['label'] as String,
      labelText: json['label_text'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      modelUsed: json['model_used'] as String,
    );
  }
}
