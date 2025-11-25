class University {
  const University({
    required this.name,
    required this.domains,
    this.country,
    this.alphaTwoCode,
    this.stateProvince,
    this.webPages,
  });

  final String name;
  final List<String> domains;
  final String? country;
  final String? alphaTwoCode;
  final String? stateProvince;
  final List<String>? webPages;

  factory University.fromJson(Map<String, dynamic> json) {
    final rawDomains = json['domains'];
    final domains = rawDomains is List
        ? rawDomains.where((e) => e != null).map((e) => e.toString()).toList()
        : <String>[];

    final rawWebPages = json['web_pages'];
    final webPages = rawWebPages is List
        ? rawWebPages.where((e) => e != null).map((e) => e.toString()).toList()
        : null;

    return University(
      name: json['name'] as String? ?? '',
      domains: domains,
      country: json['country'] as String?,
      alphaTwoCode: json['alpha_two_code'] as String?,
      stateProvince: json['state-province'] as String?,
      webPages: webPages,
    );
  }

  bool get hasDomains => domains.isNotEmpty;
}
