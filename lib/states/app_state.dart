import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uber_clone/requests/google_maps_requests.dart';

class AppState with ChangeNotifier {
  LatLng? _initialPosition;
  LatLng _lastPosition = const LatLng(0.0, 0.0);
  bool locationServiceActive = true;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polyLines = {};
  GoogleMapController? _mapController;
  final GoogleMapsServices _googleMapsServices = GoogleMapsServices();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController destinationController = TextEditingController();

  LatLng? get initialPosition => _initialPosition;
  LatLng get lastPosition => _lastPosition;
  GoogleMapsServices get googleMapsServices => _googleMapsServices;
  GoogleMapController? get mapController => _mapController;
  Set<Marker> get markers => _markers;
  Set<Polyline> get polyLines => _polyLines;

  AppState() {
    _getUserLocation();
    _loadingInitialPosition();
  }

  // Get the user's location
  Future<void> _getUserLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      List<Placemark> placemarks = await Geolocator.placemarkFromCoordinates(
          position.latitude, position.longitude);
      _initialPosition = LatLng(position.latitude, position.longitude);
      locationController.text = placemarks.first.name ?? '';
      notifyListeners();
    } catch (e) {
      print("Error fetching user location: $e");
    }
  }

  // Create route
  void createRoute(String encodedPoly) {
    _polyLines.add(Polyline(
      polylineId: PolylineId(_lastPosition.toString()),
      width: 10,
      points: _convertToLatLng(_decodePoly(encodedPoly)),
      color: Colors.black,
    ));
    notifyListeners();
  }

  // Add a marker on the map
  void _addMarker(LatLng location, String address) {
    _markers.add(Marker(
      markerId: MarkerId(location.toString()),
      position: location,
      infoWindow: InfoWindow(title: address, snippet: "Go here"),
      icon: BitmapDescriptor.defaultMarker,
    ));
    notifyListeners();
  }

  // Convert to LatLng list
  List<LatLng> _convertToLatLng(List points) {
    List<LatLng> result = [];
    for (int i = 0; i < points.length; i++) {
      if (i % 2 != 0) {
        result.add(LatLng(points[i - 1], points[i]));
      }
    }
    return result;
  }

  // Decode polyline
  List _decodePoly(String poly) {
    var list = poly.codeUnits;
    var lList = <double>[];
    int index = 0;
    int len = poly.length;
    int c = 0;

    // Decoding attributes
    do {
      int shift = 0;
      int result = 0;

      // Decode one attribute
      do {
        c = list[index] - 63;
        result |= (c & 0x1F) << (shift * 5);
        index++;
        shift++;
      } while (c >= 32);

      // Check if negative
      if (result & 1 == 1) {
        result = ~result;
      }
      double result1 = (result >> 1) * 0.00001;
      lList.add(result1);
    } while (index < len);

    // Add to previous value
    for (var i = 2; i < lList.length; i++) lList[i] += lList[i - 2];

    return lList;
  }

  // Send request to fetch route
  Future<void> sendRequest(String intendedLocation) async {
    try {
      List<Placemark> placemarks =
          await Geolocator.placemarkFromAddress(intendedLocation);
      LatLng destination = LatLng(
          placemarks.first.position.latitude, placemarks.first.position.longitude);
      _addMarker(destination, intendedLocation);
      String route = await _googleMapsServices.getRouteCoordinates(
          _initialPosition!, destination);
      createRoute(route);
    } catch (e) {
      print("Error sending request: $e");
    }
  }

  // Handle camera movement
  void onCameraMove(CameraPosition position) {
    _lastPosition = position.target;
    notifyListeners();
  }

  // Initialize map controller
  void onCreated(GoogleMapController controller) {
    _mapController = controller;
    notifyListeners();
  }

  // Loading initial position
  Future<void> _loadingInitialPosition() async {
    await Future.delayed(const Duration(seconds: 5)).then((_) {
      if (_initialPosition == null) {
        locationServiceActive = false;
        notifyListeners();
      }
    });
  }
}
