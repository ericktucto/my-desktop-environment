pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../../" as App

// Historial del portapapeles con cliphist. Quien lo llena son los dos `wl-paste --watch cliphist store`
// de hypr/autostart.lua; aquí solo se lee, se copia, se borra y se prepara lo que necesitan las acciones
// del panel (imágenes decodificadas, QR, archivos para compartir).
Singleton {
    id: store

    readonly property string cacheDir: App.Config.clipboard.cacheDir

    // [{ id, preview, search, isImage, format, mime, size, width, height }], el más reciente primero
    property var entries: []
    property var byId: ({})             // id → elemento (las listas usan solo los ids)
    property bool loaded: false
    property bool watching: true        // hay un `wl-paste` vigilando (si no, nada se guarda)
    property bool qrAvailable: false    // python3-qrcode (con Pillow) instalado
    property var imageUrls: ({})        // id → file:// de la imagen ya decodificada

    // Vista previa del elemento seleccionado (texto completo, con tope)
    property string previewId: ""
    property string previewText: ""
    property int previewChars: 0
    property int previewLines: 0
    property bool previewTruncated: false
    readonly property int previewMax: 20000

    // ── Ejecutar un comando y recibir su salida (y el fin del proceso) ──
    // Con `done(salida, códigoDeSalida)`. Para lo que deja procesos vivos (wl-copy) usar execDetached.
    Component {
        id: runner
        Process {
            id: p
            property var done
            property string out: ""
            property int code: -1
            property bool outDone: false
            property bool exitDone: false

            stdout: StdioCollector {
                onStreamFinished: {
                    p.out = text;
                    p.outDone = true;
                    p.finish();
                }
            }
            onExited: function (exitCode, exitStatus) {
                p.code = exitCode;
                p.exitDone = true;
                p.finish();
            }
            function finish() {
                if (!outDone || !exitDone)
                    return;
                if (done)
                    done(out, code);
                destroy();
            }
        }
    }

    function run(cmd, done) {
        const p = runner.createObject(store, {
            command: cmd,
            done: done
        });
        p.running = true;
    }

    // ── Lista ──
    // Los gestores de archivos (Nemo…) copian la ruta del archivo como texto, a veces como file://… o con
    // "copy "/"cut " delante. Si es una imagen, se trata como imagen. → { path, format } o null
    function imageFile(text) {
        const m = text.trim().match(/^(?:(?:copy|cut) )?(file:\/\/)?(\/.+\.(png|jpe?g|gif|webp|bmp))$/i);
        if (!m)
            return null;
        let path = m[2];
        if (m[1]) {
            try {
                path = decodeURIComponent(path);
            } catch (e) {
                return null;
            }
        }
        return {
            path: path,
            format: m[3].toLowerCase()
        };
    }

    function fileUrl(path) {
        return "file://" + path.split("/").map(encodeURIComponent).join("/");
    }

    // ── Archivos copiados desde un gestor de archivos (una o varias rutas, de cualquier tipo) ──
    property var fileInfo: ({})     // id → { files: [...], total } o { notFiles: true }
    property var toInspect: []      // cola de ids por inspeccionar
    property var candidates: []     // ids que parse() encontró sin inspeccionar (los toma refresh)
    property bool inspecting: false
    property string rawList: ""

    function fileGlyph(mime, name, isDir) {
        if (isDir)
            return 0xf024b;
        const ext = name.indexOf(".") >= 0 ? name.substring(name.lastIndexOf(".") + 1).toLowerCase() : "";
        if (mime.indexOf("image/") === 0)
            return 0xf02e9;
        if (mime.indexOf("audio/") === 0)
            return 0xf0386;
        if (mime.indexOf("video/") === 0)
            return 0xf0567;
        if (mime === "application/pdf")
            return 0xf0226;
        if (/^(docx?|odt|rtf)$/.test(ext) || mime.indexOf("wordprocessing") >= 0 || mime.indexOf("msword") >= 0)
            return 0xf022c;
        if (/^(xlsx?|ods|csv)$/.test(ext) || mime.indexOf("spreadsheet") >= 0 || mime.indexOf("ms-excel") >= 0)
            return 0xf021b;
        if (/^(zip|rar|7z|tar|gz|xz|bz2)$/.test(ext) || mime.indexOf("zip") >= 0 || mime.indexOf("compressed") >= 0 || mime.indexOf("tar") >= 0)
            return 0xf05c4;
        if (mime.indexOf("text/") === 0)
            return 0xf0219;
        return 0xf0214;
    }

    // Nombre legible del tipo (el MIME de un .docx ocupa media pantalla)
    function typeLabel(mime, name) {
        const ext = name.indexOf(".") >= 0 ? name.substring(name.lastIndexOf(".") + 1).toLowerCase() : "";
        if (mime === "application/pdf")
            return "PDF";
        if (mime.indexOf("wordprocessing") >= 0 || mime.indexOf("msword") >= 0 || /^(docx?|odt)$/.test(ext))
            return "Word";
        if (mime.indexOf("spreadsheet") >= 0 || mime.indexOf("ms-excel") >= 0 || /^(xlsx?|ods)$/.test(ext))
            return "Excel";
        if (mime.indexOf("presentation") >= 0 || mime.indexOf("powerpoint") >= 0 || /^(pptx?|odp)$/.test(ext))
            return "PowerPoint";
        if (mime.indexOf("zip") >= 0 || /^(zip|rar|7z|tar|gz|xz)$/.test(ext))
            return "Comprimido";
        if (mime === "text/plain")
            return "Texto";
        if (mime === "inode/directory")
            return "Carpeta";
        const kind = mime.split("/")[0];
        if (kind === "audio")
            return "Audio";
        if (kind === "video")
            return "Video";
        if (kind === "image")
            return "Imagen";
        return mime === "application/octet-stream" ? "Archivo" : mime;
    }

    function sizeText(bytes) {
        if (bytes < 1024)
            return bytes + " B";
        const units = ["KiB", "MiB", "GiB", "TiB"];
        let v = bytes / 1024;
        let i = 0;
        while (v >= 1024 && i < units.length - 1) {
            v /= 1024;
            i++;
        }
        return (v >= 100 || Number.isInteger(v) ? Math.round(v) : v.toFixed(1).replace(".", ",")) + " " + units[i];
    }

    // Texto copiado → rutas absolutas, o null si no es una lista de archivos.
    // Acepta rutas, file://… (con %20…) y "copy"/"cut" en la primera línea (x-special/gnome-copied-files).
    function pathsFrom(text) {
        let lines = text.split("\n").map(l => l.trim()).filter(l => l !== "");
        if (lines.length > 0 && (lines[0] === "copy" || lines[0] === "cut"))
            lines = lines.slice(1);
        if (lines.length === 0)
            return null;
        const paths = [];
        for (const l of lines) {
            if (l.indexOf("file://") === 0) {
                try {
                    paths.push(decodeURIComponent(l.substring(7)));
                } catch (e) {
                    return null;
                }
            } else if (l[0] === "/") {
                paths.push(l);
            } else {
                return null;
            }
        }
        return paths;
    }

    // Entrada de tipo "archivos": uno (pdf, docx, carpeta…) o varios
    function fileEntry(id, text, info) {
        const files = info.files;
        const one = files.length === 1 && info.total === 1 ? files[0] : null;
        let bytes = 0;
        for (const f of files)
            bytes += f.size;
        const sizeLabel = store.sizeText(bytes);
        return {
            id: id,
            preview: one ? (one.isDir ? "Carpeta · " : "Archivo · ") + one.name : info.total + " archivos",
            search: (files.map(f => f.name + " " + f.path).join(" ") + " archivo archivos " + files.map(f => f.mime).join(" ")).toLowerCase(),
            isImage: false,
            isFiles: true,
            files: files,
            count: info.total,
            name: one ? one.name : info.total + " archivos",
            glyph: one ? one.glyph : 0xf0222,
            // texto secundario de la fila
            subtitle: one ? (one.exists ? (one.isDir ? "Carpeta" : one.type + " · " + one.sizeText) : "No existe") : files.slice(0, 3).map(f => f.name).join(", ") + (info.total > 3 ? "…" : ""),
            format: "",
            mime: one ? one.mime : "application/octet-stream",
            size: sizeLabel,
            width: 0,
            height: 0
        };
    }

    function inspectNext() {
        if (inspecting || toInspect.length === 0)
            return;
        inspecting = true;
        const id = toInspect.shift();
        run(["cliphist", "decode", id], function (text) {
            const paths = store.pathsFrom(text);
            if (!paths) {
                store.inspected(id, null);
                return;
            }
            const shown = paths.slice(0, 50);
            // tipo: d = carpeta, f = archivo, m = no existe
            const script = 'for f in "$@"; do if [ -d "$f" ]; then printf "d\t0\tinode/directory\t%s\n" "$f"; elif [ -e "$f" ]; then printf "f\t%s\t%s\t%s\n" "$(stat -c %s "$f")" "$(xdg-mime query filetype "$f")" "$f"; else printf "m\t0\t-\t%s\n" "$f"; fi; done';
            run(["sh", "-c", script, "_"].concat(shown), function (out) {
                const files = [];
                for (const line of out.split("\n")) {
                    const p = line.split("\t");
                    if (p.length < 4)
                        continue;
                    const path = p.slice(3).join("\t");
                    const name = path.substring(path.lastIndexOf("/") + 1) || path;
                    const size = parseInt(p[1]) || 0;
                    const isDir = p[0] === "d";
                    const mime = p[2];
                    files.push({
                        path: path,
                        name: name,
                        exists: p[0] !== "m",
                        isDir: isDir,
                        size: size,
                        sizeText: store.sizeText(size),
                        mime: mime,
                        type: store.typeLabel(mime, name),
                        glyph: store.fileGlyph(mime, name, isDir)
                    });
                }
                // Si ninguna ruta existe, era un texto cualquiera
                store.inspected(id, files.some(f => f.exists) ? {
                    files: files,
                    total: paths.length
                } : null);
            });
        });
    }

    function inspected(id, info) {
        const m = Object.assign({}, fileInfo);
        m[id] = info || {
            notFiles: true
        };
        fileInfo = m;
        inspecting = false;
        // Lo ya inspeccionado se refleja en la lista; después, el siguiente
        if (info)
            applyList(rawList);
        inspectNext();
    }

    function applyList(out) {
        const list = store.parse(out);
        const map = {};
        for (const e of list)
            map[e.id] = e;
        store.byId = map;
        store.entries = list;
    }

    function parse(out) {
        const res = [];
        store.candidates = [];
        const lines = out.split("\n");
        for (let i = 0; i < lines.length && res.length < App.Config.clipboard.maxEntries; i++) {
            const line = lines[i];
            const tab = line.indexOf("\t");
            if (tab < 1)
                continue;
            const id = line.substring(0, tab);
            const text = line.substring(tab + 1);
            // [[ binary data 245 KiB png 1920x1080 ]]
            const m = text.match(/^\[\[ binary data (.+) (\w+) (\d+)x(\d+) \]\]$/);
            if (m) {
                const fmt = m[2].toLowerCase();
                res.push({
                    id: id,
                    preview: "Imagen · " + fmt.toUpperCase(),
                    search: "imagen " + fmt + " " + m[3] + "x" + m[4],
                    isImage: true,
                    format: fmt,
                    mime: "image/" + (fmt === "jpg" ? "jpeg" : fmt),
                    size: m[1],
                    width: parseInt(m[3]),
                    height: parseInt(m[4])
                });
            } else if (store.imageFile(text)) {
                const f = store.imageFile(text);
                const name = f.path.substring(f.path.lastIndexOf("/") + 1);
                res.push({
                    id: id,
                    preview: "Imagen · " + f.format.toUpperCase(),
                    search: ("imagen " + f.format + " " + text).toLowerCase(),
                    isImage: true,
                    isFile: true,
                    filePath: f.path,
                    name: name,
                    format: f.format,
                    mime: "image/" + (f.format === "jpg" ? "jpeg" : f.format),
                    size: "",
                    width: 0,
                    height: 0
                });
            } else if (store.fileInfo[id] && store.fileInfo[id].files) {
                res.push(store.fileEntry(id, text, store.fileInfo[id]));
            } else {
                // ¿Podría ser una lista de archivos? Se comprueba después (hay que leer el texto completo)
                if (!store.fileInfo[id] && /^(?:(?:copy|cut) )?(?:file:\/\/)?\//.test(text))
                    store.candidates.push(id);
                res.push({
                    id: id,
                    preview: text,
                    search: text.toLowerCase(),
                    isImage: false,
                    format: "",
                    mime: "text/plain",
                    size: "",
                    width: 0,
                    height: 0
                });
            }
        }
        return res;
    }

    function refresh() {
        run(["cliphist", "list"], function (out) {
            store.rawList = out;
            store.applyList(out);
            store.toInspect = store.candidates.slice();
            store.loaded = true;
            store.inspectNext();
        });
        run(["pgrep", "-x", "wl-paste"], function (out) {
            store.watching = out.trim() !== "";
        });
        run(["python3", "-c", "import qrcode, PIL; print('ok')"], function (out) {
            store.qrAvailable = out.trim() === "ok";
        });
    }

    // ── Vista previa del texto ──
    property string wantId: ""
    property bool previewBusy: false

    function loadPreview(id) {
        wantId = id;
        if (previewBusy)
            return;
        previewBusy = true;
        run(["cliphist", "decode", id], function (out) {
            store.previewBusy = false;
            if (store.wantId === id) {
                store.previewChars = out.length;
                store.previewLines = out.replace(/\n$/, "").split("\n").length;
                store.previewTruncated = out.length > store.previewMax;
                store.previewText = store.previewTruncated ? out.slice(0, store.previewMax) : out;
                store.previewId = id;
            } else if (store.wantId !== "") {
                store.loadPreview(store.wantId);
            }
        });
    }

    function clearPreview() {
        wantId = "";
        previewId = "";
        previewText = "";
    }

    // ── Imágenes: se decodifican a la caché, unas pocas a la vez ──
    property var requested: ({})
    property var queue: []
    property int active: 0

    function requestImage(entry) {
        const id = entry.id;
        if (requested[id])
            return;
        requested[id] = true;
        if (entry.isFile) {
            // ya es un archivo: no hay nada que decodificar
            const u = Object.assign({}, imageUrls);
            u[id] = fileUrl(entry.filePath);
            imageUrls = u;
            return;
        }
        queue.push({
            id: id,
            format: entry.format
        });
        pump();
    }

    function pump() {
        while (active < App.Config.clipboard.decodeJobs && queue.length > 0) {
            const job = queue.shift();
            active++;
            const path = cacheDir + "/" + job.id + "." + job.format;
            run(["sh", "-c", 'mkdir -p "$3" && cliphist decode "$1" > "$2"', "_", job.id, path, cacheDir], function () {
                store.active--;
                const u = Object.assign({}, store.imageUrls);
                u[job.id] = "file://" + path;
                store.imageUrls = u;
                store.pump();
            });
        }
    }

    // ── Acciones ──
    function copy(entry) {
        if (entry.isFile) {
            Quickshell.execDetached(["sh", "-c", 'wl-copy --type "$2" < "$1"', "_", entry.filePath, entry.mime]);
            return;
        }
        const cmd = entry.isImage ? 'cliphist decode "$1" | wl-copy --type "$2"' : 'cliphist decode "$1" | wl-copy';
        // wl-copy se queda vivo sirviendo el portapapeles: no se espera su salida
        Quickshell.execDetached(["sh", "-c", cmd, "_", entry.id, entry.mime]);
    }

    function remove(id) {
        run(["sh", "-c", 'printf "%s\\t\\n" "$1" | cliphist delete; rm -f -- "$2/$1".* "$2/qr-$1.png"', "_", id, cacheDir], function () {
            store.refresh();
        });
    }

    function wipe() {
        run(["sh", "-c", 'cliphist wipe; find "$1" -mindepth 1 -delete', "_", cacheDir], function () {
            store.imageUrls = ({});
            store.requested = ({});
            store.refresh();
        });
    }

    // Ejecuta el texto en kitty (--hold: la terminal queda abierta para ver la salida)
    function runInTerminal(id) {
        run(["cliphist", "decode", id], function (text) {
            Quickshell.execDetached(["kitty", "--hold", Quickshell.env("SHELL") || "sh", "-c", text]);
        });
    }

    // QR del texto → done(ruta, error). Sin `qrencode` o con texto largo, error en vez de ruta.
    function makeQr(id, done) {
        const out = cacheDir + "/qr-" + id + ".png";
        // scripts/clipboard-qr.py declara UTF-8 (ECI) para que las tildes se lean bien en el teléfono
        const script = 'mkdir -p "$3"; cliphist decode "$1" | python3 "$5" "$2" "$4"';
        run(["sh", "-c", script, "_", id, out, cacheDir, String(App.Config.clipboard.qrMaxBytes), Quickshell.shellPath("scripts/clipboard-qr.py")], function (o, code) {
            if (code === 0)
                done("file://" + out, "");
            else if (code === 3)
                done("", "Demasiado largo para un QR");
            else
                done("", "No se pudo crear el QR");
        });
    }

    // Deja el elemento en un archivo (el texto como .txt, la imagen ya decodificada) → done(ruta)
    function exportFile(entry, done) {
        if (entry.isFiles) {
            done(entry.files.filter(f => f.exists).map(f => f.path));
            return;
        }
        if (entry.isFile) {
            done(entry.filePath);
            return;
        }
        let path;
        if (entry.isImage)
            path = cacheDir + "/" + entry.id + "." + entry.format;
        else
            path = cacheDir + "/portapapeles-" + Qt.formatDateTime(new Date(), "yyyy-MM-dd-HHmm") + ".txt";
        run(["sh", "-c", 'mkdir -p "$3" && cliphist decode "$1" > "$2"', "_", entry.id, path, cacheDir], function (o, code) {
            if (code === 0)
                done(path);
        });
    }

    // Apps que abren un tipo MIME (la predeterminada primero) → done([{ id, name, icon }])
    property var appsCache: ({})
    // DesktopEntries solo se llena mientras alguien lo usa; así `byId` funciona aunque el launcher no se haya abierto
    readonly property var desktopApps: DesktopEntries.applications.values

    function appsFor(mime, done) {
        if (appsCache[mime]) {
            done(appsCache[mime]);
            return;
        }
        run(["sh", "-c", 'xdg-mime query default "$1"; LC_ALL=C gio mime "$1"', "_", mime], function (out) {
            const ids = [];
            const found = out.match(/[A-Za-z0-9._+\-]+\.desktop/g) || [];
            for (const f of found) {
                const id = f.replace(/\.desktop$/, "");
                if (ids.indexOf(id) < 0)
                    ids.push(id);
            }
            const apps = [];
            for (const id of ids) {
                const e = DesktopEntries.byId(id) || DesktopEntries.byId(id + ".desktop");
                apps.push({
                    id: id,
                    name: e ? e.name : id,
                    icon: e ? e.icon : ""
                });
            }
            store.appsCache[mime] = apps;
            done(apps);
        });
    }

    function openWith(appId, entry) {
        exportFile(entry, function (file) {
            Quickshell.execDetached(["gtk-launch", appId].concat(file));
        });
    }

    // La caché se vacía al arrancar la shell (las imágenes decodificadas no deben quedar en disco)
    Component.onCompleted: {
        run(["sh", "-c", 'rm -rf -- "$1" && mkdir -p "$1"', "_", cacheDir], function () {});
        refresh();
    }
}
