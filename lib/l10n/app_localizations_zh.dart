// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'USB Studio';

  @override
  String get language => '语言';

  @override
  String get languageSystem => '跟随系统';

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
  String get settingsTitle => '采集设置';

  @override
  String get close => '关闭';

  @override
  String get sectionRecord => '录制';

  @override
  String get sectionPreview => '预览';

  @override
  String get sectionPicture => '画面';

  @override
  String get sectionStream => '推流';

  @override
  String get sectionLan => '局域网播放';

  @override
  String get sectionAbout => '关于';

  @override
  String get privacyPolicy => '隐私政策';

  @override
  String get openSourceLicenses => '开源许可';

  @override
  String appVersion(String version) {
    return '版本 $version';
  }

  @override
  String aboutDeveloper(String name) {
    return '开发者  $name';
  }

  @override
  String get permissionDisclosureTitle => '相机和麦克风';

  @override
  String get permissionDisclosureBody =>
      'USB Studio 使用相机和麦克风权限，用于 USB 采集卡的画面和声音，不会用本机自拍摄像头采集。';

  @override
  String get permissionDisclosureContinue => '继续';

  @override
  String get permissionDisclosureNotNow => '暂不';

  @override
  String get recordSegment => '录制分段';

  @override
  String get recordQuality => '录制画质';

  @override
  String get saveLocation => '保存位置';

  @override
  String get changeFolder => '更改目录';

  @override
  String get autoRecord => '连接后自动开录';

  @override
  String get previewEnabled => '开启预览';

  @override
  String get previewSound => '预览声音';

  @override
  String monitorVolume(int percent) {
    return '监听音量  $percent%';
  }

  @override
  String get monitorDelay => '监听延迟';

  @override
  String get videoFormat => '视频格式';

  @override
  String get resetPicture => '恢复默认';

  @override
  String get streamUrl => '推流地址';

  @override
  String get streamKey => '推流密钥（选填）';

  @override
  String get streamKeyHint => '也可把完整地址填在上面';

  @override
  String get lanPlayback => '局域网播放';

  @override
  String get copyUrl => '复制地址';

  @override
  String get lanDisclosure => '同一 Wi-Fi 下打开此地址即可播放；未加密';

  @override
  String get connectWifi => '请先连接 Wi-Fi';

  @override
  String get snapshot => '截图';

  @override
  String get settings => '设置';

  @override
  String get library => '片库';

  @override
  String get startRecord => '开始录制';

  @override
  String get stopRecord => '停止录制';

  @override
  String get startStream => '推流';

  @override
  String get stopStream => '停止推流';

  @override
  String get mutePreview => '预览静音';

  @override
  String get unmutePreview => '取消静音';

  @override
  String get fullscreen => '全屏';

  @override
  String get insertCaptureCard => '请插入 USB 采集卡';

  @override
  String devicesFound(int count) {
    return '发现 $count 台采集设备';
  }

  @override
  String get snapshotSaved => '已保存截图';

  @override
  String segmentStatus(int index) {
    return '第$index段';
  }

  @override
  String get previewOffCanRecord => '预览已关闭，仍可录制';

  @override
  String get noSignal => '无信号';

  @override
  String get waitingSignal => '等待信号';

  @override
  String get segmentOff => '关闭';

  @override
  String segmentMinutes(int minutes) {
    return '$minutes 分钟';
  }

  @override
  String get qualityTiny => '更小（约 15MB/分钟）';

  @override
  String get qualitySmall => '省空间（约 30MB/分钟）';

  @override
  String get qualityStandard => '标准（约 60MB/分钟）';

  @override
  String get qualityHigh => '高码率（约 120MB/分钟）';

  @override
  String get saveGallery => '相册';

  @override
  String get saveMovies => '影片';

  @override
  String get saveDownloads => '下载';

  @override
  String get saveCustom => '自定义';

  @override
  String get savedGallery => '已保存到相册';

  @override
  String get savedMovies => '已保存到影片目录';

  @override
  String get savedDownloads => '已保存到下载';

  @override
  String get savedCustom => '已保存到自定义';

  @override
  String get pictureBrightness => '亮度';

  @override
  String get pictureContrast => '对比度';

  @override
  String get pictureSaturation => '饱和度';

  @override
  String get pictureHue => '色调';

  @override
  String recOnly(String time) {
    return 'REC  $time';
  }

  @override
  String recSegment(String time, int index) {
    return 'REC  $time  第$index段';
  }

  @override
  String get cardRemoved => '采集卡已拔出';

  @override
  String get cardRemovedSavedMovies => '采集卡已拔出，已保存到影片目录';

  @override
  String get cardRemovedSaved => '采集卡已拔出，录制已保存';

  @override
  String get recordInterruptedMovies => '录制中断，已保存到影片目录';

  @override
  String get recordInterruptedSaved => '录制中断，录制已保存';

  @override
  String get recordFailed => '录制失败。';

  @override
  String get libraryEmpty => '还没有录像。完成一次采集后，成片会出现在这里。';

  @override
  String get deleteTitle => '删除这段录像？';

  @override
  String get deleteConfirm => '删除后无法从本应用恢复。';

  @override
  String get deleteAction => '删除';

  @override
  String get cancelAction => '取消';

  @override
  String get shareAction => '分享';

  @override
  String get shareFailed => '没有可用的分享目标。';

  @override
  String get shareUnavailable => '此设备无法分享该文件。';

  @override
  String get mergeAction => '合并本场';

  @override
  String get mergeProgress => '正在合并本场…';

  @override
  String get renameAction => '重命名';

  @override
  String get renameTitle => '重命名录像';

  @override
  String get confirmAction => '确定';

  @override
  String get batteryTitle => '允许后台继续录制';

  @override
  String get batteryBody => '锁屏或切到后台后，系统可能会暂停采集。请在电池优化中忽略本应用，以便继续录制。';

  @override
  String get batteryOpenSettings => '去设置';

  @override
  String get batteryLater => '以后再说';

  @override
  String get errorPermission => '需要相机、麦克风或 USB 权限才能采集。';

  @override
  String get errorUsbHost => '此设备不支持 USB Host，无法使用采集卡。';

  @override
  String get errorUnsupportedPlatform => 'USB 采集仅支持 Android 手机、平板和电视。';

  @override
  String get errorUvcFailed => '无法打开采集卡。请确认设备为 UVC 采集卡。';

  @override
  String get errorPowerIssue => '无法打开采集卡，可能供电不足。请尝试带供电的 USB Hub。';

  @override
  String get errorDisconnected => '采集卡已拔出。';

  @override
  String get errorNoAudio => '采集卡未提供可用音频。';

  @override
  String get errorRecordingInProgress => '录制进行中，无法更改格式或画质。';

  @override
  String get errorSessionRecording => '这场正在录制，请停录后再合并。';

  @override
  String get errorConcatUnsupported => '当前平台不支持合并录像。';

  @override
  String get errorConcatStorage => '存储空间不足，无法合并。';

  @override
  String get errorConcatFailed => '合并失败，原分段未改动。';

  @override
  String get errorPreviewOff => '请先开启预览。';

  @override
  String get errorNoPreview => '请先连接采集卡。';

  @override
  String get errorStreamUnsupported => '当前平台不支持推流。';

  @override
  String get errorStreamInProgress => '推流进行中，无法更改格式或画质。';

  @override
  String get errorMissingUrl => '请先填写推流地址。';

  @override
  String get errorNoSignalStream => '无信号，已停止推流。';

  @override
  String get errorConnectFailed => '无法连接推流服务器。';

  @override
  String get errorHttpUnsupported => '当前平台不支持局域网播放。';

  @override
  String get errorHttpBindFailed => '无法打开局域网播放端口。';

  @override
  String get errorHttpNoNetwork => '请先连接 Wi-Fi。';

  @override
  String get errorHttpLiveFailed => '现场编码未启动，已录成片仍可播放。';

  @override
  String get errorStreamFailed => '推流失败。';

  @override
  String get errorPlayFailed => '无法用系统播放器打开。';

  @override
  String get errorRenameTaken => '已有同名录像，请换一个名称。';

  @override
  String get errorRenameInvalid => '名称无效。请去掉斜杠等特殊字符。';

  @override
  String get errorRenameUnsupported => '当前平台不支持重命名。';

  @override
  String get errorRenameFailed => '重命名失败，原文件未改动。';

  @override
  String get errorUnknown => '发生未知错误。';
}

/// The translations for Chinese, using the Han script (`zh_Hant`).
class AppLocalizationsZhHant extends AppLocalizationsZh {
  AppLocalizationsZhHant() : super('zh_Hant');

  @override
  String get appTitle => 'USB Studio';

  @override
  String get language => '語言';

  @override
  String get languageSystem => '跟隨系統';

  @override
  String get languageZhHans => '簡體中文';

  @override
  String get languageZhHant => '繁體中文';

  @override
  String get languageJa => '日本語';

  @override
  String get languageKo => '한국어';

  @override
  String get languageEn => 'English';

  @override
  String get settingsTitle => '擷取設定';

  @override
  String get close => '關閉';

  @override
  String get sectionRecord => '錄製';

  @override
  String get sectionPreview => '預覽';

  @override
  String get sectionPicture => '畫面';

  @override
  String get sectionStream => '推流';

  @override
  String get sectionLan => '區域網播放';

  @override
  String get sectionAbout => '關於';

  @override
  String get privacyPolicy => '隱私權政策';

  @override
  String get openSourceLicenses => '開放原始碼授權';

  @override
  String appVersion(String version) {
    return '版本 $version';
  }

  @override
  String aboutDeveloper(String name) {
    return '開發者  $name';
  }

  @override
  String get permissionDisclosureTitle => '相機與麥克風';

  @override
  String get permissionDisclosureBody =>
      'USB Studio 使用相機與麥克風權限，用於 USB 擷取卡的畫面與聲音，不會用本機自拍相機擷取。';

  @override
  String get permissionDisclosureContinue => '繼續';

  @override
  String get permissionDisclosureNotNow => '暫時不要';

  @override
  String get recordSegment => '錄製分段';

  @override
  String get recordQuality => '錄製畫質';

  @override
  String get saveLocation => '儲存位置';

  @override
  String get changeFolder => '更改目錄';

  @override
  String get autoRecord => '連接後自動開錄';

  @override
  String get previewEnabled => '開啟預覽';

  @override
  String get previewSound => '預覽聲音';

  @override
  String monitorVolume(int percent) {
    return '監聽音量  $percent%';
  }

  @override
  String get monitorDelay => '監聽延遲';

  @override
  String get videoFormat => '視訊格式';

  @override
  String get resetPicture => '恢復預設';

  @override
  String get streamUrl => '推流位址';

  @override
  String get streamKey => '推流金鑰（選填）';

  @override
  String get streamKeyHint => '也可把完整位址填在上面';

  @override
  String get lanPlayback => '區域網播放';

  @override
  String get copyUrl => '複製位址';

  @override
  String get lanDisclosure => '同一 Wi-Fi 下開啟此位址即可播放；未加密';

  @override
  String get connectWifi => '請先連接 Wi-Fi';

  @override
  String get snapshot => '截圖';

  @override
  String get settings => '設定';

  @override
  String get library => '片庫';

  @override
  String get startRecord => '開始錄製';

  @override
  String get stopRecord => '停止錄製';

  @override
  String get startStream => '推流';

  @override
  String get stopStream => '停止推流';

  @override
  String get mutePreview => '預覽靜音';

  @override
  String get unmutePreview => '取消靜音';

  @override
  String get fullscreen => '全螢幕';

  @override
  String get insertCaptureCard => '請插入 USB 擷取卡';

  @override
  String devicesFound(int count) {
    return '發現 $count 台擷取裝置';
  }

  @override
  String get snapshotSaved => '已儲存截圖';

  @override
  String segmentStatus(int index) {
    return '第$index段';
  }

  @override
  String get previewOffCanRecord => '預覽已關閉，仍可錄製';

  @override
  String get noSignal => '無訊號';

  @override
  String get waitingSignal => '等待訊號';

  @override
  String get segmentOff => '關閉';

  @override
  String segmentMinutes(int minutes) {
    return '$minutes 分鐘';
  }

  @override
  String get qualityTiny => '更小（約 15MB/分鐘）';

  @override
  String get qualitySmall => '省空間（約 30MB/分鐘）';

  @override
  String get qualityStandard => '標準（約 60MB/分鐘）';

  @override
  String get qualityHigh => '高位元率（約 120MB/分鐘）';

  @override
  String get saveGallery => '相簿';

  @override
  String get saveMovies => '影片';

  @override
  String get saveDownloads => '下載';

  @override
  String get saveCustom => '自訂';

  @override
  String get savedGallery => '已儲存到相簿';

  @override
  String get savedMovies => '已儲存到影片目錄';

  @override
  String get savedDownloads => '已儲存到下載';

  @override
  String get savedCustom => '已儲存到自訂';

  @override
  String get pictureBrightness => '亮度';

  @override
  String get pictureContrast => '對比度';

  @override
  String get pictureSaturation => '飽和度';

  @override
  String get pictureHue => '色調';

  @override
  String recOnly(String time) {
    return 'REC  $time';
  }

  @override
  String recSegment(String time, int index) {
    return 'REC  $time  第$index段';
  }

  @override
  String get cardRemoved => '擷取卡已拔出';

  @override
  String get cardRemovedSavedMovies => '擷取卡已拔出，已儲存到影片目錄';

  @override
  String get cardRemovedSaved => '擷取卡已拔出，錄製已儲存';

  @override
  String get recordInterruptedMovies => '錄製中斷，已儲存到影片目錄';

  @override
  String get recordInterruptedSaved => '錄製中斷，錄製已儲存';

  @override
  String get recordFailed => '錄製失敗。';

  @override
  String get libraryEmpty => '還沒有錄影。完成一次擷取後，成片會出現在這裡。';

  @override
  String get deleteTitle => '刪除這段錄影？';

  @override
  String get deleteConfirm => '刪除後無法從本應用程式還原。';

  @override
  String get deleteAction => '刪除';

  @override
  String get cancelAction => '取消';

  @override
  String get shareAction => '分享';

  @override
  String get shareFailed => '沒有可用的分享目標。';

  @override
  String get shareUnavailable => '此裝置無法分享該檔案。';

  @override
  String get mergeAction => '合併本場';

  @override
  String get mergeProgress => '正在合併本場…';

  @override
  String get renameAction => '重新命名';

  @override
  String get renameTitle => '重新命名錄影';

  @override
  String get confirmAction => '確定';

  @override
  String get batteryTitle => '允許背景繼續錄製';

  @override
  String get batteryBody => '鎖定或切到背景後，系統可能會暫停擷取。請在電池最佳化中忽略本應用程式，以便繼續錄製。';

  @override
  String get batteryOpenSettings => '前往設定';

  @override
  String get batteryLater => '以後再說';

  @override
  String get errorPermission => '需要相機、麥克風或 USB 權限才能擷取。';

  @override
  String get errorUsbHost => '此裝置不支援 USB Host，無法使用擷取卡。';

  @override
  String get errorUnsupportedPlatform => 'USB 擷取僅支援 Android 手機、平板和電視。';

  @override
  String get errorUvcFailed => '無法開啟擷取卡。請確認裝置為 UVC 擷取卡。';

  @override
  String get errorPowerIssue => '無法開啟擷取卡，可能供電不足。請嘗試帶供電的 USB Hub。';

  @override
  String get errorDisconnected => '擷取卡已拔出。';

  @override
  String get errorNoAudio => '擷取卡未提供可用音訊。';

  @override
  String get errorRecordingInProgress => '錄製進行中，無法更改格式或畫質。';

  @override
  String get errorSessionRecording => '這場正在錄製，請停錄後再合併。';

  @override
  String get errorConcatUnsupported => '目前平台不支援合併錄影。';

  @override
  String get errorConcatStorage => '儲存空間不足，無法合併。';

  @override
  String get errorConcatFailed => '合併失敗，原分段未改動。';

  @override
  String get errorPreviewOff => '請先開啟預覽。';

  @override
  String get errorNoPreview => '請先連接擷取卡。';

  @override
  String get errorStreamUnsupported => '目前平台不支援推流。';

  @override
  String get errorStreamInProgress => '推流進行中，無法更改格式或畫質。';

  @override
  String get errorMissingUrl => '請先填寫推流位址。';

  @override
  String get errorNoSignalStream => '無訊號，已停止推流。';

  @override
  String get errorConnectFailed => '無法連接推流伺服器。';

  @override
  String get errorHttpUnsupported => '目前平台不支援區域網播放。';

  @override
  String get errorHttpBindFailed => '無法開啟區域網播放連接埠。';

  @override
  String get errorHttpNoNetwork => '請先連接 Wi-Fi。';

  @override
  String get errorHttpLiveFailed => '現場編碼未啟動，已錄成片仍可播放。';

  @override
  String get errorStreamFailed => '推流失敗。';

  @override
  String get errorPlayFailed => '無法用系統播放器開啟。';

  @override
  String get errorRenameTaken => '已有同名錄影，請換一個名稱。';

  @override
  String get errorRenameInvalid => '名稱無效。請去掉斜線等特殊字元。';

  @override
  String get errorRenameUnsupported => '目前平台不支援重新命名。';

  @override
  String get errorRenameFailed => '重新命名失敗，原檔案未改動。';

  @override
  String get errorUnknown => '發生未知錯誤。';
}
