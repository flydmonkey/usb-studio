// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => 'USB Studio';

  @override
  String get language => '언어';

  @override
  String get languageSystem => '시스템 따름';

  @override
  String get languageZhHans => '简体中文';

  @override
  String get languageZhHant => '繁體中文';

  @override
  String get languageJa => '日本語';

  @override
  String get languageKo => '한국어';

  @override
  String get languageEn => 'English';

  @override
  String get settingsTitle => '캡처 설정';

  @override
  String get close => '닫기';

  @override
  String get sectionRecord => '녹화';

  @override
  String get sectionPreview => '미리보기';

  @override
  String get sectionPicture => '화면';

  @override
  String get sectionStream => '송출';

  @override
  String get sectionLan => 'LAN 재생';

  @override
  String get sectionAbout => '정보';

  @override
  String get privacyPolicy => '개인정보처리방침';

  @override
  String get openSourceLicenses => '오픈소스 라이선스';

  @override
  String appVersion(String version) {
    return '버전 $version';
  }

  @override
  String aboutDeveloper(String name) {
    return '개발자  $name';
  }

  @override
  String get permissionDisclosureTitle => '카메라와 마이크';

  @override
  String get permissionDisclosureBody =>
      'USB Studio는 USB 캡처 카드의 영상과 소리를 위해 카메라와 마이크 권한을 사용합니다. 이 기기의 전면 카메라는 사용하지 않습니다.';

  @override
  String get permissionDisclosureContinue => '계속';

  @override
  String get permissionDisclosureNotNow => '나중에';

  @override
  String get recordSegment => '녹화 분할';

  @override
  String get recordQuality => '녹화 화질';

  @override
  String get saveLocation => '저장 위치';

  @override
  String get changeFolder => '폴더 변경';

  @override
  String get autoRecord => '연결 후 자동 녹화';

  @override
  String get previewEnabled => '미리보기 켜기';

  @override
  String get previewSound => '미리보기 소리';

  @override
  String monitorVolume(int percent) {
    return '모니터 볼륨  $percent%';
  }

  @override
  String get monitorDelay => '모니터 지연';

  @override
  String get videoFormat => '영상 형식';

  @override
  String get resetPicture => '기본값';

  @override
  String get streamUrl => '송출 주소';

  @override
  String get streamKey => '송출 키(선택)';

  @override
  String get streamKeyHint => '전체 URL을 위에 붙여도 됩니다';

  @override
  String get streamBitrate => '송출 비트레이트';

  @override
  String get streamMbps1 => '1 Mbps';

  @override
  String get streamMbps2 => '2 Mbps';

  @override
  String get streamMbps4 => '4 Mbps';

  @override
  String get streamMbps6 => '6 Mbps';

  @override
  String get lanPlayback => 'LAN 재생';

  @override
  String get copyUrl => '복사';

  @override
  String get lanDisclosure => '같은 Wi-Fi의 HTTP로 재생할 수 있습니다. 암호화 없음.';

  @override
  String get connectWifi => '먼저 Wi-Fi에 연결';

  @override
  String get snapshot => '캡처';

  @override
  String get settings => '설정';

  @override
  String get library => '라이브러리';

  @override
  String get startRecord => '녹화';

  @override
  String get stopRecord => '중지';

  @override
  String get startStream => '송출';

  @override
  String get stopStream => '종료';

  @override
  String get mutePreview => '음소거';

  @override
  String get unmutePreview => '소리';

  @override
  String get fullscreen => '전체';

  @override
  String get insertCaptureCard => 'USB 캡처를 연결하세요';

  @override
  String devicesFound(int count) {
    return '캡처 장치 $count대 발견';
  }

  @override
  String get snapshotSaved => '정지 화면을 저장했습니다';

  @override
  String segmentStatus(int index) {
    return '$index번째';
  }

  @override
  String get previewOffCanRecord => '미리보기가 꺼져도 녹화할 수 있습니다';

  @override
  String get previewLanLiveBusy => '웹페이지에서 라이브를 보는 중';

  @override
  String get noSignal => '신호 없음';

  @override
  String get waitingSignal => '신호 대기';

  @override
  String get segmentOff => '끄기';

  @override
  String segmentMinutes(int minutes) {
    return '$minutes분';
  }

  @override
  String get qualityTiny => '최소(약 15MB/분)';

  @override
  String get qualitySmall => '절약(약 30MB/분)';

  @override
  String get qualityStandard => '표준(약 60MB/분)';

  @override
  String get qualityHigh => '고비트레이트(약 120MB/분)';

  @override
  String get saveGallery => '갤러리';

  @override
  String get saveMovies => '동영상';

  @override
  String get saveDownloads => '다운로드';

  @override
  String get saveCustom => '사용자 지정';

  @override
  String get savedGallery => '갤러리에 저장됨';

  @override
  String get savedMovies => '동영상 폴더에 저장됨';

  @override
  String get savedDownloads => '다운로드에 저장됨';

  @override
  String get savedCustom => '사용자 지정 폴더에 저장됨';

  @override
  String get pictureBrightness => '밝기';

  @override
  String get pictureContrast => '대비';

  @override
  String get pictureSaturation => '채도';

  @override
  String get pictureHue => '색조';

  @override
  String recOnly(String time) {
    return 'REC  $time';
  }

  @override
  String recSegment(String time, int index) {
    return 'REC  $time  $index번째';
  }

  @override
  String get cardRemoved => '캡처 카드를 분리했습니다';

  @override
  String get cardRemovedSavedMovies => '캡처 카드를 분리했습니다. 동영상 폴더에 저장됨';

  @override
  String get cardRemovedSaved => '캡처 카드를 분리했습니다. 녹화를 저장함';

  @override
  String get recordInterruptedMovies => '녹화가 중단되었습니다. 동영상 폴더에 저장됨';

  @override
  String get recordInterruptedSaved => '녹화가 중단되었습니다. 녹화를 저장함';

  @override
  String get recordFailed => '녹화에 실패했습니다.';

  @override
  String get libraryEmpty => '녹화가 없습니다. 캡처가 저장되면 여기에 나타납니다.';

  @override
  String get deleteTitle => '이 녹화를 삭제할까요?';

  @override
  String get deleteConfirm => '이 앱에서는 복원할 수 없습니다.';

  @override
  String get deleteAction => '삭제';

  @override
  String get cancelAction => '취소';

  @override
  String get shareAction => '공유';

  @override
  String get shareFailed => '공유할 대상이 없습니다.';

  @override
  String get shareUnavailable => '이 기기에서는 공유할 수 없습니다.';

  @override
  String get mergeAction => '세션 합치기';

  @override
  String get mergeProgress => '합치는 중…';

  @override
  String get renameAction => '이름 변경';

  @override
  String get renameTitle => '녹화 이름 변경';

  @override
  String get confirmAction => '확인';

  @override
  String get batteryTitle => '백그라운드 녹화 허용';

  @override
  String get batteryBody =>
      '잠금이나 백그라운드에서 시스템이 캡처를 멈출 수 있습니다. 배터리 최적화에서 이 앱을 제외하세요.';

  @override
  String get batteryOpenSettings => '설정 열기';

  @override
  String get batteryLater => '나중에';

  @override
  String get errorPermission => '캡처하려면 카메라, 마이크 또는 USB 권한이 필요합니다.';

  @override
  String get errorUsbHost => '이 기기는 USB 호스트를 지원하지 않아 캡처 카드를 쓸 수 없습니다.';

  @override
  String get errorUnsupportedPlatform => 'USB 캡처는 Android 휴대폰, 태블릿, TV만 지원합니다.';

  @override
  String get errorUvcFailed => '캡처 카드를 열 수 없습니다. UVC 장치인지 확인하세요.';

  @override
  String get errorPowerIssue =>
      '캡처 카드를 열 수 없습니다. 전원이 부족할 수 있습니다. 전원 USB 허브를 사용해 보세요.';

  @override
  String get errorDisconnected => '캡처 카드를 분리했습니다.';

  @override
  String get errorNoAudio => '캡처 카드에서 사용할 오디오가 없습니다.';

  @override
  String get errorRecordingInProgress => '녹화 중에는 형식이나 화질을 바꿀 수 없습니다.';

  @override
  String get errorSessionRecording => '이 세션이 녹화 중입니다. 중지한 뒤 합치세요.';

  @override
  String get errorConcatUnsupported => '이 환경에서는 녹화 합치기를 지원하지 않습니다.';

  @override
  String get errorConcatStorage => '저장 공간이 부족하여 합칠 수 없습니다.';

  @override
  String get errorConcatFailed => '합치기에 실패했습니다. 원래 분할은 그대로입니다.';

  @override
  String get errorPreviewOff => '먼저 미리보기를 켜세요.';

  @override
  String get errorNoPreview => '먼저 캡처 카드를 연결하세요.';

  @override
  String get errorStreamUnsupported => '이 환경에서는 송출을 지원하지 않습니다.';

  @override
  String get errorStreamInProgress => '송출 중에는 형식이나 화질을 바꿀 수 없습니다.';

  @override
  String get errorMissingUrl => '먼저 송출 주소를 입력하세요.';

  @override
  String get errorNoSignalStream => '신호가 없어 송출을 중지했습니다.';

  @override
  String get errorConnectFailed => '송출 서버에 연결할 수 없습니다.';

  @override
  String get errorHttpUnsupported => '이 환경에서는 LAN 재생을 지원하지 않습니다.';

  @override
  String get errorHttpBindFailed => 'LAN 재생 포트를 열 수 없습니다.';

  @override
  String get errorHttpNoNetwork => '먼저 Wi-Fi에 연결하세요.';

  @override
  String get errorHttpLiveFailed => '라이브 인코딩을 시작하지 못했습니다. 저장된 녹화는 재생할 수 있습니다.';

  @override
  String get errorStreamFailed => '송출에 실패했습니다.';

  @override
  String get errorPlayFailed => '시스템 플레이어로 열 수 없습니다.';

  @override
  String get errorRenameTaken => '같은 이름의 녹화가 있습니다. 다른 이름을 쓰세요.';

  @override
  String get errorRenameInvalid => '이름이 올바르지 않습니다. 슬래시 등 특수 문자를 빼세요.';

  @override
  String get errorRenameUnsupported => '이 환경에서는 이름 변경을 지원하지 않습니다.';

  @override
  String get errorRenameFailed => '이름 변경에 실패했습니다. 원래 파일은 그대로입니다.';

  @override
  String get errorUnknown => '알 수 없는 오류가 발생했습니다.';
}
