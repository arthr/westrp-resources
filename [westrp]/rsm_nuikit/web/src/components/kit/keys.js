// Teclas digitadas num campo de texto nunca disparam atalhos nem prompts.
export const isTyping = (el) => !!el && (el.tagName === "INPUT" || el.tagName === "TEXTAREA" || el.isContentEditable);
