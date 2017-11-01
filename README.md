# arenaDeviceSDK
**iOS设备相关的SDK**

- 获取设备的UUID
- 获取App当前版本号
- 获取App名字
- 扫描二维码/条形码

### 支持CocoaPods
```
pod 'ArenaDeviceSDK'
```

> 注意：请在项目Build Phases -> Copy Bundle Resources 中添加AreanDeviceSDK.framework，否则会影响图片的正常显示


### 获取UUID
 
```
let uuid:String? = Device.uuid()
```

### App当前版本号

```
let appVersion:String? = Device.appVersion()
```

### 获取App名字

```
let appName:String? = Device.appName()
```

### 扫描二维码/条形码
以模态视图弹出，自带关闭按钮可关闭当前扫描页面

```
Device.scanQRCode()
```
