import 'package:dartnative/dartnative.dart';
import 'package:dartnative_camera/dartnative_camera.dart';
import 'package:dartnative_permissions/dartnative_permissions.dart';

import '../../theme/pause_theme.dart';

class ScreenshotCameraPage extends StatefulWidget {
  const ScreenshotCameraPage({super.key});

  @override
  State<ScreenshotCameraPage> createState() => _ScreenshotCameraPageState();
}

class _ScreenshotCameraPageState extends State<ScreenshotCameraPage> {
  CameraController? _camera;
  String? _error;
  var _takingPhoto = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _startCamera();
  }

  Future<void> _startCamera() async {
    try {
      final permission = await Permission.camera.request();
      if (permission != PermissionStatus.granted) {
        if (mounted) {
          setState(() => _error = 'Allow camera access to take a photo.');
        }
        return;
      }
      final cameras = await DartNativeCamera.availableCameras();
      if (cameras.isEmpty) {
        if (mounted) setState(() => _error = 'No camera is available.');
        return;
      }
      final camera = cameras.firstWhere(
        (item) => item.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        camera,
        ResolutionPreset.veryHigh,
        enableAudio: false,
      );
      await controller.initialize();
      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() => _camera = controller);
    } catch (_) {
      if (mounted) setState(() => _error = 'Camera is unavailable.');
    }
  }

  Future<void> _capture() async {
    final camera = _camera;
    if (camera == null || _takingPhoto) return;
    setState(() => _takingPhoto = true);
    try {
      final path = await camera.takePicture();
      if (mounted) Navigator.pop(context, path);
    } catch (_) {
      if (mounted) {
        setState(() {
          _takingPhoto = false;
          _error = 'Could not take that photo. Try again.';
        });
      }
    }
  }

  @override
  void dispose() {
    _camera?.dispose();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Take a photo'),
        leading: BackButton(onTap: () => Navigator.pop(context)),
      ),
      body: _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(_error!, style: TextStyle(color: scheme.onSurface)),
              ),
            )
          : _camera == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(child: CameraPreview(controller: _camera!)),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Button(
                    title: _takingPhoto ? 'Capturing…' : 'Take photo',
                    variant: ButtonVariant.filled,
                    color: PauseColors.blue,
                    width: double.infinity,
                    onPressed: _takingPhoto ? null : _capture,
                  ),
                ),
              ],
            ),
    );
  }
}
