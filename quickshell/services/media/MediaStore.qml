pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import "../../" as App

// Reproductor multimedia (MPRIS): qué reproductor se muestra, su estado y las acciones.
Singleton {
    id: store

    readonly property var cfg: App.Config.media

    // ── Reproductores con una pista ──
    readonly property var players: Mpris.players.values.filter(p => p.trackTitle !== "")

    // El que eligió el usuario en las fichas (por dbusName); si no, el último que empezó a sonar; si no, el primero
    property string pickedBus: ""
    property string lastPlayingBus: ""

    readonly property var player: {
        const list = players;
        if (list.length === 0)
            return null;
        const picked = list.find(p => p.dbusName === pickedBus);
        if (picked)
            return picked;
        // El último que empezó a sonar, aunque ahora esté en pausa: pausar no hace saltar la pill a otro reproductor
        const last = list.find(p => p.dbusName === lastPlayingBus);
        if (last)
            return last;
        return list.find(p => p.isPlaying) || list[0];
    }

    // Recuerda cuál empezó a sonar último
    Instantiator {
        model: Mpris.players
        delegate: QtObject {
            required property var modelData
            readonly property bool playing: modelData.isPlaying
            onPlayingChanged: {
                if (playing)
                    store.lastPlayingBus = modelData.dbusName;
            }
            // Al arrancar la shell, si ya suena alguno y no hay otro anotado, es ese
            Component.onCompleted: {
                if (playing && store.lastPlayingBus === "")
                    store.lastPlayingBus = modelData.dbusName;
            }
        }
    }

    function select(p) {
        pickedBus = p.dbusName;
    }

    // ── Estado ──
    readonly property bool anyPlaying: Mpris.players.values.some(p => p.isPlaying)
    readonly property bool playing: player ? player.isPlaying : false

    // Sin sonar el reproductor que se muestra durante `hideAfter`, la pill se oculta (vuelve apenas suene)
    property bool expired: false
    readonly property bool visible: player !== null && !expired

    Timer {
        interval: store.cfg.hideAfter
        running: store.player !== null && !store.playing
        onTriggered: store.expired = true
    }
    onPlayingChanged: {
        if (playing)
            expired = false;
    }

    // ── Posición ──
    // `position` no avisa sola: se emite mientras suena y la pill se ve
    readonly property real position: player ? player.position : 0
    readonly property real length: player && player.lengthSupported ? player.length : 0
    readonly property bool isLive: player !== null && (!player.lengthSupported || player.length <= 0)
    // 0..1, limitado (hay reproductores que dan posiciones fuera de la duración)
    readonly property real progress: isLive || length <= 0 ? 0 : Math.max(0, Math.min(1, position / length))

    Timer {
        interval: store.cfg.pollInterval
        repeat: true
        running: store.visible && store.playing
        onTriggered: store.player.positionChanged()
    }

    // La posición se reinicia al cambiar de canción
    Connections {
        target: store.player
        function onPostTrackChanged() {
            store.player.positionChanged();
        }
    }

    // ── Carátula ──
    // Muchos reproductores mandan la carátula un momento después de cambiar la canción: se mantiene la
    // anterior; si en `artTimeout` no llega, se muestra el ícono de la app.
    readonly property string art: player ? player.trackArtUrl : ""
    property string shownArt: ""
    onArtChanged: {
        if (art !== "") {
            shownArt = art;
            artTimer.stop();
        } else {
            artTimer.restart();
        }
    }
    onPlayerChanged: {
        expired = false;
        shownArt = art;
    }

    Timer {
        id: artTimer
        interval: store.cfg.artTimeout
        onTriggered: store.shownArt = ""
    }

    // Ícono de la app del reproductor (Firefox, mpv…)
    readonly property var appEntry: player && player.desktopEntry !== "" ? DesktopEntries.byId(player.desktopEntry) : null
    readonly property string appIcon: appEntry && appEntry.icon ? Quickshell.iconPath(appEntry.icon, true) : ""
    // Para forzar que DesktopEntries se llene aunque no se haya abierto el launcher
    readonly property var desktopApps: DesktopEntries.applications.values

    // ── Acciones ──
    function togglePlaying() {
        if (player && player.canTogglePlaying)
            player.togglePlaying();
    }

    function next() {
        if (player && player.canGoNext)
            player.next();
    }

    function previous() {
        if (player && player.canGoPrevious)
            player.previous();
    }

    function seekBy(sec) {
        if (player && player.canSeek)
            player.seek(sec);
    }

    function seekTo(fraction) {
        if (player && player.canSeek && player.positionSupported && length > 0)
            player.position = Math.max(0, Math.min(1, fraction)) * length;
    }

    // Volumen del propio reproductor (no el del sistema)
    readonly property bool canVolume: player !== null && player.volumeSupported && player.canControl
    readonly property real volume: player && player.volumeSupported ? player.volume : 1

    function changeVolume(delta) {
        if (canVolume)
            player.volume = Math.max(0, Math.min(1, player.volume + delta));
    }

    function setVolume(v) {
        if (canVolume)
            player.volume = Math.max(0, Math.min(1, v));
    }

    function toggleShuffle() {
        if (player && player.shuffleSupported && player.canControl)
            player.shuffle = !player.shuffle;
    }

    // Sin repetir → repetir la lista → repetir la canción
    function cycleLoop() {
        if (!player || !player.loopSupported || !player.canControl)
            return;
        const s = player.loopState;
        player.loopState = s === MprisLoopState.None ? MprisLoopState.Playlist : (s === MprisLoopState.Playlist ? MprisLoopState.Track : MprisLoopState.None);
    }

    function raise() {
        if (player && player.canRaise)
            player.raise();
    }

    // ── El anillo de la pill muestra el volumen un momento tras mover la rueda ──
    property bool showVolume: false

    function volumeWheel(delta) {
        changeVolume(delta);
        showVolume = true;
        volumeTimer.restart();
    }

    Timer {
        id: volumeTimer
        interval: store.cfg.volumeOsd
        onTriggered: store.showVolume = false
    }

    // Abrir o cerrar el panel (lo escucha la pill)
    signal togglePanel

    // qs ipc call stixshell@media playPause|next|previous|seek <seg>|toggle (hypr/keybinds/media.lua)
    IpcHandler {
        target: "stixshell@media"
        function playPause(): void {
            store.togglePlaying();
        }
        function next(): void {
            store.next();
        }
        function previous(): void {
            store.previous();
        }
        function seek(seconds: int): void {
            store.seekBy(seconds);
        }
        function toggle(mon: string): void {
            store.togglePanel();
        }
    }
}
