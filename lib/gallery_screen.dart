import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'video_player_screen.dart'; // Custom video player screen

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  _GalleryScreenState createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final ImagePicker _picker = ImagePicker();
  final List<File> _mediaFiles = [];
  final List<File> _hiddenFiles = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadMedia();
  }

  // Load the media files from shared preferences
  Future<void> _loadMedia() async {
    setState(() {
      _isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final savedMedia = prefs.getStringList('mediaPaths') ?? [];
    final savedHidden = prefs.getStringList('hiddenPaths') ?? [];

    _mediaFiles.clear();
    _hiddenFiles.clear();

    for (var path in savedMedia) {
      _mediaFiles.add(File(path));
    }

    for (var path in savedHidden) {
      _hiddenFiles.add(File(path));
    }

    setState(() {
      _isLoading = false;
    });
  }

  // Save media paths to shared preferences
  Future<void> _saveMedia() async {
    final prefs = await SharedPreferences.getInstance();
    final mediaPaths = _mediaFiles.map((file) => file.path).toList();
    final hiddenPaths = _hiddenFiles.map((file) => file.path).toList();
    await prefs.setStringList('mediaPaths', mediaPaths);
    await prefs.setStringList('hiddenPaths', hiddenPaths);
  }

  // Pick an image or video from gallery
  Future<void> _pickMedia() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _mediaFiles.add(File(pickedFile.path));
      });
      _saveMedia(); // Save media paths
    }
  }

  // Pick a video from gallery
  Future<void> _pickVideo() async {
    final pickedFile = await _picker.pickVideo(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _mediaFiles.add(File(pickedFile.path));
      });
      _saveMedia(); // Save media paths
    }
  }

  // Hide file from gallery
  void _hideFile(File file) {
    setState(() {
      _mediaFiles.remove(file);
      _hiddenFiles.add(file);
    });
    _saveMedia();
  }

  // Show hidden file back to gallery
  void _showFile(File file) {
    setState(() {
      _hiddenFiles.remove(file);
      _mediaFiles.add(file);
    });
    _saveMedia();
  }

  // Rename file
  void _renameFile(File file) async {
    String newName = await showDialog(
      context: context,
      builder: (context) {
        TextEditingController controller =
            TextEditingController(text: file.uri.pathSegments.last);
        return AlertDialog(
          title: const Text("Rename File"),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: "New Name"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text("Save"),
            ),
          ],
        );
      },
    );

    if (newName.isNotEmpty) {
      final directory = await getApplicationDocumentsDirectory();
      final newPath = '${directory.path}/$newName';
      file.renameSync(newPath);

      setState(() {
        int index = _mediaFiles.indexOf(file);
        _mediaFiles[index] = File(newPath);
      });

      _saveMedia(); // Save updated media paths
    }
  }

  // Open video player screen
  void _openVideoPlayer(File mediaFile) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoPlayerScreen(mediaFile: mediaFile),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Gallery App")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _mediaFiles.isEmpty
              ? const Center(
                  child: Text('No media found. Please add images/videos.'))
              : GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _mediaFiles.length,
                  itemBuilder: (context, index) {
                    final mediaFile = _mediaFiles[index];
                    return GestureDetector(
                      onTap: () {
                        if (mediaFile.path.endsWith('.mp4')) {
                          _openVideoPlayer(mediaFile);
                        }
                      },
                      child: GridTile(
                        footer: GridTileBar(
                          backgroundColor: Colors.black54,
                          title: Text(
                            mediaFile.uri.pathSegments.last,
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _renameFile(mediaFile),
                          ),
                        ),
                        child: Image.file(mediaFile, fit: BoxFit.cover),
                      ),
                    );
                  },
                ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _pickMedia,
            heroTag: "image",
            child: const Icon(Icons.add_photo_alternate),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            onPressed: _pickVideo,
            heroTag: "video",
            child: const Icon(Icons.video_library),
          ),
        ],
      ),
    );
  }
}
