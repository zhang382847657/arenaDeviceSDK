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


> **注意：** 
> 
> 1. 如果使用到了扫一扫功能，请在项目的Info.plist增加 `Privacy - Camera Usage Description` 访问您的相机
> 2. 如果使用到了拍照功能，请在项目的Info.plist增加 `Privacy - Photo Library Additions Usage Description` 需要为您添加图片、`Privacy - Photo Library Usage Description` 想要访问您的相册、`Privacy - Camera Usage Description` 访问您的相机

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

### 拍照
弹出菜单框，可选择拍照或从相册中选取

该方法返回图片在本地磁盘中的路径`filePath`,`base64`根据参数设置情况选择性返回

```
//Parameter
// - returnOrigianl 是否返回原图
// - maxSize        返回图片的最大大小(单位kb)  默认500kb
// - returnType		返回数据类型  1：base64

Device.takePhoto(["returnOrigianl":false,
					["maxSize":500],
					["returnType":1]])
```


