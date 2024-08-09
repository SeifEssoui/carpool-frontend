import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';  // Import intl
import 'package:shared_preferences/shared_preferences.dart';
import 'package:osmflutter/Services/notification.dart';
import 'package:osmflutter/constant/colorsFile.dart';

class Notif extends StatefulWidget {
  @override
  _NotifState createState() => _NotifState();
}

class _NotifState extends State<Notif> {
  late double _height;
  late double _width;

  Future<List<dynamic>> _loadNotifications() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userID = prefs.getString("user");
    if (userID != null) {
      var response = await NotificationService().getNotificationsByUser(userID);
      if (response != null && response.data != null) {
        print("Notifications received: ${response.data}");
        return response.data;
      }
    }
    return [];
  }

  String processMessage(String? message) {
    if (message == null) return "No message available";
    int cutOffIndex = message.indexOf(" on ");
    return (cutOffIndex != -1) ? message.substring(0, cutOffIndex) : message;
  }

  @override
  Widget build(BuildContext context) {
    _height = MediaQuery.of(context).size.height;
    _width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: colorsFile.background,
      body: Column(
        children: [
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 30.0),
              height: _height * 0.03,
              width: _width,
            ),
          ),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _loadNotifications(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.error != null) {
                  return Center(child: Text('An error occurred: ${snapshot.error.toString()}'));
                }
                if (snapshot.hasData && snapshot.data!.isEmpty) {
                  return Center(child: Text("No notifications found"));
                }
                
                return ListView.builder(
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    var notification = snapshot.data![index];
                    // Format the date
                    String formattedDate = DateFormat('yyyy-MM-dd – kk:mm').format(DateTime.parse(notification['createdAt']));

                    return Padding(
                      padding: const EdgeInsets.only(right: 16.0, left: 16.0, top: 16.0),
                      child: GlassmorphicContainer(
                        height: _height * 0.15,
                        width: _width * 0.8,
                        borderRadius: 15,
                        blur: 100,
                        alignment: Alignment.center,
                        border: 2,
                        linearGradient: LinearGradient(
                          colors: [Color(0xFFD8E6EE), Color(0xFFD8E6EE)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderGradient: LinearGradient(
                          colors: [
                            Colors.white24.withOpacity(0.2),
                            Colors.white70.withOpacity(0.2),
                          ],
                        ),
                        child: Container(
                          child: Row(
                            children: [
                              SizedBox(width: 8),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(5.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        notification['title'] ?? "No Title",
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.montserrat(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                          color: colorsFile.notiftitle,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        processMessage(notification['message']),
                                        textAlign: TextAlign.start,
                                        style: GoogleFonts.montserrat(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 12,
                                          color: colorsFile.notiftext,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Spacer(),
                                          Padding(
                                            padding: const EdgeInsets.only(right: 8.0),
                                            child: Text(
                                              formattedDate,  
                                              textAlign: TextAlign.end,
                                              style: GoogleFonts.montserrat(
                                                fontWeight: FontWeight.w500,
                                                fontSize: 10,
                                                color: colorsFile.notifdate,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
