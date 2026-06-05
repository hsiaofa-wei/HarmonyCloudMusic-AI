import { media } from '@kit.MediaKit'
import { AppStorageV2 } from '@kit.ArkUI'
import { GlobalMusic } from '../pages/type/GlobalMusic'

class SimplePlayer {
  private player: media.AVPlayer | null = null
  playState: GlobalMusic = AppStorageV2.connect(
    GlobalMusic,
    'Songkey',
    () => new GlobalMusic()
  )!

  async play(url: string): Promise<void> {
    await this.stop()
    this.player = await media.createAVPlayer()
    this.player.on('stateChange', async (state: string) => {
      if (state === 'initialized') {
        await this.player?.prepare()
      }
      if (state === 'prepared') {
        await this.player?.play()
      }
    })
    this.player.on('durationUpdate', (duration: number) => {
      this.playState.duration = duration
    })
    this.player.on('timeUpdate', (time: number) => {
      this.playState.time = time
    })
    this.player.url = url
    this.playState.isPlay = true
  }

  async pause(): Promise<void> {
    await this.player?.pause()
    this.playState.isPlay = false
  }

  async resume(): Promise<void> {
    await this.player?.play()
    this.playState.isPlay = true
  }

  async stop(): Promise<void> {
    if (this.player) {
      await this.player.stop()
      await this.player.release()
      this.player = null
    }
  }

  jumpToPlay(jumpToTime: number): void {
    this.player?.seek(jumpToTime)
  }
}

export default new SimplePlayer()
