import { common } from '@kit.AbilityKit'
import { promptAction } from '@kit.ArkUI'
import { SpeechService } from '../chat/service/SpeechService'
import { AbilityContextHolder } from '../utils/AbilityContextHolder'
import { dailyRecommend, getRecommendList } from './type/data'
import recommendDailyType from './type/recommendDailyType'
import recommendListType from './type/recommendListType'

@Component
export struct Recommend {
  swiperList: string[] = [
    'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/banner1.png',
    'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/banner2.png',
    'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/banner3.png',
    'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/banner4.png',
    'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/banner5.png'
  ]
  @State dailyList: recommendDailyType[] = []
  @State recommendList: recommendListType[] = []
  @State searchText: string = ''
  @State isListening: boolean = false
  private speechService: SpeechService = SpeechService.getInstance()
  private longPressTimer: number = -1
  private voicePressActive: boolean = false
  private suppressNextMicClick: boolean = false

  async aboutToAppear(): Promise<void> {
    this.speechService.setCallbacks({
      onRecognized: (text: string, _isFinal: boolean) => {
        this.searchText = text
      },
      onListeningChange: (listening: boolean) => {
        this.isListening = listening
      }
    })
    this.dailyList = dailyRecommend
    try {
      const httpRequest = await getRecommendList()
      this.recommendList = JSON.parse(httpRequest.result as string) as recommendListType[]
    } catch (_err) {
      this.recommendList = []
    }
  }

  getAbilityContext(): common.UIAbilityContext | null {
    return AbilityContextHolder.get()
  }

  clearLongPressTimer(): void {
    if (this.longPressTimer >= 0) {
      clearTimeout(this.longPressTimer)
      this.longPressTimer = -1
    }
  }

  showVoiceError(message: string): void {
    promptAction.showToast({ message: message, duration: 2000 })
  }

  async startVoiceInput(): Promise<boolean> {
    const ctx = this.getAbilityContext()
    if (!ctx) {
      this.showVoiceError('应用上下文未就绪，请重启应用后重试')
      return false
    }
    if (this.isListening) {
      return true
    }
    const started = await this.speechService.startListening(ctx)
    if (!started) {
      const detail = this.speechService.getLastAsrError()
      this.showVoiceError(detail.length > 0 ? detail : '语音识别不可用，请在真机并连接网络后重试')
      return false
    }
    return true
  }

  stopVoiceInput(): void {
    if (this.isListening) {
      this.speechService.stopListening()
    }
  }

  async onMicClick(): Promise<void> {
    if (this.suppressNextMicClick) {
      this.suppressNextMicClick = false
      return
    }
    if (this.isListening) {
      this.stopVoiceInput()
      return
    }
    await this.startVoiceInput()
  }

  async onMicTouch(event: TouchEvent): Promise<void> {
    if (event.type === TouchType.Down) {
      this.clearLongPressTimer()
      this.longPressTimer = setTimeout(async () => {
        this.longPressTimer = -1
        this.voicePressActive = true
        const started = await this.startVoiceInput()
        if (!started) {
          this.voicePressActive = false
        }
      }, 400)
    } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
      this.clearLongPressTimer()
      if (this.voicePressActive || this.isListening) {
        this.suppressNextMicClick = true
        this.voicePressActive = false
        this.stopVoiceInput()
      }
    }
  }

  @Builder
  naviRow(title: string) {
    Flex({ justifyContent: FlexAlign.SpaceBetween }) {
      Text(title).fontColor('#fff6f5f5').fontSize(18).fontWeight(FontWeight.Bold)
      Image($r('app.media.ic_more')).height(20).fillColor('#ffd6d6d6')
    }.margin(10)
  }

  build() {
    Column() {
      Row({ space: 8 }) {
        SymbolGlyph($r('sys.symbol.magnifyingglass'))
          .fontSize(20)
          .fontColor([Color.White])
          .flexShrink(0)
        TextInput({
          text: this.searchText,
          placeholder: this.isListening ? '松开后结束…' : '只因你太美🔥'
        })
          .placeholderColor('#817D83')
          .fontSize(14)
          .fontColor('#999999')
          .layoutWeight(1)
          .backgroundColor(Color.Transparent)
          .onChange((value: string) => {
            this.searchText = value
          })
        Button({ type: ButtonType.Circle, stateEffect: true }) {
          SymbolGlyph($r('sys.symbol.mic'))
            .fontSize(22)
            .fontColor([this.isListening ? '#FF4444' : Color.White])
        }
        .width(44)
        .height(44)
        .flexShrink(0)
        .backgroundColor(this.isListening ? '#33FF4444' : Color.Transparent)
        .onClick(() => {
          this.onMicClick()
        })
        .onTouch((event: TouchEvent) => {
          this.onMicTouch(event)
        })
      }
      .height(48)
      .backgroundColor('#1F2022')
      .borderRadius(24)
      .padding({ left: 16, right: 4 })
      .margin({ left: 16, right: 16, top: 16 })
      .border({
        width: this.isListening ? 2 : 0,
        color: '#FF4444'
      })

      Swiper() {
        ForEach(this.swiperList, (item: string) => {
          Image(item)
            .width('100%')
        })
      }
      .autoPlay(true)
      .margin({ top: 10 })

      this.naviRow('每日推荐')

      List() {
        ForEach(this.dailyList, (item: recommendDailyType) => {
          ListItem() {
            Column() {
              Text(item.type)
                .height('15%')
                .width('100%')
                .backgroundColor(item.top)
                .fontColor(Color.White)
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
                .padding({ left: 5 })
                .borderRadius({ topLeft: 5, topRight: 5 })
              Image(item.img).height('65%').width('100%')
              Text(item.title)
                .height('20%')
                .width('100%')
                .backgroundColor(item.bottom)
                .fontColor(Color.White)
                .fontSize(13)
                .maxLines(2)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .ellipsisMode(EllipsisMode.END)
                .padding({ left: 5 })
                .borderRadius({ bottomLeft: 5, bottomRight: 5 })
            }.width('40%').height('100%')
          }.margin({ left: 10 })
        })
      }
      .scrollBar(BarState.Off)
      .width('100%')
      .height('30%')
      .listDirection(Axis.Horizontal)

      this.naviRow('推荐歌单')

      List() {
        ForEach(this.recommendList, (item: recommendListType) => {
          ListItem() {
            Column() {
              Stack() {
                Image(item.img).width(100).height(100).borderRadius(10)
                Text(item.count)
                  .fontColor(Color.White)
                  .fontSize(12)
                  .fontWeight(FontWeight.Bold)
                  .padding(10)
                  .position({ top: 0 })
              }.width('30%')
              Text(item.title)
                .fontColor('#ffc8c8c8')
                .fontSize(12)
                .padding({ left: 5 })
                .width('30%')
                .maxLines(2)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .ellipsisMode(EllipsisMode.END)
                .margin({ top: 5 })
            }
          }.margin({ left: 10 })
        })
      }
      .listDirection(Axis.Horizontal)
      .width('100%')
      .height('30%')
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#131215')
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}
