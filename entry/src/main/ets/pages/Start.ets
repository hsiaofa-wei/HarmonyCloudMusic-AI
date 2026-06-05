@Builder
export function StartBuilder() {
  Start()
}

@Entry({ routeName: 'Start' })
@Component
struct Start {
  pathStack: NavPathStack = new NavPathStack()
  @State num: number = 3
  timer: number | null = null

  aboutToAppear(): void {
    this.timer = setInterval(() => {
      this.num--
      if (this.num === 0) {
        clearInterval(this.timer)
        this.pathStack.replacePathByName('Layout', null, false)
      }
    }, 1000)
  }

  aboutToDisappear(): void {
    if (this.timer !== null) {
      clearInterval(this.timer)
    }
  }

  build() {
    NavDestination() {
      Stack({ alignContent: Alignment.TopEnd }) {
        Image('http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/banner1.png')
          .width('100%')
          .height('100%')
          .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
        Button(`跳过${this.num}`).onClick(() => {
          this.pathStack.replacePathByName('Layout', null, false)
        })
          .margin(15)
      }
    }
    .onReady((context: NavDestinationContext) => {
      this.pathStack = context.pathStack
    })
  }
}
