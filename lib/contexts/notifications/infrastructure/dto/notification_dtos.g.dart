// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_dtos.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AlertSubscriptionDto _$AlertSubscriptionDtoFromJson(
  Map<String, dynamic> json,
) => AlertSubscriptionDto(
  id: (json['id'] as num).toInt(),
  lotId: (json['lotId'] as num).toInt(),
  days: (json['days'] as List<dynamic>).map((e) => (e as num).toInt()).toList(),
  from: json['from'] as String,
  to: json['to'] as String,
  active: json['active'] as bool? ?? true,
);

Map<String, dynamic> _$AlertSubscriptionDtoToJson(
  AlertSubscriptionDto instance,
) => <String, dynamic>{
  'id': instance.id,
  'lotId': instance.lotId,
  'days': instance.days,
  'from': instance.from,
  'to': instance.to,
  'active': instance.active,
};

AlertSubscriptionRequestDto _$AlertSubscriptionRequestDtoFromJson(
  Map<String, dynamic> json,
) => AlertSubscriptionRequestDto(
  lotId: (json['lotId'] as num).toInt(),
  days: (json['days'] as List<dynamic>).map((e) => (e as num).toInt()).toList(),
  from: json['from'] as String,
  to: json['to'] as String,
);

Map<String, dynamic> _$AlertSubscriptionRequestDtoToJson(
  AlertSubscriptionRequestDto instance,
) => <String, dynamic>{
  'lotId': instance.lotId,
  'days': instance.days,
  'from': instance.from,
  'to': instance.to,
};

AlertSubscriptionActiveRequestDto _$AlertSubscriptionActiveRequestDtoFromJson(
  Map<String, dynamic> json,
) => AlertSubscriptionActiveRequestDto(active: json['active'] as bool);

Map<String, dynamic> _$AlertSubscriptionActiveRequestDtoToJson(
  AlertSubscriptionActiveRequestDto instance,
) => <String, dynamic>{'active': instance.active};

NotificationPreferencesDto _$NotificationPreferencesDtoFromJson(
  Map<String, dynamic> json,
) => NotificationPreferencesDto(
  pushEnabled: json['pushEnabled'] as bool,
  saturationAlerts: json['saturationAlerts'] as bool,
  lowArrivalAlerts: json['lowArrivalAlerts'] as bool,
  locale: json['locale'] as String,
  staleDataAlerts: json['staleDataAlerts'] as bool? ?? true,
  eventAlerts: json['eventAlerts'] as bool? ?? false,
);

Map<String, dynamic> _$NotificationPreferencesDtoToJson(
  NotificationPreferencesDto instance,
) => <String, dynamic>{
  'pushEnabled': instance.pushEnabled,
  'saturationAlerts': instance.saturationAlerts,
  'lowArrivalAlerts': instance.lowArrivalAlerts,
  'staleDataAlerts': instance.staleDataAlerts,
  'eventAlerts': instance.eventAlerts,
  'locale': instance.locale,
};

DeviceTokenUnregisterRequestDto _$DeviceTokenUnregisterRequestDtoFromJson(
  Map<String, dynamic> json,
) => DeviceTokenUnregisterRequestDto(token: json['token'] as String);

Map<String, dynamic> _$DeviceTokenUnregisterRequestDtoToJson(
  DeviceTokenUnregisterRequestDto instance,
) => <String, dynamic>{'token': instance.token};

DeviceTokenRequestDto _$DeviceTokenRequestDtoFromJson(
  Map<String, dynamic> json,
) => DeviceTokenRequestDto(
  token: json['token'] as String,
  platform: json['platform'] as String,
);

Map<String, dynamic> _$DeviceTokenRequestDtoToJson(
  DeviceTokenRequestDto instance,
) => <String, dynamic>{'token': instance.token, 'platform': instance.platform};
