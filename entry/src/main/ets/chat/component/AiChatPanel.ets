import { Message, MessageRole, MessageStatus } from '../model/Message'
import { ChatService } from '../service/ChatService'
import { SpeechService } from '../service/SpeechService'
import { MusicAppTheme } from '../util/MusicAppTheme'
import { MusicAiPersona } from '../util/MusicAiPersona'

@Component
export struct AiChatPanel {
  @State messages: Message[] = []
  @State inputText: string = ''
  @State isSending: boolean = false
  @State isSpeaking: boolean = false
  @State speakingMessageId: string = ''
  @State enableThinking: boolean = false
  @State expandedReasoningIds: string[] = []
  @State reasoningUiVersion: number = 0
  private chatService: ChatService = ChatService.getInstance()
  private speechService: SpeechService = SpeechService.getInstance()
  private scroller: Scroller = new Scroller()

  aboutToAppear(): void {
    if (!this.chatService.getCurrentSession()) {
      this.chatService.createNewSession()
    }
    this.enableThinking = this.chatService.isThinkingEnabled()
    this.loadMessages()
  }

  stopTts(): void {
    if (!this.isSpeaking) {
      return
    }
    this.isSpeaking = false
    this.speakingMessageId = ''
    this.reasoningUiVersion = this.reasoningUiVersion + 1
    this.speechService.stopSpeak()
  }

  startSpeakMessage(message: Message): void {
    if (message.content.trim().length === 0) {
      return
    }
    if (this.isSpeaking && this.speakingMessageId === message.id) {
      return
    }
    const speechText = SpeechService.sanitizeForSpeech(message.content)
    if (speechText.length === 0) {
      return
    }
    if (this.isSpeaking) {
      this.speechService.stopSpeak()
    }
    this.isSpeaking = true
    this.speakingMessageId = message.id
    this.reasoningUiVersion = this.reasoningUiVersion + 1
    this.speechService.speak(speechText, message.id)
  }

  stopSpeakMessage(message: Message): void {
    if (this.isSpeaking && this.speakingMessageId === message.id) {
      this.isSpeaking = false
      this.speakingMessageId = ''
      this.reasoningUiVersion = this.reasoningUiVersion + 1
      this.speechService.stopSpeak()
    }
  }

  loadMessages(): void {
    this.messages = [...this.chatService.getCurrentMessages()]
    setTimeout(() => {
      this.scroller.scrollEdge(Edge.Bottom)
    }, 100)
  }

  isReasoningExpanded(messageId: string, isStreaming: boolean): boolean {
    if (isStreaming) {
      return true
    }
    return this.expandedReasoningIds.indexOf(messageId) >= 0
  }

  toggleReasoningExpand(messageId: string): void {
    const idx = this.expandedReasoningIds.indexOf(messageId)
    const next: string[] = []
    if (idx >= 0) {
      for (let i = 0; i < this.expandedReasoningIds.length; i++) {
        if (i !== idx) {
          next.push(this.expandedReasoningIds[i])
        }
      }
    } else {
      for (let i = 0; i < this.expandedReasoningIds.length; i++) {
        next.push(this.expandedReasoningIds[i])
      }
      next.push(messageId)
    }
    this.expandedReasoningIds = next
    this.reasoningUiVersion = this.reasoningUiVersion + 1
  }

  @Builder
  ReasoningBlock(messageId: string, text: string, isStreaming: boolean, isExpanded: boolean) {
    Column() {
      Row() {
        Text('思考过程')
          .fontSize(12)
          .fontColor(MusicAppTheme.TEXT_HINT)
          .fontWeight(FontWeight.Medium)
        Blank().layoutWeight(1)
        Button({ type: ButtonType.Normal }) {
          Text(isExpanded ? '收起 ▲' : '展开 ▼')
            .fontSize(12)
            .fontColor(MusicAppTheme.ACCENT_SOFT)
        }
        .backgroundColor(Color.Transparent)
        .height(28)
        .enabled(!isStreaming)
        .onClick(() => {
          this.toggleReasoningExpand(messageId)
        })
      }
      .width('100%')
      .margin({ bottom: isExpanded ? 6 : 0 })

      if (isExpanded) {
        Scroll() {
          Text(isStreaming ? `${text}▋` : text)
            .fontSize(13)
            .fontColor(MusicAppTheme.TEXT_SECONDARY)
            .lineHeight(20)
        }
        .width('100%')
        .constraintSize({ maxHeight: 120 })
        .scrollBar(BarState.Auto)
      }
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(8)
    .margin({ bottom: 8 })
    .backgroundColor(MusicAppTheme.REASONING_BG)
    .borderRadius(8)
  }

  @Builder
  MessageBubble(message: Message, isReasoningExpanded: boolean, isThisSpeaking: boolean) {
    Row() {
      if (message.role === MessageRole.USER) {
        Blank().layoutWeight(1)
        Text(message.content)
          .fontSize(15)
          .fontColor(Color.White)
          .lineHeight(22)
          .padding(12)
          .constraintSize({ maxWidth: '78%' })
          .backgroundColor(MusicAppTheme.USER_BUBBLE)
          .borderRadius(16)
      } else {
        Column() {
          if (message.status === MessageStatus.SENDING && message.reasoningContent.length === 0 &&
            message.content.length === 0) {
            Row() {
              LoadingProgress().width(20).height(20).color(MusicAppTheme.ACCENT)
              Text('思考中…')
                .fontSize(14)
                .fontColor(MusicAppTheme.TEXT_SECONDARY)
                .margin({ left: 8 })
            }
            .padding(4)
          } else {
            if (message.reasoningContent.length > 0) {
              this.ReasoningBlock(
                message.id,
                message.reasoningContent,
                message.status === MessageStatus.SENDING,
                isReasoningExpanded
              )
            } else if (message.status === MessageStatus.SENDING && message.content.length === 0) {
              Row() {
                LoadingProgress()
                  .width(18)
                  .height(18)
                  .color('#9E9E9E')
                Text('正在思考…')
                  .fontSize(13)
                  .fontColor(MusicAppTheme.TEXT_HINT)
                  .margin({ left: 8 })
              }
              .padding({ top: 4, bottom: 4 })
            }
            if (message.content.length > 0) {
              Text(message.status === MessageStatus.SENDING ? `${message.content}▋` : message.content)
                .fontSize(15)
                .fontColor(message.status === MessageStatus.ERROR ? MusicAppTheme.ERROR :
                  MusicAppTheme.TEXT_PRIMARY)
                .lineHeight(22)
                .margin({ top: message.reasoningContent.length > 0 ? 4 : 0 })

              if (message.status !== MessageStatus.SENDING && message.status !== MessageStatus.ERROR) {
                Row() {
                  Button({ type: ButtonType.Capsule }) {
                    Text('朗读')
                      .fontSize(12)
                      .fontColor(Color.White)
                  }
                  .height(28)
                  .padding({ left: 12, right: 12 })
                  .backgroundColor(MusicAppTheme.ACCENT)
                  .enabled(!isThisSpeaking)
                  .onClick(() => {
                    this.startSpeakMessage(message)
                  })

                  Button({ type: ButtonType.Capsule }) {
                    Text('停止')
                      .fontSize(12)
                      .fontColor(Color.White)
                  }
                  .height(28)
                  .padding({ left: 12, right: 12 })
                  .margin({ left: 8 })
                  .backgroundColor(MusicAppTheme.STOP)
                  .enabled(isThisSpeaking)
                  .onClick(() => {
                    this.stopSpeakMessage(message)
                  })
                }
                .margin({ top: 8 })
              }
            }
          }
        }
        .alignItems(HorizontalAlign.Start)
        .width('78%')
        .padding(12)
        .backgroundColor(MusicAppTheme.ASSISTANT_BUBBLE)
        .borderRadius(16)
        .border({
          width: 1,
          color: MusicAppTheme.BORDER
        })
        Blank().layoutWeight(1)
      }
    }
    .width('100%')
    .margin({ top: 6, bottom: 6 })
    .alignItems(VerticalAlign.Top)
  }

  async sendMessage(): Promise<void> {
    if (this.inputText.trim() === '' || this.isSending) {
      return
    }

    const content = this.inputText.trim()
    this.inputText = ''
    this.isSending = true
    this.chatService.setThinkingEnabled(this.enableThinking)
    this.messages = [...this.chatService.getCurrentMessages()]
    try {
      await this.chatService.sendMessage(content, () => {
        this.messages = [...this.chatService.getCurrentMessages()]
        setTimeout(() => {
          this.scroller.scrollEdge(Edge.Bottom)
        }, 50)
      })
    } catch (_err) {
      this.messages = [...this.chatService.getCurrentMessages()]
    } finally {
      this.isSending = false
      this.messages = [...this.chatService.getCurrentMessages()]
      setTimeout(() => {
        this.scroller.scrollEdge(Edge.Bottom)
      }, 100)
    }
  }

  build() {
    Column() {
      Row() {
        Text('深度思考')
          .fontSize(13)
          .fontColor(MusicAppTheme.TEXT_SECONDARY)
        Text('（乐评向分析）')
          .fontSize(11)
          .fontColor(MusicAppTheme.TEXT_HINT)
          .margin({ left: 4 })
        Blank().layoutWeight(1)
        Toggle({ type: ToggleType.Switch, isOn: this.enableThinking })
          .selectedColor(MusicAppTheme.ACCENT)
          .switchPointColor(Color.White)
          .onChange((isOn: boolean) => {
            this.enableThinking = isOn
            this.chatService.setThinkingEnabled(isOn)
          })
      }
      .width('100%')
      .height(40)
      .padding({ left: 12, right: 12 })
      .backgroundColor(MusicAppTheme.BG_PRIMARY)

      List({ scroller: this.scroller }) {
        ForEach(this.messages, (message: Message) => {
          ListItem() {
            this.MessageBubble(
              message,
              this.isReasoningExpanded(message.id, message.status === MessageStatus.SENDING),
              this.isSpeaking && this.speakingMessageId === message.id
            )
          }
        }, (message: Message) =>
          `${message.id}_${message.status}_${message.content.length}_${message.reasoningContent.length}_` +
          `${this.reasoningUiVersion}_` +
          `${this.isReasoningExpanded(message.id, message.status === MessageStatus.SENDING)}_` +
          `${this.isSpeaking}_${this.speakingMessageId}`)
      }
      .layoutWeight(1)
      .width('100%')
      .padding({ left: 8, right: 8, top: 8, bottom: 8 })

      Row() {
        TextInput({
          text: this.inputText,
          placeholder: MusicAiPersona.INPUT_PLACEHOLDER
        })
          .layoutWeight(1)
          .height(44)
          .borderRadius(22)
          .backgroundColor(MusicAppTheme.INPUT_BG)
          .fontColor(MusicAppTheme.TEXT_PRIMARY)
          .placeholderColor(MusicAppTheme.TEXT_HINT)
          .padding({ left: 16, right: 16 })
          .enabled(!this.isSending)
          .onChange((value: string) => {
            this.inputText = value
          })
          .onSubmit(() => {
            this.sendMessage()
          })

        Button(this.isSending ? '…' : '发送')
          .type(ButtonType.Capsule)
          .height(44)
          .margin({ left: 8 })
          .fontColor(Color.White)
          .backgroundColor(MusicAppTheme.ACCENT)
          .opacity(!this.isSending && this.inputText.trim().length > 0 ? 1 : 0.45)
          .enabled(!this.isSending && this.inputText.trim().length > 0)
          .onClick(() => {
            this.sendMessage()
          })
      }
      .width('100%')
      .padding(12)
      .backgroundColor(MusicAppTheme.INPUT_BAR)
      .border({
        width: { top: 1 },
        color: MusicAppTheme.BORDER
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(MusicAppTheme.BG_PRIMARY)
  }
}
