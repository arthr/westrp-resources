/**
 * WestRP UI Engine — Main NUI Dispatcher & Router (~80 linhas)
 * Centraliza o recebimento de mensagens do RedM e despacha para os módulos.
 */

window.addEventListener('message', (event) => {
  const data = event.data;
  if (!data || !data.action) return;

  switch (data.action) {
    // 1. DOCK LATERAL
    case 'westrp_ui:open':
      if (window.uiDock) window.uiDock.open(data.options || {});
      break;
    case 'westrp_ui:close':
      if (window.uiDock) window.uiDock.close();
      break;

    // 2. PANEL CENTRAL
    case 'westrp_ui:openPanel':
      if (window.uiPanel) window.uiPanel.open(data.options || {});
      break;
    case 'westrp_ui:closePanel':
      if (window.uiPanel) window.uiPanel.close();
      break;

    // 3. DIALOG MODAL / INPUT (SUBSTITUTO VORP_INPUTS)
    case 'westrp_ui:openDialog':
      if (window.uiDialog) window.uiDialog.openDialog(data.options || {});
      break;
    case 'westrp_ui:closeDialog':
      if (window.uiDialog) window.uiDialog.closeDialog();
      break;

    // 4. CONFIRM MODAL
    case 'westrp_ui:openConfirm':
      if (window.uiDialog) window.uiDialog.openConfirm(data.options || {});
      break;
    case 'westrp_ui:closeConfirm':
      if (window.uiDialog) window.uiDialog.closeConfirm();
      break;

    // 5. ACTION PROGRESS BAR
    case 'westrp_ui:startProgress':
      if (window.uiProgress) window.uiProgress.start(data.options || {});
      break;
    case 'westrp_ui:cancelProgress':
      if (window.uiProgress) window.uiProgress.cancel();
      break;

    // 6. TOAST NOTIFICATIONS
    case 'westrp_ui:toast':
      if (window.uiToast) window.uiToast.show(data.title, data.message, data.type, data.duration);
      break;

    // 7. RDR2 MODAL FLUTUANTE (ZOOM-IN ANIMATION / RDRMODAL)
    case 'westrp_ui:openModal':
      if (window.uiModal) window.uiModal.open(data.options || {});
      break;
    case 'westrp_ui:closeModal':
      if (window.uiModal) window.uiModal.close();
      break;

    // 8. RDR2 SLIDER PANEL (GAVETA LATERAL / RDRSLIDER)
    case 'westrp_ui:openSliderPanel':
      if (window.uiSliderPanel) window.uiSliderPanel.open(data.options || {});
      break;
    case 'westrp_ui:closeSliderPanel':
      if (window.uiSliderPanel) window.uiSliderPanel.close();
      break;

    // 9. DOCK CURSOR TOGGLE (MOUSE / CÂMERA LIVRE)
    case 'westrp_ui:setDockCursor':
      if (window.uiDock) window.uiDock.setCursorState(!!data.hasCursor);
      break;
  }
});

/* ==========================================================================
   GLOBAL KEYBOARD DISPATCHER
   ========================================================================== */
window.addEventListener('keydown', (e) => {
  // A1. Modal RDR2 Aberto
  if (window.uiModal && window.uiModal.isOpen) {
    if (e.key === 'Escape') {
      e.preventDefault();
      window.uiModal.close();
      return;
    }
  }

  // A2. Slider Panel RDR2 Aberto
  if (window.uiSliderPanel && window.uiSliderPanel.isOpen) {
    if (e.key === 'Escape') {
      e.preventDefault();
      window.uiSliderPanel.close();
      return;
    }
  }

  // A. Diálogo de Entrada Aberto
  if (window.uiDialog && window.uiDialog.isOpen) {
    if (e.key === 'Escape') {
      e.preventDefault();
      window.uiDialog.closeDialog();
    } else if (e.key === 'Enter' && e.target.tagName !== 'TEXTAREA') {
      e.preventDefault();
      window.uiDialog.submitDialog();
    }
    return;
  }

  // B. Modal de Confirmação Aberto
  if (window.uiDialog && window.uiDialog.isConfirmOpen) {
    if (e.key === 'Escape') {
      e.preventDefault();
      window.uiDialog.closeConfirm();
    } else if (e.key === 'Enter') {
      e.preventDefault();
      window.uiDialog.submitConfirm();
    }
    return;
  }

  // C. Barra de Progresso Ativa
  if (window.uiProgress && window.uiProgress.isActive()) {
    if (e.key === 'Escape' || e.key === 'Backspace') {
      e.preventDefault();
      window.uiProgress.cancel(true);
    }
    return;
  }

  // D. Panel Central Aberto
  if (window.uiPanel && window.uiPanel.isOpen) {
    if (e.key === 'Escape') {
      e.preventDefault();
      window.uiPanel.close();
    }
    return;
  }

  // E. Dock Lateral Aberto (Navegação Rockstar 350px)
  if (window.uiDock && window.uiDock.isOpen) {
    if (e.key === 'Alt' || e.code === 'AltLeft' || e.code === 'AltRight') {
      e.preventDefault();
      if (e.repeat) return;
      window.uiDock.toggleCursor();
      return;
    }

    switch (e.code) {
      case 'ArrowUp':
        e.preventDefault();
        window.uiDock.navigate('up');
        break;
      case 'ArrowDown':
        e.preventDefault();
        window.uiDock.navigate('down');
        break;
      case 'ArrowLeft':
        e.preventDefault();
        window.uiDock.adjustSlider('left');
        break;
      case 'ArrowRight':
        e.preventDefault();
        window.uiDock.adjustSlider('right');
        break;
      case 'KeyQ':
        e.preventDefault();
        window.uiDock.prevTab();
        break;
      case 'KeyE':
        e.preventDefault();
        window.uiDock.nextTab();
        break;
      case 'Enter':
      case 'NumpadEnter':
        e.preventDefault();
        window.uiDock.executeCurrentItem();
        break;
      case 'Backspace':
        e.preventDefault();
        window.uiDock.goBack();
        break;
      case 'Escape':
        e.preventDefault();
        window.uiDock.close();
        break;
    }
  }
});
