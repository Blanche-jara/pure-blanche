/// The forge only needs two short, overlapping one-shot effects.
abstract class ForgeAudio {
  const ForgeAudio();
  Future<void> load() async {}
  void unlock() {}
  void setMusic({required bool playing}) {}
  void hammer({bool quiet = false});
  void shatter({bool quiet = false});
  void stop() {}
  void dispose() {}
}

/// Native/VM fallback; the delivered game runs in the browser.
class SilentForgeAudio extends ForgeAudio {
  const SilentForgeAudio();
  @override
  void hammer({bool quiet = false}) {}
  @override
  void shatter({bool quiet = false}) {}
}
