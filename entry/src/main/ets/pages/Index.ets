import { common } from '@kit.AbilityKit'
import { AppStorageV2 } from '@kit.ArkUI'
import { AiChatFloat } from '../chat/component/AiChatFloat'
import { SpeechService } from '../chat/service/SpeechService'
import { AbilityContextHolder } from '../utils/AbilityContextHolder'

@Entry
@Component
struct Index {
  pathStack: NavPathStack = AppStorageV2.connect(
    NavPathStack,
    'navStack',
    () => new NavPathStack()
  )!
  private speechService: SpeechService = SpeechService.getInstance()

  aboutToAppear(): void {
    AbilityContextHolder.set(getContext(this) as common.UIAbilityContext)
    this.speechService.init().catch(() => {
    })
  }

  build() {
    Stack() {
      Navigation(this.pathStack) {
      }
      .onAppear(() => {
        this.pathStack.pushPathByName('Start', null, false)
      })
      .hideNavBar(true)
      .width('100%')
      .height('100%')

      AiChatFloat()
    }
    .width('100%')
    .height('100%')
  }
}
