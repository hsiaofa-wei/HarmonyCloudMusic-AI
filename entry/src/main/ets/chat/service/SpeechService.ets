import { textToSpeech, speechRecognizer } from '@kit.CoreSpeechKit';
import { abilityAccessCtrl, common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

export interface SpeechCallbacks {
  onRecognized?: (text: string, isFinal: boolean) => void;
  onListeningChange?: (isListening: boolean) => void;
}

export class SpeechService {
  private static instance: SpeechService | null = null;

  private ttsEngine: textToSpeech.TextToSpeechEngine | null = null;
  private asrEngine: speechRecognizer.SpeechRecognitionEngine | null = null;
  private initPromise: Promise<void> | null = null;
  private asrInitPromise: Promise<void> | null = null;
  private sessionId: string = '';
  private callbacks: SpeechCallbacks = {};
  private currentMessageId: string = '';
  private speakGeneration: number = 0;
  private lastAsrError: string = '';

  private constructor() {
  }

  static getInstance(): SpeechService {
    if (!SpeechService.instance) {
      SpeechService.instance = new SpeechService();
    }
    return SpeechService.instance;
  }

  setCallbacks(callbacks: SpeechCallbacks): void {
    this.callbacks = callbacks;
  }

  static sanitizeForSpeech(text: string): string {
    let result = text;
    result = result.replace(/```[\s\S]*?```/g, ' ');
    result = result.replace(/`[^`]*`/g, ' ');
    result = result.replace(/\[([^\]]*)\]\([^)]*\)/g, '$1');
    result = result.replace(/[#*_~>|]/g, '');
    result = result.replace(/\s+/g, ' ');
    return result.trim();
  }

  async init(): Promise<void> {
    if (this.initPromise === null) {
      this.initPromise = this.initEngines();
    }
    await this.initPromise;
  }

  async requestMicPermission(ctx: common.UIAbilityContext): Promise<boolean> {
    const atManager = abilityAccessCtrl.createAtManager();
    try {
      const result = await atManager.requestPermissionsFromUser(ctx, ['ohos.permission.MICROPHONE']);
      return result.authResults[0] === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
    } catch (err) {
      console.error('申请麦克风权限失败:', JSON.stringify(err));
      return false;
    }
  }

  isAsrSupported(): boolean {
    return canIUse('SystemCapability.AI.SpeechRecognizer');
  }

  getLastAsrError(): string {
    return this.lastAsrError;
  }

  async startListening(ctx: common.UIAbilityContext): Promise<boolean> {
    await this.init();
    this.stopSpeak();
    if (!this.isAsrSupported()) {
      this.lastAsrError = '当前设备不支持语音识别';
      return false;
    }
    const granted = await this.requestMicPermission(ctx);
    if (!granted) {
      this.lastAsrError = '需要麦克风权限才能语音输入';
      return false;
    }
    if (this.asrEngine === null) {
      if (this.lastAsrError.length === 0) {
        this.lastAsrError = '语音识别引擎未就绪，请完全关闭应用后重试';
      }
      return false;
    }
    try {
      const engine = this.asrEngine;
      if (engine === null) {
        this.lastAsrError = '语音识别引擎未就绪';
        return false;
      }
      this.sessionId = Date.now().toString();
      const startParams: speechRecognizer.StartParams = {
        sessionId: this.sessionId,
        audioInfo: {
          audioType: 'pcm',
          sampleRate: 16000,
          soundChannel: 1,
          sampleBit: 16
        },
        extraParams: {
          recognitionMode: 0,
          maxAudioDuration: 60000
        }
      };
      engine.startListening(startParams);
      this.callbacks.onListeningChange?.(true);
      return true;
    } catch (err) {
      const error = err as BusinessError;
      this.lastAsrError = `启动语音识别失败(${error.code}): ${error.message}`;
      console.error('启动语音识别失败:', error.code, error.message);
      return false;
    }
  }

  stopListening(): void {
    try {
      this.asrEngine?.finish(this.sessionId);
    } catch (err) {
      const error = err as BusinessError;
      console.error('停止语音识别失败:', error.code, error.message);
    } finally {
      this.callbacks.onListeningChange?.(false);
    }
  }

  cancelListening(): void {
    try {
      this.asrEngine?.cancel(this.sessionId);
    } catch (err) {
      console.error('取消语音识别失败:', JSON.stringify(err));
    }
    this.callbacks.onListeningChange?.(false);
  }

  /** 仅驱动引擎，不回调 UI */
  speak(text: string, messageId: string): void {
    const trimmed = text.trim();
    if (trimmed.length === 0) {
      return;
    }
    this.init().then(() => {
      if (!this.ttsEngine) {
        console.error('TTS引擎未就绪');
        return;
      }
      const generation = ++this.speakGeneration;
      this.currentMessageId = messageId;
      try {
        const speakParams: textToSpeech.SpeakParams = {
          requestId: `${generation}`,
          extraParams: { speed: 1.1, volume: 2.0, pitch: 0.9 }
        };
        this.ttsEngine.speak(trimmed, speakParams);
      } catch (err) {
        const error = err as BusinessError;
        console.error('朗读失败:', error.code, error.message);
      }
    }).catch(() => {
    });
  }

  /** 仅停止引擎，不回调 UI（UI 已自行复位） */
  stopSpeak(): void {
    this.speakGeneration++;
    this.currentMessageId = '';
    if (!this.ttsEngine) {
      return;
    }
    try {
      this.ttsEngine.stop();
    } catch (err) {
      console.error('停止TTS失败:', JSON.stringify(err));
    }
  }

  destroy(): void {
    this.cancelListening();
    this.stopSpeak();
    this.ttsEngine?.shutdown();
    this.ttsEngine = null;
    this.asrEngine?.shutdown();
    this.asrEngine = null;
    this.initPromise = null;
    this.asrInitPromise = null;
  }

  private async initEngines(): Promise<void> {
    await this.initTts();
    await this.initAsr();
  }

  private async initTts(): Promise<void> {
    if (this.ttsEngine !== null) {
      return;
    }
    try {
      const initParams: textToSpeech.CreateEngineParams = {
        language: 'zh-CN',
        person: 0,
        online: 1
      };
      this.ttsEngine = await textToSpeech.createEngine(initParams);
      this.setTtsListener();
    } catch (err) {
      const error = err as BusinessError;
      console.error('TTS初始化失败:', error.code, error.message);
    }
  }

  private setTtsListener(): void {
    if (!this.ttsEngine) {
      return;
    }
    const speakListener: textToSpeech.SpeakListener = {
      onStart: (_requestId: string, _response: textToSpeech.StartResponse) => {
      },
      onComplete: (_requestId: string, _response: textToSpeech.CompleteResponse) => {
        console.info('TTS onComplete（不通知 UI）');
        this.currentMessageId = '';
      },
      onStop: (_requestId: string, _response: textToSpeech.StopResponse) => {
        //  deliberately empty — UI 不依赖 onStop
      },
      onError: (_requestId: string, errorCode: number, errorMessage: string) => {
        console.error(`TTS onError ${errorCode}: ${errorMessage}`);
        this.currentMessageId = '';
      },
      onData: (_requestId: string, _audio: ArrayBuffer, _response: textToSpeech.SynthesisResponse) => {
      }
    };
    this.ttsEngine.setListener(speakListener);
  }

  private async initAsr(): Promise<void> {
    if (!this.isAsrSupported() || this.asrEngine !== null) {
      return;
    }
    if (this.asrInitPromise !== null) {
      await this.asrInitPromise;
      return;
    }
    this.asrInitPromise = this.createAsrEngine();
    try {
      await this.asrInitPromise;
    } finally {
      this.asrInitPromise = null;
    }
  }

  private async createAsrEngine(): Promise<void> {
    try {
      const initParams: speechRecognizer.CreateEngineParams = {
        language: 'zh-CN',
        online: 1,
        extraParams: { 'recognizerMode': 'short' }
      };
      this.asrEngine = await speechRecognizer.createEngine(initParams);
      this.setAsrListener();
    } catch (err) {
      const error = err as BusinessError;
      if (error.code === 1002200001) {
        this.lastAsrError = '语音引擎已被占用，请完全关闭应用（含 chat）后重新打开';
      } else {
        this.lastAsrError = `ASR初始化失败(${error.code}): ${error.message}`;
      }
      console.error('ASR初始化失败:', error.code, error.message);
    }
  }

  private setAsrListener(): void {
    if (!this.asrEngine) {
      return;
    }
    const listener: speechRecognizer.RecognitionListener = {
      onStart: (_sessionId: string, _eventMessage: string) => {
      },
      onEvent: (_sessionId: string, _eventCode: number, _eventMessage: string) => {
      },
      onResult: (_sessionId: string, result: speechRecognizer.SpeechRecognitionResult) => {
        const isFinal = result.isFinal || result.isLast;
        this.callbacks.onRecognized?.(result.result, isFinal);
      },
      onComplete: (_sessionId: string, _eventMessage: string) => {
        this.callbacks.onListeningChange?.(false);
      },
      onError: (_sessionId: string, errorCode: number, errorMessage: string) => {
        console.error(`识别错误 ${errorCode}: ${errorMessage}`);
        this.callbacks.onListeningChange?.(false);
      }
    };
    this.asrEngine.setListener(listener);
  }
}
