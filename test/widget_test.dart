import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/main.dart'; // 確保路徑正確

void main() {
  testWidgets('基本載入測試', (WidgetTester tester) async {
    // 讓測試環境跑起你的音樂播放器
    await tester.pumpWidget(const MyMusicPlayer());

    // 只要能找到「音樂播放器」這幾個字，測試就算通過
    expect(find.textContaining('音樂播放器'), findsOneWidget);
  });
}
