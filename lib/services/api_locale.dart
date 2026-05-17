import 'package:flutter/widgets.dart';

import '../l10n/app_localizations.dart';

/// 백엔드 API가 받는 locale 코드 ('ko' | 'en').
/// 백엔드는 Pydantic Literal["ko","en"]로 엄격 매칭하므로 소문자 2자리만 허용.
/// 미전달 시 백엔드 default는 "ko".
String apiLocaleOf(BuildContext context) =>
    AppLocalizations.of(context).localeName.startsWith('en') ? 'en' : 'ko';
