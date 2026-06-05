import http from '@ohos.net.http'
import recommendDailyType from './recommendDailyType'

export let dailyRecommend: recommendDailyType[] = [
  {
    img: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/recommend1.png',
    title: '每日推荐 | 今天从《不得不爱》听起 | 私人雷达',
    type: '每日推荐',
    top: '#660000',
    bottom: '#382e2f'
  },
  {
    img: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/recommend2.png',
    title: '从 [Nothing on Me] 开启无限漫游',
    type: '私人漫游',
    top: '#382e2f',
    bottom: '#a37862'
  },
  {
    img: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/recommend3.png',
    title: '每日推荐 | 今天从《不得不爱》听起 | 私人雷达',
    type: '华语流行',
    top: '#a37862',
    bottom: '#174847'
  },
  {
    img: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/recommend4.png',
    title: '每日推荐 | 今天从《不得不爱》听起 | 私人雷达',
    type: '私人雷达',
    top: '#174847',
    bottom: '#174847'
  }
]

export let getSongItemTypeList = async (): Promise<http.HttpResponse> => {
  const xhr = http.createHttp()
  return xhr.request('http://82.157.173.3:3030/api/music/songs', {
    method: http.RequestMethod.GET
  })
}

export let getRecommendList = async (): Promise<http.HttpResponse> => {
  const xhr = http.createHttp()
  return xhr.request('http://82.157.173.3:3030/api/music/playlists', {
    method: http.RequestMethod.GET
  })
}
