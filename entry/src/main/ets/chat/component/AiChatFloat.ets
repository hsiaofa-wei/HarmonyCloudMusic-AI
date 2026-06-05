import { AiChatPanel } from './AiChatPanel'
import { MusicAppTheme } from '../util/MusicAppTheme'
import { MusicAiPersona } from '../util/MusicAiPersona'

@Component
export struct AiChatFloat {
  @State panelVisible: boolean = false
  @State fabX: number = -1
  @State fabY: number = -1
  private containerWidth: number = 0
  private containerHeight: number = 0
  private touchStartX: number = 0
  private touchStartY: number = 0
  private fabStartX: number = 0
  private fabStartY: number = 0
  private hasMoved: boolean = false
  private readonly fabSize: number = 52
  private readonly edgePadding: number = 12
  private readonly defaultMarginRight: number = 16
  private readonly defaultMarginBottom: number = 28

  initFabPosition(): void {
    if (this.containerWidth <= 0 || this.containerHeight <= 0) {
      return
    }
    if (this.fabX < 0 || this.fabY < 0) {
      this.fabX = this.containerWidth - this.fabSize - this.defaultMarginRight
      this.fabY = this.containerHeight - this.fabSize - this.defaultMarginBottom
    }
  }

  clampFabPosition(x: number, y: number): void {
    const maxX = this.containerWidth - this.fabSize - this.edgePadding
    const maxY = this.containerHeight - this.fabSize - this.edgePadding
    this.fabX = Math.max(this.edgePadding, Math.min(x, maxX))
    this.fabY = Math.max(this.edgePadding, Math.min(y, maxY))
  }

  snapFabToEdge(): void {
    if (this.containerWidth <= 0) {
      return
    }
    const centerX = this.fabX + this.fabSize / 2
    const snapX = centerX < this.containerWidth / 2
      ? this.edgePadding
      : this.containerWidth - this.fabSize - this.edgePadding
    this.clampFabPosition(snapX, this.fabY)
  }

  onFabTouch(event: TouchEvent): void {
    if (this.panelVisible) {
      return
    }
    const touch = event.touches[0]
    if (event.type === TouchType.Down) {
      this.touchStartX = touch.screenX
      this.touchStartY = touch.screenY
      this.fabStartX = this.fabX
      this.fabStartY = this.fabY
      this.hasMoved = false
    } else if (event.type === TouchType.Move) {
      const dx = touch.screenX - this.touchStartX
      const dy = touch.screenY - this.touchStartY
      if (Math.abs(dx) > 4 || Math.abs(dy) > 4) {
        this.hasMoved = true
      }
      this.clampFabPosition(this.fabStartX + dx, this.fabStartY + dy)
    } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
      if (this.hasMoved) {
        this.snapFabToEdge()
      } else {
        this.panelVisible = true
      }
    }
  }

  build() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      if (this.panelVisible) {
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor(MusicAppTheme.OVERLAY)
          .onClick(() => {
            this.panelVisible = false
          })
          .hitTestBehavior(HitTestMode.Default)

        Column() {
          Row() {
            Row({ space: 8 }) {
              Image($r('app.media.ic_music'))
                .width(22)
                .height(22)
                .fillColor(MusicAppTheme.ACCENT)
              Column({ space: 2 }) {
                Text(MusicAiPersona.ASSISTANT_NAME)
                  .fontSize(16)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(MusicAppTheme.TEXT_PRIMARY)
                Text('发现好歌 · 解读音乐')
                  .fontSize(11)
                  .fontColor(MusicAppTheme.TEXT_HINT)
              }
            }
            Blank().layoutWeight(1)
            Button({ type: ButtonType.Normal }) {
              Text('收起')
                .fontSize(14)
                .fontColor(MusicAppTheme.ACCENT_SOFT)
            }
            .backgroundColor(Color.Transparent)
            .height(36)
            .onClick(() => {
              this.panelVisible = false
            })
          }
          .width('100%')
          .height(48)
          .padding({ left: 14, right: 12 })
          .backgroundColor(MusicAppTheme.BG_SECONDARY)
          .border({
            width: { bottom: 1 },
            color: MusicAppTheme.BORDER
          })

          AiChatPanel()
            .layoutWeight(1)
        }
        .width('90%')
        .height('72%')
        .backgroundColor(MusicAppTheme.BG_PRIMARY)
        .borderRadius(16)
        .border({
          width: 1,
          color: MusicAppTheme.BORDER
        })
        .clip(true)
        .shadow({
          radius: 20,
          color: '#66000000',
          offsetX: 0,
          offsetY: 6
        })
        .margin({ bottom: 72, right: 12 })
        .hitTestBehavior(HitTestMode.Default)
      }

      if (!this.panelVisible && this.fabX >= 0 && this.fabY >= 0) {
        Button({ type: ButtonType.Circle, stateEffect: true }) {
          Image($r('app.media.ic_music'))
            .width(26)
            .height(26)
            .fillColor(Color.White)
        }
        .width(this.fabSize)
        .height(this.fabSize)
        .backgroundColor(MusicAppTheme.ACCENT)
        .position({ x: this.fabX, y: this.fabY })
        .shadow({
          radius: 10,
          color: '#66E85A88',
          offsetX: 0,
          offsetY: 3
        })
        .onTouch((event: TouchEvent) => {
          this.onFabTouch(event)
        })
        .hitTestBehavior(HitTestMode.Default)
      }
    }
    .width('100%')
    .height('100%')
    .hitTestBehavior(this.panelVisible ? HitTestMode.Default : HitTestMode.None)
    .onAreaChange((_old, newArea) => {
      this.containerWidth = newArea.width as number
      this.containerHeight = newArea.height as number
      this.initFabPosition()
    })
  }
}
