import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';

List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    cameras = await availableCameras();
  } on CameraException catch (e) {
    print('Error in fetching the cameras: $e');
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(brightness: Brightness.dark),
      home: const CameraScreen(),
    );
  }
}

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});
  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? controller;
  bool _isCameraInitialized = false;
  int selectedCameraIndex = 0;

  List<double> selectedFilter = [
    1, 0, 0, 0, 0,
    0, 1, 0, 0, 0,
    0, 0, 1, 0, 0,
    0, 0, 0, 1, 0,
  ];

  @override
  void initState() {
    super.initState();
    if (cameras.isNotEmpty) onNewCameraSelected(cameras[selectedCameraIndex]);
  }

  void onNewCameraSelected(CameraDescription cameraDescription) async {
    if (controller != null) await controller!.dispose();
    controller = CameraController(cameraDescription, ResolutionPreset.high, enableAudio: false);
    try {
      await controller!.initialize();
      if (mounted) setState(() => _isCameraInitialized = true);
    } catch (e) {
      print(e);
    }
  }

  Future<void> _takePicture() async {
    if (controller == null || !controller!.value.isInitialized) return;
    try {
      XFile imageFile = await controller!.takePicture();
      await GallerySaver.saveImage(imageFile.path);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('📸 บันทึกรูปลงแกลลอรี่แล้ว!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: _isCameraInitialized
                ? ColorFiltered(
                    colorFilter: ColorFilter.matrix(selectedFilter),
                    child: CameraPreview(controller!),
                  )
                : const Center(child: CircularProgressIndicator()),
          ),

          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _filterIconButton("เดิม", [1,0,0,0,0, 0,1,0,0,0, 0,0,1,0,0, 0,0,0,1,0], Icons.refresh),
                  const SizedBox(height: 15),
                  _filterIconButton("ขาวดำ", [0.21,0.72,0.07,0,0, 0.21,0.72,0.07,0,0, 0.21,0.72,0.07,0,0, 0,0,0,1,0], Icons.blur_on),
                  const SizedBox(height: 15),
                  _filterIconButton("ซีเปีย", [0.39,0.76,0.18,0,0, 0.35,0.68,0.16,0,0, 0.27,0.53,0.13,0,0, 0,0,0,1,0], Icons.history_edu),
                  const SizedBox(height: 15),
                  _filterIconButton("เนกาทีฟ", [-1,0,0,0,255, 0,-1,0,0,255, 0,0,-1,0,255, 0,0,0,1,0], Icons.invert_colors),
                ],
              ),
            ),
          ),

          // ปุ่มควบคุมด้านล่าง (ถ่ายรูป/สลับกล้อง)
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.flip_camera_android, color: Colors.white, size: 35),
                  onPressed: () {
                    selectedCameraIndex = (selectedCameraIndex == 0) ? 1 : 0;
                    onNewCameraSelected(cameras[selectedCameraIndex]);
                  },
                ),
                GestureDetector(
                  onTap: _takePicture,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3)),
                    child: const CircleAvatar(radius: 35, backgroundColor: Colors.white),
                  ),
                ),
                const SizedBox(width: 50),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterIconButton(String name, List<double> matrix, IconData icon) {
    bool isSelected = selectedFilter == matrix;
    return Column(
      children: [
        IconButton(
          icon: Icon(icon, color: isSelected ? Colors.yellow : Colors.white, size: 30),
          onPressed: () => setState(() => selectedFilter = matrix),
        ),
        Text(name, style: const TextStyle(fontSize: 10, color: Colors.white)),
      ],
    );
  }
}