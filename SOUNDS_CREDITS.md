# 🎵 Sound Effects Credits

Este aplicativo utiliza os seguintes efeitos sonoros:

---

## SND01_sine - Professional UI Sound Library

**Fonte**: [SND.dev](https://snd.dev) - Sound for Developers  
**Pack**: SND01_sine (Sine Wave Sound Pack)  
**Licença**: Uso livre para desenvolvimento  
**Autor**: SND.dev Team  
**Inspiração**: Filosofia de design de som UI/UX profissional

### Sons SND01_sine utilizados:

#### Buttons & Taps
- `button.wav` - Botão com função específica
- `tap_01.wav` a `tap_05.wav` - Feedback tátil responsivo (5 variações)
- `select.wav` - Seleção de elementos (checkbox, radio, form)
- `disabled.wav` - Botão desabilitado

#### Toggles & Switches
- `toggle_on.wav` - Switch ativado (grave → agudo)
- `toggle_off.wav` - Switch desativado (agudo → grave)

#### Transitions
- `transition_up.wav` - Abrir modal/dialog (transição hierárquica)
- `transition_down.wav` - Fechar modal/dialog
- `swipe_01.wav` a `swipe_05.wav` - Transição horizontal (5 variações)

#### Input
- `type_01.wav` a `type_05.wav` - Digitação de texto (5 variações)

#### Notifications & Feedback
- `notification.wav` - Notificação genérica
- `caution.wav` - Aviso negativo/erro
- `celebration.wav` - Conquista máxima

#### Loops
- `progress_loop.wav` - Loop de processamento
- `ringtone_loop.wav` - Alarme/toque (loop até ação)

**Total**: 29 arquivos de som WAV profissionais

### Características do Pack SND01_sine:
- Ondas senoidais limpas e profissionais
- Design específico para UI/UX moderna
- Variações aleatórias para evitar fadiga auditiva
- Diferenciação clara entre tipos de interação
- Inspirado nos melhores apps (iOS, Material Design)

### Implementação:
- Service: `lib/src/utils/services/sound_service.dart`
- Widgets: `lib/src/shared/widgets/sound_widgets.dart`
- Helpers: `lib/src/utils/sound_helpers.dart`
- NavigatorObserver: Transições automáticas de rotas
- Documentação: `SND_SOUND_SYSTEM.md`

---

## Octave UI Sound Pack (Legacy)

**Fonte**: [Octave - Free UI Sound Pack](https://github.com/nickytonline/octave)  
**Licença**: MIT License - Uso livre  
**Autor**: nickytonline / Octave  

### Sons utilizados:

#### Clicks/Taps
- `button_click.ogg` - tap-crisp.aif
- `tap_soft.ogg` - tap-simple.aif
- `edit_click.ogg` - tap-professional.aif

#### Transitions
- `page_turn.ogg` - slide-paper.aif
- `swipe_clean.ogg` - slide-network.aif
- `navigation.ogg` - slide-magic.aif

#### Feedback
- `success_chime.ogg` - beep-piano.aif
- `error_beep.ogg` - beep-rejected.aif
- `add_item.ogg` - tap-mellow.aif
- `delete_whoosh.ogg` - slide-scissors.aif

#### Popups
- `modal_open.ogg` - beep-brightpop.aif
- `modal_close.ogg` - tap-hollow.aif

#### Notifications
- `reminder_ding.ogg` - beep-xylo.aif
- `alert_ping.ogg` - beep-attention.aif

---

## SampleFire UI Sound Effects

**Fonte**: SampleFire UI Sound Effect Pack  
**Licença**: Royalty-Free  
**Categoria**: Modern UI Sounds  

Sons disponíveis para uso futuro.

---

## Processamento

### Sons SND01_sine:
- Formato: WAV (originais, sem processamento)
- Qualidade: Alta fidelidade
- Otimizados: Para latência mínima
- Tamanho: ~660KB total (29 arquivos)

### Sons Legacy (Octave):
1. Convertidos para formato OGG (Vorbis) para melhor compressão
2. Reamostrados para 44.1kHz mono
3. Normalizados para -3dB
4. Otimizados para uso mobile (arquivos ~8KB cada)

---

## Licença de Uso

### SND01_sine
Os sons SND01_sine são disponibilizados pelo projeto SND.dev para uso em desenvolvimento.
Referência: https://snd.dev

### Octave
Os efeitos sonoros do Octave são disponibilizados sob licença MIT, 
permitindo uso comercial e modificação livre, desde que a atribuição 
seja mantida neste arquivo.

---

## Estatísticas

**Sons SND (novos)**:
- Total: 29 arquivos WAV
- Tamanho: ~660KB
- Formato: WAV (16-bit)
- Qualidade: Alta fidelidade

**Sons Legacy (Octave)**:  
- Total: 14 efeitos sonoros UI  
- Tamanho: ~112KB  
- Formato: OGG Vorbis  
- Qualidade: 44.1kHz, Mono, Quality 5

**Total geral**: 43 efeitos sonoros UI/UX

---

## Referências

- [SND.dev](https://snd.dev) - Sound for Developers
- [SND GitHub](https://github.com/snd-lib/snd-lib) - Biblioteca JavaScript
- [Octave](https://github.com/nickytonline/octave) - Free UI Sound Pack

---

*Última atualização: 2025-12-14*
