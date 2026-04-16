import 'package:flutter_test/flutter_test.dart';
import 'package:poster_tool/main.dart';

void main() {
  testWidgets('app boots into splash screen', (tester) async {
    await tester.pumpWidget(const TamellakPosterTool());

    expect(find.text('Poster Tool'), findsOneWidget);
    expect(find.text('Prepare, review, and export ad posters.'), findsOneWidget);
  });
}
