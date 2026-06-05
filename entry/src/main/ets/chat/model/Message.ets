export enum MessageRole {
  SYSTEM = 'system',
  USER = 'user',
  ASSISTANT = 'assistant'
}

export enum MessageStatus {
  SENDING = 'sending',
  SUCCESS = 'success',
  ERROR = 'error'
}

export interface Message {
  id: string
  role: MessageRole
  content: string
  reasoningContent: string
  timestamp: number
  status: MessageStatus
}

export function createMessage(
  role: MessageRole,
  content: string,
  status: MessageStatus = MessageStatus.SUCCESS
): Message {
  return {
    id: `msg_${Date.now()}_${Math.random().toString(36).substring(2, 9)}`,
    role: role,
    content: content,
    reasoningContent: '',
    timestamp: Date.now(),
    status: status
  }
}
