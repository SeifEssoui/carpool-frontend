// services/notification_service.dart
import 'package:dio/dio.dart';
import 'package:osmflutter/constant/url.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
 Dio dio = Dio(BaseOptions(baseUrl: link.url)); 

  Future<Response?> getNotificationsByUser(String userID) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      print("token $token");
      if (token != null) {
        
        dio.options.headers["Authorization"] = "Bearer $token";
      }

      var response = await dio.get("api/notifications/getByUser/$userID");
       print("Data received: ${response.data}");
      print("Type of data: ${response.data.runtimeType}");
      return response;
    } on DioException catch (e) {
      print("Error getting notifications: ${e.message}");
      return e.response;
    }
  }

  Future<Response?> createNotification(Map data) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      
      if (token != null) {
        dio.options.headers["Authorization"] = "Bearer $token";
      }

      var response = await dio.post("api/notifications/create", data: data);
      return response;
    } on DioException catch (e) {
      print("Error creating notification: ${e.message}");
      return e.response;
    }
  }

  Future<Response?> deleteNotification(String id) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      
      if (token != null) {
        dio.options.headers["Authorization"] = "Bearer $token";
      }

      var response = await dio.delete("api/notifications/delete/$id");
      return response;
    } on DioException catch (e) {
      print("Error deleting notification: ${e.message}");
      return e.response;
    }
  }
}
