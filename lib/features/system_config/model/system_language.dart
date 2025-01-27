class SystemLanguage {
  const SystemLanguage({
    required this.name,
    required this.isRTL,
    required this.version,
    required this.isDefault,
    this.translations,
  });

  SystemLanguage.fromJson(Map<String, dynamic> json)
      : name = json['name'] as String,
        isRTL = (json['app_rtl_support'] as String) == '1',
        version = json['app_version'] as String,
        isDefault = (json['app_default'] as String) == '1',
        translations = json['translations'] != null
            ? (json['translations'] as Map).cast<String, String>()
            : null;

  final String name;
  final bool isRTL;
  final String version;
  final bool isDefault;
  final Map<String, String>? translations;

  SystemLanguage copyWith({
    String? name,
    bool? isRTL,
    String? version,
    bool? isDefault,
    Map<String, String>? translations,
  }) =>
      SystemLanguage(
        name: name ?? this.name,
        isRTL: isRTL ?? this.isRTL,
        version: version ?? this.version,
        isDefault: isDefault ?? this.isDefault,
        translations: translations ?? this.translations,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'name': name,
        'app_rtl_support': isRTL ? '1' : '0',
        'app_version': version,
        'app_default': isDefault ? '1' : '0',
        'translations': translations,
      };

  static const empty = SystemLanguage(
    name: '',
    isRTL: false,
    version: '',
    isDefault: false,
  );
}
