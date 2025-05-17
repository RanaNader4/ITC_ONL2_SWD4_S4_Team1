import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../models/category.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({Key? key}) : super(key: key);

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  List<HabitCategory> categories = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final categoriesJson = prefs.getStringList('categories');

    if (categoriesJson == null) {
      // First time - initialize with default categories
      categories = CategoryList.getDefaultCategories();
      _saveCategories();
    } else {
      categories = categoriesJson
          .map((json) => HabitCategory.fromJson(jsonDecode(json)))
          .toList();
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _saveCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final categoriesJson = categories
        .map((category) => jsonEncode(category.toJson()))
        .toList();
    await prefs.setStringList('categories', categoriesJson);
  }

  void _addCategory() {
    showDialog(
      context: context,
      builder: (context) => CategoryDialog(
        onSave: (category) {
          setState(() {
            categories.add(category);
            _saveCategories();
          });
        },
      ),
    );
  }

  void _editCategory(int index) {
    showDialog(
      context: context,
      builder: (context) => CategoryDialog(
        category: categories[index],
        onSave: (updatedCategory) {
          setState(() {
            categories[index] = updatedCategory;
            _saveCategories();
          });
        },
      ),
    );
  }

  void _deleteCategory(int index) {
    // Don't allow deleting the "Other" category
    if (categories[index].id == 'other') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('The "Other" category cannot be deleted'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text(
          'Are you sure you want to delete "${categories[index].name}"? '
          'All habits in this category will be moved to "Other".',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                categories.removeAt(index);
                _saveCategories();
              });
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        backgroundColor: Colors.red,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : categories.isEmpty
              ? const Center(child: Text('No categories yet'))
              : ListView.builder(
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: category.color,
                          child: Icon(
                            category.icon,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(category.name),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _editCategory(index),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _deleteCategory(index),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCategory,
        backgroundColor: Colors.red,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class CategoryDialog extends StatefulWidget {
  final HabitCategory? category;
  final Function(HabitCategory) onSave;

  const CategoryDialog({
    Key? key,
    this.category,
    required this.onSave,
  }) : super(key: key);

  @override
  State<CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<CategoryDialog> {
  late TextEditingController _nameController;
  late IconData _selectedIcon;
  late Color _selectedColor;
  String? _nameError;

  final List<IconData> _availableIcons = [
    Icons.favorite,
    Icons.fitness_center,
    Icons.work,
    Icons.school,
    Icons.self_improvement,
    Icons.people,
    Icons.book,
    Icons.sports_soccer,
    Icons.music_note,
    Icons.brush,
    Icons.restaurant,
    Icons.local_drink,
    Icons.home,
    Icons.more_horiz,
  ];

  final List<Color> _availableColors = [
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.brown,
    Colors.grey,
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.category?.name ?? '',
    );
    _selectedIcon = widget.category?.icon ?? Icons.more_horiz;
    _selectedColor = widget.category?.color ?? Colors.blue;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _validateAndSave() {
    final name = _nameController.text.trim();
    
    if (name.isEmpty) {
      setState(() {
        _nameError = 'Category name cannot be empty';
      });
      return;
    }
    
    setState(() {
      _nameError = null;
    });

    final category = HabitCategory(
      id: widget.category?.id ?? name.toLowerCase().replaceAll(' ', '_'),
      name: name,
      icon: _selectedIcon,
      color: _selectedColor,
    );

    widget.onSave(category);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.category == null ? 'Add Category' : 'Edit Category'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Category Name',
                errorText: _nameError,
              ),
            ),
            const SizedBox(height: 16),
            const Text('Select Icon'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableIcons.map((icon) {
                final isSelected = icon == _selectedIcon;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedIcon = icon;
                    });
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isSelected ? _selectedColor : Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      color: isSelected ? Colors.white : Colors.grey[600],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            const Text('Select Color'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableColors.map((color) {
                final isSelected = color == _selectedColor;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedColor = color;
                    });
                  },
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: Colors.black, width: 2)
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _validateAndSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
