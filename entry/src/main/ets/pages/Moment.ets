@Component
export struct Moment {
  build() {
    Column() {
      Text('动态')
        .fontColor(Color.White)
        .fontSize(18)
        .margin({ top: 20 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#131215')
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}
