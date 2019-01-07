import 'dart:async';
import 'dart:math';

import 'package:OtherSide/map_utils.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

const String APP_NAME = "OtherSide";
const int ANIM_DURATION_FLY = 5000;
const double ZOOM = 5.0;

const LatLng SF_COORDS = LatLng(37.7752202, -122.4194261);

void main() => runApp(OtherSideApp());

class OtherSideApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: APP_NAME,
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: MapPage(title: APP_NAME),
    );
  }
}

class MapPage extends StatefulWidget {
  MapPage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final Geolocator _geolocator = Geolocator();
  GoogleMapController _mapController;

  LatLng _loc = SF_COORDS;
  Position _position;
  Offset _positionOffsetDp = Offset.zero;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  void _initLocation() async {
    bool hasFineLocPerm = await _hasFineLocationPermission();
    if (!hasFineLocPerm) {
      hasFineLocPerm = await _requestFineLocationPermission();
      if (!hasFineLocPerm) return;
    }

    Position position =
        await _geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

    if (!mounted) return;

    setState(() {
      _position = position;
    });
  }

  Future<bool> _hasFineLocationPermission() async {
    PermissionStatus permission = await PermissionHandler().checkPermissionStatus(PermissionGroup.location);
    return Future.value(permission == PermissionStatus.granted);
  }

  Future<bool> _requestFineLocationPermission() async {
    await PermissionHandler().requestPermissions([PermissionGroup.location]);
    return _hasFineLocationPermission();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red,
      body: Stack(
        children: <Widget>[
          _buildMap(context),
          _buildInfoText(context),
          // _buildMyLocationDot(context),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(left: 32.0),
        child: _buildButtonBar(context),
      ),
    );
  }

  Widget _buildMap(BuildContext context) {
    return GoogleMap(
        onMapCreated: _onMapCreated,
        options: GoogleMapOptions(
          cameraPosition: CameraPosition(target: _loc, zoom: ZOOM),
          trackCameraPosition: true
        )
    );
  }

  Widget _buildMyLocationDot(BuildContext context) {
    double size = 16.0;
    return IgnorePointer(
        child: Container(
            margin: EdgeInsets.only(
              left: max(_positionOffsetDp.dx - size / 2.0, 0.0),
              top: max(_positionOffsetDp.dy - size / 2.0, 0.0),
            ),
            child: Container(
              width: size,
              height: size,
              decoration:
                  BoxDecoration(shape: BoxShape.circle, color: Colors.blue),
            )));
  }

  Widget _buildInfoText(BuildContext context) {
    TextStyle textStyle =
        Theme.of(context).textTheme.title.copyWith(color: Colors.black);
    String currentLoc = _position == null
        ? "Unknown"
        : "(${_position.latitude.toStringAsFixed(4)}, ${_position.longitude.toStringAsFixed(4)})";
    return IgnorePointer(
      child: Padding(
          padding: EdgeInsets.all(12.0).copyWith(bottom: 112.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text("Viewport loc:", style: textStyle),
              Text(
                  "(${_loc.latitude.toStringAsFixed(4)}, ${_loc.longitude.toStringAsFixed(4)})",
                  style: textStyle),
              Text("", style: textStyle),
              Text("Device loc:", style: textStyle),
              Text("$currentLoc", style: textStyle),
            ],
          )),
    );
  }

  Widget _buildButtonBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          FloatingActionButton(
            onPressed: _flyToMyLocation,
            tooltip: 'My Location',
            child: Icon(Icons.my_location),
          ),
          FloatingActionButton(
            onPressed: _flyToRandomLocation,
            tooltip: 'Random Location',
            child: Icon(Icons.casino),
          ),
          FloatingActionButton(
            onPressed: _flyToAntipodeLocation,
            tooltip: 'Flip to OtherSide',
            child: Icon(Icons.cached),
          ),
        ],
      ),
    );
  }

  void _flyToAntipodeLocation() async {
    _moveToNewCameraPosition(MapUtils.antipode(MapUtils.centerLatLng(_mapController)));
  }

  void _flyToMyLocation() {
    if (_position != null) {
      _moveToNewCameraPosition(LatLng(_position.latitude, _position.longitude));
    }
  }

  void _flyToRandomLocation() {
    _moveToNewCameraPosition(MapUtils.randomUsLocation());
  }

  void _moveToNewCameraPosition(LatLng loc, {double zoom = ZOOM}) {
    setState(() {
      _loc = loc;
      _mapController.animateCamera(CameraUpdate.newLatLngZoom(loc, ZOOM)); // set time to ANIM_DURATION_FLY
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    setState(() { _mapController = controller; });
  }
}
