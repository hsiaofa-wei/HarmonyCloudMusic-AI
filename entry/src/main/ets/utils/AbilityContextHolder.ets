import { common } from '@kit.AbilityKit'

export class AbilityContextHolder {
  private static ctx: common.UIAbilityContext | null = null

  static set(ctx: common.UIAbilityContext): void {
    AbilityContextHolder.ctx = ctx
  }

  static get(): common.UIAbilityContext | null {
    return AbilityContextHolder.ctx
  }
}
