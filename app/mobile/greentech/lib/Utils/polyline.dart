import 'package:latlong2/latlong.dart';

List<LatLng> decodePolyline(String encoded, {int precision = 5}) {
  if (encoded.isEmpty) return const [];

  final factor = _pow10(precision);
  final points = <LatLng>[];

  var index = 0;
  var lat = 0;
  var lon = 0;

  while (index < encoded.length) {
    final latDelta = _decodeValue(encoded, index);
    if (latDelta == null) break;
    index = latDelta.nextIndex;
    lat += latDelta.value;

    final lonDelta = _decodeValue(encoded, index);
    if (lonDelta == null) break;
    index = lonDelta.nextIndex;
    lon += lonDelta.value;

    points.add(LatLng(lat / factor, lon / factor));
  }

  return points;
}

class _Decoded {
  const _Decoded(this.value, this.nextIndex);

  final int value;
  final int nextIndex;
}

_Decoded? _decodeValue(String encoded, int start) {
  var index = start;
  var shift = 0;
  var result = 0;
  int byte;

  do {
    if (index >= encoded.length) return null;
    byte = encoded.codeUnitAt(index++) - 63;
    result |= (byte & 0x1f) << shift;
    shift += 5;
  } while (byte >= 0x20);

  final value = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
  return _Decoded(value, index);
}

double _pow10(int exponent) {
  var value = 1.0;
  for (var i = 0; i < exponent; i++) {
    value *= 10;
  }
  return value;
}
