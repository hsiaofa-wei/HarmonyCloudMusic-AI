import { AppStorageV2 } from '@kit.ArkUI'
import { SongItemType } from './type/music'
import { GlobalMusic } from './type/GlobalMusic'
import { getSongItemTypeList } from './type/data'
import avplayer from '../utils/avPlayerMusic'

@Builder
export function PlayBuilder() {
  Play()
}

@Entry({ routeName: 'Play' })
@ComponentV2
struct Play {
  @Local panelHeight: string = '0%'
  @Local panelOpacity: number = 0
  pathStack: NavPathStack = new NavPathStack()
  @Local songs: SongItemType[] = []
  @Local playState: GlobalMusic = AppStorageV2.connect(GlobalMusic, 'Songkey', () => new GlobalMusic())!

  async aboutToAppear(): Promise<void> {
    try {
      const res = await getSongItemTypeList()
      this.songs = JSON.parse(res.result as string) as SongItemType[]
    } catch (_err) {
      this.songs = []
    }
  }

  @Builder
  deleteButton(index: number) {
    Button('删除')
      .backgroundColor('#ec5c87')
      .fontColor(Color.White)
      .width(80)
      .height('100%')
      .type(ButtonType.Normal)
      .onClick(() => {
        // 预留删除逻辑
      })
  }

  number2time(number: number): string {
    if (number > 60 * 1000) {
      const s = Math.floor(number / 1000 % 60)
      const m = Math.floor(number / 1000 / 60)
      const second = s.toString().padStart(2, '0')
      const minute = m.toString().padStart(2, '0')
      return minute + ':' + second
    } else {
      const s = Math.floor(number / 1000 % 60)
      const second = s.toString().padStart(2, '0')
      return '00:' + second
    }
  }

  build() {
    NavDestination() {
      Stack({ alignContent: Alignment.Bottom }) {
        Stack() {
          Image(this.playState.img)
            .width('100%')
            .height('100%')
            .blur(1000)
            .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])

          Column() {
            Column() {
              Stack({ alignContent: Alignment.Top }) {
                Row() {
                  Row() {
                    Image(this.playState.img)
                      .width('70%')
                      .borderRadius(400)
                  }
                  .backgroundImage($r('app.media.ic_music'))
                  .backgroundImageSize(ImageSize.Cover)
                  .justifyContent(FlexAlign.Center)
                  .width('100%')
                  .borderRadius(400)
                  .clip(true)
                  .aspectRatio(1)
                }
                .margin({ top: 50 })
                .width('90%')
                .aspectRatio(1)
                .justifyContent(FlexAlign.Center)
                .padding(24)

                Image($r('app.media.ic_music'))
                  .width(200)
                  .aspectRatio(1)
                  .rotate({ angle: -55, centerX: 100, centerY: 30 })
                  .animation({ duration: 500 })
              }

              Stack() {
                Column({ space: 8 }) {
                  Text(this.playState.name)
                    .fontSize(28)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#4bb0c4')
                  Text(this.playState.author)
                    .fontSize(18)
                    .fontColor('#4bb0c4')
                }
                .layoutWeight(1)
                .justifyContent(FlexAlign.Center)
                .zIndex(1)

                Column({ space: 8 }) {
                  Text(this.playState.name)
                    .fontSize(28)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#ec5c87')
                  Text(this.playState.author)
                    .fontSize(18)
                    .fontColor('#ec5c87')
                }
                .layoutWeight(1)
                .justifyContent(FlexAlign.Center)
                .zIndex(2)

                Column({ space: 8 }) {
                  Text(this.playState.name)
                    .fontSize(28)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(Color.White)
                  Text(this.playState.author)
                    .fontSize(18)
                    .fontColor(Color.White)
                }
                .layoutWeight(1)
                .justifyContent(FlexAlign.Center)
                .zIndex(3)
              }
              .layoutWeight(1)

              Row() {
                Badge({ value: '99+', style: { badgeSize: 12, badgeColor: '#45CCCCCC' } }) {
                  Image($r('app.media.ic_like'))
                    .fillColor(Color.White)
                    .width(24)
                }
                Badge({ value: '10W', style: { badgeSize: 12, badgeColor: '#45cccccc' } }) {
                  Image($r('app.media.ic_comment_o'))
                    .fillColor(Color.White)
                    .width(18)
                }
                Badge({ value: 'hot', style: { badgeSize: 12, badgeColor: '#a8ff3131' } }) {
                  Image($r('app.media.ic_bells_o'))
                    .fillColor(Color.White)
                    .width(24)
                }
                Badge({ value: 'vip', style: { badgeSize: 12, badgeColor: '#b7efd371' } }) {
                  Image($r('app.media.ic_download_o'))
                    .fillColor(Color.White)
                    .width(24)
                }
              }
              .width('100%')
              .justifyContent(FlexAlign.SpaceAround)

              Column() {
                Row({ space: 4 }) {
                  Text(this.number2time(this.playState.time))
                    .fontSize(12)
                    .fontColor(Color.White)
                  Slider({
                    value: this.playState.time,
                    min: 0,
                    max: this.playState.duration > 0 ? this.playState.duration : 1
                  })
                    .layoutWeight(1)
                    .blockColor(Color.White)
                    .selectedColor(Color.White)
                    .trackColor('#ccc5c5c5')
                    .trackThickness(2)
                    .onChange((value: number, mode: SliderChangeMode) => {
                      if (mode === SliderChangeMode.End) {
                        avplayer.jumpToPlay(value)
                      }
                    })
                  Text(this.number2time(this.playState.duration))
                    .fontSize(12)
                    .fontColor(Color.White)
                }
                .width('100%')
                .padding(24)

                Row() {
                  Image($r('app.media.ic_auto'))
                    .fillColor(Color.White)
                    .width(30)
                  Image($r('app.media.ic_prev'))
                    .fillColor(Color.White)
                    .width(30)
                  Image(this.playState.isPlay ? $r('app.media.ic_paused') : $r('app.media.ic_play'))
                    .fillColor(Color.White)
                    .width(50)
                    .onClick(() => {
                      if (this.playState.isPlay) {
                        avplayer.pause()
                      } else {
                        avplayer.resume()
                      }
                    })
                  Image($r('app.media.ic_next'))
                    .fillColor(Color.White)
                    .width(30)
                  Image($r('app.media.ic_song_list'))
                    .fillColor(Color.White)
                    .width(30)
                    .onClick(() => {
                      this.panelHeight = '50%'
                      this.panelOpacity = 1
                    })
                }
                .width('100%')
                .padding({ bottom: 24 })
                .justifyContent(FlexAlign.SpaceAround)
              }
              .width('100%')
            }
            .layoutWeight(1)
            .width('100%')
          }
        }
        .width('100%')
        .height('100%')
        .backgroundColor(Color.Transparent)

        Column() {
          Column() {
          }
          .width('100%')
          .layoutWeight(1)
          .onClick(() => {
            this.panelHeight = '0%'
            this.panelOpacity = 0
          })

          Column() {
            Row() {
              Row() {
                Image($r('app.media.ic_play'))
                  .width(20)
                  .fillColor('#ff5186')
              }
              .width(50)
              .aspectRatio(1)
              .justifyContent(FlexAlign.Center)

              Row({ space: 8 }) {
                Text(`播放列表 (${this.songs.length})`)
                  .fontColor(Color.White)
                  .fontSize(14)
              }
              .layoutWeight(1)

              Image($r('app.media.ic_close'))
                .fillColor('#ffa49a9a')
                .width(24)
                .height(24)
                .margin({ right: 16 })
                .onClick(() => {
                  this.panelHeight = '0%'
                  this.panelOpacity = 0
                })
            }
            .width('100%')
            .backgroundColor('#ff353333')
            .padding(8)
            .border({
              width: { bottom: 1 },
              color: '#12ec5c87'
            })
            .borderRadius({
              topLeft: 4,
              topRight: 4
            })

            List() {
              ForEach(this.songs, (item: SongItemType, index: number) => {
                ListItem() {
                  Row() {
                    Row() {
                      Text((index + 1).toString())
                        .fontColor('#ffa49a9a')
                    }
                    .width(50)
                    .aspectRatio(1)
                    .justifyContent(FlexAlign.Center)

                    Row({ space: 10 }) {
                      Column() {
                        Text(item.name)
                          .fontSize(14)
                          .fontColor('#ffa49a9a')
                        Text(item.author)
                          .fontSize(12)
                          .fontColor(Color.Gray)
                      }
                      .layoutWeight(1)
                      .alignItems(HorizontalAlign.Start)
                      .justifyContent(FlexAlign.Center)
                    }
                    .layoutWeight(1)

                    Image($r('app.media.ic_more'))
                      .width(24)
                      .height(24)
                      .margin({ right: 16 })
                      .fillColor(Color.Gray)
                  }
                  .alignItems(VerticalAlign.Center)
                }
                .swipeAction({
                  end: {
                    builder: (): void => {
                      this.deleteButton(index)
                    }
                  }
                })
                .border({
                  width: { bottom: 1 },
                  color: '#12ec5c87'
                })
                .onClick(() => {
                  this.playState.img = item.img
                  this.playState.name = item.name
                  this.playState.author = item.author
                  this.playState.url = item.url
                  avplayer.play(item.url)
                })
              })
            }
            .layoutWeight(1)
            .backgroundColor('#ff353333')
          }
          .height(400)
        }
        .height(this.panelHeight)
        .animation({ duration: 300 })
        .backgroundColor('#ff353333')
        .opacity(this.panelOpacity)
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
      }
      .width('100%')
      .height('100%')
      .backgroundColor(Color.Transparent)
    }
    .onReady((context: NavDestinationContext) => {
      this.pathStack = context.pathStack
    })
    .hideTitleBar(true)
  }
}
