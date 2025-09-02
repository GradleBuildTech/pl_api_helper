class CourseCategory {
  final String id;
  final String name;

  CourseCategory({required this.id, required this.name});

  factory CourseCategory.fromJson(Map<String, dynamic> json) {
    return CourseCategory(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }
}

// Mock Response Model
class CourseCategoryResposne {
  final List<CourseCategory> categories;

  CourseCategoryResposne({required this.categories});

  factory CourseCategoryResposne.fromJson(Map<String, dynamic> json) {
    final cats = (json['categories'] as List<dynamic>)
        .map((e) => CourseCategory.fromJson(e as Map<String, dynamic>))
        .toList();
    return CourseCategoryResposne(categories: cats);
  }
}
