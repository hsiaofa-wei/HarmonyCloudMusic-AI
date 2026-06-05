import { util } from '@kit.ArkTS';
import { http } from '@kit.NetworkKit';
import { MessageRole } from '../model/Message';

export class ApiConfig {
  static API_KEY: string = '你的密钥';
  static BASE_URL: string = 'https://api.deepseek.com/chat/completions';
  static MODEL: string = 'deepseek-v4-flash';
  static MAX_TOKENS: number = 2000;
  static TEMPERATURE: number = 0.7;
  /** 是否开启思考模式（显示 reasoning_content） */
  static ENABLE_THINKING: boolean = false;
  /** 思考力度：high | max（仅 ENABLE_THINKING 为 true 时生效） */
  static REASONING_EFFORT: string = 'high';
}

export class ThinkingBody {
  type: string = 'disabled';

  constructor(enabled: boolean) {
    this.type = enabled ? 'enabled' : 'disabled';
  }
}

export class ApiMessage {
  role: string = '';
  content: string = '';

  constructor(role: string, content: string) {
    this.role = role;
    this.content = content;
  }
}

/** 关闭思考模式时的请求体（不包含 reasoning_effort） */
export class DeepSeekRequestBody {
  model: string = '';
  messages: ApiMessage[] = [];
  max_tokens: number = 2000;
  temperature: number = 0.7;
  stream: boolean = false;
  thinking: ThinkingBody = new ThinkingBody(false);

  constructor(
    model: string,
    messages: ApiMessage[],
    maxTokens: number,
    temperature: number,
    stream: boolean
  ) {
    this.model = model;
    this.messages = messages;
    this.max_tokens = maxTokens;
    this.temperature = temperature;
    this.stream = stream;
    this.thinking = new ThinkingBody(false);
  }
}

/** 开启思考模式时的请求体 */
export class DeepSeekThinkingRequestBody {
  model: string = '';
  messages: ApiMessage[] = [];
  max_tokens: number = 2000;
  temperature: number = 0.7;
  stream: boolean = false;
  thinking: ThinkingBody = new ThinkingBody(true);
  reasoning_effort: string = 'high';

  constructor(
    model: string,
    messages: ApiMessage[],
    maxTokens: number,
    temperature: number,
    stream: boolean,
    reasoningEffort: string
  ) {
    this.model = model;
    this.messages = messages;
    this.max_tokens = maxTokens;
    this.temperature = temperature;
    this.stream = stream;
    this.thinking = new ThinkingBody(true);
    this.reasoning_effort = reasoningEffort;
  }
}

export class RequestMessageItem {
  role: MessageRole = MessageRole.USER;
  content: string = '';

  constructor(role: MessageRole, content: string) {
    this.role = role;
    this.content = content;
  }
}

/** 流式增量：正文与思考过程分开 */
export class StreamDelta {
  contentPiece: string = '';
  reasoningPiece: string = '';
}

export class ChatReply {
  content: string = '';
  reasoningContent: string = '';
}

export class DeepSeekApi {
  private static instance: DeepSeekApi;

  private constructor() {
  }

  static getInstance(): DeepSeekApi {
    if (!DeepSeekApi.instance) {
      DeepSeekApi.instance = new DeepSeekApi();
    }
    return DeepSeekApi.instance;
  }

  private buildRequestExtraData(messages: ApiMessage[], stream: boolean): string {
    if (ApiConfig.ENABLE_THINKING) {
      const body = new DeepSeekThinkingRequestBody(
        ApiConfig.MODEL,
        messages,
        ApiConfig.MAX_TOKENS,
        ApiConfig.TEMPERATURE,
        stream,
        ApiConfig.REASONING_EFFORT
      );
      return JSON.stringify(body);
    }
    const body = new DeepSeekRequestBody(
      ApiConfig.MODEL,
      messages,
      ApiConfig.MAX_TOKENS,
      ApiConfig.TEMPERATURE,
      stream
    );
    return JSON.stringify(body);
  }

  async sendChatRequest(messages: RequestMessageItem[]): Promise<ChatReply> {
    if (ApiConfig.API_KEY === '' || ApiConfig.API_KEY === 'YOUR_API_KEY_HERE') {
      throw new Error('请先配置 DeepSeek API Key');
    }

    const apiMessages: ApiMessage[] = messages.map((msg: RequestMessageItem) =>
      new ApiMessage(msg.role, msg.content)
    );
    const extraData = this.buildRequestExtraData(apiMessages, false);

    const httpRequest = http.createHttp();
    try {
      const response = await httpRequest.request(
        ApiConfig.BASE_URL,
        {
          method: http.RequestMethod.POST,
          header: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${ApiConfig.API_KEY}`
          },
          extraData: extraData,
          connectTimeout: 60000,
          readTimeout: 120000
        }
      );

      if (response.responseCode !== 200) {
        const errorBody = response.result as string;
        throw new Error(`API请求失败(${response.responseCode}): ${errorBody}`);
      }

      const result = response.result as string;
      const jsonResponse: Record<string, Object> = JSON.parse(result) as Record<string, Object>;

      if (jsonResponse['error']) {
        const errorObj = jsonResponse['error'] as Record<string, Object>;
        const errorMsg = errorObj['message'] as string;
        throw new Error(errorMsg ?? 'API 返回错误');
      }

      const reply = new ChatReply();
      const choices = jsonResponse['choices'] as Array<Record<string, Object>>;
      if (choices && choices.length > 0) {
        const message = choices[0]['message'] as Record<string, Object>;
        if (message && message['content']) {
          reply.content = message['content'] as string;
        }
        if (ApiConfig.ENABLE_THINKING && message && message['reasoning_content']) {
          reply.reasoningContent = message['reasoning_content'] as string;
        }
      }

      if (reply.content.length === 0) {
        throw new Error('API 响应格式异常，无法提取回复内容');
      }

      return reply;
    } finally {
      httpRequest.destroy();
    }
  }

  async sendChatStreamRequest(
    messages: RequestMessageItem[],
    onDelta: (delta: StreamDelta) => void
  ): Promise<void> {
    if (ApiConfig.API_KEY === '' || ApiConfig.API_KEY === 'YOUR_API_KEY_HERE') {
      throw new Error('请先配置 DeepSeek API Key');
    }

    const apiMessages: ApiMessage[] = messages.map((msg: RequestMessageItem) =>
      new ApiMessage(msg.role, msg.content)
    );
    const extraData = this.buildRequestExtraData(apiMessages, true);
    const enableThinking = ApiConfig.ENABLE_THINKING;

    return new Promise((resolve, reject) => {
      const httpRequest = http.createHttp();
      let lineBuffer: string = '';
      let rawText: string = '';
      let responseCode: number = 0;
      let finished: boolean = false;
      let streamEnded: boolean = false;
      let statusReady: boolean = false;
      let emitted: boolean = false;
      const decoder = util.TextDecoder.create('utf-8', { ignoreBOM: true });

      const emitDelta = (delta: StreamDelta): void => {
        if (delta.contentPiece.length > 0 || delta.reasoningPiece.length > 0) {
          emitted = true;
          onDelta(delta);
        }
      };

      const finish = (error: Error | null): void => {
        if (finished) {
          return;
        }
        finished = true;
        httpRequest.off('dataReceive');
        httpRequest.off('dataEnd');
        httpRequest.destroy();
        if (error !== null) {
          reject(error);
        } else {
          resolve();
        }
      };

      const tryComplete = (): void => {
        if (finished || !streamEnded || !statusReady) {
          return;
        }
        if (responseCode !== 200) {
          finish(new Error(`API请求失败(${responseCode})`));
          return;
        }
        if (!emitted && rawText.length > 0) {
          DeepSeekApi.parseAllSseText(rawText, enableThinking, emitDelta);
        }
        finish(null);
      };

      const appendAndParse = (text: string): void => {
        if (text.length === 0) {
          return;
        }
        rawText = rawText + text;
        lineBuffer = lineBuffer + text;
        let newlineIndex = lineBuffer.indexOf('\n');
        while (newlineIndex >= 0) {
          let line = lineBuffer.substring(0, newlineIndex);
          lineBuffer = lineBuffer.substring(newlineIndex + 1);
          if (line.endsWith('\r')) {
            line = line.substring(0, line.length - 1);
          }
          const parseError = DeepSeekApi.parseSseLine(line.trim(), enableThinking, emitDelta);
          if (parseError !== null) {
            finish(parseError);
            return;
          }
          newlineIndex = lineBuffer.indexOf('\n');
        }
      };

      httpRequest.on('dataReceive', (data: ArrayBuffer) => {
        try {
          const text = decoder.decodeToString(new Uint8Array(data));
          appendAndParse(text);
        } catch (e) {
          const msg = e instanceof Error ? e.message : '数据解析失败';
          finish(new Error(msg));
        }
      });

      httpRequest.on('dataEnd', () => {
        const rest = lineBuffer.trim();
        if (rest.length > 0) {
          const parseError = DeepSeekApi.parseSseLine(rest, enableThinking, emitDelta);
          if (parseError !== null) {
            finish(parseError);
            return;
          }
        }
        lineBuffer = '';
        streamEnded = true;
        tryComplete();
      });

      httpRequest.requestInStream(
        ApiConfig.BASE_URL,
        {
          method: http.RequestMethod.POST,
          header: {
            'Content-Type': 'application/json',
            'Accept': 'text/event-stream',
            'Authorization': `Bearer ${ApiConfig.API_KEY}`
          },
          extraData: extraData,
          connectTimeout: 60000,
          readTimeout: 120000
        }
      ).then((code: number) => {
        responseCode = code;
        statusReady = true;
        if (code !== 200) {
          finish(new Error(`API请求失败(${code})`));
          return;
        }
        tryComplete();
      }).catch((err: Object) => {
        const msg = err instanceof Error ? err.message : '网络请求失败';
        finish(new Error(msg));
      });
    });
  }

  private static parseAllSseText(
    text: string,
    enableThinking: boolean,
    onDelta: (delta: StreamDelta) => void
  ): void {
    const lines = text.split('\n');
    for (let i = 0; i < lines.length; i++) {
      let line = lines[i].trim();
      if (line.endsWith('\r')) {
        line = line.substring(0, line.length - 1);
      }
      DeepSeekApi.parseSseLine(line, enableThinking, onDelta);
    }
  }

  private static parseSseLine(
    line: string,
    enableThinking: boolean,
    onDelta: (delta: StreamDelta) => void
  ): Error | null {
    if (line.length === 0 || !line.startsWith('data:')) {
      return null;
    }
    const payload = line.substring(5).trim();
    if (payload === '[DONE]' || payload.length === 0) {
      return null;
    }
    try {
      const jsonChunk: Record<string, Object> = JSON.parse(payload) as Record<string, Object>;
      if (jsonChunk['error']) {
        const errorObj = jsonChunk['error'] as Record<string, Object>;
        const errorMsg = errorObj['message'] as string;
        return new Error(errorMsg ?? 'API 返回错误');
      }
      const choices = jsonChunk['choices'] as Array<Record<string, Object>>;
      if (choices && choices.length > 0) {
        const delta = choices[0]['delta'] as Record<string, Object>;
        if (delta) {
          const streamDelta = new StreamDelta();
          if (delta['content']) {
            streamDelta.contentPiece = delta['content'] as string;
          }
          if (enableThinking) {
            if (delta['reasoning_content']) {
              streamDelta.reasoningPiece = delta['reasoning_content'] as string;
            } else if (delta['reasoning']) {
              streamDelta.reasoningPiece = delta['reasoning'] as string;
            }
          }
          if (streamDelta.contentPiece.length > 0 || streamDelta.reasoningPiece.length > 0) {
            onDelta(streamDelta);
          }
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
