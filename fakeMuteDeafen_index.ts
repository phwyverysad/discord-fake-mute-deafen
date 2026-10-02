import { ApplicationCommandInputType } from "@api/Commands";
import { definePluginSettings } from "@api/Settings";
import { Logger } from "@utils/Logger";
import definePlugin, { OptionType } from "@utils/types";
import { findAll, findByProps } from "@webpack";
import {
    ChannelStore,
    MediaEngineStore,
    SelectedChannelStore,
    UserStore,
    VoiceStateStore
} from "@webpack/common";

import managedStyle from "./style.css?managed";

const logger = new Logger("FakeMuteDeafen");

// สถานะ Fake Mute / Fake Deafen (อิสระต่อกัน 100%)
let spoofMute = false;
let spoofDeafen = false;

let rtcConnectionClass: any | undefined;
let lastRtcConnectionInstance: any | undefined;
let originalRtcConnect: ((...args: any[]) => any) | undefined;
let originalRtcSetState: ((...args: any[]) => any) | undefined;
let originalSend: typeof WebSocket.prototype.send | null = null;
let activeGatewayWs: WebSocket | null = null;

let wrapper: HTMLDivElement | null = null;
let boundMouseMove: ((e: MouseEvent) => void) | null = null;
let boundMouseUp: (() => void) | null = null;
let hoverTimeout: any = null;

// Synchronization & Rapid-Toggle Throttling Engine
let lastGatewaySendTime = 0;
let pendingGatewayTimer: any = null;
let desyncCheckTimer: any = null;
let fluxAudioDebounceTimer: any = null;
const GATEWAY_THROTTLE_MS = 120; // 120ms prevents hitting Discord's Opcode 4 rate-limits while keeping 0ms perceived latency

const settings = definePluginSettings({
    showFloatingWidget: {
        type: OptionType.BOOLEAN,
        description: "แสดงปุ่ม Floating Widget เล็กๆ ที่มุมขวาล่างของจอ",
        default: true,
        onChange(v) {
            if (wrapper) {
                wrapper.style.display = v ? "flex" : "none";
            }
        }
    }
});

// -------------------------------------------------------------
// ตรรกะตรวจสอบสถานะจริงของ Discord (Real Hardware States)
// -------------------------------------------------------------
function isRealMute(): boolean {
    try {
        return Boolean(MediaEngineStore?.isMute?.() || MediaEngineStore?.isSelfMute?.());
    } catch {
        return false;
    }
}

function isRealDeaf(): boolean {
    try {
        return Boolean(MediaEngineStore?.isDeaf?.() || MediaEngineStore?.isSelfDeaf?.());
    } catch {
        return false;
    }
}

// ตรวจสอบว่าในระดับฮาร์ดแวร์ ไมค์ควรจะถูกปิดจริงหรือไม่
function shouldActuallyMuteMic(requestedMute: boolean): boolean {
    // หากผู้ใช้กดปิดไมค์จริงหรือกดปิดหูฟังจริงใน Discord ไมค์ต้องดับสนิท 100%
    if (isRealMute() || isRealDeaf()) {
        return true;
    }
    // หากไม่ได้ปิดจริง แต่เปิด Fake Mute หรือ Fake Deafen หลอกไว้ ให้เปิดไมค์ไว้เพื่อให้เราพูดได้
    if (spoofMute || spoofDeafen) {
        return false;
    }
    return Boolean(requestedMute);
}

// ตรวจสอบว่าในระดับฮาร์ดแวร์ เสียงหูฟังควรจะดับจริงหรือไม่
function shouldActuallyDeafenAudio(requestedDeaf: boolean): boolean {
    // หากผู้ใช้กดปิดหูฟังจริงใน Discord เสียงต้องดับสนิท 100%
    if (isRealDeaf()) {
        return true;
    }
    // หากไม่ได้ปิดจริง แต่เปิด Fake Deafen หลอกไว้ ให้เปิดเสียงไว้เพื่อให้เราได้ยิน
    if (spoofDeafen) {
        return false;
    }
    return Boolean(requestedDeaf);
}

// -------------------------------------------------------------
// 1. Gateway Socket Interception & Sending (Opcode 4)
//    ควบคุมสถานะส่งให้เซิร์ฟเวอร์แบบอิสระต่อกัน พร้อมระบบกันบั๊กกดรัว
// -------------------------------------------------------------
function getGatewaySocket(): any {
    try {
        const wsModule = (findByProps as any)("getSocket");
        return wsModule?.getSocket?.();
    } catch {
        return null;
    }
}

function hookGatewaySocket(socket: any) {
    if (!socket || socket._fakeSendHooked) return;
    socket._fakeSendHooked = true;

    const origSend = socket.send;
    socket.send = function (op: number, data: any) {
        // Opcode 4: Voice State Update
        if (op === 4 && data) {
            if (spoofDeafen) {
                data.self_deaf = true;
            }
            if (spoofMute) {
                data.self_mute = true;
            }
        }
        return origSend.apply(this, arguments);
    };

    logger.info("GatewaySocket send hooked successfully");
}

function sendGatewayVoiceStateNow() {
    const voiceChannelId = SelectedChannelStore?.getVoiceChannelId();
    if (!voiceChannelId) {
        logger.warn("Not in a voice channel, skipping Opcode 4 send");
        return;
    }

    const channel = ChannelStore?.getChannel(voiceChannelId);
    const guildId = channel?.guild_id ?? null;

    const isDeaf = Boolean(spoofDeafen || isRealDeaf());
    const isMute = Boolean(spoofMute || isRealMute() || isRealDeaf());

    const payload = {
        guild_id: guildId,
        channel_id: voiceChannelId,
        self_mute: isMute,
        self_deaf: isDeaf,
        self_video: false,
        flags: 0
    };

    lastGatewaySendTime = Date.now();
    let sent = false;

    // วิธีที่ 1: ส่งผ่าน GatewaySocket ของ Discord โดยตรง
    const socket = getGatewaySocket();
    if (socket) {
        hookGatewaySocket(socket);
        try {
            socket.send(4, payload);
            logger.info("Sent Opcode 4 via GatewaySocket", payload);
            sent = true;
        } catch (e) {
            logger.error("Error sending Opcode 4 via GatewaySocket", e);
        }
    }

    // วิธีที่ 2: ส่งผ่าน Raw WebSocket หากมี instance ที่ตรวจพบ
    if (activeGatewayWs && activeGatewayWs.readyState === WebSocket.OPEN) {
        try {
            activeGatewayWs.send(JSON.stringify({ op: 4, d: payload }));
            logger.info("Sent Opcode 4 via activeGatewayWs", payload);
            sent = true;
        } catch (e) {
            logger.error("Error sending Opcode 4 via activeGatewayWs", e);
        }
    }

    if (!sent) {
        logger.warn("Could not find active Gateway socket to send Opcode 4 immediately (will apply on next packet)");
    }

    // ตรวจสอบความถูกต้องของสถานะหลังส่ง 400ms เพื่อป้องกันการหลุด desync
    scheduleDesyncVerification();
}

function queueGatewayVoiceState() {
    const now = Date.now();
    const elapsed = now - lastGatewaySendTime;

    if (elapsed >= GATEWAY_THROTTLE_MS) {
        // ครั้งแรก หรือไม่ได้กดรัว: ส่งทันที 0ms ทันใจ
        if (pendingGatewayTimer) {
            clearTimeout(pendingGatewayTimer);
            pendingGatewayTimer = null;
        }
        sendGatewayVoiceStateNow();
    } else {
        // หากกดสลับเร็วๆ: ป้องกันการโดน Discord Gateway Rate-Limit ตัดทิ้ง
        // โดยจะตั้งเวลาส่งสถานะสุดท้ายที่แน่นอนเสมอ (Trailing Edge Sync)
        if (pendingGatewayTimer) {
            clearTimeout(pendingGatewayTimer);
        }
        const delay = Math.max(10, GATEWAY_THROTTLE_MS - elapsed);
        pendingGatewayTimer = setTimeout(() => {
            pendingGatewayTimer = null;
            sendGatewayVoiceStateNow();
        }, delay);
    }
}

function scheduleDesyncVerification() {
    if (desyncCheckTimer) clearTimeout(desyncCheckTimer);
    desyncCheckTimer = setTimeout(() => {
        try {
            const currentUserId = UserStore?.getCurrentUser?.()?.id;
            const vs = currentUserId ? VoiceStateStore?.getVoiceStateForUser?.(currentUserId) : null;
            if (vs && SelectedChannelStore?.getVoiceChannelId()) {
                const expectedDeaf = Boolean(spoofDeafen || isRealDeaf());
                const expectedMute = Boolean(spoofMute || isRealMute() || isRealDeaf());
                if (Boolean(vs.selfMute) !== expectedMute || Boolean(vs.selfDeaf) !== expectedDeaf) {
                    logger.info("Auto-sync: Server voice state mismatch detected, resending Opcode 4...");
                    sendGatewayVoiceStateNow();
                }
            }
        } catch {}
    }, 400);
}

// -------------------------------------------------------------
// 2. Hardware / RTC Protection
// -------------------------------------------------------------
function getRtcConnectionClass() {
    if (rtcConnectionClass) return rtcConnectionClass;

    const [mod] = findAll((m: any) => {
        try {
            const candidate = typeof m === "function"
                ? m
                : typeof m?.A === "function"
                    ? m.A
                    : undefined;
            if (!candidate?.prototype) return false;

            const src = Function.prototype.toString.call(candidate);
            return src.includes("RTCConnection._handleConnect")
                && src.includes("_handleDisconnect")
                && src.includes("selectProtocol")
                && typeof candidate.prototype.setState === "function";
        } catch {
            return false;
        }
    });

    rtcConnectionClass = typeof mod === "function" ? mod : mod?.A;
    return rtcConnectionClass;
}

function installRtcTracker() {
    const cls = getRtcConnectionClass();
    const proto = cls?.prototype;
    if (!proto) return;

    if (!originalRtcConnect && typeof proto.connect === "function") {
        originalRtcConnect = proto.connect;
        proto.connect = function (...args: any[]) {
            lastRtcConnectionInstance = this;
            patchConnection(this?._connection);
            return originalRtcConnect!.apply(this, args);
        };
    }

    if (!originalRtcSetState && typeof proto.setState === "function") {
        originalRtcSetState = proto.setState;
        proto.setState = function (...args: any[]) {
            lastRtcConnectionInstance = this;
            patchConnection(this?._connection);
            return originalRtcSetState!.apply(this, args);
        };
    }
}

function uninstallRtcTracker() {
    const cls = getRtcConnectionClass();
    const proto = cls?.prototype;
    if (proto) {
        if (originalRtcConnect) proto.connect = originalRtcConnect;
        if (originalRtcSetState) proto.setState = originalRtcSetState;
    }
    originalRtcConnect = undefined;
    originalRtcSetState = undefined;
    lastRtcConnectionInstance = undefined;
}

function getAllMediaConnections(): any[] {
    const conns: any[] = [];
    try {
        const engine = (MediaEngineStore as any)?.getMediaEngine?.();
        if (engine?.connections) {
            for (const c of engine.connections) {
                if (c && !conns.includes(c)) conns.push(c);
            }
        }
    } catch {}

    const rtcConn = lastRtcConnectionInstance?._connection;
    if (rtcConn && !conns.includes(rtcConn)) {
        conns.push(rtcConn);
    }
    return conns;
}

function patchConnection(conn: any) {
    if (!conn) return;

    // Patch Prototype
    try {
        const proto = Object.getPrototypeOf(conn);
        if (proto && !proto._fakeMuteDeafenPatched) {
            proto._fakeMuteDeafenPatched = true;

            const origProtoMute = proto.setSelfMute;
            proto.setSelfMute = function (mute: boolean) {
                const target = shouldActuallyMuteMic(mute);
                return origProtoMute ? origProtoMute.call(this, target) : undefined;
            };

            const origProtoDeaf = proto.setSelfDeaf;
            proto.setSelfDeaf = function (deaf: boolean) {
                const target = shouldActuallyDeafenAudio(deaf);
                return origProtoDeaf ? origProtoDeaf.call(this, target) : undefined;
            };

            const origProtoInput = proto.setInputMuted;
            if (origProtoInput) {
                proto.setInputMuted = function (mute: boolean) {
                    return origProtoInput.call(this, shouldActuallyMuteMic(mute));
                };
            }

            const origProtoOutput = proto.setOutputMuted;
            if (origProtoOutput) {
                proto.setOutputMuted = function (deaf: boolean) {
                    return origProtoOutput.call(this, shouldActuallyDeafenAudio(deaf));
                };
            }
        }
    } catch {}

    // Patch Instance
    if (!conn._fakeMuteDeafenPatched) {
        conn._fakeMuteDeafenPatched = true;

        const origInstMute = conn.setSelfMute;
        conn.setSelfMute = function (mute: boolean) {
            const target = shouldActuallyMuteMic(mute);
            return origInstMute ? origInstMute.call(this, target) : undefined;
        };

        const origInstDeaf = conn.setSelfDeaf;
        conn.setSelfDeaf = function (deaf: boolean) {
            const target = shouldActuallyDeafenAudio(deaf);
            return origInstDeaf ? origInstDeaf.call(this, target) : undefined;
        };

        const origInstInput = conn.setInputMuted;
        if (origInstInput) {
            conn.setInputMuted = function (mute: boolean) {
                return origInstInput.call(this, shouldActuallyMuteMic(mute));
            };
        }

        const origInstOutput = conn.setOutputMuted;
        if (origInstOutput) {
            conn.setOutputMuted = function (deaf: boolean) {
                return origInstOutput.call(this, shouldActuallyDeafenAudio(deaf));
            };
        }
    }
}

export function restoreLocalMedia() {
    const conns = getAllMediaConnections();
    const targetMute = shouldActuallyMuteMic(false);
    const targetDeaf = shouldActuallyDeafenAudio(false);

    for (const conn of conns) {
        patchConnection(conn);
        try { conn.setSelfMute?.(targetMute); } catch {}
        try { conn.setInputMuted?.(targetMute); } catch {}
        try { conn.setMicrophoneMute?.(targetMute); } catch {}
        try { conn.setAudioEnabled?.(!targetMute); } catch {}

        try { conn.setSelfDeaf?.(targetDeaf); } catch {}
        try { conn.setOutputMuted?.(targetDeaf); } catch {}
        try { conn.setAudioOutputMuted?.(targetDeaf); } catch {}
        try { conn.setSpeakerMute?.(targetDeaf); } catch {}
    }
}

// -------------------------------------------------------------
// 3. ควบคุมสถานะ Fake Mute / Fake Deafen (ทำงานทันที 0ms)
// -------------------------------------------------------------
export function setFakeMute(enabled: boolean) {
    spoofMute = Boolean(enabled);
    
    // 1. UI อัปเดตทันที 0ms ไม่มีความหน่วง
    updateButtonsUI();

    // 2. ปรับระดับเสียงไมค์และฮาร์ดแวร์ทันที 0ms
    restoreLocalMedia();

    // 3. ซิงค์สถานะกับ Discord Gateway อย่างแม่นยำ
    queueGatewayVoiceState();

    logger.info(`Fake Mute set to: ${spoofMute}`);
}

export function setFakeDeafen(enabled: boolean) {
    spoofDeafen = Boolean(enabled);

    // 1. UI อัปเดตทันที 0ms ไม่มีความหน่วง
    updateButtonsUI();

    // 2. ปรับระดับเสียงหูฟังและฮาร์ดแวร์ทันที 0ms
    restoreLocalMedia();

    // 3. ซิงค์สถานะกับ Discord Gateway อย่างแม่นยำ
    queueGatewayVoiceState();

    logger.info(`Fake Deafen set to: ${spoofDeafen}`);
}

function updateButtonsUI() {
    const dot = document.getElementById("fm-dot");
    const muteBtn = document.getElementById("fakeMuteBtn");
    const deafenBtn = document.getElementById("fakeDeafenBtn");

    if (wrapper) {
        if (spoofMute || spoofDeafen) {
            wrapper.classList.add("has-active");
        } else {
            wrapper.classList.remove("has-active");
        }
    }

    if (dot) {
        if (spoofMute || spoofDeafen) {
            dot.title = `Fake Mute/Deafen กำลังเปิดใช้งาน: ${[spoofMute ? "Fake Mute" : null, spoofDeafen ? "Fake Deafen" : null].filter(Boolean).join(" + ")} (นำเมาส์มาจ่อเพื่อเปิดเมนู)`;
        } else {
            dot.title = "Discord Fake Mute / Deafen (นำเมาส์มาจ่อเพื่อเปิดเมนู)";
        }
    }

    if (muteBtn) {
        if (spoofMute) {
            muteBtn.classList.add("active");
            muteBtn.setAttribute("aria-pressed", "true");
            muteBtn.title = "Fake Mute: กำลังเปิดใช้งาน (คนอื่นเห็นว่าปิดไมค์ แต่ไมค์จริงไม่ปิด)";
        } else {
            muteBtn.classList.remove("active");
            muteBtn.setAttribute("aria-pressed", "false");
            muteBtn.title = "Fake Mute: ปิดอยู่ (คลิกเพื่อเปิด Fake Mute)";
        }
    }

    if (deafenBtn) {
        if (spoofDeafen) {
            deafenBtn.classList.add("active");
            deafenBtn.setAttribute("aria-pressed", "true");
            deafenBtn.title = "Fake Deafen: กำลังเปิดใช้งาน (คนอื่นเห็นว่าปิดหูฟัง แต่หูฟัง/ไมค์จริงไม่ปิด)";
        } else {
            deafenBtn.classList.remove("active");
            deafenBtn.setAttribute("aria-pressed", "false");
            deafenBtn.title = "Fake Deafen: ปิดอยู่ (คลิกเพื่อเปิด Fake Deafen)";
        }
    }
}

// ฟังก์ชันรักษาเมนูเปิดไว้เมื่อผู้ใช้กำลังคลิกหรือใช้งานต่อเนื่อง
function keepMenuOpen(duration = 1500) {
    if (hoverTimeout) clearTimeout(hoverTimeout);
    wrapper?.classList.add("menu-open");
    hoverTimeout = setTimeout(() => {
        if (!wrapper?.matches(":hover")) {
            wrapper?.classList.remove("menu-open");
        }
    }, duration);
}

// -------------------------------------------------------------
// 4. Minimalist Bottom-Right Dot UI (มุมขวาล่าง เล็กๆ คลีนๆ สไลด์เมนูเมื่อจ่อเมาส์)
// -------------------------------------------------------------
function initUI() {
    if (document.getElementById("fm-wrapper")) return;

    wrapper = document.createElement("div");
    wrapper.id = "fm-wrapper";
    if (!settings.store.showFloatingWidget) {
        wrapper.style.display = "none";
    }

    wrapper.innerHTML = `
        <div id="fm-container">
            <div id="fm-dot" title="Discord Fake Mute / Deafen (นำเมาส์มาจ่อเพื่อเปิดเมนู)"></div>
            <div id="fm-panel">
                <button class="fm-btn" id="fakeMuteBtn" type="button" title="Fake Mute (คนอื่นเห็นว่าปิดไมค์ แต่ไมค์จริงไม่ปิด พูดได้ปกติ)">
                    <div class="slash-line"></div>
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M12 2a3 3 0 0 0-3 3v7a3 3 0 0 0 6 0V5a3 3 0 0 0-3-3Z"></path>
                        <path d="M19 10v2a7 7 0 0 1-14 0v-2"></path>
                        <line x1="12" y1="19" x2="12" y2="22"></line>
                        <line x1="8" y1="22" x2="16" y2="22"></line>
                    </svg>
                </button>
                <button class="fm-btn" id="fakeDeafenBtn" type="button" title="Fake Deafen (คนอื่นเห็นว่าปิดหูฟัง แต่หูฟัง/ไมค์จริงไม่ปิด ได้ยินและพูดได้)">
                    <div class="slash-line"></div>
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M3 14h3a2 2 0 0 1 2 2v3a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-7a9 9 0 0 1 18 0v7a2 2 0 0 1-2 2h-1a2 2 0 0 1-2-2v-3a2 2 0 0 1 2-2h3"></path>
                    </svg>
                </button>
            </div>
        </div>
    `;
    document.body.appendChild(wrapper);

    const dot = document.getElementById("fm-dot");
    const muteBtn = document.getElementById("fakeMuteBtn");
    const deafenBtn = document.getElementById("fakeDeafenBtn");

    updateButtonsUI();

    // ตัวจัดการคลิกความเร็วสูง (รองรับทั้ง click ปกติ และ dblclick โดยไม่หลุดตกหล่น)
    const bindFastAction = (el: HTMLElement | null, actionFn: () => void) => {
        if (!el) return;
        const handler = (e: Event) => {
            e.preventDefault();
            e.stopPropagation();
            keepMenuOpen(1500);
            actionFn();
        };
        el.addEventListener("click", handler);
        el.addEventListener("dblclick", handler);
    };

    bindFastAction(muteBtn, () => setFakeMute(!spoofMute));
    bindFastAction(deafenBtn, () => setFakeDeafen(!spoofDeafen));

    if (dot) {
        dot.onclick = (e) => {
            e.stopPropagation();
            wrapper?.classList.toggle("menu-open");
        };
    }

    wrapper.addEventListener("mouseenter", () => {
        if (hoverTimeout) clearTimeout(hoverTimeout);
        wrapper?.classList.add("menu-open");
    });

    wrapper.addEventListener("mouseleave", () => {
        if (hoverTimeout) clearTimeout(hoverTimeout);
        hoverTimeout = setTimeout(() => {
            wrapper?.classList.remove("menu-open");
        }, 320);
    });
}

function removeUI() {
    if (pendingGatewayTimer) { clearTimeout(pendingGatewayTimer); pendingGatewayTimer = null; }
    if (desyncCheckTimer) { clearTimeout(desyncCheckTimer); desyncCheckTimer = null; }
    if (fluxAudioDebounceTimer) { clearTimeout(fluxAudioDebounceTimer); fluxAudioDebounceTimer = null; }
    if (hoverTimeout) { clearTimeout(hoverTimeout); hoverTimeout = null; }

    if (boundMouseMove) window.removeEventListener("mousemove", boundMouseMove);
    if (boundMouseUp) window.removeEventListener("mouseup", boundMouseUp);
    if (boundResize) window.removeEventListener("resize", boundResize);
    boundMouseMove = null;
    boundMouseUp = null;
    boundResize = null;

    if (wrapper && wrapper.parentNode) {
        wrapper.parentNode.removeChild(wrapper);
    }
    wrapper = null;
}

// -------------------------------------------------------------
// 5. Expose Helpers for Console & Debug
// -------------------------------------------------------------
function exposeHelpers() {
    const g = globalThis as any;
    g.FakeMuteDeafen = {
        version: "1.0.1",
        getStatus: () => {
            const userId = UserStore.getCurrentUser?.()?.id;
            const vs = userId ? VoiceStateStore.getVoiceStateForUser?.(userId) : undefined;
            return {
                spoofMute,
                spoofDeafen,
                voiceChannelId: SelectedChannelStore?.getVoiceChannelId(),
                serverVoiceState: {
                    selfMute: Boolean(vs?.selfMute),
                    selfDeaf: Boolean(vs?.selfDeaf)
                },
                realDiscordState: {
                    isMute: MediaEngineStore.isMute(),
                    isDeaf: MediaEngineStore.isDeaf()
                }
            };
        },
        setFakeMute,
        setFakeDeafen,
        sendGatewayVoiceStateNow,
        queueGatewayVoiceState,
        restoreLocalMedia
    };
}

function removeHelpers() {
    delete (globalThis as any).FakeMuteDeafen;
}

// จัดการเหตุการณ์ Flux ให้รวบยอด Debounce ป้องกันการลูปย้อนกลับขณะกดรัว
function handleFluxAudioStateChange() {
    if (fluxAudioDebounceTimer) clearTimeout(fluxAudioDebounceTimer);
    fluxAudioDebounceTimer = setTimeout(() => {
        restoreLocalMedia();
        updateButtonsUI();
    }, 40);
}

export default definePlugin({
    name: "FakeMuteDeafen",
    description: "แสดงไอคอน Mute/Deafen ให้คนอื่นเห็น โดยของจริงไม่ปิด (ไมค์และหูฟังจริงยังเปิดใช้งานได้ 100%) [v1.0.1]",
    authors: [
        {
            name: "phwyverysad",
            id: 0n
        },
        {
            name: "Woranat",
            id: 0n
        }
    ],
    tags: ["Voice", "Utility"],
    managedStyle,
    settings,

    commands: [
        {
            name: "fakemute",
            description: "เปิด/ปิด Fake Mute (คนอื่นเห็นว่าปิดไมค์ แต่ไมค์จริงไม่ปิด)",
            inputType: ApplicationCommandInputType.BUILT_IN,
            execute() {
                setFakeMute(!spoofMute);
                return {
                    content: `Fake Mute: ${spoofMute ? "เปิดใช้งาน (คนอื่นจะเห็นไอคอนปิดไมค์ แต่เรายังพูดได้ปกติ)" : "ปิดการใช้งาน"}`
                };
            }
        },
        {
            name: "fakedeafen",
            description: "เปิด/ปิด Fake Deafen (คนอื่นเห็นว่าปิดหูฟัง แต่หูฟังและไมค์จริงไม่ปิด)",
            inputType: ApplicationCommandInputType.BUILT_IN,
            execute() {
                setFakeDeafen(!spoofDeafen);
                return {
                    content: `Fake Deafen: ${spoofDeafen ? "เปิดใช้งาน (คนอื่นจะเห็นไอคอนปิดหูฟัง แต่เรายังได้ยินและพูดได้)" : "ปิดการใช้งาน"}`
                };
            }
        }
    ],

    start() {
        installRtcTracker();

        const socket = getGatewaySocket();
        if (socket) {
            hookGatewaySocket(socket);
        }

        originalSend = WebSocket.prototype.send;
        WebSocket.prototype.send = function (data: any) {
            try {
                if (typeof data === "string") {
                    const json = JSON.parse(data);
                    if (json && (json.op === 1 || json.op === 2 || json.op === 4)) {
                        activeGatewayWs = this;
                    }
                    if (json && json.op === 4 && json.d) {
                        if (spoofDeafen) {
                            json.d.self_deaf = true;
                        }
                        if (spoofMute) {
                            json.d.self_mute = true;
                        }
                        data = JSON.stringify(json);
                    }
                }
            } catch (err) {}
            return originalSend!.call(this, data);
        };

        exposeHelpers();
        initUI();
    },

    stop() {
        if (originalSend) {
            WebSocket.prototype.send = originalSend;
            originalSend = null;
        }

        uninstallRtcTracker();
        removeHelpers();

        if (spoofMute || spoofDeafen) {
            spoofMute = false;
            spoofDeafen = false;
            sendGatewayVoiceStateNow();
            restoreLocalMedia();
        }

        removeUI();
    },

    flux: {
        RTC_CONNECTION_STATE({ state }: { state?: string; }) {
            if (state === "RTC_CONNECTED") {
                const s = getGatewaySocket();
                if (s) hookGatewaySocket(s);

                const conns = getAllMediaConnections();
                for (const c of conns) patchConnection(c);

                if (spoofMute || spoofDeafen) {
                    queueGatewayVoiceState();
                    restoreLocalMedia();
                }
            }
        },

        VOICE_CHANNEL_SELECT() {
            if (spoofMute || spoofDeafen) {
                setTimeout(() => {
                    const s = getGatewaySocket();
                    if (s) hookGatewaySocket(s);
                    queueGatewayVoiceState();
                    restoreLocalMedia();
                }, 200);
            }
        },

        // เมื่อผู้ใช้กดปิดไมค์/เปิดไมค์จริง หรือปิดหูฟัง/เปิดหูฟังจริงใน Discord
        AUDIO_TOGGLE_SELF_MUTE() {
            handleFluxAudioStateChange();
        },
        AUDIO_TOGGLE_SELF_DEAF() {
            handleFluxAudioStateChange();
        },
        AUDIO_SET_SELF_MUTE() {
            handleFluxAudioStateChange();
        },
        AUDIO_SET_SELF_DEAF() {
            handleFluxAudioStateChange();
        },
        MEDIA_ENGINE_SET_SELF_MUTE() {
            handleFluxAudioStateChange();
        },
        MEDIA_ENGINE_SET_SELF_DEAF() {
            handleFluxAudioStateChange();
        }
    }
});
