@Component
export struct Mine {
  build() {
    Column({ space: 16 }) {
      Image($r('app.media.ic_logo'))
        .width(80)
        .height(80)
        .borderRadius(40)
        .margin({ top: 40 })
      Text('云音乐用户')
        .fontColor(Color.White)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
      Text('我的')
        .fontColor('#63AAAA')
        .fontSize(14)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#131215')
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}
