import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:camera/camera.dart';
import 'package:firebase_core/firebase_core.dart';

List<CameraDescription> cameras = [];
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化 Firebase（用于用户认证、数据存储、推送通知等）
  await Firebase.initializeApp();

  // 获取设备上的摄像头
  cameras = await availableCameras();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}
class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  // 三个主要页面：首页、拍照识别、地图
  static List<Widget> _widgetOptions = <Widget>[
    HomeScreen(),
    CameraScreen(),
    MapScreen(),
  ];

void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AI Pollinator Guardian'),
      ),
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '首页',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera),
            label: '拍照识别',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: '地图',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.green,
        onTap: _onItemTapped,
      ),
    );
  }
}
class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
         padding: const EdgeInsets.all(16.0),
         child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
               Text(
                 '欢迎使用 AI Pollinator Guardian',
                 style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                 textAlign: TextAlign.center,
               ),
               SizedBox(height: 16),
               Text(
                 '通过拍照识别传粉者，上传目击记录，共同保护生物多样性与粮食安全。',
                 style: TextStyle(fontSize: 16),
                 textAlign: TextAlign.center,
               ),
               SizedBox(height: 32),
               ElevatedButton(
                  onPressed: () {
                     // 后续可跳转到项目详细介绍或使用说明页面
                  },
                  child: Text('了解更多'),
               ),
            ],
         ),
      ),
    );
  }
}

/// 拍照识别页面，使用摄像头拍照并调用 AI 模型识别传粉者
class CameraScreen extends StatefulWidget {
  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  String _detectionResult = '';

  @override
  void initState() {
    super.initState();
    if (cameras.isNotEmpty) {
      _controller = CameraController(cameras[0], ResolutionPreset.medium);
      _initializeControllerFuture = _controller?.initialize();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  /// 拍照并调用 AI 检测（后续接入 Google Cloud AutoML Vision）
  Future<void> _captureAndDetect() async {
    try {
      await _initializeControllerFuture;
      final image = await _controller?.takePicture();

      // TODO: 调用 Google Cloud AutoML Vision 进行传粉者识别
      // 模拟 AI 检测结果
      String detectedSpecies = await detectPollinator(image?.path);
      setState(() {
        _detectionResult = detectedSpecies;
      });

      // TODO: 上传图像与检测结果到 Firebase Firestore
    } catch (e) {
      print(e);
    }
  }

  /// 模拟的传粉者检测函数，实际使用时替换为 AI 模型调用逻辑
  Future<String> detectPollinator(String? imagePath) async {
    await Future.delayed(Duration(seconds: 2));
    return "检测到：大黄蜂"; // 模拟返回结果
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initializeControllerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return Column(
            children: [
              AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: CameraPreview(_controller!),
              ),
              SizedBox(height: 8),
              ElevatedButton(
                onPressed: _captureAndDetect,
                child: Text('拍照并识别'),
              ),
              SizedBox(height: 16),
              Text(
                _detectionResult,
                style: TextStyle(fontSize: 18),
              ),
            ],
          );
        } else {
          return Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}

/// 地图页面，展示传粉者目击地点（使用 Google Maps API）
class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // 初始地图位置（示例坐标，可根据实际数据调整）
  static const LatLng _center = LatLng(37.42796133580664, -122.085749655962);
  late GoogleMapController mapController;

  // 示例标记，后续可通过 Firebase 获取实时数据更新
  final Set<Marker> _markers = {
    Marker(
      markerId: MarkerId('sighting1'),
      position: _center,
      infoWindow: InfoWindow(
        title: '传粉者目击点',
        snippet: '大黄蜂在此出现',
      ),
    ),
  };

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      onMapCreated: _onMapCreated,
      initialCameraPosition: CameraPosition(
        target: _center,
        zoom: 11.0,
      ),
      markers: _markers,
    );
  }
}
