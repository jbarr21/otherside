import 'dart:math';

import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapUtils {
  static final Random _random = Random();

  static final double _usNorth = 49.3457868;
  static final double _usSouth = 24.7433195;
  static final double _usWest = -124.7844079;
  static final double _usEast = -66.9513812;

  // Returns a LatLng for the center of the map's viewport
  static LatLng centerLatLng(GoogleMapController mapController) =>
      mapController.cameraPosition.target;

  // http://en.wikipedia.org/wiki/Extreme_points_of_the_United_States#Westernmost
  static LatLng randomUsLocation() => LatLng(
      _random.nextDouble() * (_usNorth - _usSouth) + _usSouth,
      _random.nextDouble() * (_usEast - _usWest) + _usWest);

  static LatLng antipode(LatLng loc) => LatLng(
      loc.latitude * -1, loc.longitude + 180.0 * (loc.longitude < 0 ? 1 : -1));
}
