import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart';
import 'package:tflite/tflite.dart';
import 'dart:math' as math;
import 'package:image/image.dart' as imglib;
import 'dart:io';
import '/util/helper.dart';
import 'package:location/location.dart';
import 'package:path_provider/path_provider.dart';

typedef void Callback(List<dynamic> list, int h, int w);

Util helper = Util();
Location location = Location();

class CameraFeed extends StatefulWidget {
  final List<CameraDescription> cameras;
  final Callback setRecognitions;
  // The cameraFeed Class takes the cameras list and the setRecognitions
  // function as argument
  CameraFeed(this.cameras, this.setRecognitions);

  @override
  _CameraFeedState createState() => new _CameraFeedState();
}

class _CameraFeedState extends State<CameraFeed> {
  late CameraController controller;
  bool isDetecting = false;

  //Remove image compression to improve the performance
  imglib.PngEncoder pngEncoder = imglib.PngEncoder(level: 0, filter: 0);

  @override
  void initState() {
    super.initState();
    print(widget.cameras);
    if (widget.cameras == null || widget.cameras.length < 1) {
      print('No Cameras Found.');
    } else {
      controller =
          new CameraController(widget.cameras[0], ResolutionPreset.medium);
      controller.initialize().then((_) async {
        if (!mounted) {
          return;
        }
        setState(() {});

        // Create Files folder for images and detection files
        await helper.createFilesFolder();
        //Sync smartphone time with GPS time
        await helper.syncTime();

        //Camera Zoom

        controller.setZoomLevel(3);
        //controller.lockCaptureOrientation(DeviceOrientation.portraitUp);

        controller.setFocusMode(FocusMode.locked);

        int timer = DateTime.now().millisecondsSinceEpoch;

        controller.startImageStream((CameraImage img) async {
          //Implement code to only capture 1 image per number of milliseconds
          int timeNow = DateTime.now().millisecondsSinceEpoch;
          int delay = timeNow - timer;
          //set a delay to allow image conversion and time to store the image
          //Furthermoe, if delay exceeds 1000 ms, pause for 5000 ms (bottom if statement)
          if (delay > 500 && delay < 1000) {
            //if (!isDetecting) {
            //LocationData loc = await location.getLocation();

            GlobalVar.GPSTimeStamp = (DateTime.now().millisecondsSinceEpoch +
                    GlobalVar.MobileSyncDiff)
                .toInt();

            var png = _convertYUV420(img);
            await _write(png); // Save image

            if (!isDetecting) {
              isDetecting = true;

              Tflite.detectObjectOnFrame(
                bytesList: img.planes.map((plane) {
                  return plane.bytes;
                }).toList(),
                model: "SSDMobileNet",
                imageHeight: img.height,
                imageWidth: img.width,
                rotation: 0,
                imageMean: 127.5,
                imageStd: 127.5,
                numResultsPerClass: 1,
                threshold: 0.50,
              ).then((recognitions) {
                /*
              When setRecognitions is called here, the parameters are being passed on to the parent widget as callback. i.e. to the LiveFeed class
               */

                widget.setRecognitions(recognitions!, img.height, img.width);
                isDetecting = false;
              });
            }
            timer = DateTime.now().millisecondsSinceEpoch;
          } else {}
          if (delay > 5000) {
            timer = DateTime.now().millisecondsSinceEpoch;
          }
        });
      });
    }
  }

//Convrt Yuv420 to png
// code from https://gist.github.com/Alby-o/fe87e35bc21d534c8220aed7df028e03
  imglib.Image _convertYUV420(CameraImage image) {
    var img = imglib.Image(image.width, image.height); // Create Image buffer

    final int width = image.width;
    final int height = image.height;
    final int uvRowStride = image.planes[1].bytesPerRow;
    final int? uvPixelStride = image.planes[1].bytesPerPixel;
    const shift = (0xFF << 24);

    for (int x = 0; x < width; x++) {
      for (int y = 0; y < height; y++) {
        final int uvIndex =
            uvPixelStride! * (x / 2).floor() + uvRowStride * (y / 2).floor();
        final int index = y * width + x;

        final yp = image.planes[0].bytes[index];
        final up = image.planes[1].bytes[uvIndex];
        final vp = image.planes[2].bytes[uvIndex];
        // Calculate pixel color
        int r = (yp + vp * 1436 / 1024 - 179).round().clamp(0, 255);
        int g = (yp - up * 46549 / 131072 + 44 - vp * 93604 / 131072 + 91)
            .round()
            .clamp(0, 255);
        int b = (yp + up * 1814 / 1024 - 227).round().clamp(0, 255);
        img.data[index] = shift | (b << 16) | (g << 8) | r;
      }
    }
    var resizedImage = copyResize(img, width: 300, height: 300);
    return resizedImage;
    //return img;
  }

  //File writer
  _write(imglib.Image img) {
    try {
      List<int> png = pngEncoder.encodeImage(img);
      String fileName = GlobalVar.GPSTimeStamp.toString();
      final File file = File(
          '/storage/emulated/0/Android/data/com.example.pothole_detection/files/' +
              fileName +
              '.png');
      file.writeAsBytes(png);
      helper.getImageLocation(fileName + '.png');
    } on Exception {}
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (controller == null || !controller.value.isInitialized) {
      return Container();
    }

    Size? tmp = MediaQuery.of(context).size;
    var screenH = math.max(tmp.height, tmp.width);
    var screenW = math.min(tmp.height, tmp.width);
    tmp = controller.value.previewSize;
    var previewH = math.max(tmp!.height, tmp.width);
    var previewW = math.min(tmp.height, tmp.width);
    var screenRatio = screenH / screenW;
    var previewRatio = previewH / previewW;

    return OverflowBox(
      maxHeight:
          screenRatio > previewRatio ? screenH : screenW / previewW * previewH,
      maxWidth:
          screenRatio > previewRatio ? screenH / previewH * previewW : screenW,
      child: CameraPreview(controller),
    );
  }
}
