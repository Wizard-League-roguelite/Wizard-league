// ===== music.js (stubs — synth engine removed) =====
let _musicEnabled = true;
let _volumeLevel  = 0.50;
let _mutedByBtn   = false;
let _audioStarted = false;  // true after first gesture fires

function _tryResumeAudio() {}
function musicPlay(key) {}
function musicStop() {}

// Get the live MP3 element safely (declared later in mp3audio.js)
function _getVol() { return (typeof _mp3El !== 'undefined' && _mp3El) ? _mp3El : null; }

function volumeSet(val) {
  const v = Math.max(0, Math.min(100, Number(val))) / 100;
  _volumeLevel  = v;
  _mutedByBtn   = (v === 0);
  _musicEnabled = (v > 0);
  const el = _getVol();
  if (el) el.volume = v;
  _updateVolIcon();
}

function volumeToggleMute() {
  // If audio hasn't started yet, let _firstGesture handle it — don't mute
  if (!_audioStarted) return;

  if (_mutedByBtn || !_musicEnabled) {
    // Unmute
    _mutedByBtn   = false;
    _musicEnabled = true;
    const v = Math.max(0.10, _volumeLevel);
    _volumeLevel  = v;
    const el = _getVol();
    if (el) {
      el.volume = v;
      if (el.paused) el.play().catch(function(){});
    }
    const slider = document.getElementById('vol-slider');
    if (slider) slider.value = Math.round(v * 100);
  } else {
    // Mute
    _mutedByBtn   = true;
    _musicEnabled = false;
    const el = _getVol();
    if (el) el.volume = 0;
  }
  _updateVolIcon();
}

function _updateVolIcon() {
  const icon = document.getElementById('vol-icon');
  if (!icon) return;
  const muted = _mutedByBtn || !_musicEnabled || _volumeLevel === 0;
  icon.textContent = muted ? '\uD83D\uDD07' : (_volumeLevel < 0.4 ? '\uD83D\uDD09' : '\uD83D\uDD0A');
}

function musicToggle() {
  volumeToggleMute();
  return _musicEnabled;
}

