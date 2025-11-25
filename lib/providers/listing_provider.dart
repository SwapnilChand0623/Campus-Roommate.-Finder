import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/listing.dart';
import '../services/listing_service.dart';

/// Provider for listing service
final listingServiceProvider = Provider((ref) => ListingService());

/// Provider for all listings
final listingsProvider = FutureProvider<List<Listing>>((ref) async {
  final service = ref.watch(listingServiceProvider);
  return service.fetchListings();
});

/// Provider for listings by category
final listingsByCategoryProvider =
    FutureProvider.family<List<Listing>, String>((ref, category) async {
  final service = ref.watch(listingServiceProvider);
  return service.fetchListingsByCategory(category);
});

/// Provider for user's own listings
final myListingsProvider =
    FutureProvider.family<List<Listing>, String>((ref, userId) async {
  final service = ref.watch(listingServiceProvider);
  return service.fetchMyListings(userId);
});
