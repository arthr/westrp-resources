import { useEffect, useRef, useState } from "react";

const isTyping = (el) => el && (el.tagName === "INPUT" || el.tagName === "TEXTAREA" || el.isContentEditable);

// Keycap on the square frame; `fill` (0-1) rises from the bottom while held.
export function KeyCap({ k, fill = 0, size = 30, dim = false }) {
  return (
    <span
      className="tx-key relative grid shrink-0 place-items-center overflow-hidden"
      style={{ width: size, height: size, "--frame": dim ? "var(--kit-faint)" : "var(--kit-text)" }}
    >
      <span
        aria-hidden
        className="absolute inset-[3px] origin-bottom"
        style={{ background: "var(--kit-accent)", transform: `scaleY(${fill})` }}
      />
      <span
        className={`relative font-display text-[13px] leading-none ${dim ? "text-faint" : fill > 0.5 ? "text-on-accent" : "text-ink"}`}
      >
        {k}
      </span>
    </span>
  );
}

// Static prompt row: keycap + label on the prompt strip
export function Prompt({ k, label, dim = false, fill = 0 }) {
  return (
    <div className={`tx-prompt flex h-11 w-max min-w-[15rem] items-center gap-3 py-1.5 pr-6 pl-2 ${dim ? "opacity-60" : ""}`}>
      <KeyCap k={k} fill={fill} dim={dim} />
      <span className={`text-[14px] ${dim ? "text-faint" : "text-ink"}`}>{label}</span>
    </div>
  );
}

// Prompt de toque: um toque na tecla (ou um clique) dispara onPress.
export function PressPrompt({ k, code, label, onPress, disabled = false }) {
  const [flash, setFlash] = useState(false);
  const pressRef = useRef(onPress);

  useEffect(() => {
    pressRef.current = onPress;
  }, [onPress]);

  // o keycap acende por um instante a cada toque
  useEffect(() => {
    if (!flash) return undefined;
    const t = setTimeout(() => setFlash(false), 180);
    return () => clearTimeout(t);
  }, [flash]);

  useEffect(() => {
    if (disabled) return undefined;
    const down = (e) => {
      if (e.code !== code || e.repeat || isTyping(e.target)) return;
      setFlash(true);
      if (pressRef.current) pressRef.current();
    };
    window.addEventListener("keydown", down);
    return () => window.removeEventListener("keydown", down);
  }, [code, disabled]);

  const click = () => {
    setFlash(true);
    if (pressRef.current) pressRef.current();
  };

  return (
    <button
      type="button"
      disabled={disabled}
      onClick={click}
      className={`block text-left outline-none select-none ${disabled ? "cursor-not-allowed" : "cursor-pointer"}`}
    >
      <Prompt k={k} label={label} dim={disabled} fill={flash ? 1 : 0} />
    </button>
  );
}

// Hold-to-confirm prompt. Hold the key (or press and hold the mouse on it);
// letting go early cancels. Completing fires onComplete once per hold.
export function HoldPrompt({ k = "G", code = "KeyG", label, duration = 1300, onComplete, disabled = false }) {
  const [holding, setHolding] = useState(false);
  const [progress, setProgress] = useState(0);
  const rafRef = useRef(0);
  const doneRef = useRef(onComplete);

  useEffect(() => {
    doneRef.current = onComplete;
  }, [onComplete]);

  // Fill loop: runs only while held, torn down on release or unmount.
  useEffect(() => {
    if (!holding) {
      setProgress(0);
      return undefined;
    }
    const start = performance.now();
    const tick = (now) => {
      const p = Math.min(1, (now - start) / duration);
      setProgress(p);
      if (p >= 1) {
        rafRef.current = 0;
        setHolding(false);
        if (doneRef.current) doneRef.current();
        return;
      }
      rafRef.current = requestAnimationFrame(tick);
    };
    rafRef.current = requestAnimationFrame(tick);
    return () => {
      cancelAnimationFrame(rafRef.current);
      rafRef.current = 0;
    };
  }, [holding, duration]);

  // Keyboard hold. Auto-repeat is ignored, so one hold = one completion.
  useEffect(() => {
    if (disabled) return undefined;
    const down = (e) => {
      if (e.code !== code || e.repeat || isTyping(e.target)) return;
      setHolding(true);
    };
    const up = (e) => {
      if (e.code === code) setHolding(false);
    };
    const cancel = () => setHolding(false);
    window.addEventListener("keydown", down);
    window.addEventListener("keyup", up);
    window.addEventListener("blur", cancel);
    return () => {
      window.removeEventListener("keydown", down);
      window.removeEventListener("keyup", up);
      window.removeEventListener("blur", cancel);
      setHolding(false);
    };
  }, [code, disabled]);

  const start = (e) => {
    if (disabled) return;
    e.currentTarget.setPointerCapture(e.pointerId);
    setHolding(true);
  };
  const stop = () => setHolding(false);

  return (
    <button
      type="button"
      disabled={disabled}
      onPointerDown={start}
      onPointerUp={stop}
      onPointerCancel={stop}
      className={`block touch-none text-left outline-none select-none ${disabled ? "cursor-not-allowed" : "cursor-pointer"}`}
    >
      <div className={`tx-prompt flex h-11 w-max min-w-[15rem] items-center gap-3 py-1.5 pr-6 pl-2 ${disabled ? "opacity-60" : ""}`}>
        <KeyCap k={k} fill={progress} dim={disabled} />
        <span className={`text-[14px] ${disabled ? "text-faint" : "text-ink"}`}>{label}</span>
      </div>
    </button>
  );
}
