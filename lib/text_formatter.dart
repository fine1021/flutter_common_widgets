import 'dart:math' as math;

import 'package:characters/characters.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// A [TextInputFormatter] that prevents the insertion of more characters
/// (currently defined as Unicode scalar values) than allowed.
///
/// Since this formatter only prevents new characters from being added to the
/// text, it preserves the existing [TextEditingValue.selection].
///
///  * [maxLength], which discusses the precise meaning of "number of
///    characters" and how it may differ from the intuitive meaning.
class KnowableLengthLimitingTextInputFormatter extends TextInputFormatter {
  /// Creates a formatter that prevents the insertion of more characters than a
  /// limit.
  ///
  /// The [maxLength] must be null, -1 or greater than zero. If it is null or -1
  /// then no limit is enforced.
  KnowableLengthLimitingTextInputFormatter(
    this.maxLength, {
    this.onThreshold,
    this.maxLengthEnforcement,
  }) : assert(maxLength == null || maxLength == -1 || maxLength > 0);

  /// The limit on the number of characters (i.e. Unicode scalar values) this formatter
  /// will allow.
  ///
  /// The value must be null or greater than zero. If it is null, then no limit
  /// is enforced.
  ///
  /// This formatter does not currently count Unicode grapheme clusters (i.e.
  /// characters visible to the user), it counts Unicode scalar values, which leaves
  /// out a number of useful possible characters (like many emoji and composed
  /// characters), so this will be inaccurate in the presence of those
  /// characters. If you expect to encounter these kinds of characters, be
  /// generous in the maxLength used.
  ///
  /// For instance, the character "ö" can be represented as '\u{006F}\u{0308}',
  /// which is the letter "o" followed by a composed diaeresis "¨", or it can
  /// be represented as '\u{00F6}', which is the Unicode scalar value "LATIN
  /// SMALL LETTER O WITH DIAERESIS". In the first case, the text field will
  /// count two characters, and the second case will be counted as one
  /// character, even though the user can see no difference in the input.
  ///
  /// Similarly, some emoji are represented by multiple scalar values. The
  /// Unicode "THUMBS UP SIGN + MEDIUM SKIN TONE MODIFIER", "👍🏽", should be
  /// counted as a single character, but because it is a combination of two
  /// Unicode scalar values, '\u{1F44D}\u{1F3FD}', it is counted as two
  /// characters.
  final int? maxLength;

  final ValueChanged<int>? onThreshold;

  /// Determines how the [maxLength] limit should be enforced.
  ///
  /// Defaults to [MaxLengthEnforcement.enforced].
  ///
  /// {@macro flutter.services.textFormatter.maxLengthEnforcement}
  final MaxLengthEnforcement? maxLengthEnforcement;

  /// Returns a [MaxLengthEnforcement] that follows the specified [platform]'s
  /// convention.
  ///
  /// {@template flutter.services.textFormatter.effectiveMaxLengthEnforcement}
  /// ### Platform specific behaviors
  ///
  /// Different platforms follow different behaviors by default, according to
  /// their native behavior.
  ///  * Android, Windows: [MaxLengthEnforcement.enforced]. The native behavior
  ///    of these platforms is enforced. The composing will be handled by the
  ///    IME while users are entering CJK characters.
  ///  * iOS: [MaxLengthEnforcement.truncateAfterCompositionEnds]. iOS has no
  ///    default behavior and it requires users implement the behavior
  ///    themselves. Allow the composition to exceed to avoid breaking CJK input.
  ///  * Web, macOS, linux, fuchsia:
  ///    [MaxLengthEnforcement.truncateAfterCompositionEnds]. These platforms
  ///    allow the composition to exceed by default.
  /// {@endtemplate}
  static MaxLengthEnforcement getDefaultMaxLengthEnforcement([
    TargetPlatform? platform,
  ]) {
    if (kIsWeb) {
      return MaxLengthEnforcement.truncateAfterCompositionEnds;
    } else {
      switch (platform ?? defaultTargetPlatform) {
        case TargetPlatform.android:
        case TargetPlatform.windows:
          return MaxLengthEnforcement.enforced;
        case TargetPlatform.iOS:
        case TargetPlatform.macOS:
        case TargetPlatform.linux:
        case TargetPlatform.fuchsia:
          return MaxLengthEnforcement.truncateAfterCompositionEnds;
      }
    }
  }

  /// Truncate the given TextEditingValue to maxLength user-perceived
  /// characters.
  ///
  /// See also:
  ///  * [Dart's characters package](https://pub.dev/packages/characters).
  ///  * [Dart's documentation on runes and grapheme clusters](https://dart.dev/guides/language/language-tour#runes-and-grapheme-clusters).
  @visibleForTesting
  static TextEditingValue truncate(TextEditingValue value, int maxLength) {
    final CharacterRange iterator = CharacterRange(value.text);
    if (value.text.characters.length > maxLength) {
      iterator.expandNext(maxLength);
    }
    final String truncated = iterator.current;

    return TextEditingValue(
      text: truncated,
      selection: value.selection.copyWith(
        baseOffset: math.min(value.selection.start, truncated.length),
        extentOffset: math.min(value.selection.end, truncated.length),
      ),
      composing: !value.composing.isCollapsed &&
              truncated.length > value.composing.start
          ? TextRange(
              start: value.composing.start,
              end: math.min(value.composing.end, truncated.length),
            )
          : TextRange.empty,
    );
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue, // unused.
    TextEditingValue newValue,
  ) {
    final int? maxLength = this.maxLength;

    if (maxLength == null ||
        maxLength == -1 ||
        newValue.text.characters.length <= maxLength) {
      return newValue;
    }

    assert(maxLength > 0);
    onThreshold?.call(maxLength);

    switch (maxLengthEnforcement ?? getDefaultMaxLengthEnforcement()) {
      case MaxLengthEnforcement.none:
        return newValue;
      case MaxLengthEnforcement.enforced:
        // If already at the maximum and tried to enter even more, and has no
        // selection, keep the old value.
        if (oldValue.text.characters.length == maxLength &&
            oldValue.selection.isCollapsed) {
          return oldValue;
        }

        // Enforced to return a truncated value.
        return truncate(newValue, maxLength);
      case MaxLengthEnforcement.truncateAfterCompositionEnds:
        // If already at the maximum and tried to enter even more, and the old
        // value is not composing, keep the old value.
        if (oldValue.text.characters.length == maxLength &&
            !oldValue.composing.isValid) {
          return oldValue;
        }

        // Temporarily exempt `newValue` from the maxLength limit if it has a
        // composing text going and no enforcement to the composing value, until
        // the composing is finished.
        if (newValue.composing.isValid) {
          return newValue;
        }

        return truncate(newValue, maxLength);
    }
  }
}

/// A [TextInputFormatter] that prevents the insertion of more characters
/// (currently defined as Unicode scalar values) than allowed.
///
/// Since this formatter only prevents new characters from being added to the
/// text, it preserves the existing [TextEditingValue.selection].
///
///  * [maxLength], which discusses the precise meaning of "number of
///    characters" and how it may differ from the intuitive meaning.
class InterceptLengthLimitingTextInputFormatter extends TextInputFormatter {
  /// Creates a formatter that prevents the insertion of more characters than a
  /// limit.
  ///
  /// The [maxLength] must be null, -1 or greater than zero. If it is null or -1
  /// then no limit is enforced.
  InterceptLengthLimitingTextInputFormatter(
    this.maxLength, {
    this.onIntercept,
  }) : assert(maxLength == null || maxLength == -1 || maxLength > 0);

  /// The limit on the number of characters (i.e. Unicode scalar values) this formatter
  /// will allow.
  ///
  /// The value must be null or greater than zero. If it is null, then no limit
  /// is enforced.
  ///
  /// This formatter does not currently count Unicode grapheme clusters (i.e.
  /// characters visible to the user), it counts Unicode scalar values, which leaves
  /// out a number of useful possible characters (like many emoji and composed
  /// characters), so this will be inaccurate in the presence of those
  /// characters. If you expect to encounter these kinds of characters, be
  /// generous in the maxLength used.
  ///
  /// For instance, the character "ö" can be represented as '\u{006F}\u{0308}',
  /// which is the letter "o" followed by a composed diaeresis "¨", or it can
  /// be represented as '\u{00F6}', which is the Unicode scalar value "LATIN
  /// SMALL LETTER O WITH DIAERESIS". In the first case, the text field will
  /// count two characters, and the second case will be counted as one
  /// character, even though the user can see no difference in the input.
  ///
  /// Similarly, some emoji are represented by multiple scalar values. The
  /// Unicode "THUMBS UP SIGN + MEDIUM SKIN TONE MODIFIER", "👍🏽", should be
  /// counted as a single character, but because it is a combination of two
  /// Unicode scalar values, '\u{1F44D}\u{1F3FD}', it is counted as two
  /// characters.
  final int maxLength;

  final InterceptValue<TextEditingValue>? onIntercept;

  /// Truncate the given TextEditingValue to maxLength characters.
  ///
  /// See also:
  ///  * [Dart's characters package](https://pub.dev/packages/characters).
  ///  * [Dart's documenetation on runes and grapheme clusters](https://dart.dev/guides/language/language-tour#runes-and-grapheme-clusters).
  @visibleForTesting
  static TextEditingValue truncate(TextEditingValue value, int maxLength) {
    final CharacterRange iterator = CharacterRange(value.text);
    if (value.text.characters.length > maxLength) {
      iterator.expandNext(maxLength);
    }
    final String truncated = iterator.current;
    return TextEditingValue(
      text: truncated,
      selection: value.selection.copyWith(
        baseOffset: math.min(value.selection.start, truncated.length),
        extentOffset: math.min(value.selection.end, truncated.length),
      ),
      composing: TextRange.empty,
    );
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue, // unused.
    TextEditingValue newValue,
  ) {
    if (maxLength != null &&
        maxLength > 0 &&
        newValue.text.characters.length > maxLength) {
      // Intercept edit value if need
      TextEditingValue? value = onIntercept?.call(newValue);
      if (value != null && value.text.characters.length <= maxLength) {
        return value;
      }
      // If already at the maximum and tried to enter even more, keep the old
      // value.
      if (oldValue.text.characters.length == maxLength) {
        return oldValue;
      }
      return truncate(newValue, maxLength);
    }
    return newValue;
  }
}

typedef InterceptValue<T> = T? Function(T value);
