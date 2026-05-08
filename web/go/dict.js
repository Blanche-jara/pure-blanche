// It's Safe Link — shared dictionary
// MUST stay in sync with lib/apps/safe_link/_dict.dart
// Used by both:
//   - lib/apps/safe_link/safe_link_app.dart  (encoder, via JS interop)
//   - web/go/index.html                       (decoder)
//
// Tokens are control chars (\x01..\x1F) — these never appear in real URLs,
// so the substitution is collision-free.
(function (global) {
  // Build [token, prefix] pairs. Token is single char with code 0x01 + index.
  // Order matters: longer/more-specific prefixes must come first when ambiguous.
  var rawPrefixes = [
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

  global.SafeLinkDict = {
    /// [token, urlPrefix] pairs.
    prefixes: rawPrefixes.map(function (p, i) {
      return [String.fromCharCode(1 + i), p];
    }),

    /// Query parameters stripped when "Strip tracking" toggle is ON.
    trackingParams: [
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
    ],
  };
})(typeof window !== 'undefined' ? window : globalThis);
