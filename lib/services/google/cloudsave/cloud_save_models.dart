class CloudSaveOwner {
  final String provider; // 'google'
  final String playerId; // Google Play Games ID

  CloudSaveOwner({required this.provider, required this.playerId});

  Map<String, dynamic> toJson() => {
        'provider': provider,
        'playerId': playerId,
      };

  static CloudSaveOwner fromJson(Map<String, dynamic> json) => CloudSaveOwner(
        provider: json['provider'] as String,
        playerId: json['playerId'] as String,
      );
}

class CloudSaveDisplayData {
  final double money;
  final double paperclips;
  final int autoClipperCount;
  final double netProfit;

  CloudSaveDisplayData({
    required this.money,
    required this.paperclips,
    required this.autoClipperCount,
    required this.netProfit,
  });

  Map<String, dynamic> toJson() => {
        'money': money,
        'paperclips': paperclips,
        'autoClipperCount': autoClipperCount,
        'netProfit': netProfit,
      };

  static CloudSaveDisplayData fromJson(Map<String, dynamic> json) =>
      CloudSaveDisplayData(
        money: (json['money'] as num?)?.toDouble() ?? 0.0,
        paperclips: (json['paperclips'] as num?)?.toDouble() ?? 0.0,
        autoClipperCount: (json['autoClipperCount'] as num?)?.toInt() ?? 0,
        netProfit: (json['netProfit'] as num?)?.toDouble() ?? 0.0,
      );
}

class CloudSavePayload {
  final String version; // 'SAVE_SCHEMA_V1'
  final Map<String, dynamic> snapshot; // gameSnapshot object
  final CloudSaveDisplayData displayData;

  CloudSavePayload({
    required this.version,
    required this.snapshot,
    required this.displayData,
  });

  Map<String, dynamic> toJson() => {
        'version': version,
        'snapshot': snapshot,
        'displayData': displayData.toJson(),
      };

  static CloudSavePayload fromJson(Map<String, dynamic> json) => CloudSavePayload(
        version: json['version'] as String,
        snapshot: (json['snapshot'] as Map).cast<String, dynamic>(),
        displayData:
            CloudSaveDisplayData.fromJson((json['displayData'] as Map).cast<String, dynamic>()),
      );
}

class CloudSaveDeviceInfo {
  final String model;
  final String platform; // 'android' | 'ios' | 'web' | 'desktop'
  final String locale;

  CloudSaveDeviceInfo({
    required this.model,
    required this.platform,
    required this.locale,
  });

  Map<String, dynamic> toJson() => {
        'model': model,
        'platform': platform,
        'locale': locale,
      };

  static CloudSaveDeviceInfo fromJson(Map<String, dynamic> json) =>
      CloudSaveDeviceInfo(
        model: json['model'] as String? ?? '?',
        platform: json['platform'] as String? ?? 'unknown',
        locale: json['locale'] as String? ?? 'fr-FR',
      );
}

class CloudSaveMeta {
  final String appVersion;
  final DateTime createdAt;
  final DateTime uploadedAt;
  final CloudSaveDeviceInfo device;

  CloudSaveMeta({
    required this.appVersion,
    required this.createdAt,
    required this.uploadedAt,
    required this.device,
  });

  Map<String, dynamic> toJson() => {
        'appVersion': appVersion,
        'createdAt': createdAt.toIso8601String(),
        'uploadedAt': uploadedAt.toIso8601String(),
        'device': device.toJson(),
      };

  static CloudSaveMeta fromJson(Map<String, dynamic> json) => CloudSaveMeta(
        appVersion: json['appVersion'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        uploadedAt: DateTime.parse(json['uploadedAt'] as String),
        device: CloudSaveDeviceInfo.fromJson((json['device'] as Map).cast<String, dynamic>()),
      );
}

class CloudSaveRecord {
  final String? id; // peut être null avant upload
  final CloudSaveOwner owner;
  final CloudSavePayload payload;
  final CloudSaveMeta meta;

  CloudSaveRecord({
    required this.id,
    required this.owner,
    required this.payload,
    required this.meta,
  });

  Map<String, dynamic> toJson() => {
        'cloudSave': {
          'id': id,
          'owner': owner.toJson(),
          'payload': payload.toJson(),
          'meta': meta.toJson(),
        }
      };

  static CloudSaveRecord fromJson(Map<String, dynamic> json) {
    final root = (json['cloudSave'] as Map).cast<String, dynamic>();
    return CloudSaveRecord(
      id: root['id'] as String?,
      owner: CloudSaveOwner.fromJson((root['owner'] as Map).cast<String, dynamic>()),
      payload: CloudSavePayload.fromJson((root['payload'] as Map).cast<String, dynamic>()),
      meta: CloudSaveMeta.fromJson((root['meta'] as Map).cast<String, dynamic>()),
    );
  }
}
