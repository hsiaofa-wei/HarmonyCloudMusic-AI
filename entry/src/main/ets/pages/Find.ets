import { AppStorageV2 } from '@kit.ArkUI'
import { SongItemType } from './type/music'
import { getSongItemTypeList } from './type/data'
import { GlobalMusic } from './type/GlobalMusic'
import avplayer from '../utils/avPlayerMusic'

@ComponentV2
export struct Find {
  @Local songs: SongItemType[] = []
  pathStack: NavPathStack = AppStorageV2.connect(NavPathStack, 'navStack', () => new NavPathStack())!
  currentSong: GlobalMusic = AppStorageV2.connect(GlobalMusic, 'Songkey', () => new GlobalMusic())!

  async aboutToAppear(): Promise<void> {
    try {
      const res = await getSongItemTypeList()
      this.songs = JSON.parse(res.result as string) as SongItemType[]
    } catch (_err) {
      this.songs = []
    }
  }

  build() {
    Column() {
      Text('猜你喜欢')
        .fontColor(Color.White)
        .width('100%')
        .margin({ bottom: 10 })
      List() {
        ForEach(this.songs, (item: SongItemType, index: number) => {
          ListItem() {
            Row() {
              Stack() {
                Image(item.img)
                  .width(80)
                  .border({ radius: 8 })
                  .margin({ right: 10 })
                if (this.currentSong.isPlay && item.url === this.currentSong.url) {
                  Image($r('app.media.ic_music'))
                    .width(24)
                }
              }
              Column() {
                Text(item.name)
                  .fontColor('#F3F3F3')
                  .width('100%')
                  .fontWeight(700)
                  .margin({ bottom: 15 })
                Row() {
                  Text('VIP')
                    .fontColor('#9A8E28')
                    .border({ width: 1, color: '#9A8E28', radius: 12 })
                    .padding({
                      left: 5,
                      right: 5,
                      top: 3,
                      bottom: 3
                    })
                    .margin({ right: 10 })
                  Text(item.author)
                    .fontColor('#696969')
                }
                .width('100%')
              }
              .layoutWeight(1)
              Image($r('app.media.ic_more'))
                .width(24)
                .fillColor('#FEFEFE')
            }
            .width('100%')
            .height(80)
            .margin({ bottom: 10 })
          }
          .onClick(() => {
            this.pathStack.pushPathByName('Play', null, false)
            this.currentSong.img = item.img
            this.currentSong.name = item.name
            this.currentSong.author = item.author
            this.currentSong.url = item.url
            avplayer.play(item.url)
          })
        })
      }
      .scrollBar(BarState.Off)
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#131313')
    .padding({ left: 10, right: 10 })
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}
