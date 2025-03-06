import 'dart:math' as math;
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

/// 寻找礼物屏幕
/// 允许用户在AR环境中寻找和收集虚拟礼物
class FindGiftScreen extends StatefulWidget {
  const FindGiftScreen({super.key});

  @override
  State<FindGiftScreen> createState() => _FindGiftScreenState();
}

class ParticleModel {
  late Offset position;
  late Color color;
  late double speed;
  late double theta;
  late double radius;

  ParticleModel({
    required this.position,
    required this.color,
    required this.speed,
    required this.theta,
    required this.radius,
  });
}

class CollectionAnimation extends StatefulWidget {
  final VoidCallback onComplete;
  final Offset position;

  const CollectionAnimation({
    Key? key,
    required this.onComplete,
    required this.position,
  }) : super(key: key);

  @override
  State<CollectionAnimation> createState() => _CollectionAnimationState();
}

class _CollectionAnimationState extends State<CollectionAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<ParticleModel> particles;
  final int numberOfParticles = 20;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _initializeParticles();
    _controller.forward().then((_) {
      widget.onComplete();
    });
  }

  void _initializeParticles() {
    particles = List.generate(numberOfParticles, (index) {
      final random = math.Random();
      return ParticleModel(
        position: widget.position,
        color: Color.fromRGBO(
          random.nextInt(255),
          random.nextInt(255),
          random.nextInt(255),
          1,
        ),
        speed: random.nextDouble() * 100 + 50,
        theta: random.nextDouble() * 2 * math.pi,
        radius: random.nextDouble() * 10 + 5,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: ParticlePainter(
            particles: particles,
            progress: _controller.value,
            position: widget.position,
          ),
        );
      },
    );
  }
}

class ParticlePainter extends CustomPainter {
  final List<ParticleModel> particles;
  final double progress;
  final Offset position;

  ParticlePainter({
    required this.particles,
    required this.progress,
    required this.position,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      final paint = Paint()
        ..color = particle.color.withOpacity(1 - progress)
        ..style = PaintingStyle.fill;

      final radius = particle.radius * (1 - progress);
      final offset = Offset(
        position.dx + math.cos(particle.theta) * particle.speed * progress,
        position.dy + math.sin(particle.theta) * particle.speed * progress,
      );

      canvas.drawCircle(offset, radius, paint);
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) => true;
}

class _FindGiftScreenState extends State<FindGiftScreen> {
  // AR会话管理器，负责管理AR会话的生命周期
  ARSessionManager? arSessionManager;
  // AR对象管理器，负责管理AR场景中的3D对象
  ARObjectManager? arObjectManager;
  // AR锚点管理器，负责管理AR锚点
  ARAnchorManager? arAnchorManager;
  // AR位置管理器，负责管理AR中的地理位置
  ARLocationManager? arLocationManager;
  
  // 存储场景中放置的AR节点
  List<ARNode> nodes = [];
  // 可寻找的礼物模型列表，包含路径、名称和收集状态
  List<Map<String, dynamic>> giftModels = [
    {
      'path': 'assets/models/giftbox.glb',
      'name': '礼物盒',
      'collected': false,
      'position': vmath.Vector3(2.0, 0.0, -2.0),
      'isVisible': false,
      'scale': 0.3,
    },
    {
      'path': 'assets/models/treasure_coins_chest.glb',
      'name': '宝藏箱',
      'collected': false,
      'position': vmath.Vector3(-1.5, 0.0, -3.0),
      'isVisible': false,
      'scale': 1.0,
    },
    {
      'path': 'assets/models/cute_shark_animated_character.glb',
      'name': '可爱鲨鱼',
      'collected': false,
      'position': vmath.Vector3(0.0, 0.0, -4.0),
      'isVisible': false,
      'scale': 1.0,
    },
    {
      'path': 'assets/models/free_medieval_sword.glb',
      'name': '中世纪宝剑',
      'collected': false,
      'position': vmath.Vector3(1.5, 0.0, -2.5),
      'isVisible': false,
      'scale': 1.5,
    },
  ];
  // 当前选中的模型索引
  int selectedModelIndex = 0;
  // 是否正在寻宝模式
  bool isHunting = false;
  double? distanceToTarget;
  vmath.Vector3? userPosition;
  bool isCollecting = false;
  Offset? collectionPosition;

  /// 请求并检查相机权限
  Future<bool> _checkAndRequestCameraPermission() async {
    // 检查当前权限状态
    PermissionStatus status = await Permission.camera.status;
    
    if (status.isDenied) {
      // 如果权限被拒绝，请求权限
      status = await Permission.camera.request();
    }
    
    if (status.isPermanentlyDenied) {
      // 如果权限被永久拒绝，显示对话框引导用户去设置中心开启
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('需要相机权限'),
            content: const Text('AR功能需要相机权限才能使用。请在设置中开启相机权限。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () {
                  openAppSettings();
                  Navigator.pop(context);
                },
                child: const Text('去设置'),
              ),
            ],
          ),
        );
      }
      return false;
    }
    
    return status.isGranted;
  }

  @override
  void initState() {
    super.initState();
    // 初始化时检查权限
    _initializeWithPermissionCheck();
    
    // 监听礼物服务变化
    GiftService().addListener(_onGiftServiceChanged);
  }

  Future<void> _initializeWithPermissionCheck() async {
    final hasPermission = await _checkAndRequestCameraPermission();
    if (!hasPermission && mounted) {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    GiftService().removeListener(_onGiftServiceChanged);
    arSessionManager?.dispose();
    super.dispose();
  }

  void _onGiftServiceChanged() {
    if (mounted) {
      setState(() {
        // 更新UI
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('寻找礼物'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Stack(
        children: [
          _buildARView(),
          _buildStatusBar(),
          _buildDistanceIndicator(),
          _buildGiftSelector(),
          if (isCollecting && collectionPosition != null)
            CollectionAnimation(
              position: collectionPosition!,
              onComplete: () {
                setState(() {
                  isCollecting = false;
                  collectionPosition = null;
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildStatusBar() {
    final placedGifts = GiftService().placedGifts;
    final String statusText;
    
    if (placedGifts.isEmpty) {
      statusText = '请先在放置礼物界面放置一些礼物';
    } else {
      statusText = '正在寻找: ${placedGifts[selectedModelIndex].name}\n环顾四周，点击礼物来收集它';
    }

    return Positioned(
      top: 10,
      left: 10,
      right: 10,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          statusText,
          style: const TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildDistanceIndicator() {
    return const SizedBox.shrink();
  }

  Widget _buildGiftSelector() {
    final placedGifts = GiftService().placedGifts;
    
    if (placedGifts.isEmpty) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            '还没有放置任何礼物\n请先在放置礼物界面放置一些礼物',
            style: TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Text(
                '选择要寻找的礼物',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: placedGifts.length,
                itemBuilder: (context, index) {
                  final gift = placedGifts[index];
                  return GestureDetector(
                    onTap: () => _selectGift(index),
                    child: Container(
                      width: 100,
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: selectedModelIndex == index
                            ? Colors.blue.withOpacity(0.3)
                            : Colors.grey.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selectedModelIndex == index
                              ? Colors.blue
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            gift.isCollected ? Icons.check_circle : Icons.card_giftcard,
                            color: gift.isCollected ? Colors.green : Colors.white,
                            size: 30,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            gift.name,
                            style: const TextStyle(color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildARView() {
    return ARView(
      onARViewCreated: onARViewCreated,
      planeDetectionConfig: PlaneDetectionConfig.horizontalAndVertical,
    );
  }

  /// AR视图创建完成的回调函数
  /// 初始化AR会话和各种管理器
  void onARViewCreated(
      ARSessionManager sessionManager,
      ARObjectManager objectManager,
      ARAnchorManager anchorManager,
      ARLocationManager locationManager) {
    arSessionManager = sessionManager;
    arObjectManager = objectManager;
    arAnchorManager = anchorManager;
    arLocationManager = locationManager;

    arSessionManager!.onInitialize(
      showFeaturePoints: true,
      showPlanes: true,
      customPlaneTexturePath: "assets/images/triangle.png",
      handlePans: true,
      handleRotation: true,
    );
    
    arObjectManager!.onInitialize();
    
    // 设置点击事件处理
    arSessionManager!.onPlaneOrPointTap = _onPlaneOrPointTapped;

    // 自动开始寻宝
    setState(() {
      isHunting = true;
    });
    _startHunting();
  }

  Future<void> _startHunting() async {
    final placedGifts = GiftService().placedGifts;
    if (placedGifts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('还没有放置任何礼物，请先放置礼物'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (selectedModelIndex >= placedGifts.length) {
      selectedModelIndex = 0;
    }

    final targetGift = placedGifts[selectedModelIndex];
    if (targetGift.isCollected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('这个礼物已经被收集了，请选择其他礼物')),
      );
      return;
    }
    
    // 在预设位置放置礼物
    final newNode = ARNode(
      type: NodeType.localGLTF2,
      uri: targetGift.modelPath,
      scale: vmath.Vector3.all(targetGift.scale),
      position: targetGift.position,
      rotation: targetGift.rotation,
    );

    bool? didAddNode = await arObjectManager?.addNode(newNode);
    if (didAddNode!) {
      nodes.add(newNode);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('开始寻找${targetGift.name}！环顾四周来找到它')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('模型加载失败：${targetGift.modelPath}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _stopHunting() {
    _removeAllNodes();
  }

  Future<void> _onPlaneOrPointTapped(List<ARHitTestResult> hitTestResults) async {
    if (!isHunting || hitTestResults.isEmpty) return;
    
    final hit = hitTestResults.first;
    final hitPosition = hit.worldTransform.getTranslation();
    
    // 检查是否点击到了礼物
    for (final node in nodes) {
      final nodePosition = node.position;
      final distance = (hitPosition - nodePosition).length;
      
      // 如果点击位置在礼物附近（50厘米内）
      if (distance < 0.5) {
        await _collectGift();
        break;
      }
    }
  }

  void _selectGift(int index) {
    setState(() {
      selectedModelIndex = index;
      // 移除当前显示的礼物节点
      _removeAllNodes();
      // 开始寻找新选择的礼物
      _startHunting();
    });
  }

  Future<void> _collectGift() async {
    final placedGifts = GiftService().placedGifts;
    if (selectedModelIndex < placedGifts.length) {
      final gift = placedGifts[selectedModelIndex];
      
      // 获取礼物在屏幕上的位置
      if (nodes.isNotEmpty) {
        final node = nodes.first;
        
        // 设置动画位置为屏幕中心
        final size = MediaQuery.of(context).size;
        setState(() {
          isCollecting = true;
          collectionPosition = Offset(size.width / 2, size.height / 2);
        });

        // 播放收集动画
        await _playCollectionAnimation(node);
      }

      // 标记礼物为已收集
      GiftService().markGiftAsCollected(gift);
      
      // 显示成功消息
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('恭喜！你找到了${gift.name}！'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
      
      // 移除所有节点
      _removeAllNodes();
      
      // 自动切换到下一个未收集的礼物
      _switchToNextUncollectedGift();
    }
  }

  Future<void> _playCollectionAnimation(ARNode node) async {
    // 缩放动画
    const duration = Duration(milliseconds: 800);
    
    // 开始缩放动画
    final startScale = node.scale;
    final endScale = vmath.Vector3(0, 0, 0);
    
    // 使用更多的步骤使动画更平滑
    for (double t = 0; t <= 1.0; t += 0.05) {
      if (!mounted) break;
      
      // 使用缓动函数使动画更自然
      final easedT = Curves.easeInOut.transform(t);
      
      // 计算当前缩放
      final scale = vmath.Vector3(
        startScale.x * (1 - easedT) + endScale.x * easedT,
        startScale.y * (1 - easedT) + endScale.y * easedT,
        startScale.z * (1 - easedT) + endScale.z * easedT,
      );
      
      // 应用变换
      node.scale = scale;
      
      // 等待一小段时间
      await Future.delayed(const Duration(milliseconds: 30));
    }
    
    // 确保最终状态
    node.scale = endScale;
  }

  void _switchToNextUncollectedGift() {
    final placedGifts = GiftService().placedGifts;
    if (placedGifts.isEmpty) return;

    // 从当前索引开始查找下一个未收集的礼物
    int nextIndex = selectedModelIndex;
    bool found = false;
    
    for (int i = 0; i < placedGifts.length; i++) {
      nextIndex = (selectedModelIndex + i) % placedGifts.length;
      if (!placedGifts[nextIndex].isCollected) {
        found = true;
        break;
      }
    }

    if (found) {
      setState(() {
        selectedModelIndex = nextIndex;
        _startHunting();
      });
    } else {
      // 所有礼物都已收集
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('恭喜！你已经收集了所有礼物！'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _removeAllNodes() async {
    for (final node in nodes) {
      await arObjectManager?.removeNode(node);
    }
    nodes.clear();
  }
}