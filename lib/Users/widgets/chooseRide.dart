import 'dart:convert';

import 'package:clay_containers/clay_containers.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:osmflutter/Services/reservation.dart';
import 'package:osmflutter/Users/widgets/routeCrad.dart';
import 'package:osmflutter/constant/colorsFile.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

class ChooseRide extends StatefulWidget {
  final Function() showMyRides;
  final Function() ridesVisible;
  final Function(Map) updateSelectedRouteCardInfo;
  final Function() selectMap;
  Set<Polyline>? _polyline;
  Set<Marker>? _markers;
  final Function() isSearch;
  Marker? pickMarker;
  dynamic selectedDate;
  String routeType;
  // final Function() getSchedule;
  List<dynamic> listSchedules;
  List<dynamic> listRoutes;

  ChooseRide(
      this.showMyRides,
      this.ridesVisible,
      this.updateSelectedRouteCardInfo,
      this.selectMap,
      this._polyline,
      this._markers,
      this.isSearch,
      this.pickMarker,
      this.selectedDate,
      this.routeType,
      // this.getSchedule,
      this.listSchedules,
      this.listRoutes,
      {Key? key})
      : super(key: key);

  @override
  _ChooseRideState createState() => _ChooseRideState();
}

class _ChooseRideState extends State<ChooseRide> {
  late double _height;
  late double _width;
  bool bottomSheetVisible = true;
  bool isCardSelected = false;
  int selectedIndexRoute = -1;
  List<LatLng> routeCoords = [];

  dynamic position1_lat, position1_lng;
  dynamic currentPosition_lat, currentPosition_lng;
  dynamic position2_lat = 36.85135579846211, position2_lng = 10.179065957033673;
  List<Color> containerColors = List.filled(
      4, colorsFile.cardColor); // Use the background color as the default color

  // List<dynamic> schedules = [];
  int selectedRouteCardIndex = 0;
  void toggleSelection(int index) async {
    final prefs = await SharedPreferences.getInstance();

    prefs.remove("markerLat");
    prefs.remove("markerLng");
    if (selectedIndexRoute == index) {
      // Toggle the selection state if the card is tapped again
      setState(() {
        selectedIndexRoute = -1;
        isCardSelected = !isCardSelected;
      });
      // Reset card color to default when the second tab is selected
    } else {
      setState(() {
        widget.ridesVisible();
        selectedIndexRoute = index;
        isCardSelected = true;
      });
      // If it's a new selection, update the selected index and set the selection state to true

      drawRoute();
    }
  }

  Map<String, dynamic> polylineToMap(Polyline polyline) {
    return {
      'polylineId': polyline.polylineId.value,
      'points': polyline.points
          .map((point) =>
              {'latitude': point.latitude, 'longitude': point.longitude})
          .toList(),
      'width': polyline.width,
      'color': polyline.color.value,
    };
  }

  Polyline mapToPolyline(Map<String, dynamic> map) {
    return Polyline(
      polylineId: PolylineId(map['polylineId']),
      points: (map['points'] as List)
          .map((point) => LatLng(point['latitude'], point['longitude']))
          .toList(),
      width: map['width'],
      color: Color(map['color']),
    );
  }

  Future<void> savePolylines(Set<Polyline> polylines) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> polylineList = polylines
        .map((polyline) => jsonEncode(polylineToMap(polyline)))
        .toList();
    await prefs.setStringList('polylines', polylineList);
  }

  void drawRoute() async {
    routeCoords = [];

    widget.listRoutes[selectedIndexRoute]["polyline"].forEach((polyline) {
      routeCoords.add(LatLng(polyline[0], polyline[1]));
    });
    position1_lat =
        widget.listRoutes[selectedIndexRoute]["startPoint"]["coordinates"][0];
    position1_lng =
        widget.listRoutes[selectedIndexRoute]["startPoint"]["coordinates"][1];
    position2_lat =
        widget.listRoutes[selectedIndexRoute]["endPoint"]["coordinates"][0];
    position2_lng =
        widget.listRoutes[selectedIndexRoute]["endPoint"]["coordinates"][1];
    widget._polyline!.clear();
    widget._markers!.clear();
    widget._polyline = {};
    setState(() {
      widget._polyline!.add(Polyline(
        polylineId: const PolylineId('polyline1'),
        visible: true,
        points: routeCoords,
        color: Colors.white,
        width: 5,
      ));

      // Add markers
      widget._markers!.add(
        Marker(
          markerId: const MarkerId('start'),
          position: LatLng(
              widget.listRoutes[selectedIndexRoute]["startPoint"]["coordinates"]
                  [0],
              widget.listRoutes[selectedIndexRoute]["startPoint"]["coordinates"]
                  [1]),
          infoWindow: const InfoWindow(title: 'start'),
          icon: BitmapDescriptor.defaultMarker,
        ),
      );
      widget._markers!.add(
        Marker(
          markerId: const MarkerId('end'),
          position: LatLng(
              widget.listRoutes[selectedIndexRoute]["endPoint"]["coordinates"]
                  [0],
              widget.listRoutes[selectedIndexRoute]["endPoint"]["coordinates"]
                  [1]),
          infoWindow: const InfoWindow(title: 'End'),
          icon: BitmapDescriptor.defaultMarker,
        ),
      );
      widget.isSearch();
      widget.selectMap();
    });
    await savePolylines(widget._polyline!);

/*    CameraPosition camera_position = CameraPosition(
        target: LatLng(
            listRoutes[selectedIndexRoute]["startPoint"]["coordinates"][0],
            listRoutes[selectedIndexRoute]["startPoint"]["coordinates"][0]),
        zoom: 7);

    mapController = await _controller.future;

    mapController
        .animateCamera(CameraUpdate.newCameraPosition(camera_position));*/
  }

  void updateSelectedCardIndex(int index) {
    setState(() => selectedRouteCardIndex = index);
  }

  String formatTime(String time) {
    if (time.endsWith(":")) {
      // Remove the last character if it is a colon
      return time.substring(0, time.length - 1);
    }
    return time;
  }

// Usage

  Future _createReservation(BuildContext context) async {
    //   try {
    final prefs = await SharedPreferences.getInstance();
    prefs.reload();
    bool latitudeTest = prefs.containsKey("markerLat");
    bool longitudeTest = prefs.containsKey("markerLng");
    final alertStyle = AlertStyle(
        backgroundColor: const Color(0xFF003A5A).withOpacity(0.8),
        animationType: AnimationType.fromTop,
        isCloseButton: false,
        isOverlayTapDismiss: true,
        descStyle: const TextStyle(fontWeight: FontWeight.bold),
        animationDuration: const Duration(milliseconds: 400),
        alertBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(0.0),
          side: const BorderSide(
            color: Colors.grey,
          ),
        ),
        titleStyle: const TextStyle(
          color: Colors.red,
        ),
        // constraints: BoxConstraints.expand(width: 300),
        //First to chars "55" represents transparency of color
        overlayColor: Colors.black.withOpacity(0.36),
        alertElevation: 0,
        alertAlignment: Alignment.topCenter);

    if (widget.listSchedules.isNotEmpty && latitudeTest && longitudeTest) {
      final userID = prefs.getString("user");
      final latitudePos = prefs.getDouble("markerLat");
      final longitudePos = prefs.getDouble("markerLng");
      String startTime = widget.listSchedules[selectedIndexRoute]["startTime"];
      String formattedTime = formatTime(startTime);

      final reqBody = {
        "user": userID,
        "schedule": widget.listSchedules[selectedIndexRoute]["_id"],
        "pickupTime": widget.listSchedules[selectedIndexRoute]["startTime"],
        "pickupLocation": {
          "type": "Point",
          "coordinates": [latitudePos, longitudePos],
        }
      };
      print("lattttttttttttttt ${latitudePos}");
      print("longggggggggggggg ${longitudePos}");
      await Reservation().createReservation(reqBody).then(
        (resp) {
          if (resp!.statusCode == 200) {
            Alert(
              context: context,
              type: AlertType.info,
              style: alertStyle,
              title: "",
              desc: "Reservation created successfully",
              buttons: [
                DialogButton(
                  onPressed: () {
                    Navigator.pop(context);
                    widget.showMyRides();
                  },
                  color: Colors.grey,
                  child: const Text(
                    "Close",
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
              ],
            ).show();
          } else {
            Alert(
              context: context,
              type: AlertType.error,
              style: alertStyle,
              title: "",
              desc: "Failed to create reservation",
              buttons: [
                DialogButton(
                  onPressed: () => Navigator.pop(context),
                  color: Colors.grey,
                  child: const Text(
                    "Close",
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
              ],
            ).show();
          }
        },
        onError: (error) => Alert(
          context: context,
          type: AlertType.error,
          style: alertStyle,
          title: "",
          desc: "Failed to create reservation",
          buttons: [
            DialogButton(
              onPressed: () => Navigator.pop(context),
              color: Colors.grey,
              child: const Text(
                "Close",
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ],
        ).show(),
      );
    } else {
      Alert(
        context: context,
        type: AlertType.error,
        style: alertStyle,
        title: "",
        desc:
            "Please specify your pickup location before submitting (must be on the traced route)",
        buttons: [
          DialogButton(
            onPressed: () => Navigator.pop(context),
            color: Colors.grey,
            child: const Text(
              "Close",
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
        ],
      ).show();
    }
  }

  @override
  Widget build(BuildContext context) {
    _height = MediaQuery.of(context).size.height;
    _width = MediaQuery.of(context).size.width;

    return SlidingUpPanel(
      maxHeight: MediaQuery.of(context).size.height * 0.7,
      minHeight: MediaQuery.of(context).size.height * 0.35,
      panel: Stack(
        alignment: AlignmentDirectional.topCenter,
        // clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 5,
            child: Container(
              width: 60,
              height: 7,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                color: colorsFile.background,
              ),
            ),
          ),
          Positioned(
            child: Column(
              children: [
                const SizedBox(height: 20),
                Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(50, 8.0, 0, 8),
                      child: Text(
                        "Choose a ride",
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: colorsFile.titleCard,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        height: 50,
                        width: 50,
                        child: Stack(
                          children: [
                            ClayContainer(
                              color: Colors.white,
                              height: 50,
                              width: 50,
                              borderRadius: 50,
                              curveType: CurveType.concave,
                              depth: 30,
                              spread: 1,
                            ),
                            GestureDetector(
                              onTap: () => _createReservation(context),
                              child: Center(
                                child: ClayContainer(
                                  color: Colors.white,
                                  height: 40,
                                  width: 40,
                                  borderRadius: 40,
                                  curveType: CurveType.convex,
                                  depth: 30,
                                  spread: 1,
                                  child: const Center(
                                    child: Icon(
                                      Icons.send,
                                      color: colorsFile.buttonIcons,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(
                      widget.listSchedules.length,
                      (index) {
                        print(
                            "userrrrrrrrrrrrrrrrrr${widget.listSchedules[index]['user']}");
                        final Map? driverData =
                            widget.listSchedules[index]['user'];
                        return GestureDetector(
                          onTap: () {
                            toggleSelection(index);
                          },
                          child: RouteCard(widget.listSchedules, driverData,
                              isCardSelected, selectedIndexRoute, index),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Container(),
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(50.0),
        topRight: Radius.circular(50.0),
      ),
      color: colorsFile.cardColor,
      onPanelSlide: (double pos) {
        setState(() {
          bottomSheetVisible = pos > 0.5;
        });
      },
      isDraggable: true,
    );
  }
}

// Available routes once the passenger picks the route, time and date
