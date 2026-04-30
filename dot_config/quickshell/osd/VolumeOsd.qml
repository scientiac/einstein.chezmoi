import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Item {
	id: root

	// === Exposed live state ===
	readonly property real sinkVolume: _sink && _sink.audio ? _sink.audio.volume : 0
	readonly property bool sinkMuted: _sink && _sink.audio ? _sink.audio.muted : false
	readonly property real sourceVolume: _source && _source.audio ? _source.audio.volume : 0
	readonly property bool sourceMuted: _source && _source.audio ? _source.audio.muted : false

	// === Change signals ===
	signal volumeChanged()
	signal micChanged()

	// === Internal ===
	property var _sink: Pipewire.defaultAudioSink
	property var _source: Pipewire.defaultAudioSource

	PwObjectTracker { objects: [Pipewire.defaultAudioSink] }
	PwObjectTracker { objects: [Pipewire.defaultAudioSource] }

	Connections {
		target: _sink ? _sink.audio : null
		function onVolumeChanged() { root.volumeChanged() }
		function onMutedChanged() { root.volumeChanged() }
	}

	Connections {
		target: _source ? _source.audio : null
		function onVolumeChanged() { root.micChanged() }
		function onMutedChanged() { root.micChanged() }
	}

	// === Control functions ===
	function setVolume(val) {
		if (_sink && _sink.audio) _sink.audio.volume = Math.max(0, Math.min(1.5, val));
	}
	function toggleMute() {
		if (_sink && _sink.audio) _sink.audio.muted = !_sink.audio.muted;
	}
	function setMicVolume(val) {
		if (_source && _source.audio) _source.audio.volume = Math.max(0, Math.min(1.5, val));
	}
	function toggleMicMute() {
		if (_source && _source.audio) _source.audio.muted = !_source.audio.muted;
	}
}
