import 'package:ar_flutter_plugin/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin/models/ar_hittest_result.dart';
import 'package:flutter/material.dart';
import 'package:ar_flutter_plugin/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin/datatypes/node_types.dart';
import 'package:ar_flutter_plugin/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin/models/ar_node.dart';
import 'package:vector_math/vector_math_64.dart' as vmath;
import 'package:permission_handler/permission_handler.dart';
import '../services/gift_service.dart';

/// 放置礼物屏幕
/// 允许用户在AR环境中放置虚拟礼物模型
class PlaceGiftScreen extends StatefulWidget {
  const PlaceGiftScreen({super.key});

  @override
  State<PlaceGiftScreen> createState() => _PlaceGiftScreenState();
}

class _PlaceGiftScreenState extends State<PlaceGiftScreen> {
  // AR相關管理器
  ARSessionManager? arSessionManager;
  ARObjectManager? arObjectManager;
  ARAnchorManager? arAnchorManager;
  ARLocationManager? arLocationManager;
  
  // 存储场景中放置的AR节点
  List<ARNode> nodes = [];
  // 可用的礼物模型列表
  List<String> giftModels = [
    'assets/models/giftbox.glb',
    'assets/models/treasure_coins_chest.glb',
    'assets/models/cute_shark_animated_character.glb',
    'assets/models/free_medieval_sword.glb',
  ];

  // 模型配置
  final Map<String, Map<String, dynamic>> modelConfigs = {

    'assets/models/treasure_coins_chest.glb': {
      'name': '寶藏箱',
      'scale': 0.5,
      'rotation': [1.0, 0.0, 0.0, 0.0],
            'yOffset': 0.0,  // 根据实际需要调整

    },
    'assets/models/cute_shark_animated_character.glb': {
      'name': '可愛鯊魚',
      'scale': 1.0,
      'rotation': [1.0, 0.0, 0.0, 0.0],
    },
    'assets/models/giftbox.glb': {
      'name': '禮物盒',
      'scale': 1.3,
      'rotation': [1.0, 0.0, 0.0, 0.0],
      'yOffset': 0.0,  // 根据实际需要调整
    },
    'assets/models/free_medieval_sword.glb': {
      'name': '中世紀寶劍',
      'scale': 2.5,
      'rotation': [1.0, 0.0, 0.0, 0.0],
    },
  };

  int selectedModelIndex = 0;
  bool isARViewCreated = false;
  bool isPlaneDetected = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('放置礼物'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Stack(
        children: [
          if (isARViewCreated)
            ARView(
              onARViewCreated: onARViewCreated,
              planeDetectionConfig: PlaneDetectionConfig.horizontalAndVertical,
            )
          else
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('需要相機權限來使用 AR 功能'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => _requestCameraPermission(),
                    child: const Text('授權使用相機'),
                  ),
                ],
              ),
            ),
          if (isARViewCreated) ...[
            // 頂部提示信息
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isPlaneDetected 
                    ? '點擊檢測到的平面來放置${modelConfigs[giftModels[selectedModelIndex]]?['name'] ?? '禮物'}'
                    : '請將相機對準平面進行掃描...',
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            // 當前選中的模型信息
            Positioned(
              top: 80,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '當前選擇：${modelConfigs[giftModels[selectedModelIndex]]?['name'] ?? '未知模型'}',
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            // 底部操作按钮
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 30.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [

                    FloatingActionButton(
                      onPressed: _onRemoveGift,
                      heroTag: 'place_gift_remove_btn',
                      backgroundColor: Colors.red,
                      child: const Icon(Icons.remove),
                    ),
                    FloatingActionButton(
                      onPressed: _onSwitchGiftModel,
                      heroTag: 'place_gift_switch_model_btn',
                      backgroundColor: Colors.blue,
                      child: const Icon(Icons.swap_horiz),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// AR视图创建完成的回调函数
  void onARViewCreated(
      ARSessionManager sessionManager,
      ARObjectManager objectManager,
      ARAnchorManager anchorManager,
      ARLocationManager locationManager) {
    arSessionManager = sessionManager;
    arObjectManager = objectManager;
    arAnchorManager = anchorManager;
    arLocationManager = locationManager;

    // 初始化AR会话
    arSessionManager!.onInitialize(
      showFeaturePoints: true,
      showPlanes: true,
      customPlaneTexturePath: "assets/images/triangle.png",
      showWorldOrigin: false,
      handlePans: true,
      handleRotation: true,
    );
    arObjectManager!.onInitialize();

    // 设置平面检测回调
    arSessionManager!.onPlaneOrPointTap = (List<ARHitTestResult> hits) {
      if (hits.isNotEmpty && !isPlaneDetected) {
        setState(() {
          isPlaneDetected = true;
        });
      }
      _handlePlaneOrPointTapped(hits);
    };
    
    print('AR 視圖已創建並初始化完成');
  }

  /// 处理平面或点击事件
  /// 当用户点击AR视图中的平面时调用
  Future<void> _handlePlaneOrPointTapped(List<ARHitTestResult> hitTestResults) async {
    if (hitTestResults.isEmpty) return;
    final hit = hitTestResults.first;
    _placeGift(hit);
  }

  /// 在点击位置放置礼物
  Future<void> _placeGift(ARHitTestResult hit) async {
    try {
      final currentModel = giftModels[selectedModelIndex];
      final config = modelConfigs[currentModel];
      
      if (config == null) {
        print('未找到模型配置：$currentModel');
        return;
      }

      // 获取点击位置的变换矩阵
      final transform = hit.worldTransform;
      final position = transform.getTranslation();
      
      // 调整Y轴位置，确保模型放置在平面上
      position.y += (config['yOffset'] ?? 0.0);
      
      print('放置位置: $position');
      print('正在加載模型: $currentModel');
      
      // 创建一个新的AR节点，使用调整后的位置
      final newNode = ARNode(
        type: NodeType.localGLTF2,
        uri: currentModel,
        scale: vmath.Vector3.all(config['scale']),
        position: position,
        rotation: vmath.Vector4.array(config['rotation']),
      );
      
      // 将节点添加到AR场景中
      bool? didAddNode = await arObjectManager?.addNode(newNode);
      print('模型加載狀態: $didAddNode');
      
      if (didAddNode!) {
        nodes.add(newNode);
        
        // 添加到礼物服务
        final placedGift = PlacedGift(
          modelPath: currentModel,
          name: config['name'],
          position: position,
          rotation: vmath.Vector4.array(config['rotation']),
          scale: config['scale'],
        );
        GiftService().addPlacedGift(placedGift);
      
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('模型加載失敗，請重試'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('放置模型時發生錯誤: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('放置模型時發生錯誤: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 切换礼物模型按钮点击事件处理
  void _onSwitchGiftModel() {
    setState(() {
      selectedModelIndex = (selectedModelIndex + 1) % giftModels.length;
    });
    
    final currentModel = giftModels[selectedModelIndex];
    final config = modelConfigs[currentModel];
    
    if (config != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已切換到${config['name']}'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  /// 移除礼物按钮点击事件处理
  void _onRemoveGift() {
    if (nodes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('沒有可移除的禮物'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // 移除最后放置的礼物
    final lastNode = nodes.last;
    arObjectManager?.removeNode(lastNode);
    nodes.removeLast();
    
    // 从礼物服务中移除
    final placedGifts = GiftService().placedGifts;
    if (placedGifts.isNotEmpty) {
      GiftService().removePlacedGift(placedGifts.last);
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('已移除最後放置的禮物'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  void dispose() {
    arSessionManager?.dispose();
    super.dispose();
  }

  /// 點擊添加按鈕時觸發放置禮物
  void _onPlaceGift() {
    if (!isPlaneDetected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('請先對準平面再放置禮物'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    arSessionManager?.onPlaneOrPointTap?.call([]);
  }

  /// 請求相機權限
  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      setState(() => isARViewCreated = true);
    }
  }
}