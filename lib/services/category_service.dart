import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/category.dart';

class CategoryService {
  static final CategoryService _instance = CategoryService._internal();
  factory CategoryService() => _instance;
  
  List<HabitCategory> categories = [];
  
  CategoryService._internal();
  
  Future<void> init() async {
    await _loadCategories();
  }
  
  Future<void> _loadCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final categoriesJson = prefs.getStringList('categories');

    if (categoriesJson == null) {
      // First time - initialize with default categories
      categories = CategoryList.getDefaultCategories();
      await _saveCategories();
    } else {
      categories = categoriesJson
          .map((json) => HabitCategory.fromJson(jsonDecode(json)))
          .toList();
    }
  }
  
  Future<void> _saveCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final categoriesJson = categories
        .map((category) => jsonEncode(category.toJson()))
        .toList();
    await prefs.setStringList('categories', categoriesJson);
  }
  
  Future<List<HabitCategory>> getCategories() async {
    if (categories.isEmpty) {
      await _loadCategories();
    }
    return categories;
  }
  
  Future<HabitCategory> getCategoryById(String id) async {
    if (categories.isEmpty) {
      await _loadCategories();
    }
    
    return categories.firstWhere(
      (category) => category.id == id,
      orElse: () => categories.firstWhere((c) => c.id == 'other'),
    );
  }
  
  Future<void> addCategory(HabitCategory category) async {
    if (categories.isEmpty) {
      await _loadCategories();
    }
    
    categories.add(category);
    await _saveCategories();
  }
  
  Future<void> updateCategory(HabitCategory category) async {
    if (categories.isEmpty) {
      await _loadCategories();
    }
    
    final index = categories.indexWhere((c) => c.id == category.id);
    if (index >= 0) {
      categories[index] = category;
      await _saveCategories();
    }
  }
  
  Future<void> deleteCategory(String id) async {
    if (categories.isEmpty) {
      await _loadCategories();
    }
    
    // Don't allow deleting the "other" category
    if (id == 'other') return;
    
    categories.removeWhere((c) => c.id == id);
    await _saveCategories();
  }
}
