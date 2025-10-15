// lib/models/daily_totals.dart
class DailyTotals {
  final int fajr, dhuhr, asr, maghrib, isha;

  const DailyTotals({
    required this.fajr,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
  });

  int get sum => fajr + dhuhr + asr + maghrib + isha;

  DailyTotals copyWith({
    int? fajr,
    int? dhuhr,
    int? asr,
    int? maghrib,
    int? isha,
  }) {
    return DailyTotals(
      fajr: fajr ?? this.fajr,
      dhuhr: dhuhr ?? this.dhuhr,
      asr: asr ?? this.asr,
      maghrib: maghrib ?? this.maghrib,
      isha: isha ?? this.isha,
    );
  }

  Map<String, int> toMap() => {
        'fajr': fajr,
        'dhuhr': dhuhr,
        'asr': asr,
        'maghrib': maghrib,
        'isha': isha,
      };

  factory DailyTotals.fromMap(Map<String, dynamic> m) => DailyTotals(
        fajr: (m['fajr'] as int?) ?? 0,
        dhuhr: (m['dhuhr'] as int?) ?? 0,
        asr: (m['asr'] as int?) ?? 0,
        maghrib: (m['maghrib'] as int?) ?? 0,
        isha: (m['isha'] as int?) ?? 0,
      );
}