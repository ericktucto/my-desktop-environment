import QtQuick
import "../../base" as Base
import "../../../" as App
import "../../indicators/" as I

Base.Island {
    id: root

    property string current: 'applist'

    expandedHeight: {
        if (current == 'applist')
            return 600;
        if (current == 'wallpapers')
            return App.Config.imgHeight * 2 + App.Config.spacingCell * 2 + 32;
        return 300;
    }
    expandedWidth: {
        if (current == 'applist')
            return 480;
        if (current == 'wallpapers')
            return 800;
        return 400;
    }

    radiusExpanded: 32

    preventFocus: true

    I.ClockText {}

    body: IslandBody {
        root: root
    }

    onOpened: {
        console.log("Island abierta, wallpaper actual", App.Wallpaper.current);
    }
}
