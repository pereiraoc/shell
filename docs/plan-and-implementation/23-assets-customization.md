# 🎨 Assets Customization - Trocar GIFs

**ID**: 23  
**Status**: ✅ GIFs Removidos / ⏱️ Config Pendente  
**Complexidade**: 🟢 Baixa  
**Tempo Estimado**: 30min (config UI)

---

## 📋 Resumo

~~Trocar~~ **Os GIFs foram removidos** (kurukuru.gif e bongocat.gif). Este plano agora documenta a remoção e propõe adicionar configuração via UI para assets customizáveis (opcional).

---

## 🎯 Status Atual

- ✅ `kurukuru.gif` foi **removido**
- ✅ `bongocat.gif` foi **removido**
- ⏱️ (Opcional) Adicionar config UI para assets customizáveis

---

## 📂 Assets a Modificar

### 1. kurukuru.gif - Session Loading

**Localização**: `assets/kurukuru.gif`

**Usado em**: `modules/session/Content.qml` (linha 48-58)

```qml
AnimatedImage {
    source: Paths.absolutePath(Config.paths.sessionGif)
    fillMode: Image.PreserveAspectFit
    anchors.fill: parent
    playing: true
}
```

**Quando aparece**:
- Ao fazer logout
- Ao desligar/reiniciar
- Durante transição de session

**Config**: `config/UserPaths.qml`
```qml
property string sessionGif: "root:/assets/kurukuru.gif"
```

---

### 2. bongocat.gif - Media Visualizer

**Localização**: `assets/bongocat.gif`

**Usado em**: `modules/dashboard/dash/Media.qml` (linha 204-220)

```qml
AnimatedImage {
    source: Paths.absolutePath(Config.paths.mediaGif)
    fillMode: Image.PreserveAspectCrop
    anchors.fill: parent
    playing: root.show
}
```

**Quando aparece**:
- Dashboard/Lock screen (widget Media)
- Quando música está tocando

**Config**: `config/UserPaths.qml`
```qml
property string mediaGif: "root:/assets/bongocat.gif"
```

---

## 🎨 Opções de Substituição

### Para kurukuru.gif (Session Loading)

#### Opção 1: Spinner Simples

**Sugestões**:
- Material Design spinner: https://loading.io/spinner/
- Simples, profissional, neutro

**Criar com CSS**:
```html
<!-- Gerar em loading.io e exportar como GIF -->
Spinner tipo: "Material"
Cor: Accent color (azul/amarelo)
Tamanho: 256x256px
FPS: 30
```

#### Opção 2: Power Icon Pulsando

**Criar em GIMP/Photoshop**:
- Ícone de power (material-design-icons)
- Animação de fade in/out (pulse)
- Fundo transparente
- 256x256px, loop infinito

#### Opção 3: Sem Animação

**Imagem estática**:
- Apenas ícone de power
- Ou logo do Caelestia
- PNG estático (modificar QML para usar Image ao invés de AnimatedImage)

---

### Para bongocat.gif (Media Visualizer)

#### Opção 1: Equalizer Animado

**Sugestões**:
- Bars verticais animadas (estilo audio visualizer)
- Cores: gradient seguindo palette M3
- Sincroniza com `Audio.beatTracker` (já existe no código)

**Criar**:
- Canvas QML com animação customizada
- Ou GIF pré-renderizado de equalizer

#### Opção 2: Visualizador de Áudio Real

**Usar beatTracker**:
```qml
// Em Media.qml, substituir AnimatedImage por:
Canvas {
    id: visualizer
    anchors.fill: parent
    
    onPaint: {
        var ctx = getContext("2d")
        // Desenhar bars baseado em Audio.beatTracker.level
        // ...
    }
    
    Connections {
        target: Audio.beatTracker
        function onLevelChanged() {
            visualizer.requestPaint()
        }
    }
}
```

#### Opção 3: Esconder Completamente

**Adicionar toggle**:
```qml
// config/DashboardConfig.qml
property bool showMediaGif: false

// Media.qml
AnimatedImage {
    visible: Config.dashboard.showMediaGif
    // ...
}
```

#### Opção 4: Album Cover

**Mostrar capa do álbum** (se disponível via MPRIS):
```qml
Image {
    source: Mpris.artUrl  // Já existe no Caelestia
    fillMode: Image.PreserveAspectCrop
}
```

---

## 🛠️ Implementação

### Método 1: Substituição Simples (Quick Win)

**Apenas trocar os arquivos**:

```bash
# 1. Baixar/criar novos GIFs
# kurukuru-new.gif (spinner)
# bongocat-new.gif (equalizer)

# 2. Backup dos originais
cp assets/kurukuru.gif assets/kurukuru.gif.orig
cp assets/bongocat.gif assets/bongocat.gif.orig

# 3. Substituir
cp kurukuru-new.gif assets/kurukuru.gif
cp bongocat-new.gif assets/bongocat.gif

# 4. Rebuild (se necessário)
cmake --build build
sudo cmake --install build

# 5. Reiniciar
killall quickshell
quickshell -c caelestia --daemonize
```

**Tempo**: 15 min (+ tempo de criar/baixar GIFs)

---

### Método 2: Configurável via UI (Feature Completa)

**Adicionar opções no config**:

#### Passo 1: Modificar UserPaths.qml

```qml
// config/UserPaths.qml
component UserPaths: JsonObject {
    // Existente:
    property string sessionGif: "root:/assets/kurukuru.gif"
    property string mediaGif: "root:/assets/bongocat.gif"
    
    // NOVO:
    property bool useSessionGif: true  // Toggle on/off
    property bool useMediaGif: true
    
    // NOVO: Custom paths (optional)
    property string customSessionGif: ""
    property string customMediaGif: ""
}
```

#### Passo 2: Modificar Content.qml (Session)

```qml
// modules/session/Content.qml
AnimatedImage {
    visible: Config.paths.useSessionGif
    source: {
        if (Config.paths.customSessionGif !== "") {
            return Config.paths.customSessionGif
        }
        return Paths.absolutePath(Config.paths.sessionGif)
    }
    // ...
}
```

#### Passo 3: Modificar Media.qml (Dashboard)

```qml
// modules/dashboard/dash/Media.qml
Loader {
    anchors.fill: parent
    
    sourceComponent: {
        if (!Config.paths.useMediaGif) return null
        
        if (Config.paths.customMediaGif !== "") {
            return customGifComponent
        }
        return defaultGifComponent
    }
}

Component {
    id: defaultGifComponent
    AnimatedImage {
        source: Paths.absolutePath(Config.paths.mediaGif)
        // ...
    }
}

Component {
    id: customGifComponent
    AnimatedImage {
        source: Config.paths.customMediaGif
        // ...
    }
}
```

#### Passo 4: UI no Control Center (Opcional)

```qml
// modules/controlcenter/appearance/sections/AssetsSection.qml (novo)
ColumnLayout {
    SectionLabel { text: qsTr("Assets Customization") }
    
    // Session GIF
    ToggleInput {
        label: qsTr("Show session loading GIF")
        checked: Config.paths.useSessionGif
        onToggled: checked => {
            Config.paths.useSessionGif = checked
        }
    }
    
    FilePickerInput {
        label: qsTr("Custom session GIF")
        placeholderText: qsTr("Leave empty for default")
        value: Config.paths.customSessionGif
        filter: "Images (*.gif *.png)"
        onValueChanged: value => {
            Config.paths.customSessionGif = value
        }
    }
    
    // Media GIF
    ToggleInput {
        label: qsTr("Show media visualizer GIF")
        checked: Config.paths.useMediaGif
        onToggled: checked => {
            Config.paths.useMediaGif = checked
        }
    }
    
    FilePickerInput {
        label: qsTr("Custom media GIF")
        placeholderText: qsTr("Leave empty for default")
        value: Config.paths.customMediaGif
        filter: "Images (*.gif *.png)"
        onValueChanged: value => {
            Config.paths.customMediaGif = value
        }
    }
}
```

**Tempo**: 2-3h (completo com UI)

---

## 🎨 Recursos para GIFs

### Fontes de GIFs/Spinners

- **Loading.io**: https://loading.io/ (gerar spinners customizados)
- **LottieFiles**: https://lottiefiles.com/ (animações JSON, converter para GIF)
- **Material Icons**: https://fonts.google.com/icons (ícones estáticos)
- **Giphy**: https://giphy.com/ (GIFs prontos, filtrar "loading")

### Ferramentas para Criar GIFs

**Online**:
- Loading.io Spinner Generator
- Ezgif.com (editar/otimizar GIFs)

**Desktop**:
- GIMP (criar frame-by-frame)
- Photoshop (timeline animation)
- Blender (3D animation → GIF)

**Code**:
- Canvas QML (animação programática)
- Python + Pillow (gerar GIF)

### Especificações Sugeridas

**kurukuru.gif** (Session Loading):
- Tamanho: 256x256px (ou maior)
- FPS: 24-30
- Loop: Infinito
- Transparência: Sim (fundo transparente)
- Cores: Seguir palette M3

**bongocat.gif** (Media Visualizer):
- Tamanho: 200x200px (ou maior)
- FPS: 30
- Loop: Infinito
- Transparência: Opcional
- Cores: Accent color

---

## 🧪 Testes

### Checklist

- [ ] kurukuru.gif aparece ao fazer logout
  ```bash
  # Testar:
  hyprctl dispatch exit
  ```

- [ ] bongocat.gif aparece no media widget
  ```bash
  # Testar:
  # 1. Tocar música (Spotify/etc)
  # 2. Abrir dashboard (se lock screen, lock)
  # 3. Verificar widget Media
  ```

- [ ] GIFs não quebram layout
- [ ] Animação é suave (sem lag)
- [ ] Transparência funciona
- [ ] Cores harmonizam com tema

---

## 🐛 Troubleshooting

### GIF Não Aparece

**Causa**: Path incorreto ou formato inválido

**Solução**:
```bash
# Verificar path
ls -la assets/kurukuru.gif
ls -la assets/bongocat.gif

# Verificar formato
file assets/kurukuru.gif
# Deve dizer: GIF image data

# Testar fora do Quickshell
feh assets/kurukuru.gif  # Ou qualquer image viewer
```

---

### GIF Aparece mas Não Anima

**Causa**: AnimatedImage não configurado corretamente

**Debug**:
```qml
AnimatedImage {
    source: Paths.absolutePath(Config.paths.sessionGif)
    playing: true  // Deve estar true
    Component.onCompleted: {
        console.log("GIF loaded:", status)
        console.log("Frame count:", frameCount)
    }
}
```

---

### Performance Ruim

**Causa**: GIF muito grande ou FPS muito alto

**Solução**: Otimizar GIF
```bash
# Reduzir tamanho e FPS
gifsicle -O3 --resize 256x256 --delay=4 input.gif -o output.gif

# delay=4 → 25 FPS (100ms/frame = 1000ms / 4)
# delay=3 → 33 FPS
```

---

## 📝 Recomendação Final

### Para Quick Win (Fase 1):

1. **Substituir kurukuru.gif** por spinner Material Design
2. **Substituir bongocat.gif** por equalizer simples ou album cover
3. **Tempo**: 30 min

### Para Feature Completa (Fase 2+):

1. Implementar toggles e custom paths
2. Adicionar UI no Control Center
3. Permitir upload de GIFs customizados
4. **Tempo**: 2-3h

---

## ✅ Checklist de Conclusão

- [ ] Novos GIFs criados/baixados
- [ ] Backup dos originais feito
- [ ] GIFs substituídos em `assets/`
- [ ] Rebuild e reinstalação
- [ ] Testado em session logout
- [ ] Testado em media widget
- [ ] Documentação atualizada

---

## 🔗 Referências

- **Qt AnimatedImage**: https://doc.qt.io/qt-6/qml-qtquick-animatedimage.html
- **GIF Optimization**: https://www.lcdf.org/gifsicle/
- **Material Design Motion**: https://m3.material.io/styles/motion/overview

---

**Próximo**: Após implementar, marcar como ✅ no `99-pendencias.md`!
