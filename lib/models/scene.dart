import 'package:flutter/material.dart';

/// Available scene for AI generation.
/// Used for scene selection before generating images.
class Scene {
  final String id;
  final String label;
  final IconData icon;
  final String description;

  const Scene({
    required this.id,
    required this.label,
    required this.icon,
    required this.description,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Scene && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Predefined scenes available for AI generation.
/// IDs must match Cloud Function SCENES array.
const List<Scene> availableScenes = [
  Scene(
    id: 'beach',
    label: 'Beach',
    icon: Icons.beach_access_outlined,
    description: 'Tropical beach vibes',
  ),
  Scene(
    id: 'city',
    label: 'City',
    icon: Icons.location_city_outlined,
    description: 'Urban street style',
  ),
  Scene(
    id: 'mountain',
    label: 'Mountain',
    icon: Icons.terrain_outlined,
    description: 'Adventure outdoors',
  ),
  Scene(
    id: 'cafe',
    label: 'Cafe',
    icon: Icons.coffee_outlined,
    description: 'Cozy coffee moment',
  ),
  Scene(
    id: 'forest',
    label: 'Forest',
    icon: Icons.forest_outlined,
    description: 'Nature escape',
  ),
  Scene(
    id: 'sunset',
    label: 'Sunset',
    icon: Icons.wb_twilight_outlined,
    description: 'Golden hour magic',
  ),
  Scene(
    id: 'snow',
    label: 'Snow',
    icon: Icons.ac_unit_outlined,
    description: 'Winter wonderland',
  ),
  Scene(
    id: 'garden',
    label: 'Garden',
    icon: Icons.local_florist_outlined,
    description: 'Blooming flowers',
  ),
];
