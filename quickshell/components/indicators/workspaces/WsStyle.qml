import QtQuick
import "../../../services/workspaces/" as S

// Base de los estilos de la pill de workspaces. Cada estilo dibuja `items` (S.WorkspaceStore.items) con un
// Repeater dentro de una Row (`rowItem` y `rep`) y así `idAt(x)` sabe qué workspace hay bajo el mouse.
Item {
    id: root

    property var items: S.WorkspaceStore.items
    // El workspace bajo el mouse (0 = ninguno); lo pone la pill
    property int hoverId: 0
    // Para idAt: la fila de los workspaces y su Repeater
    property Item rowItem: null
    property Item rep: null

    // El id del workspace cuyo centro está más cerca de x (en coordenadas de este estilo); -1 si no hay ninguno
    function idAt(x) {
        if (!rowItem || !rep)
            return -1;
        let best = -1, bestDist = Infinity;
        for (let i = 0; i < rep.count; i++) {
            const d = rep.itemAt(i);
            if (!d)
                continue;
            const c = rowItem.mapToItem(root, d.x + d.width / 2, 0).x;
            const dist = Math.abs(c - x);
            if (dist < bestDist) {
                bestDist = dist;
                best = items[i].id;
            }
        }
        return best;
    }
}
