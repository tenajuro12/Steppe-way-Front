import 'package:flutter/material.dart';
import '../services/favorite_screen.dart';

class FavoriteButton extends StatefulWidget {
  final int itemId;
  final String itemType;
  final String title;
  final String imageUrl;
  final String? description;
  final String? city;
  final String? location;
  final DateTime? date;
  final String? category;
  final Function(bool)? onToggle;  // Callback with current state
  final Color activeColor;
  final Color inactiveColor;
  final double size;

  const FavoriteButton({
    Key? key,
    required this.itemId,
    required this.itemType,
    required this.title,
    required this.imageUrl,
    this.description,
    this.city,
    this.location,
    this.date,
    this.category,
    this.onToggle,
    this.activeColor = Colors.red,
    this.inactiveColor = Colors.white,
    this.size = 24.0,
  }) : super(key: key);

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton> {
  final FavoritesService _favoritesService = FavoritesService();
  bool _isFavorite = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkFavoriteStatus();
  }

  Future<void> _checkFavoriteStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final isFavorite = await _favoritesService.isFavorite(
          widget.itemType,
          widget.itemId
      );

      if (mounted) {
        setState(() {
          _isFavorite = isFavorite;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error checking favorite status: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleFavorite() async {
    setState(() {
      _isLoading = true;
    });

    try {
      bool success;

      if (_isFavorite) {
        success = await _favoritesService.removeFavorite(
            widget.itemType,
            widget.itemId
        );
      } else {
        success = await _favoritesService.addFavorite(
          itemId: widget.itemId,
          itemType: widget.itemType,
          title: widget.title,
          imageUrl: widget.imageUrl,
          description: widget.description,
          city: widget.city,
          location: widget.location,
          date: widget.date,
          category: widget.category,
        );
      }

      if (mounted && success) {
        final newState = !_isFavorite;
        setState(() {
          _isFavorite = newState;
          _isLoading = false;
        });

        if (widget.onToggle != null) {
          widget.onToggle!(newState);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                newState
                    ? 'Added to favorites'
                    : 'Removed from favorites'
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      } else if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error toggling favorite: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      iconSize: widget.size,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      icon: _isLoading
          ? SizedBox(
        width: widget.size,
        height: widget.size,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
              _isFavorite ? widget.activeColor : widget.inactiveColor
          ),
        ),
      )
          : Icon(
        _isFavorite ? Icons.favorite : Icons.favorite_border,
        color: _isFavorite ? widget.activeColor : widget.inactiveColor,
        size: widget.size,
      ),
      onPressed: _isLoading ? null : _toggleFavorite,
    );
  }
}