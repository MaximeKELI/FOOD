import 'package:flutter/material.dart';

class Meal {
  const Meal({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.price,
    required this.rating,
    required this.image,
    required this.accent,
    required this.category,
  });

  final String id;
  final String name;
  final String subtitle;
  final double price;
  final double rating;
  final String image;
  final Color accent;
  final String category;
}

