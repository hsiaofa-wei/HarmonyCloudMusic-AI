import { Recommend } from './Recommend'
import { Find } from './Find'
import { Moment } from './Moment'
import { Mine } from './Mine'

interface TabClass {
  text: string
  icon: ResourceStr
}

@Builder
export function LayoutBuilder() {
  Layout()
}

@Entry({ routeName: 'Layout' })
@Component
struct Layout {
  pathStack: NavPathStack = new NavPathStack()
  @State currentIndex: number = 0
  tabData: TabClass[] = [
    { text: '推荐', icon: $r('app.media.ic_recommend') },
    { text: '发现', icon: $r('app.media.ic_find') },
    { text: '动态', icon: $r('app.media.ic_moment') },
    { text: '我的', icon: $r('app.media.ic_mine') }
  ]

  @Builder
  tabBuilder(item: TabClass, index: number) {
    Column({ space: 5 }) {
      Image(item.icon)
        .width(25)
        .fillColor(this.currentIndex === index ? '#E85A88' : '#63AAAA')
      Text(item.text)
        .fontSize(14)
        .fontColor(this.currentIndex === index ? '#E85A88' : '#63AAAA')
    }
  }

  build() {
    NavDestination() {
      Tabs({ barPosition: BarPosition.End }) {
        ForEach(this.tabData, (item: TabClass, index: number) => {
          TabContent() {
            if (index === 0) {
              Recommend()
            } else if (index === 1) {
              Find()
            } else if (index === 2) {
              Moment()
            } else {
              Mine()
            }
          }
          .tabBar(this.tabBuilder(item, index))
          .backgroundColor('#131215')
          .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
        })
      }
      .barBackgroundColor('#3B3F42')
      .backgroundColor('#131215')
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
      .onChange((index: number) => {
        this.currentIndex = index
      })
    }
    .onReady((context: NavDestinationContext) => {
      this.pathStack = context.pathStack
    })
  }
}
