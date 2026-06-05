import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'dart:math';

void main() {
  runApp(const DNAStorageApp());
}

class DNAStorageApp extends StatelessWidget {
  const DNAStorageApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Synthetic DNA Storage',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: "Segoe UI",
      ),
      home: const EncodeScreen(),
    );
  }
}

class EncodeScreen extends StatefulWidget {
  const EncodeScreen({super.key});

  @override
  State<EncodeScreen> createState() => _EncodeScreenState();
}

class _EncodeScreenState extends State<EncodeScreen>
    with SingleTickerProviderStateMixin {
  File? selectedFile;
  String status = "No file selected";
  final TextEditingController keyController = TextEditingController();
  bool obscureKey = true;

  late AnimationController _dnaController;

  // 🔥 Backend process reference
  Process? backendProcess;

  @override
void initState() {
  super.initState();

  _dnaController =
      AnimationController(vsync: this, duration: const Duration(seconds: 6))
        ..repeat();

  startBackend(); // 🔥 Auto start backend
}


  // 🔥 START BACKEND AUTOMATICALLY
  Future<void> startBackend() async {
  try {
    // Path of the running Flutter exe
    final exeDir = File(Platform.resolvedExecutable).parent.path;

    final backendPath = "$exeDir\\backend.exe";

    print("Trying to start backend from: $backendPath");

    backendProcess = await Process.start(
      backendPath,
      [],
      mode: ProcessStartMode.detached,
    );

    await Future.delayed(const Duration(seconds: 2));

    print("Backend started successfully");
  } catch (e) {
    print("Failed to start backend: $e");
  }
}

  @override
  void dispose() {
    _dnaController.dispose();

    // 🔥 Kill backend when app closes (optional but clean)
    backendProcess?.kill();

    super.dispose();
  }

  Future<void> pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      setState(() {
        selectedFile = File(result.files.single.path!);
        status = "File selected: ${result.files.single.name}";
      });
    } else {
      setState(() {
        status = "No file selected";
      });
    }
  }

  Future<void> encodeFile() async {
    if (selectedFile == null) {
      setState(() => status = "Please select a file first!");
      return;
    }

    if (keyController.text.length != 16) {
      setState(() => status = "Key must be exactly 16 characters!");
      return;
    }

    setState(() => status = "Encoding file...");

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://127.0.0.1:5000/encode'),
      );

      request.fields['key'] = keyController.text;

      request.files.add(
        await http.MultipartFile.fromPath('file', selectedFile!.path),
      );

      var response = await request.send();

      if (response.statusCode == 200) {
        Uint8List bytes = await response.stream.toBytes();
        final directory = await getDownloadsDirectory();
        final filePath = "${directory!.path}/encoded_output.fasta";

        await File(filePath).writeAsBytes(bytes);

        setState(() => status = "FASTA saved to Downloads!");
      } else {
        setState(() => status = "Server error during encoding.");
      }
    } catch (e) {
      setState(() => status = "Error: $e");
    }
  }

  Future<void> decodeFile() async {
    if (selectedFile == null) {
      setState(() => status = "Please select a FASTA file first!");
      return;
    }

    if (keyController.text.length != 16) {
      setState(() => status = "Key must be exactly 16 characters!");
      return;
    }

    setState(() => status = "Decoding FASTA...");

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://127.0.0.1:5000/decode'),
      );

      request.fields['key'] = keyController.text;

      request.files.add(
        await http.MultipartFile.fromPath('file', selectedFile!.path),
      );

      var response = await request.send();

      if (response.statusCode == 200) {
        Uint8List bytes = await response.stream.toBytes();

        String? contentDisposition =
            response.headers['content-disposition'];

        String filename = "decoded_output";

        if (contentDisposition != null &&
            contentDisposition.contains("filename=")) {
          filename = contentDisposition
              .split("filename=")[1]
              .replaceAll('"', '');
        }

        final directory = await getDownloadsDirectory();
        final filePath = "${directory!.path}/$filename";

        await File(filePath).writeAsBytes(bytes);

        setState(() => status = "File restored as $filename");
      } else {
        setState(() => status = "Wrong key or corrupted file!");
      }
    } catch (e) {
      setState(() => status = "Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 🌌 Gradient Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF141E30), Color(0xFF243B55)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // 🧬 Animated DNA
          AnimatedBuilder(
            animation: _dnaController,
            builder: (_, __) {
              return CustomPaint(
                painter: DNAPainter(_dnaController.value),
                size: Size.infinite,
              );
            },
          ),

          // 💎 Glass Card
          Center(
            child: Card(
              color: Colors.white.withOpacity(0.9),
              elevation: 30,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: SizedBox(
                  width: 500,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.biotech,
                          size: 90, color: Colors.deepPurple),

                      const SizedBox(height: 20),

                      const Text(
                        "Synthetic DNA Data Storage",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 30),

                      TextField(
                        controller: keyController,
                        obscureText: obscureKey,
                        decoration: InputDecoration(
                          labelText: "Enter 16-character Encryption Key",
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(obscureKey
                                ? Icons.visibility
                                : Icons.visibility_off),
                            onPressed: () {
                              setState(() {
                                obscureKey = !obscureKey;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),

                      const SizedBox(height: 25),

                      ElevatedButton.icon(
                        onPressed: pickFile,
                        icon: const Icon(Icons.upload_file),
                        label: const Text("Select File"),
                        style: _buttonStyle(Colors.grey.shade700),
                      ),

                      const SizedBox(height: 15),

                      ElevatedButton.icon(
                        onPressed: encodeFile,
                        icon: const Icon(Icons.auto_fix_high),
                        label: const Text("Encode to DNA"),
                        style: _buttonStyle(Colors.deepPurple),
                      ),

                      const SizedBox(height: 15),

                      ElevatedButton.icon(
                        onPressed: decodeFile,
                        icon: const Icon(Icons.restore),
                        label: const Text("Decode from DNA"),
                        style: _buttonStyle(Colors.teal),
                      ),

                      const SizedBox(height: 25),

                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          status,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 15),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  ButtonStyle _buttonStyle(Color color) {
    return ElevatedButton.styleFrom(
      backgroundColor: color,
      foregroundColor: Colors.white,
      minimumSize: const Size(double.infinity, 50),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      elevation: 8,
    );
  }
}

class DNAPainter extends CustomPainter {
  final double progress;
  DNAPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()
      ..color = Colors.deepPurple.withOpacity(0.3);

    final paint2 = Paint()
      ..color = Colors.tealAccent.withOpacity(0.3);

    final centerX = size.width / 2;
    final amplitude = 80.0;
    final frequency = 0.02;

    for (double y = 0; y < size.height; y += 12) {
      double x1 = centerX +
          amplitude * sin((y * frequency) + (progress * 2 * pi));
      double x2 = centerX +
          amplitude *
              sin((y * frequency) + (progress * 2 * pi) + pi);

      canvas.drawCircle(Offset(x1, y), 3, paint1);
      canvas.drawCircle(Offset(x2, y), 3, paint2);
    }
  }

  @override
  bool shouldRepaint(covariant DNAPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
