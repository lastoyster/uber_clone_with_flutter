import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:uber_clone/states/app_state.dart';

class MyHomePage extends StatefulWidget {
  final String title;

  const MyHomePage({Key? key, required this.title}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(body: MapWidget());
  }
}

class MapWidget extends StatefulWidget {
  @override
  _MapWidgetState createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return SafeArea(
      child: appState.initialPosition == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SpinKitRotatingCircle(
                    color: Colors.black,
                    size: 50.0,
                  ),
                  const SizedBox(height: 10),
                  Visibility(
                    visible: !appState.locationServiceActive,
                    child: const Text(
                      "Please enable location services!",
                      style: TextStyle(color: Colors.grey, fontSize: 18),
                    ),
                  ),
                ],
              ),
            )
          : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: appState.initialPosition!,
                    zoom: 10.0,
                  ),
                  onMapCreated: appState.onCreated,
                  myLocationEnabled: true,
                  mapType: MapType.normal,
                  compassEnabled: true,
                  markers: appState.markers,
                  onCameraMove: appState.onCameraMove,
                  polylines: appState.polyLines,
                ),
                _buildTextField(
                  controller: appState.locationController,
                  hint: "Pick up",
                  icon: Icons.location_on,
                  top: 50.0,
                ),
                _buildTextField(
                  controller: appState.destinationController,
                  hint: "Destination?",
                  icon: Icons.local_taxi,
                  top: 105.0,
                  onSubmitted: appState.sendRequest,
                ),
              ],
            ),
    );
  }

  // Helper method to build the TextFields
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required double top,
    void Function(String)? onSubmitted,
  }) {
    return Positioned(
      top: top,
      right: 15.0,
      left: 15.0,
      child: Container(
        height: 50.0,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(3.0),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey,
              offset: Offset(1.0, 5.0),
              blurRadius: 10,
              spreadRadius: 3,
            ),
          ],
        ),
        child: TextField(
          cursorColor: Colors.black,
          controller: controller,
          textInputAction: TextInputAction.go,
          onSubmitted: onSubmitted,
          decoration: InputDecoration(
            icon: Padding(
              padding: const EdgeInsets.only(left: 20, top: 5),
              child: Icon(
                icon,
                color: Colors.black,
              ),
            ),
            hintText: hint,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.only(left: 15.0, top: 16.0),
          ),
        ),
      ),
    );
  }
}

