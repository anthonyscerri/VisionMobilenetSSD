// ignore: import_of_legacy_library_into_null_safe
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/rendering.dart';
import 'package:location/location.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';

class GlobalVar {
  static int GPSTimeStamp = 0;
  static List<String> Det = List<String>.filled(6, '');
  static double MobileSyncDiff = 0;
}

class Util {
  Location location = Location();

  ScreenshotController screenshotController = ScreenshotController();

  Future createFilesFolder() async {
    // Creates dir/ and dir/subdir/.
    var directory = await Directory(
            '/storage/emulated/0/Android/data/com.example.pothole_detection/files/')
        .create(recursive: true);
  }

  Future<bool> syncTime() async {
    // return mobile's clock time diff from GPS' atomic clock
    double diff = 0;

    for (int i = 0; i < 100; i++) {
      LocationData loc = await location.getLocation();
      diff = (diff +
          (double.parse(DateTime.now().millisecondsSinceEpoch.toString()) -
              double.parse(loc.time.toString())));
      print(i);
    }
    GlobalVar.MobileSyncDiff = diff / 100;
    return true;
  }

  //File writer
  _writeAnomalyDetection(String text) {
    try {
      final File file = File(
          '/storage/emulated/0/Android/data/com.example.pothole_detection/files/AnomalyDetection.txt');
      file.writeAsString(text, mode: FileMode.append);
    } on Exception {
      var error = '';
      print('File Write Error');
    }
  }

  void getLocation(String obj, String perc, String left, String top,
      String width, String height) async {
    LocationData loc = await location.getLocation();
    _writeAnomalyDetection(DateTime.now().toString() +
        ',' +
        (DateTime.now().millisecondsSinceEpoch - GlobalVar.GPSTimeStamp)
            .toString() +
        ',' +
        // Smartphone less GPS sync
        GlobalVar.GPSTimeStamp.toString() +
        ',' +
        loc.latitude.toString() +
        ',' +
        loc.longitude.toString() +
        ',' +
        loc.speed.toString() +
        ',' +
        obj +
        ',' +
        perc +
        ',' +
        left +
        ',' +
        top +
        ',' +
        width +
        ',' +
        height +
        '\n');
  }

  //File writer
  _writeImageLocation(String text) async {
    try {
      var directory = await getExternalStorageDirectory();
      final File file = File('${directory!.path}/ImageLocation.txt');
      await file.writeAsString(text, mode: FileMode.append);
    } on Exception {}
  }

  void getImageLocation(String imgFile) async {
    LocationData loc = await location.getLocation();
    try {
      await _writeImageLocation(DateTime.now().toString() +
          ',' +
          //(DateTime.now().millisecondsSinceEpoch - GlobalVar.GPSTimeStamp)
          //    .toString() +
          ',' +
          GlobalVar.GPSTimeStamp.toString() +
          ',' +
          loc.latitude.toString() +
          ',' +
          loc.longitude.toString() +
          ',' +
          loc.speed.toString() +
          ',' +
          imgFile +
          '\n');
    } on Exception {}
  }

  @override
  void initState() {}
}
