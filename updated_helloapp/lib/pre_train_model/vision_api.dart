import 'dart:typed_data';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class VisionApi {
  late Interpreter _interpreter;
  late Interpreter _antiSpoofingInterpreter;
  bool _isInitialized = false;

  VisionApi() {
    loadModel();
  }

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
    var input = _imageToByteListFloat32(image, 112, 128, 128);

    // Define input and output shapes
    var inputShape = _interpreter.getInputTensor(0).shape;
    var outputShape = _interpreter.getOutputTensor(0).shape;
    var output = List<double>.filled(outputShape.reduce((a, b) => a * b), 0)
        .reshape(outputShape);

    // Run the interpreter
    _interpreter.run(input, output);

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
    var input = _imageToByteListFloat32(image, 112, 128, 128);

    var inputShape = _antiSpoofingInterpreter.getInputTensor(0).shape;
    var outputShape = _antiSpoofingInterpreter.getOutputTensor(0).shape;
    var output = List<double>.filled(outputShape.reduce((a, b) => a * b), 0)
        .reshape(outputShape);

    // Run the interpreter
    _antiSpoofingInterpreter.run(input, output);

    // Adjust this condition based on your model's output format
    return output[0] > 0.5;
  }

  List<int> _imageToByteListFloat32(img.Image image, int inputSize, double mean, double std) {
    final Float32List byteData = Float32List(inputSize * inputSize * 3);
    int bufferIndex = 0;

    for (int y = 0; y < inputSize; y++) {
      for (int x = 0; x < inputSize; x++) {
        final pixel = image.getPixel(x, y);
        byteData[bufferIndex++] = (img.getRed(pixel) - mean) / std;
        byteData[bufferIndex++] = (img.getGreen(pixel) - mean) / std;
        byteData[bufferIndex++] = (img.getBlue(pixel) - mean) / std;
      }
    }

    return byteData.buffer.asUint8List();
  }
}
