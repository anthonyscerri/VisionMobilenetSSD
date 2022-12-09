import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pothole_detection/realtime/bounding_box.dart';
import 'package:pothole_detection/realtime/camera.dart';
import 'dart:math' as math;
import 'package:tflite/tflite.dart';
import '/util/helper.dart';

Util helper = Util();

class LiveFeed extends StatefulWidget {
  final List<CameraDescription> cameras;
  LiveFeed(this.cameras);
  @override
  _LiveFeedState createState() => _LiveFeedState();
}

class _LiveFeedState extends State<LiveFeed> {
  List<dynamic> _recognitions = [];
  int _imageHeight = 0;
  int _imageWidth = 0;
  initCameras() async {}
  loadTfModel() async {
    await Tflite.loadModel(
      model: "assets/models/20220730.tflite",
      labels: "assets/models/labels.txt",
    );
  }

  /* 
  The set recognitions function assigns the values of recognitions, imageHeight and width to the variables defined here as callback
  */
  setRecognitions(recognitions, imageHeight, imageWidth) {
    setState(() {
      _recognitions = recognitions;
      _imageHeight = imageHeight;
      _imageWidth = imageWidth;
      //Save recognition to file
      if (_recognitions.isNotEmpty) {
        var obj = _recognitions[0]['detectedClass'].toString();
        var perc = _recognitions[0]['confidenceInClass'].toString();
        var loc_w = _recognitions[0]['rect']['w'].toString();
        var loc_x = _recognitions[0]['rect']['x'].toString();
        var loc_h = _recognitions[0]['rect']['h'].toString();
        var loc_y = _recognitions[0]['rect']['y'].toString();

        helper.getLocation(obj, perc, loc_w, loc_x, loc_h, loc_y);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    loadTfModel();
  }

  @override
  Widget build(BuildContext context) {
    Size screen = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: Text("Pothole MobilenetSSD Detection"),
      ),
      body: Stack(
        children: <Widget>[
          CameraFeed(widget.cameras, setRecognitions),
          BoundingBox(
            _recognitions == null ? [] : _recognitions,
            math.max(_imageHeight, _imageWidth),
            math.min(_imageHeight, _imageWidth),
            screen.height,
            screen.width,
          ),
        ],
      ),
    );
  }
}
