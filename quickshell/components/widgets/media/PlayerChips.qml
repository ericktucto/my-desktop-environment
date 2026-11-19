import QtQuick
import Quickshell
import "../../../services/media/" as M

// Fichas para elegir el reproductor (Firefox, mpv…). Solo se usan con dos o más.
ItemChips {
    model: M.MediaStore.players.map(p => {
        const entry = p.desktopEntry !== "" ? DesktopEntries.byId(p.desktopEntry) : null;
        return {
            key: p,
            label: p.identity,
            icon: entry && entry.icon ? Quickshell.iconPath(entry.icon, true) : ""
        };
    })
    currentKey: M.MediaStore.player
    onPicked: key => M.MediaStore.select(key)
}
