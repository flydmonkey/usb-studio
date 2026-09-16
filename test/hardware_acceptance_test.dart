import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'hardware acceptance requires a UVC capture card on the target device',
    () {},
    skip:
        '已在红米 Note 9 4G（M2010J19SC）验过：预览+监听；开录/停止成片进所选位置；片库看/分享/删除；锁屏或切走至少 10 分钟续录出多段；录制中拔线只丢当前段；忽略电池优化后通知仍在。换机或换采集卡时再跑一遍。',
  );
}
