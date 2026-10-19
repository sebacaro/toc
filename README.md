# Toc

Gestor personal de ventanas para macOS, basado en [Magnetism](https://github.com/sadopc/magnetism), de sadopc, bajo licencia MIT. Mueve y redimensiona ventanas mediante atajos, el menú de la barra superior o arrastre hacia los bordes de la pantalla.

## Proyecto

- Swift 6, AppKit y SwiftUI; macOS 14 o posterior.
- Nombre visible: **Toc**. Target y esquema compartido: `toc`.
- Target de pruebas: `tocTests`.
- Bundle IDs: `com.seba.toc` y `com.seba.toc.tests`.
- Configuración de XcodeGen: `project.yml`.
- Proyecto generado y versionado: `toc.xcodeproj`.
- Dependencia: [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts), mediante Swift Package Manager.

## Funciones de esta versión

- Mitades, cuartos, tercios horizontales y verticales, dos tercios, centrar, maximizar y restaurar; traslado entre pantallas.
- Atajos configurables y movimientos directos en orden, sin animaciones simultáneas sobre una ventana.
- En pantallas horizontales: laterales para mitades, esquinas para cuartos, arriba para maximizar y cinco tramos abajo para tercios/dos tercios horizontales.
- En pantallas verticales: ambos laterales tienen cinco tramos para tercios/dos tercios verticales; abajo hay mitades izquierda/derecha. Las esquinas conservan prioridad.
- Sensibilidad entre 1 y 40 puntos, por defecto 8. Exclusiones por Bundle ID, uno por línea en Preferences > General; afectan a menú, atajos y arrastre.
- Previsualización y movimiento usan la misma ventana y zona. Si cambian la pantalla o la zona antes de soltar, se cancela el ajuste para evitar aplicar una geometría no mostrada.
- Recuperación automática del arrastre al conceder Accesibilidad y tras desactivación del event tap.
- Comprobación de errores AX y tamaños mínimos impuestos por las aplicaciones. El último problema o limitación se muestra en Preferences > General.
- Historial temporal de hasta 128 ventanas, basado en igualdad pública de AX, sin API privada de ID de ventana. Restore conserva el primer estado hasta completar la restauración; si falta la pantalla original, se ajusta a una disponible.

Los cinco atajos verticales nuevos no tienen una combinación predeterminada; se asignan en Preferences > Shortcuts. El historial se pierde al cerrar Toc. Una app puede rechazar cambios o imponer un tamaño mayor que la pantalla; en ese caso se intenta mantener accesible su esquina superior izquierda y se informa del límite.

## Generar y compilar

Requiere Xcode 16 o posterior y XcodeGen. El proyecto de Xcode ya está incluido; ejecuta XcodeGen cuando cambies `project.yml` o agregues, elimines o renombres archivos Swift. Los comandos de esta guía se ejecutan desde la raíz del repositorio:

```bash
xcodegen generate --spec project.yml
```

Compilación Release, con los productos dentro del proyecto:

```bash
xcodebuild \
  -project toc.xcodeproj \
  -scheme toc \
  -configuration Release \
  -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath build \
  -clonedSourcePackagesDirPath build/SourcePackages \
  -packageCachePath build/PackageCache \
  -disablePackageRepositoryCache \
  build
```

Aplicación resultante: `build/Build/Products/Release/toc.app`.

## Verificación

Entrega 1.1.2 (build 5): nombre visible **Toc**, con T mayúscula, en Finder, preferencias, mensajes y menú. El DMG distribuye `Toc.app` y se instala en `/Applications/Toc.app`; el target, esquema y Bundle ID conservan sus identificadores técnicos. Se verificaron la compilación Release universal, firma ad hoc, metadatos, suma SHA-256 del DMG y nombre en Finder.

Entrega 1.1.1 (build 4): icono T morado aprobado, diez variantes compiladas de 16 a 1024 px, Release universal para Intel y Apple Silicon, mínimo macOS 14. Se verificaron firma, versión, icono dentro de la app y del DMG, catálogo de recursos, guía incluida y suma SHA-256. `dist` conserva únicamente `toc.dmg` y `toc.dmg.sha256`; el paquete anterior fue reemplazado.

El 18 de octubre de 2026 pasaron 34 pruebas en 7 suites con Xcode 26.2, en Apple Silicon. La versión 1.1.0 (build 3) compiló en Release universal (`arm64` y `x86_64`), con firma ad hoc válida y sin advertencias del compilador Swift. Xcode solo emitió el aviso de extracción omitida de App Intents, que toc no utiliza.

Las pruebas automatizadas cubren geometría con coordenadas negativas, zonas de arrastre horizontales y verticales, límites de sensibilidad, exclusiones, escritura AX simulada, tamaños mínimos, errores y restauración. El host de pruebas no pide Accesibilidad ni registra entrada global.

Swift Package Manager fija KeyboardShortcuts en 2.4.0 mediante `toc.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`.

Para repetir las pruebas:

```bash
xcodebuild \
  -project toc.xcodeproj \
  -scheme toc \
  -configuration Debug \
  -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath build \
  -clonedSourcePackagesDirPath build/SourcePackages \
  -packageCachePath build/PackageCache \
  -disablePackageRepositoryCache \
  -skipPackageUpdates \
  -parallel-testing-enabled NO \
  -only-testing:tocTests \
  test
```

Los resultados XCTest se guardan en `build/Logs/Test/`.

Las pruebas simulan las respuestas AX para no mover ventanas reales. Atajos y arrastre sobre apps reales, cambios de TCC, monitores físicos, Spaces y rendimiento siguen requiriendo validación manual. La firma ad hoc puede obligar a volver a autorizar la copia instalada tras actualizarla.

## Accesibilidad

En el primer uso, autoriza **Toc** en **Ajustes del Sistema → Privacidad y seguridad → Accesibilidad**. Es necesario para mover las ventanas de otras aplicaciones. La app vive en la barra de menú y no muestra un icono en el Dock.

### Si el permiso aparece activado pero Toc no mueve ventanas

Al recompilar con firma ad hoc, puede cambiar la identidad del ejecutable. Puede quedar una entrada antigua activada que ya no autorice la copia actual.

1. Cierra todas las copias de Toc y usa únicamente `/Applications/Toc.app`, después de copiarla desde el DMG.
2. En Ajustes del Sistema → Privacidad y seguridad → Accesibilidad, elimina **solo Toc** con «−».
3. Añade `/Applications/Toc.app` con «+» y activa su permiso. Si macOS solicita autenticación, complétala tú.
4. Cierra y vuelve a abrir la copia instalada. Prueba **Left Half** con una ventana normal de Finder activa.

Si sigue fallando, consulta Preferences → General y el registro de `com.seba.toc`. No hace falta conceder Acceso completo al disco ni desactivar Gatekeeper. Evita recompilar o sustituir la app durante esta comprobación, porque cambiaría otra vez su firma.

## Empaquetar e instalar el DMG

Con la compilación Release disponible, ejecuta el script nativo de empaquetado:

```bash
bash scripts/package-dmg.sh
```

Genera `dist/toc.dmg` y su suma SHA-256 en `dist/toc.dmg.sha256`. Usa `ditto` para copiar la app conservando su firma y `hdiutil` para crear y verificar una imagen HFS+ comprimida y de solo lectura. El DMG contiene `Toc.app`, el enlace `Applications`, `LICENSE` y `LEEME.txt`. Al repetirlo, reemplaza el DMG generado anterior después de verificar la nueva imagen.

El mismo `toc.dmg` sirve para tus otros Macs con macOS 14 o posterior, tanto Intel como Apple Silicon. Para instalar en cada equipo, abre `toc.dmg`, arrastra `Toc.app` a `Applications`, expulsa el disco y abre `/Applications/Toc.app`. No ejecutes la app desde el volumen del DMG. Autoriza la copia instalada en Accesibilidad en **cada Mac**; ese permiso no se transfiere con el instalador.

Al actualizar, cierra Toc antes de reemplazar `/Applications/Toc.app`. Si Accesibilidad aparece activada pero la app deja de mover ventanas, elimina solo su entrada y vuelve a añadir la copia instalada, como se explica arriba. Esto resolvió el permiso ligado a una compilación anterior durante la comprobación manual en el Mac de desarrollo.

Verificación del instalador: la imagen pasó `hdiutil verify`, se montó en modo de solo lectura y se comprobó que contiene los cuatro elementos previstos. La firma de la app copiada es válida y su ejecutable coincide con el Release original. La suma SHA-256 también pasó; la imagen se desmontó al terminar.

### Gatekeeper y cuarentena

La app tiene firma ad hoc para uso local; no está firmada con Developer ID ni notarizada. Si macOS bloquea la apertura por desarrollador no identificado, intenta abrir la app instalada y usa **Ajustes del Sistema → Privacidad y seguridad → Abrir igualmente**, como indica [Apple](https://support.apple.com/es-cl/102445).

Para esta copia que tú compilaste, si tiene el atributo de cuarentena, también puedes retirar únicamente ese atributo de `toc`:

```bash
xattr -dr com.apple.quarantine "/Applications/Toc.app"
open "/Applications/Toc.app"
```

Esto no desactiva Gatekeeper globalmente. Las instrucciones completas también se incluyen en `docs/INSTALAR.txt` y dentro del DMG como `LEEME.txt`.

## Icono

El icono de Toc usa el diseño morado aprobado: una T blanca con tres bloques alineados arriba y una sola pieza vertical debajo. La imagen fuente está en `docs/branding/toc-icon-purple-t-v2.png`; los tamaños para macOS están en `toc/Assets.xcassets/AppIcon.appiconset/`.

El símbolo de la barra de menú se configura por separado en `toc/MenuBar/MenuBarManager.swift`.

## Atribución

El código original de Magnetism pertenece a sadopc. Se conserva `LICENSE` sin modificaciones y se incluye como recurso de la aplicación. El enlace de la pantalla About identifica explícitamente el proyecto original.
