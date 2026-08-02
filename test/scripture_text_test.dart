import 'package:flutter_test/flutter_test.dart';

import 'package:bible_pulse/utils/scripture_text.dart';

void main() {
  test('strips Strong numbers and restores word spacing', () {
    const raw =
        'I|strong="G1473"am|strong="G1510"the|strong="G2532"Alpha and|strong="G2532"the|strong="G2532"Omega|strong="G5598",';
    expect(
      ScriptureText.clean(raw),
      'I am the Alpha and the Omega,',
    );
  });

  test('leaves clean scripture unchanged', () {
    const raw = 'In the beginning God created the heavens and the earth.';
    expect(ScriptureText.clean(raw), raw);
  });

  test('handles Hebrew Strong tags', () {
    const raw =
        'Therefore it is said in The|strong="H5921"Book|strong="H5612"of|strong="H3068"Wars';
    expect(
      ScriptureText.clean(raw),
      'Therefore it is said in The Book of Wars',
    );
  });
}
