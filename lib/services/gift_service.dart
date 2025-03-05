import 'package:vector_math/vector_math_64.dart' as vmath;
import 'package:flutter/foundation.dart';

class PlacedGift {
  final String modelPath;
  final String name;
  final vmath.Vector3 position;
  final vmath.Vector4 rotation;
  final double scale;
  bool isCollected;

  PlacedGift({
    required this.modelPath,
    required this.name,
    required this.position,
    required this.rotation,
    required this.scale,
    this.isCollected = false,
  });
}

class GiftService extends ChangeNotifier {
  static final GiftService _instance = GiftService._internal();
  
  factory GiftService() {
    return _instance;
  }
  
  GiftService._internal();

  final List<PlacedGift> _placedGifts = [];

  List<PlacedGift> get placedGifts => List.unmodifiable(_placedGifts);

  void addPlacedGift(PlacedGift gift) {
    _placedGifts.add(gift);
    notifyListeners();
  }

  void removePlacedGift(PlacedGift gift) {
    _placedGifts.remove(gift);
    notifyListeners();
  }

  void clearAllGifts() {
    _placedGifts.clear();
    notifyListeners();
  }

  void markGiftAsCollected(PlacedGift gift) {
    final index = _placedGifts.indexOf(gift);
    if (index != -1) {
      _placedGifts[index].isCollected = true;
      notifyListeners();
    }
  }
} 