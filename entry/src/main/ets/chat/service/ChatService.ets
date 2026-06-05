import {
  createMessage,
  Message,
  MessageRole,
  MessageStatus
} from '../model/Message';
import { ApiConfig, DeepSeekApi, RequestMessageItem, StreamDelta } from './DeepSeekApi';
import { MusicAiPersona } from '../util/MusicAiPersona';

export class ChatSession {
  id: string = '';
  title: string = MusicAiPersona.SESSION_TITLE;
  messages: Message[] = [];
  updatedAt: number = 0;

  constructor(title: string) {
    this.id = `session_${Date.now()}`;
    this.title = title;
    this.updatedAt = Date.now();
  }
}

export function createChatSession(title: string = MusicAiPersona.SESSION_TITLE): ChatSession {
  return new ChatSession(title);
}

export class ChatService {
  private static instance: ChatService;
  private apiService: DeepSeekApi;
  private currentSession: ChatSession | null = null;

  private constructor() {
    this.apiService = DeepSeekApi.getInstance();
  }

  static getInstance(): ChatService {
    if (!ChatService.instance) {
      ChatService.instance = new ChatService();
    }
    return ChatService.instance;
  }

  isThinkingEnabled(): boolean {
    return ApiConfig.ENABLE_THINKING;
  }

  setThinkingEnabled(enabled: boolean): void {
    ApiConfig.ENABLE_THINKING = enabled;
  }

  createNewSession(title: string = MusicAiPersona.SESSION_TITLE): ChatSession {
    const session = createChatSession(title);
    session.messages.push(
      createMessage(
        MessageRole.ASSISTANT,
        MusicAiPersona.WELCOME_MESSAGE
      )
    );
    this.currentSession = session;
    return session;
  }

  getCurrentSession(): ChatSession | null {
    return this.currentSession;
  }

  getCurrentMessages(): Message[] {
    const list = this.currentSession?.messages ?? [];
    const copied: Message[] = [];
    for (let i = 0; i < list.length; i++) {
      const m = list[i];
      copied.push({
        id: m.id,
        role: m.role,
        content: m.content,
        reasoningContent: m.reasoningContent,
        timestamp: m.timestamp,
        status: m.status
      });
    }
    return copied;
  }

  private findMessage(messageId: string): Message | null {
    const msgs = this.currentSession?.messages ?? [];
    for (let i = 0; i < msgs.length; i++) {
      if (msgs[i].id === messageId) {
        return msgs[i];
      }
    }
    return null;
  }

  private replaceMessage(
    messageId: string,
    content: string,
    reasoningContent: string,
    status: MessageStatus
  ): void {
    const msgs = this.currentSession!.messages;
    for (let i = 0; i < msgs.length; i++) {
      if (msgs[i].id === messageId) {
        msgs[i] = {
          id: msgs[i].id,
          role: msgs[i].role,
          content: content,
          reasoningContent: reasoningContent,
          timestamp: msgs[i].timestamp,
          status: status
        };
        return;
      }
    }
  }

  private buildRequestItems(): RequestMessageItem[] {
    const items: RequestMessageItem[] = [];
    items.push(new RequestMessageItem(MessageRole.SYSTEM, MusicAiPersona.SYSTEM_PROMPT));
    const list = this.currentSession!.messages.filter((m: Message) => m.status !== MessageStatus.SENDING);
    for (let i = 0; i < list.length; i++) {
      const m = list[i];
      items.push(new RequestMessageItem(m.role, m.content));
    }
    return items;
  }

  async sendMessage(
    content: string,
    onProgress?: (message: Message) => void
  ): Promise<Message> {
    if (!this.currentSession) {
      this.createNewSession();
    }

    const userMessage = createMessage(MessageRole.USER, content);
    this.currentSession!.messages.push(userMessage);
    this.currentSession!.updatedAt = Date.now();

    const aiMessage = createMessage(MessageRole.ASSISTANT, '', MessageStatus.SENDING);
    this.currentSession!.messages.push(aiMessage);

    if (onProgress) {
      onProgress(aiMessage);
    }

    try {
      const apiMessages = this.buildRequestItems();

      let reply = '';
      let reasoning = '';
      let streamWorked = false;

      try {
        await this.apiService.sendChatStreamRequest(apiMessages, (delta: StreamDelta) => {
          streamWorked = true;
          if (delta.contentPiece.length > 0) {
            reply = reply + delta.contentPiece;
          }
          if (delta.reasoningPiece.length > 0) {
            reasoning = reasoning + delta.reasoningPiece;
          }
          this.replaceMessage(aiMessage.id, reply, reasoning, MessageStatus.SENDING);
          if (onProgress) {
            const latest = this.findMessage(aiMessage.id);
            if (latest !== null) {
              onProgress(latest);
            }
          }
        });
      } catch (streamError) {
        // 流式失败时由下方非流式请求兜底
      }

      if (!streamWorked && reply.length === 0 && reasoning.length === 0) {
        const fullReply = await this.apiService.sendChatRequest(apiMessages);
        reply = fullReply.content;
        reasoning = ApiConfig.ENABLE_THINKING ? fullReply.reasoningContent : '';
        this.replaceMessage(aiMessage.id, reply, reasoning, MessageStatus.SENDING);
        if (onProgress) {
          const latest = this.findMessage(aiMessage.id);
          if (latest !== null) {
            onProgress(latest);
          }
        }
      }

      this.replaceMessage(aiMessage.id, reply, reasoning, MessageStatus.SUCCESS);
      this.currentSession!.updatedAt = Date.now();

      const finalMsg = this.findMessage(aiMessage.id);
      if (onProgress && finalMsg !== null) {
        onProgress(finalMsg);
      }
      return finalMsg ?? aiMessage;
    } catch (error) {
      const errText = error instanceof Error ? error.message : `${error}`;
      this.replaceMessage(aiMessage.id, `抱歉，发生了错误：${errText}`, '', MessageStatus.ERROR);

      if (onProgress) {
        onProgress(aiMessage);
      }
      throw new Error(`发送失败: ${errText}`);
    }
  }
}
