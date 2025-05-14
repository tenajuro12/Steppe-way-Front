import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/food.dart';
import '../../services/food_service.dart';
import 'add_review_screen.dart';
import 'review_image_gallery_screen.dart';

class FoodReviewsScreen extends StatefulWidget {
  final Place place;

  const FoodReviewsScreen({Key? key, required this.place}) : super(key: key);

  @override
  _FoodReviewsScreenState createState() => _FoodReviewsScreenState();
}

class _FoodReviewsScreenState extends State<FoodReviewsScreen> {
  List<FoodReview> _reviews = [];
  bool _isLoading = false;
  int _currentPage = 1;
  bool _hasMorePages = true;
  final int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _reviews = List.from(widget.place.reviews);
    if (_reviews.length < _pageSize) {
      _hasMorePages = false;
    } else {
      // Load additional reviews if needed
      _loadMoreReviews();
    }
  }

  Future<void> _loadMoreReviews() async {
    if (!_hasMorePages || _isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final newReviews = await FoodService.getPlaceReviews(
        widget.place.id,
        page: _currentPage + 1,
        pageSize: _pageSize,
      );

      setState(() {
        if (newReviews.isEmpty) {
          _hasMorePages = false;
        } else {
          _reviews.addAll(newReviews);
          _currentPage++;
        }
      });
    } catch (e) {
      print('Error loading more reviews: $e');
      // Show error message if needed
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reviews for ${widget.place.name}'),
      ),
      body: Column(
        children: [
          _buildSummary(),
          Expanded(
            child: _reviews.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.rate_review,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No reviews yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
                : NotificationListener<ScrollNotification>(
              onNotification: (ScrollNotification scrollInfo) {
                if (!_isLoading &&
                    _hasMorePages &&
                    scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
                  _loadMoreReviews();
                  return true;
                }
                return false;
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _reviews.length + (_hasMorePages ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _reviews.length) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                  return _buildReviewItem(_reviews[index]);
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddReviewScreen(place: widget.place),
            ),
          ).then((_) {
            // Refresh reviews after adding a new one
            setState(() {
              _reviews = List.from(widget.place.reviews);
            });
          });
        },
        child: const Icon(Icons.rate_review),
      ),
    );
  }

  Widget _buildSummary() {
    if (_reviews.isEmpty) return const SizedBox.shrink();

    // Calculate average rating
    double avgRating = widget.place.averageRating;

    // Count ratings by star value
    final ratingCounts = List<int>.filled(5, 0);
    for (final review in _reviews) {
      if (review.rating >= 1 && review.rating <= 5) {
        ratingCounts[review.rating - 1]++;
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: Column(
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    avgRating.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: List.generate(5, (index) {
                      return Icon(
                        index < avgRating.floor() ? Icons.star :
                        (index < avgRating.ceil() && index > avgRating.floor())
                            ? Icons.star_half : Icons.star_border,
                        color: Colors.amber,
                        size: 20,
                      );
                    }),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_reviews.length} reviews',
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 32),
              Expanded(
                child: Column(
                  children: List.generate(5, (index) {
                    // Reverse the index to show 5 stars first
                    final starIndex = 4 - index;
                    final count = ratingCounts[starIndex];
                    final percentage = _reviews.isNotEmpty ? count / _reviews.length * 100 : 0.0;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Row(
                        children: [
                          Text(
                            '${starIndex + 1}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const Icon(Icons.star, size: 16, color: Colors.amber),
                          const SizedBox(width: 8),
                          Expanded(
                            child: LinearProgressIndicator(
                              value: percentage / 100,
                              backgroundColor: Colors.grey[300],
                              valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$count',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReviewItem(FoodReview review) {
    final currentUserId = 0; // In a real app, get this from the auth service
    final isCurrentUserReview = review.userId == currentUserId;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: review.profileImg.isNotEmpty
                      ? NetworkImage(
                    review.profileImg.startsWith('http')
                        ? review.profileImg
                        : '${FoodService.baseUrl}${review.profileImg}',
                  )
                      : null,
                  child: review.profileImg.isEmpty
                      ? Text(review.username.isNotEmpty ? review.username[0].toUpperCase() : 'U')
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.username,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        DateFormat('MMM d, yyyy').format(review.createdAt),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < review.rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 20,
                    );
                  }),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              review.comment,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
            if (review.images.isNotEmpty) ...[
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReviewImageGalleryScreen(
                        images: review.images.map((img) => img.url).toList(),
                      ),
                    ),
                  );
                },
                child: SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: review.images.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            review.images[index].url.startsWith('http')
                                ? review.images[index].url
                                : '${FoodService.baseUrl}${review.images[index].url}',
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
            if (isCurrentUserReview) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      // Navigate to edit review screen
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      // Show delete confirmation
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Review'),
                          content: const Text('Are you sure you want to delete this review?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () async {
                                Navigator.of(context).pop();
                                try {
                                  await FoodService.deleteReview(review.id);
                                  setState(() {
                                    _reviews.removeWhere((r) => r.id == review.id);
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Review deleted successfully')),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Failed to delete review: $e')),
                                  );
                                }
                              },
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.delete),
                    label: const Text('Delete'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}