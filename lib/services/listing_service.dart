import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/listing.dart';

/// Service for managing marketplace listings
class ListingService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Fetch all active listings
  Future<List<Listing>> fetchListings() async {
    final response = await _supabase
        .from('listings')
        .select()
        .eq('is_sold', false)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => Listing.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Fetch listings by category
  Future<List<Listing>> fetchListingsByCategory(String category) async {
    final response = await _supabase
        .from('listings')
        .select()
        .eq('category', category)
        .eq('is_sold', false)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => Listing.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Fetch user's own listings
  Future<List<Listing>> fetchMyListings(String userId) async {
    final response = await _supabase
        .from('listings')
        .select()
        .eq('seller_id', userId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => Listing.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Create a new listing
  Future<Listing> createListing({
    required String sellerId,
    required String sellerName,
    required String title,
    required String description,
    required double price,
    required List<String> photoUrls,
    required String category,
  }) async {
    final now = DateTime.now();
    final data = {
      'seller_id': sellerId,
      'seller_name': sellerName,
      'title': title,
      'description': description,
      'price': price,
      'photo_urls': photoUrls,
      'category': category,
      'is_sold': false,
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    };

    final response = await _supabase
        .from('listings')
        .insert(data)
        .select()
        .single();

    return Listing.fromJson(response as Map<String, dynamic>);
  }

  /// Update a listing
  Future<Listing> updateListing({
    required String listingId,
    String? title,
    String? description,
    double? price,
    List<String>? photoUrls,
    String? category,
    bool? isSold,
  }) async {
    final data = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (title != null) data['title'] = title;
    if (description != null) data['description'] = description;
    if (price != null) data['price'] = price;
    if (photoUrls != null) data['photo_urls'] = photoUrls;
    if (category != null) data['category'] = category;
    if (isSold != null) data['is_sold'] = isSold;

    final response = await _supabase
        .from('listings')
        .update(data)
        .eq('id', listingId)
        .select()
        .single();

    return Listing.fromJson(response as Map<String, dynamic>);
  }

  /// Mark listing as sold
  Future<void> markAsSold(String listingId) async {
    await _supabase
        .from('listings')
        .update({
          'is_sold': true,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', listingId);
  }

  /// Delete a listing
  Future<void> deleteListing(String listingId) async {
    await _supabase.from('listings').delete().eq('id', listingId);
  }

  /// Upload listing photos to Supabase Storage
  Future<List<String>> uploadPhotos(String userId, List<String> filePaths) async {
    final List<String> photoUrls = [];

    for (int i = 0; i < filePaths.length; i++) {
      final filePath = filePaths[i];
      final fileName = 'listing_${userId}_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
      final path = 'listings/$userId/$fileName';

      // Read file as bytes
      final file = File(filePath);
      final bytes = await file.readAsBytes();

      // Upload file
      await _supabase.storage.from('listings').uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );

      // Get public URL
      final url = _supabase.storage.from('listings').getPublicUrl(path);
      photoUrls.add(url);
    }

    return photoUrls;
  }

  /// Delete photos from storage
  Future<void> deletePhotos(List<String> photoUrls) async {
    for (final url in photoUrls) {
      // Extract path from URL
      final uri = Uri.parse(url);
      final path = uri.pathSegments.skip(4).join('/'); // Skip /storage/v1/object/public/listings/
      
      try {
        await _supabase.storage.from('listings').remove([path]);
      } catch (e) {
        print('Error deleting photo: $e');
      }
    }
  }
}
