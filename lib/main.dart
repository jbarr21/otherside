import 'dart:async';
import 'package:OtherSide/map_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mapbox_gl/controller.dart';
import 'package:mapbox_gl/flutter_mapbox.dart';
import 'package:mapbox_gl/overlay.dart';
import 'package:simple_permissions/simple_permissions.dart';
import 'dart:math';

const int ANIM_DURATION_FLY = 5000;
const double ZOOM = 5.0;

final LatLng SF_COORDS = LatLng(lat: 37.7752202, lng: -122.4194261);

void main() => runApp(OtherSideApp());

class OtherSideApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OtherSide',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: MapPage(title: 'OtherSide'),
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
  final MapboxOverlayController _controller = MapboxOverlayController();
  final Geolocator _geolocator = Geolocator();

  LatLng _loc = SF_COORDS;
  String _platformVersion = 'Unknown';
  MediaQueryData _mediaQueryData;

  Position _position;
  Offset _positionOffsetDp = Offset.zero;

  @override
  void initState() {
    super.initState();
    _initPermission();
    _initLocation();
  }

  Future<String> _initPermission() async {
    String platformVersion;
    try {
      platformVersion = await SimplePermissions.platformVersion;
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    if (!mounted) return Future.value(null);

    setState(() {
      _platformVersion = platformVersion;
    });

    return Future.value(platformVersion);
  }

  void _initLocation() async {
    await _initPermission();

    Permission fineLocPerm = Permission.AccessFineLocation;
    bool hasFineLocPerm = await SimplePermissions.checkPermission(fineLocPerm);
    if (!hasFineLocPerm) {
      hasFineLocPerm = await SimplePermissions.requestPermission(fineLocPerm);
    }

    if (!hasFineLocPerm) return;

    Position position =
        await _geolocator.getCurrentPosition(LocationAccuracy.high);

    if (!mounted) return;

    setState(() {
      _position = position;
    });
  }

  @override
  Widget build(BuildContext context) {
    _mediaQueryData = MediaQuery.of(context);
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
    return Listener(
      onPointerMove: (PointerMoveEvent event) async {
        if (_position != null) {
          Offset offsetDp = await MapUtils.offsetForLatLngDp(
              LatLng(lat: _position.latitude, lng: _position.longitude),
              _controller,
              _mediaQueryData);
          setState(() {
            _positionOffsetDp = offsetDp;
          });
        }
        LatLng loc = await MapUtils.centerLatLng(_controller, _mediaQueryData);
        setState(() {
          _loc = loc;
        });
      },
      child: MapboxOverlay(
        controller: _controller,
        options: MapboxMapOptions(
          style: Style.mapboxStreets,
          camera: CameraPosition(target: _loc, zoom: ZOOM),
        ),
      ),
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
                  "(${_loc.lat.toStringAsFixed(4)}, ${_loc.lng.toStringAsFixed(4)})",
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
    _moveToNewCameraPosition(MapUtils.antipode(
        await MapUtils.centerLatLng(_controller, _mediaQueryData)));
  }

  void _flyToMyLocation() {
    if (_position != null) {
      _moveToNewCameraPosition(
          LatLng(lat: _position.latitude, lng: _position.longitude));
    }
  }

  void _flyToRandomLocation() {
    _moveToNewCameraPosition(MapUtils.randomUsLocation());
  }

  void _moveToNewCameraPosition(LatLng loc, {double zoom = ZOOM}) {
    setState(() {
      _loc = loc;
      _controller.flyTo(
          CameraPosition(target: loc, zoom: ZOOM), ANIM_DURATION_FLY);
    });
  }
}
