// lib/screens/food/dish_details_screen.dart
import 'package:flutter/material.dart';
import '../../models/food.dart';
import '../../services/food_service.dart';

class DishDetailsScreen extends StatefulWidget {
  final Dish dish;

  const DishDetailsScreen({Key? key, required this.dish}) : super(key: key);

  @override
  State<DishDetailsScreen> createState() => _DishDetailsScreenState();
}

class _DishDetailsScreenState extends State<DishDetailsScreen> {
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.dish.name),
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Column(
        children: [
          // Image gallery
          _buildImageGallery(),

          // Dish details
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name, price and specialty badge
                  _buildDishHeader(),

                  // Description if available
                  if (widget.dish.description.isNotEmpty)
                    _buildDescription(),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGallery() {
    if (widget.dish.images.isEmpty) {
      return Container(
        height: 250,
        width: double.infinity,
        color: Colors.grey[200],
        child: Center(
          child: Icon(
            Icons.restaurant_menu,
            size: 80,
            color: Colors.grey[400],
          ),
        ),
      );
    }

    return Container(
      height: 250,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Image slider
          PageView.builder(
            controller: _pageController,
            itemCount: widget.dish.images.length,
            onPageChanged: (index) {
              setState(() {
                _currentImageIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final image = widget.dish.images[index];
              return GestureDetector(
                onTap: () {
                  // Optional: implement full-screen image view
                },
                child: Image.network(
                  image.url.startsWith('http')
                      ? image.url
                      : '${FoodService.baseUrl}${image.url}',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      child: Center(
                        child: Icon(
                          Icons.broken_image,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),

          // Navigation arrows
          if (widget.dish.images.length > 1) ...[
            // Left arrow
            Positioned(
              left: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: _buildNavigationButton(
                  icon: Icons.arrow_back_ios_rounded,
                  onPressed: () {
                    if (_currentImageIndex > 0) {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                ),
              ),
            ),

            // Right arrow
            Positioned(
              right: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: _buildNavigationButton(
                  icon: Icons.arrow_forward_ios_rounded,
                  onPressed: () {
                    if (_currentImageIndex < widget.dish.images.length - 1) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                ),
              ),
            ),
          ],

          // Page indicator dots
          if (widget.dish.images.length > 1)
            Positioned(
              left: 0,
              right: 0,
              bottom: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.dish.images.length,
                      (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: _currentImageIndex == index ? 24 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: _currentImageIndex == index
                          ? Theme.of(context).primaryColor
                          : Colors.white.withOpacity(0.6),
                    ),
                  ),
                ),
              ),
            ),

          // Specialty badge
          if (widget.dish.isSpecialty)
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(
                      Icons.star,
                      size: 16,
                      color: Colors.white,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Specialty',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNavigationButton({required IconData icon, required VoidCallback onPressed}) {
    return Material(
      color: Colors.black.withOpacity(0.3),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            color: Colors.white,
            size: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildDishHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name
          Text(
            widget.dish.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          // Price
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context).primaryColor.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  '₸${widget.dish.price.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),
          const Divider(),
        ],
      ),
    );
  }

  Widget _buildDescription() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 20,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 8),
              const Text(
                'Description',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.dish.description,
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }
}