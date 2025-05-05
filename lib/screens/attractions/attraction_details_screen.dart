import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/attraction.dart';
import '../../models/review.dart';

class AttractionDetailsScreen extends StatefulWidget {
  final Attraction attraction;

  const AttractionDetailsScreen({Key? key, required this.attraction})
      : super(key: key);

  @override
  State<AttractionDetailsScreen> createState() => _AttractionDetailsScreenState();
}

class _AttractionDetailsScreenState extends State<AttractionDetailsScreen> with SingleTickerProviderStateMixin {
  List<Review> reviews = [];
  final commentController = TextEditingController();
  int rating = 5;
  File? selectedImage;
  bool isLoading = false;
  late TabController _tabController;
  double averageRating = 0.0;

  final _storage = const FlutterSecureStorage();
  final Dio _dio = Dio();
  final String baseUrl = 'http://10.0.2.2:8080'; // для эмулятора
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    loadUserId();
    fetchReviews();
  }

  @override
  void dispose() {
    _tabController.dispose();
    commentController.dispose();
    super.dispose();
  }

  Future<void> loadUserId() async {
    final storage = FlutterSecureStorage();
    currentUserId = await storage.read(key: 'user_id');
    setState(() {}); // чтобы обновить UI после загрузки
  }

  Future<String?> getCurrentUserId() async {
    final storage = FlutterSecureStorage();
    return await storage.read(key: 'user_id');
  }

  Future<void> fetchReviews() async {
    try {
      setState(() => isLoading = true);
      final token = await _storage.read(key: 'session_token');
      if (token == null) throw Exception('Нет токена');

      final res = await _dio.get(
        '$baseUrl/reviews?attraction_id=${widget.attraction.id}',
        options: Options(
          headers: {
            'Cookie': 'session_token=$token',
          },
        ),
      );

      // 🛠️ Явный парсинг JSON, если Dio вернул String
      final data = res.data is String ? jsonDecode(res.data) : res.data;

      print('📦 Ответ сервера: $data');

      if (data is List) {
        final parsed = data.map((json) => Review.fromJson(json)).toList();

        // Вычисление среднего рейтинга
        double sum = 0;
        for (var review in parsed) {
          sum += review.rating;
        }

        setState(() {
          reviews = parsed;
          averageRating = parsed.isEmpty ? 0 : sum / parsed.length;
          isLoading = false;
        });
      } else {
        print('⚠️ Неверный формат ответа: $data');
        setState(() => isLoading = false);
        throw Exception('Неверный формат ответа. Ожидался список.');
      }
    } catch (e) {
      setState(() => isLoading = false);
      print('❌ Ошибка при загрузке отзывов: $e');
    }
  }

  Future<void> submitReview() async {
    setState(() => isLoading = true);

    final token = await _storage.read(key: 'session_token');
    if (token == null) {
      showSnack('Вы не вошли в систему');
      setState(() => isLoading = false);
      return;
    }

    try {
      final formData = FormData.fromMap({
        'attraction_id': widget.attraction.id.toString(),
        'rating': rating.toString(),
        'comment': commentController.text,
        if (selectedImage != null)
          'image': await MultipartFile.fromFile(
            selectedImage!.path,
            filename: selectedImage!.path.split('/').last,
          ),
      });

      final res = await _dio.post(
        '$baseUrl/reviews',
        data: formData,
        options: Options(
          headers: {
            'Cookie': 'session_token=$token',
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      if (res.statusCode == 201) {
        showSnack('✅ Отзыв отправлен!');
        commentController.clear();
        selectedImage = null;
        fetchReviews();
      } else {
        showSnack('❌ Ошибка при отправке отзыва');
      }
    } catch (e) {
      showSnack('❌ Ошибка сети: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showEditDialog(Review review) {
    final TextEditingController commentController =
    TextEditingController(text: review.comment);
    int updatedRating = review.rating;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Редактировать отзыв"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: commentController),
            DropdownButton<int>(
              value: updatedRating,
              onChanged: (val) => setState(() => updatedRating = val!),
              items: [1, 2, 3, 4, 5]
                  .map((r) => DropdownMenuItem(value: r, child: Text("⭐ $r")))
                  .toList(),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Отмена")),
          ElevatedButton(
            onPressed: () async {
              await _updateReview(review.id, updatedRating, commentController.text);
              Navigator.pop(context);
              fetchReviews(); // перезагрузка списка
            },
            child: const Text("Сохранить"),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(Review review) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Удалить отзыв?"),
        content: const Text("Вы уверены, что хотите удалить этот отзыв?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Отмена")),
          ElevatedButton(
            onPressed: () async {
              await _deleteReview(review.id);
              Navigator.pop(context);
              fetchReviews();
            },
            child: const Text("Удалить"),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteReview(int id) async {
    final token = await _storage.read(key: 'session_token');
    final res = await _dio.delete(
      '$baseUrl/reviews/$id',
      options: Options(
        headers: {
          'Cookie': 'session_token=$token',
        },
      ),
    );
    print("🗑 Отзыв удалён: ${res.statusCode}");
  }

  Future<void> _updateReview(int id, int rating, String comment) async {
    final token = await _storage.read(key: 'session_token');
    final response = await _dio.put(
      '$baseUrl/reviews/$id',
      data: {
        "rating": rating,
        "comment": comment,
      },
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Cookie': 'session_token=$token',
        },
      ),
    );
    print('🔄 Review updated: ${response.statusCode}');
  }

  void showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        selectedImage = File(picked.path);
      });
    }
  }

  // Виджет для отображения рейтинга звездами
  Widget _buildRatingStars(double rating) {
    return Row(
      children: List.generate(5, (index) {
        if (index < rating.floor()) {
          return const Icon(Icons.star, color: Colors.amber, size: 18);
        } else if (index == rating.floor() && rating % 1 > 0) {
          return const Icon(Icons.star_half, color: Colors.amber, size: 18);
        } else {
          return const Icon(Icons.star_border, color: Colors.amber, size: 18);
        }
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.attraction;

    return Scaffold(
      appBar: AppBar(
        title: Text(a.title),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Основное изображение достопримечательности
          if (a.imageUrl.isNotEmpty)
            SizedBox(
              height: 200,
              width: double.infinity,
              child: Image.network(
                a.imageUrl,
                fit: BoxFit.cover,
              ),
            ),

          // Контрастная панель вкладок
          Container(
            color: Colors.blue, // Фон для вкладок
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              tabs: [
                const Tab(
                  icon: Icon(Icons.info_outline),
                  text: "Description",
                ),
                Tab(
                  icon: const Icon(Icons.star_outline),
                  text: "Reviews (${reviews.length})",
                ),
              ],
            ),
          ),

          // Содержимое вкладок
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Вкладка "Об объекте"
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a.description,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),

                // Вкладка "Отзывы"
                isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Секция со средним рейтингом в стиле 2ГИС
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: averageRating >= 4.5
                                        ? Colors.green
                                        : averageRating >= 3.5
                                        ? Colors.orange
                                        : Colors.red,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    averageRating.toStringAsFixed(1),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildRatingStars(averageRating),
                                    const SizedBox(height: 4),
                                    Text(
                                      "${reviews.length} ${_getReviewsText(reviews.length)}",
                                      style: const TextStyle(
                                        color: Colors.black54,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(20),
                                    ),
                                  ),
                                  builder: (context) => _buildReviewForm(),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(45),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text("Написать отзыв"),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Список отзывов
                      ...reviews.map(
                            (r) => Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundImage: r.imageUrl.isNotEmpty
                                          ? NetworkImage(r.imageUrl)
                                          : null,
                                      child: r.imageUrl.isEmpty
                                          ? const Icon(Icons.person)
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            r.username,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              ...List.generate(
                                                r.rating,
                                                    (index) => const Icon(
                                                  Icons.star,
                                                  color: Colors.amber,
                                                  size: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (currentUserId != null && r.userId.toString() == currentUserId)
                                      PopupMenuButton<String>(
                                        onSelected: (value) {
                                          if (value == 'edit') {
                                            _showEditDialog(r);
                                          } else if (value == 'delete') {
                                            _confirmDelete(r);
                                          }
                                        },
                                        itemBuilder: (context) => [
                                          const PopupMenuItem(
                                            value: 'edit',
                                            child: Text('Редактировать'),
                                          ),
                                          const PopupMenuItem(
                                            value: 'delete',
                                            child: Text('Удалить'),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  r.comment,
                                  style: const TextStyle(fontSize: 14),
                                ),
                                if (r.imageUrl.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      r.imageUrl,
                                      height: 180,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.broken_image),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),

                      if (reviews.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 32),
                            child: Text(
                              "Отзывов пока нет. Будьте первым!",
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewForm() {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Оставить отзыв",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text("Ваша оценка"),
            const SizedBox(height: 8),
            Row(
              children: List.generate(
                5,
                    (index) => IconButton(
                  onPressed: () {
                    setState(() => rating = index + 1);
                    Navigator.pop(context);
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      builder: (context) => _buildReviewForm(),
                    );
                  },
                  icon: Icon(
                    index < rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 32,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: commentController,
              decoration: const InputDecoration(
                labelText: "Ваш комментарий",
                border: OutlineInputBorder(),
                hintText: "Поделитесь своими впечатлениями",
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: pickImage,
                    icon: const Icon(Icons.photo_camera),
                    label: const Text("Добавить фото"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[200],
                      foregroundColor: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isLoading
                        ? null
                        : () {
                      submitReview();
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(isLoading ? "Отправка..." : "Отправить"),
                  ),
                ),
              ],
            ),
            if (selectedImage != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 16),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        "Выбрано фото: ${selectedImage!.path.split('/').last}",
                        style: const TextStyle(fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getReviewsText(int count) {
    if (count % 10 == 1 && count % 100 != 11) {
      return "отзыв";
    } else if ([2, 3, 4].contains(count % 10) && ![12, 13, 14].contains(count % 100)) {
      return "отзыва";
    } else {
      return "отзывов";
    }
  }
}