## Eth.build 简介

Eth.build 是一个聚焦于 Web3.0 的教育型沙盒，具备如下特性——

- 无代码拖拽式编程
- 完全开源
- 可视化地直观地理解以太坊的工作方式

> **主页地址：**
>
> https://eth.build/
>
> **Youtube 学习频道：**
>
> https://www.youtube.com/playlist?list=PLJz1HruEnenCXH7KW7wBCEBnBLOVkiqIi
>
> **Repo 地址：**
>
> https://github.com/austintgriffith/eth.build

## Eth.build 极速上手

### 加载现成的教学案例

点击「learn more」，会弹出很多现成的教学案例，可点击按钮进行加载或查看教学视频！

![image-20210917102528583](https://tva1.sinaimg.cn/large/008i3skNgy1gulyz5cppuj60c3039wed02.jpg)

![image-20210917102633107](https://tva1.sinaimg.cn/large/008i3skNgy1gulyz7rehbj61hc0g3gpb02.jpg)

![image-20210917102938705](https://tva1.sinaimg.cn/large/008i3skNgy1gulyza3jq4j61hb0qvn0e02.jpg)

### 基础操作实践：以以太坊余额抓取为例

![image-20210917104531017](https://tva1.sinaimg.cn/large/008i3skNgy1gulyz79y71j60os09ywet02.jpg)

这是一个简单的例子，实现了从以太坊抓取余额的功能。

我们可以通过这个例子来学习`eth.build`的使用。

#### STEP 0x01. 创建 Text Block

通过`INPUT`>`TEXT`创建一个文本输入框。`INPUT`是输入组件的集合。

![image-20210917104858238](https://tva1.sinaimg.cn/large/008i3skNgy1gulyz6qx2oj604e07gglh02.jpg)

#### STEP 0x02. 创建 Balance Block

通过`WEB3`>`BALANCE`创造一个余额查询块，`WEB3`是一系列以太坊`WEB3`功能的实现，和`ether.js`中的实现等价。

![image-20210917113330225](https://tva1.sinaimg.cn/large/008i3skNgy1gulyz324ksj605502xglf02.jpg)

观察这个 Block，会发现抽象来看它由三部分组成：输入`INPUTS`、处理（隐藏）和输出`OUTPUTS`，因此，这些 Blocks，从计算机的角度可以看做是函数`Functions`的可视化。

#### STEP 0x03. 链接 Text 与 Balance

我们将 Text 的输出连上 Balance 的输入，这两个 Block 就链接起来了。

![image-20210917113718107](https://tva1.sinaimg.cn/large/008i3skNgy1gulyz4wvatj60gr0473yh02.jpg)

#### STEP 0x04. 输入一个地址！

随便找到一个地址，将其复制到`Text`中，我们会发现`Balance`的输入变成了数字。

![image-20210917113848959](https://tva1.sinaimg.cn/large/008i3skNgy1gulyz9kg4cj60gj0413yj02.jpg)

#### STEP 0x05. Wei to ETH

但这是一个整数，因为这个数字的单位是`wei`，我们可以将其转换为`ETH`，所以我们再添加两个 Block——

「`Utils`>`From Wei`」和「`DISPLAY`>`WATCH`」。Utils 是通用组件的集合，DISPLAY 是输出组件的集合。

![image-20210917114243087](https://tva1.sinaimg.cn/large/008i3skNgy1gulyz858zej60rn085aad02.jpg)

#### STEP 0x06. Show it to ur FRIENDS！

好了，你已经完成了你的第一个`eth.build`作品，你可以把它 show 给你的朋友！

![image-20210917114533319](https://tva1.sinaimg.cn/large/008i3skNgy1gulyzahxbzj60bz01pa9x02.jpg)

`SAVE` > `Share`，你会获得一个网址，你可以把这个网址发给你的朋友，他打开就能见到你的作品：

![image-20210917114727200](https://tva1.sinaimg.cn/large/008i3skNgy1gulyz964j5j60m00mmq4l02.jpg)

#### STEP 0x07. 本地保存

也许你需要把它保存在本地，以便于之后的加载。

「`Save`>`Download`」和「`Load`>`Load From File`」可以满足你的需求。

### 进阶玩法

> 无代码以太坊区块链浏览器：
>
> https://eth.build/build#3c50b1af5fd2956e808ac4d3132a9d063b8e2f9eac3b44d3971fe83165d5d0b8

这是一个无代码版本的以太坊区块链浏览器！

通过这个例子我们可以康康`eth.build`有哪些进阶玩法。

![image-20210917122822025](https://tva1.sinaimg.cn/large/008i3skNgy1gulyz3nuz3j61ck0ntjv202.jpg)

#### 0x01. 修改属性值

![image-20210917122804436](https://tva1.sinaimg.cn/large/008i3skNgy1gulyz2irhij609c076jrf02.jpg)

通过`Properties`的修改，我们可以给`BUTTON`、`WATCH`等 Block 修改名称等属性值，这样就呈现更加友好。例如我会用`0x01`等标记上按钮的点击顺序。

![image-20210917122956248](https://tva1.sinaimg.cn/large/008i3skNgy1gulyz4jl8pj60p40brjsa02.jpg)

#### 0x02. 标题与个人二维码

通过「`DISPLAY`>`TITLE`」我们能给作品显眼地标记上自己的大名。

![image-20210917123424682](https://tva1.sinaimg.cn/large/008i3skNgy1gulyz8n1rwj60hc026t8m02.jpg)

除此之外，我们还能通过`Text`和`QR`的组合在作品上加上个人二维码！

![image-20210917123505349](https://tva1.sinaimg.cn/large/008i3skNgy1gulyz5v0ymj60bl07iglv02.jpg)

从微信下载个人二维码后，通过草料二维码 (https://cli.im/deqr) 将二维码转换为`URL`，输入`Text`中即可。

![image-20210917123708696](https://tva1.sinaimg.cn/large/008i3skNgy1gulyz6fe6ej60t209c75302.jpg)

`eth.build`快速上手就到这里，这个「神器」还有很多玩法可以挖掘 🤩。
