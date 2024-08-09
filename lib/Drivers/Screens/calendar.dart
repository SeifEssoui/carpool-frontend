import 'package:clay_containers/clay_containers.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:osmflutter/GoogleMaps/driver_polyline_map.dart';
import 'package:osmflutter/GoogleMaps/googlemaps.dart';
import 'package:osmflutter/Services/schedule.dart';
import 'package:osmflutter/constant/colorsFile.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:url_launcher/url_launcher.dart';

class Person {
  final String name;
  final String phoneNumber;

  Person({required this.name, required this.phoneNumber});

  @override
  String toString() => 'Person(name: $name, phoneNumber: $phoneNumber)';
}

class Calendar extends StatefulWidget {
  const Calendar({Key? key}) : super(key: key);

  @override
  State<Calendar> createState() => _CalendarState();
}

class _CalendarState extends State<Calendar> {
  late String selectedTime = '07:20';
  List? schedules;
  int selectedIndex = 0;
  int selectedTimeIndex = 0;
  int selectedPersonIndex = -1;
  DateTime now = DateTime.now();
  late DateTime lastDayOfMonth;
  bool bottomSheetVisible = true;
  Set<Polyline> _polyline = {};
  Set<Marker> _markers = {};
  dynamic position2_lat = 36.85135579846211, position2_lng = 10.179065957033673;
  dynamic position1_lat, position1_lng;
  bool check_map = true;
  List<LatLng> routeCoords = [];
  List<dynamic> listRoutes = [];
  late BitmapDescriptor _customIcon;
  late double _height;
  late double _width;
  void _loadCustomMarker() async {
    _customIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(50, 50)),
      'assets/images/pinRes.png',
    );
  }

  void drawRoute() async {
    routeCoords = [];
    listRoutes[selectedTimeIndex]["polyline"].forEach((polyline) {
      routeCoords.add(LatLng(polyline[0], polyline[1]));
    });
    position1_lat =
        listRoutes[selectedTimeIndex]["startPoint"]["coordinates"][0];
    position1_lng =
        listRoutes[selectedTimeIndex]["startPoint"]["coordinates"][1];
    position2_lat = listRoutes[selectedTimeIndex]["endPoint"]["coordinates"][0];
    position2_lng = listRoutes[selectedTimeIndex]["endPoint"]["coordinates"][1];
    _polyline.clear();
    _markers.clear();
    _polyline = {};

    final reservations = schedules![selectedTimeIndex]["reservations"];

    reservations.forEach((reservation) {
      print("sssssssssss${reservation["pickupLocation"]["coordinates"]}");

      if (reservation["pickupLocation"]["coordinates"].length != 0) {
        final coordinates = reservation["pickupLocation"]["coordinates"];
        final latLng = LatLng(coordinates[0], coordinates[1]);
        final marker = Marker(
          markerId: MarkerId(latLng.toString()),
          position: latLng,
          icon: _customIcon,
        );
        setState(() {
          _markers.add(marker);
        });
      }
    });
    setState(() {
      check_map = false;
      _polyline.add(Polyline(
        polylineId: PolylineId('route'),
        visible: true,
        points: routeCoords,
        color: Colors.white,
        width: 5,
      ));

      // Add markers
      _markers.add(
        Marker(
          markerId: MarkerId('start'),
          position: LatLng(
              listRoutes[selectedTimeIndex]["startPoint"]["coordinates"][0],
              listRoutes[selectedTimeIndex]["startPoint"]["coordinates"][1]),
          infoWindow: InfoWindow(title: 'start'),
          icon: BitmapDescriptor.defaultMarker,
        ),
      );

      _markers.add(
        Marker(
          markerId: MarkerId('end'),
          position: LatLng(
              listRoutes[selectedTimeIndex]["endPoint"]["coordinates"][0],
              listRoutes[selectedTimeIndex]["endPoint"]["coordinates"][1]),
          infoWindow: InfoWindow(title: 'End'),
          icon: BitmapDescriptor.defaultMarker,
        ),
      );
      check_map = false;
    });

    /*  CameraPosition camera_position = CameraPosition(
        target: LatLng(
            listRoutes[selectedIndex]["startPoint"]["coordinates"][0],
            listRoutes[selectedIndex]["startPoint"]["coordinates"][0]),
        zoom: 7);*/
    //
    // mapController = await _controller.future;
    //
    // mapController
    //     .animateCamera(CameraUpdate.newCameraPosition(camera_position));
  }

  @override
  void initState() {
    super.initState();
    _loadCustomMarker();
    lastDayOfMonth = DateUtils.dateOnly(DateTime.now().add(Duration(days: 15)));

//    lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
    print("ddddddddddddddddddddddddddddddddd ${lastDayOfMonth}");
    // print("111111111111111111111111111111111 ${lastDayOfMonth1}");
    _loadPassengers();
  }

  Future<dynamic> _loadPassengers() async {
    print("ddddddddddddddddddddddddddddddddd ${lastDayOfMonth}");

    final DateTime date = now.add(Duration(days: selectedIndex));
    final String dateString =
        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? user = prefs.getString('user');
    await scheduleServices()
        .getScheduleReservationsByDate(dateString, user!)
        .then((resp) async {
      setState(() {
        schedules = resp.data['schedule'];
      });

      if (schedules!.isNotEmpty) {
        listRoutes = [];
        for (final (index, schedule) in schedules!.indexed) {
          listRoutes.add(schedules?[index]["routes"]);
          List<Person> ppl = (schedule['reservations'] as List)
              .map((element) => Person(
                  name:
                      "${element['user']['firstName']} ${element['user']['lastName']}",
                  phoneNumber: element['user']['phoneNumber'] ?? "-"))
              .toList();
          schedules![index]['people'] = ppl;
        }
        drawRoute();
        //   _loadPickUpPoints();
        setState(() {});
      } else {
        _polyline.clear();
        _markers.clear();
        _polyline = {};
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    _height = MediaQuery.of(context).size.height;
    _width = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment(0.8, 1),
              colors: <Color>[
                Color.fromRGBO(94, 149, 180, 1),
                Color.fromRGBO(77, 140, 175, 1),
              ],
              tileMode: TileMode.mirror,
            ),
          ),
        ),
        automaticallyImplyLeading: false,
        leading: null,
        toolbarHeight: 100.0,
        title: Column(
          children: [
            const SizedBox(height: 16.0),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const ClampingScrollPhysics(),
              child: Row(
                children: List.generate(
                  lastDayOfMonth.difference(now).inDays,
                  // lastDayOfMonth.day - now.day + 1,
                  (index) {
                    final currentDate = now.add(Duration(days: index));
                    final dayName = DateFormat('EEE').format(currentDate);
                    return Padding(
                      padding: EdgeInsets.only(
                          left: index == 0 ? 16.0 : 0.0, right: 16.0),
                      child: GestureDetector(
                        onTap: () async {
                          print("Selected Index : $index");

                          setState(() {
                            selectedIndex = index;

                            //drawRoute();
                          });
                          await _loadPassengers();
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              height: 42.0,
                              width: 42.0,
                              alignment: Alignment.center,
                              child: Text(
                                "${now.add(Duration(days: index)).day}",
                                style: TextStyle(
                                  fontSize: 16.0,
                                  color: selectedIndex == index
                                      ? Colors.white
                                      : colorsFile.titleCard,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              dayName.substring(0, 3),
                              style: TextStyle(
                                fontSize: 16.0,
                                color: selectedIndex == index
                                    ? Colors.white
                                    : Colors.white30,
                                fontWeight: selectedIndex == index
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          //  MapsGoogleExample(),

          check_map == true
              ? MapsGoogleExample()
              : DriverOnMap(
                  poly_lat1: position1_lat,
                  poly_lng1: position1_lng,
                  poly_lat2: position2_lat,
                  poly_lng2: position2_lng,
                  route_id: 'route',
                  polyline: _polyline,
                  markers: _markers,
                  isSearch: false),

          //Updated Code

          SlidingUpPanel(
            maxHeight: 350,
            minHeight: 120,
            panel: Column(
              children: [
                Container(
                  height: 350,
                  decoration: const BoxDecoration(
                    color: colorsFile.cardColor,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(50.0),
                    ),
                  ),
                  child: schedules == null
                      ? Container(
                          height: 130,
                          decoration: const BoxDecoration(
                            color: colorsFile.ProfileIcon,
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(50.0),
                            ),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : schedules!.isEmpty
                          ? Container(
                              height: 120,
                              width: _width,
                              decoration: const BoxDecoration(
                                color: colorsFile.ProfileIcon,
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(50.0),
                                ),
                              ),
                              child: Container(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 40.0),
                                  child: Text(
                                    textAlign: TextAlign.center,
                                    "No scheduled rides",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                            )
                          : Column(
                              children: [
                                Container(
                                  height: 115,
                                  decoration: const BoxDecoration(
                                    color: colorsFile.ProfileIcon,
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(50.0),
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      const SizedBox(
                                        height: 10,
                                      ),
                                      Container(
                                        width: 60,
                                        // height: 7,
                                        margin:
                                            const EdgeInsets.only(bottom: 20),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(5),
                                          color: colorsFile.background,
                                        ),
                                      ),
                                      const Align(
                                        alignment: Alignment.centerLeft,
                                        child: Padding(
                                          padding:
                                              EdgeInsets.fromLTRB(30, 0, 5, 10),
                                          child: Text(
                                            "Passengers",
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: List.generate(
                                          schedules!.length,
                                          (index) => TextButton(
                                            onPressed: () {
                                              setState(() {
                                                selectedTimeIndex = index;
                                              });
                                            },
                                            child: Row(
                                              children: [
                                                Text(
                                                  schedules![index]
                                                              ['startTime'] !=
                                                          null
                                                      ? TimeOfDay.fromDateTime(
                                                          DateTime.parse(
                                                              schedules![index][
                                                                  'startTime']),
                                                        ).format(context)
                                                      : "",
                                                  style: TextStyle(
                                                    color: selectedTimeIndex ==
                                                            index
                                                        ? Colors.white
                                                        : Colors.grey,
                                                    decoration:
                                                        selectedTimeIndex ==
                                                                index
                                                            ? TextDecoration
                                                                .underline
                                                            : TextDecoration
                                                                .none,
                                                  ),
                                                ),
                                                // if (selectedTimeIndex == index)
                                                //   const Icon(Icons.edit,
                                                //       color: Colors.white),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                              5.0, 5, 5, 5),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: [
                                              Padding(
                                                padding: EdgeInsets.fromLTRB(
                                                    10, 10, 5, 10),
                                                child: Container(
                                                  // color: Colors.red,
                                                  child: Text(
                                                    schedules![selectedTimeIndex]
                                                                [
                                                                'routeDirection'] ==
                                                            "toOffice"
                                                        ? "To office"
                                                        : "From office",
                                                    //  textAlign: TextAlign.right,
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 13,
                                                      color: colorsFile.icons,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              SizedBox(
                                                width: 15,
                                              ),
                                              ...List.generate(
                                                schedules![selectedTimeIndex]
                                                    ['availablePlaces'],
                                                (index) => Container(
                                                  child: Image.asset(
                                                    'assets/images/seat.png',
                                                    width: 15,
                                                    height: 15,
                                                    color: colorsFile.done,
                                                  ),
                                                ),
                                              )
                                            ],
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                              1.0, 5, 40, 5),
                                          child: Text(
                                            TimeOfDay.fromDateTime(
                                              DateTime.parse(
                                                  schedules![selectedTimeIndex]
                                                      ["startTime"]),
                                            ).format(context),
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                              color: colorsFile.detailColor,
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                              25.0, 5, 20, 5),
                                          child: Row(
                                            children: [
                                              GestureDetector(
                                                onTap: () {
                                                  _onAlertButtonsPressed(
                                                      context);
                                                },
                                                child: const Icon(
                                                  Icons.delete,
                                                  color: colorsFile.skyBlue,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        ...List.generate(
                                          schedules![selectedTimeIndex]
                                                  ['people']
                                              .length,
                                          (index) => GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                if (selectedPersonIndex ==
                                                    index) {
                                                  selectedPersonIndex = -1;
                                                } else {
                                                  selectedPersonIndex = index;
                                                }
                                              });
                                            },
                                            child: Column(
                                              children: [
                                                CircleAvatar(
                                                  backgroundImage: const AssetImage(
                                                      'assets/images/homme1.png'),
                                                  radius: 30,
                                                  backgroundColor:
                                                      selectedPersonIndex ==
                                                              index
                                                          ? Colors.blue
                                                          : null,
                                                ),
                                                const SizedBox(height: 8),
                                                if (selectedPersonIndex ==
                                                    index)
                                                  Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .center,
                                                    children: [
                                                      Center(
                                                        child: Text(
                                                          schedules![selectedTimeIndex]
                                                                      ['people']
                                                                  [index]
                                                              .name,
                                                          style: GoogleFonts
                                                              .montserrat(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontSize: 15,
                                                                  color: colorsFile
                                                                      .titleCard),
                                                        ),
                                                      ),
                                                      SizedBox(
                                                        height: 5,
                                                      ),
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .only(
                                                                right: 10.0),
                                                        child: Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Container(
                                                              height: 30,
                                                              width: 30,
                                                              child: Stack(
                                                                children: [
                                                                  ClayContainer(
                                                                    color: Colors
                                                                        .white,
                                                                    height: 30,
                                                                    width: 30,
                                                                    borderRadius:
                                                                        50,
                                                                    curveType:
                                                                        CurveType
                                                                            .concave,
                                                                    depth: 20,
                                                                    spread: 1,
                                                                  ),
                                                                  GestureDetector(
                                                                    onTap: () {
                                                                      _launchPhone(schedules![selectedTimeIndex]['people']
                                                                              [
                                                                              index]
                                                                          .phoneNumber);
                                                                    },
                                                                    child:
                                                                        Center(
                                                                      child:
                                                                          ClayContainer(
                                                                        color: Colors
                                                                            .white,
                                                                        height:
                                                                            20,
                                                                        width:
                                                                            20,
                                                                        borderRadius:
                                                                            40,
                                                                        curveType:
                                                                            CurveType.convex,
                                                                        depth:
                                                                            30,
                                                                        spread:
                                                                            1,
                                                                        child:
                                                                            const Center(
                                                                          child:
                                                                              Icon(
                                                                            Icons.phone,
                                                                            size:
                                                                                20,
                                                                            color:
                                                                                colorsFile.buttonIcons,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  )
                                                                ],
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                                width: 8),
                                                            Text(
                                                              schedules![selectedTimeIndex]
                                                                          [
                                                                          'people']
                                                                      [index]
                                                                  .phoneNumber,
                                                              style: GoogleFonts.montserrat(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                  fontSize: 13,
                                                                  color: colorsFile
                                                                      .titleCard),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                              ],
                                            ),
                                          ),
                                        )
                                      ],
                                    ),
                                  ],
                                )
                                // Placeholder, you can add content for '18:30' here
                              ],
                            ),
                ),
              ],
            ),
            body: Container(), // Your body widget here
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
          ),
        ],
      ),
    );
  }

  _onAlertButtonsPressed(context) {
    var alertStyle = AlertStyle(
        backgroundColor: Color(0xFF003A5A).withOpacity(0.8),
        animationType: AnimationType.fromTop,
        isCloseButton: false,
        isOverlayTapDismiss: true,
        descStyle: TextStyle(fontWeight: FontWeight.bold),
        animationDuration: Duration(milliseconds: 400),
        alertBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(0.0),
          side: BorderSide(
            color: Colors.grey,
          ),
        ),
        titleStyle: TextStyle(
          color: Colors.red,
        ),
        // constraints: BoxConstraints.expand(width: 300),
        //First to chars "55" represents transparency of color
        overlayColor: Colors.black.withOpacity(0.36),
        alertElevation: 0,
        alertAlignment: Alignment.topCenter);

    Alert(
      context: context,
      type: AlertType.warning,
      style: alertStyle,
      title: "",
      desc: "Are you sure you want to cancel this ride ?",
      buttons: [
        DialogButton(
          child: Text(
            "No",
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          onPressed: () => Navigator.pop(context),
          color: Colors.grey,
        ),
        DialogButton(
          child: Text(
            "Yes",
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          onPressed: () async {
            await deleteScheduleByID();
            Navigator.pop(context);
          },
          color: colorsFile.buttonIcons,
        )
      ],
    ).show();
  }

  Future<dynamic> deleteScheduleByID() async {
    return await scheduleServices()
        .deleteScheduleByID(schedules![selectedTimeIndex]['_id'])
        .then((value) async => await _loadPassengers());
  }

  // Function to launch the phone app
  _launchPhone(String phoneNumber) async {
    final url = 'tel:$phoneNumber';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}
