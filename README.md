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


> **注意：** 如果使用到了扫一扫功能，请在项目的Info.plist增加 `Privacy - Camera Usage Description` 访问相机的权限

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
