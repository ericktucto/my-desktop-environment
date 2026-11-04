import QtQuick
import "../../base" as Base
import "../../../" as App
import "../../indicators/" as I

Base.Island {
    id: root

    property string current: 'applist'

    expandedHeight: {
        if (current == 'applist')
            return App.Config.panel.launcherHeight;
        if (current == 'wallpapers')
            return App.Config.wallpaperPicker.imgHeight * 2 + App.Config.wallpaperPicker.spacingCell * 2 + 2 * App.Config.pill.padding;
        return 300;
    }
    expandedWidth: {
        if (current == 'applist')
            return App.Config.panel.launcherWidth;
        if (current == 'wallpapers')
            return App.Config.panel.wallpapersWidth;
        return 400;
    }

    preventFocus: true

    I.ClockText {}

    body: IslandBody {
        root: root
    }

    onClicked: {
        current = 'applist';
    }

    onOpened: {
        console.log("Island abierta, wallpaper actual", App.Wallpaper.current);
    }
}
