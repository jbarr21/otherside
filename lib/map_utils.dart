import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mapbox_gl/controller.dart';

class MapUtils {
  static Random _random = Random();

  // Returns a LatLng for the center of the map's viewport
  static Future<LatLng> centerLatLng(
      MapboxOverlayController controller, MediaQueryData mediaQueryData) async {
    Offset center = mediaQueryData.size.center(Offset.zero);
    return await latLngForOffsetDp(center, controller, mediaQueryData);
  }

  // Returns an offset in DP for the given location
  static Future<Offset> offsetForLatLngDp(LatLng loc,
      MapboxOverlayController controller, MediaQueryData mediaQueryData) async {
    Offset offset = await controller.getOffsetForLatLng(loc);
    double scale =
        mediaQueryData != null ? 1 / mediaQueryData.devicePixelRatio : 1;
    return Future.value(offset.scale(scale, scale));
  }

  // Returns a LatLng for the given offset
  static Future<LatLng> latLngForOffsetDp(Offset offsetDp,
      MapboxOverlayController controller, MediaQueryData mediaQueryData) async {
    double scale = mediaQueryData != null ? mediaQueryData.devicePixelRatio : 1;
    Offset offsetPx = offsetDp.scale(scale, scale);
    return Future.value(await controller.getLatLngForOffset(offsetPx));
  }

  // http://en.wikipedia.org/wiki/Extreme_points_of_the_United_States#Westernmost
  static LatLng randomUsLocation() {
    double north = 49.3457868;
    double south = 24.7433195;
    double west = -124.7844079;
    double east = -66.9513812;
    return LatLng(
        lat: _random.nextDouble() * (north - south) + south,
        lng: _random.nextDouble() * (east - west) + west);
  }

  static LatLng antipode(LatLng loc) =>
      LatLng(lat: loc.lat * -1, lng: loc.lng + 180.0 * (loc.lng < 0 ? 1 : -1));
}
