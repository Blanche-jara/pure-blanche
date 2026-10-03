import 'forge_audio.dart';
import 'forge_audio_stub.dart'
    if (dart.library.js_interop) 'forge_audio_web.dart'
    as platform;

ForgeAudio createForgeAudio() => platform.createForgeAudio();
