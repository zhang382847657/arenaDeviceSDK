# arenaDeviceSDK
**iOS设备相关的SDK**

- 获取设备的UUID
- 获取App当前版本号
- 获取App名字
- 扫描二维码/条形码

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

```
Device.scanQRCode()
```