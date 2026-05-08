// It's Safe Link — shared dictionary
// MUST stay in sync with web/go/dict.js
//
// Token is a single control char with code 0x01 + index.
// Tokens never appear in real URLs, making substitution collision-free.

const List<String> _rawPrefixes = [
  'https://www.coupang.com/vp/products/',
  'https://link.coupang.com/a/',
  'https://www.youtube.com/watch?v=',
  'https://youtu.be/',
  'https://www.youtube.com/playlist?list=',
  'https://www.youtube.com/shorts/',
  'https://search.naver.com/search.naver?query=',
  'https://shopping.naver.com/',
  'https://blog.naver.com/',
  'https://cafe.naver.com/',
  'https://m.naver.com/',
  'https://www.notion.so/',
  'https://github.com/',
  'https://twitter.com/',
  'https://x.com/',
  'https://www.instagram.com/p/',
  'https://www.instagram.com/',
  'https://www.amazon.com/dp/',
  'https://map.naver.com/',
  'https://map.kakao.com/',
  'https://drive.google.com/file/d/',
  'https://docs.google.com/',
];

/// Display names for each prefix (UI only; same order as _rawPrefixes).
const List<String> _prefixLabels = [
  'Coupang Products',
  'Coupang Link',
  'YouTube Watch',
  'YouTube (youtu.be)',
  'YouTube Playlist',
  'YouTube Shorts',
  'Naver Search',
  'Naver Shopping',
  'Naver Blog',
  'Naver Cafe',
  'Naver Mobile',
  'Notion',
  'GitHub',
  'Twitter',
  'X',
  'Instagram Post',
  'Instagram',
  'Amazon Product',
  'Naver Map',
  'Kakao Map',
  'Google Drive File',
  'Google Docs',
];

/// (token, urlPrefix, label)
class DictEntry {
  final String token;
  final String prefix;
  final String label;
  const DictEntry(this.token, this.prefix, this.label);
}

final List<DictEntry> kDictEntries = [
  for (int i = 0; i < _rawPrefixes.length; i++)
    DictEntry(
      String.fromCharCode(1 + i),
      _rawPrefixes[i],
      _prefixLabels[i],
    ),
];

const Set<String> kTrackingParams = {
  // Universal
  'utm_source', 'utm_medium', 'utm_campaign', 'utm_term', 'utm_content',
  'fbclid', 'gclid', 'gclsrc', 'dclid', 'msclkid',
  'mc_cid', 'mc_eid', 'igshid',
  '_ga', '_gl',
  'ref', 'ref_src', 'ref_url', 'referrer',
  // YouTube
  'feature', 'si', 'pp', 't',
  // Coupang
  'sourceType', 'itemsCount', 'searchRank', 'rank', 'searchId', 'traceId',
  // Naver
  'where', 'frm', 'sm',
};

/// Apply dict prefix substitution. Returns (result, matchedLabelOrNull).
({String result, String? label}) applyDict(String url) {
  for (final entry in kDictEntries) {
    if (url.startsWith(entry.prefix)) {
      return (
        result: entry.token + url.substring(entry.prefix.length),
        label: entry.label,
      );
    }
  }
  return (result: url, label: null);
}

/// Strip known tracking params from query string.
/// Returns the cleaned URL (or original if no change).
String stripTracking(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null || uri.queryParameters.isEmpty) return url;
  final params = Map<String, String>.from(uri.queryParameters);
  final originalLen = params.length;
  params.removeWhere((k, _) => kTrackingParams.contains(k));
  if (params.length == originalLen) return url;
  final newUri = uri.replace(
    queryParameters: params.isEmpty ? null : params,
  );
  var result = newUri.toString();
  // Trim dangling '?' if all params were stripped.
  if (params.isEmpty && result.endsWith('?')) {
    result = result.substring(0, result.length - 1);
  }
  return result;
}
