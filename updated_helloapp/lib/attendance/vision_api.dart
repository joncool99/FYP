import 'dart:typed_data';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class VisionApi {
  late Interpreter _interpreter;
  late Interpreter _antiSpoofingInterpreter;
  bool _isInitialized = false;

  VisionApi();

  Future<void> loadModel() async {
    _interpreter = await Interpreter.fromAsset('mobilefacenet.tflite');
    _antiSpoofingInterpreter =
        await Interpreter.fromAsset('FaceAntiSpoofing.tflite');
    _isInitialized = true;
  }

  Future<List<double>> detectFaces(Uint8List imageData) async {
    if (!_isInitialized) throw Exception("Model not initialized");

    // Process image data to fit the model input requirements
    img.Image? image = img.decodeImage(imageData);
    if (image == null) {
      throw Exception("Cannot decode image");
    }

    // Resize and normalize the image
    image = img.copyResize(image, width: 112, height: 112);
    var input = image.getBytes().buffer.asUint8List();

    // Define input and output shapes
    var inputShape = _interpreter.getInputTensor(0).shape;
    var outputShape = _interpreter.getOutputTensor(0).shape;
    var output = List<double>.filled(outputShape.reduce((a, b) => a * b), 0)
        .reshape(outputShape);

    // Run the interpreter
    _interpreter.run([input], output);

    return output.flatten().cast<double>().toList();
  }

  bool checkForSpoofing(Uint8List imageData) {
    if (!_isInitialized) throw Exception("Model not initialized");

    // Perform anti-spoofing check
    img.Image? image = img.decodeImage(imageData);
    if (image == null) {
      throw Exception("Cannot decode image");
    }

    // Resize and normalize the image
    image = img.copyResize(image, width: 112, height: 112);
    var input = image.getBytes().buffer.asUint8List();

    var inputShape = _antiSpoofingInterpreter.getInputTensor(0).shape;
    var outputShape = _antiSpoofingInterpreter.getOutputTensor(0).shape;
    var output = List<double>.filled(outputShape.reduce((a, b) => a * b), 0)
        .reshape(outputShape);

    // Run the interpreter
    _antiSpoofingInterpreter.run([input], output);

    return output[0] == 1; // Adjust this condition as per your model's output
  }
}
