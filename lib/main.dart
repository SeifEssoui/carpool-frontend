import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:osmflutter/SplashScreen/splash_screen.dart';
import 'package:osmflutter/constant/colorsFile.dart';
import 'package:osmflutter/constant/url.dart';

import 'Services/API.dart';

void main() async {
  DioInterceptor dioInterceptor = DioInterceptor();

  // Create a Dio instance and add the interceptor
  Dio dio = Dio(BaseOptions(baseUrl: link.url));
  dio.interceptors.add(dioInterceptor);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        focusColor: colorsFile.cursorColor,
        textSelectionTheme: TextSelectionThemeData(
            selectionColor: colorsFile.cursorColor,
            selectionHandleColor: colorsFile
                .cursorColor), // textSelectionHandleColor: Colors.transparent,
        scaffoldBackgroundColor: Colors.transparent,
      ),
      home: SplashScreen(),
      //home:  ChooseRole(),
    );
  }
}
