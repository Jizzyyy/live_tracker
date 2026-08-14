String formatDuration(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return h > 0 ? '$h:$m:$s' : '$m:$s';
}

String formatDistance(double km) {
  if (km < 1) return '${(km * 1000).round()} M';
  return '${km.toStringAsFixed(1)} KM';
}

String formatSpeed(double kmh) => kmh.toStringAsFixed(1);
