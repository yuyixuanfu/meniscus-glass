# meniscus

Flutter 的液体玻璃。一个片段着色器直接采样页面背景图，把贴边那圈的背后按真实玻璃的折射推弯，中间保持清楚。

Liquid glass for Flutter. A fragment shader samples the page backdrop and bends it along the edge
the way real glass refracts, while the middle stays clear.

<img src="docs/screenshot.jpg" width="360" alt="meniscus on an Android phone">

## 用法 / Usage

```yaml
dependencies:
  meniscus:
    git: https://github.com/yuyixuanfu/meniscus-glass.git
```

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LensGlass.load();
  runApp(const MyApp());
}

GlassBackdrop(
  image: const AssetImage('assets/backdrop.png'),
  child: ListView(children: [
    LensGlass(radius: 20, child: Text('hello')),
  ]),
);

// 不在滚动列表里、浮在内容上面的面(输入栏、按钮)读屏幕上背后的真实画面:
// Floating surfaces that are not inside a scroll view read the live backdrop:
const LensGlass(radius: 26, live: true, child: SizedBox(height: 52));
```

| 参数 / Parameter | 说明 / Meaning |
|---|---|
| `radius` | 圆角 / corner radius |
| `tint` | 膜色，alpha 是膜厚 / film colour, alpha is its thickness |
| `live` | `true` 时读背后的真实画面，需要 `ImageFilter.isShaderFilterSupported`(Impeller)；不支持时退回采样 `GlassBackdrop` 的图 / reads the live backdrop; needs Impeller, otherwise falls back to the `GlassBackdrop` image |

## 限制 / Limitations

- `live: false` 只弯得到 `GlassBackdrop` 那张图，弯不到压在玻璃后面的别的组件。
  With `live: false` only the `GlassBackdrop` image is refracted, not other widgets behind the glass.
- 着色器和渲染代码在作者自己的 App 里用过：Flutter 3.47.7，Impeller，华为安卓真机。这个包单独拆出来以后的测试见 example。
  The shader and render code shipped in the author's app (Flutter 3.47.7, Impeller, Android). See `example/` for the standalone package.
- iOS、桌面没测过。/ Not tested on iOS or desktop.

## 示例 / Example

```
cd example
flutter run
```

手机上整屏是一段对话，右上角按钮打开设置：换底片、调圆角和膜厚、开关读背后真实画面。电脑上手机框放在中间，设置在旁边。
网页版能跑，但浏览器不支持读背后真实画面，浮着的玻璃只弯底片，效果比手机差一档。

On a phone the demo is a conversation; the top-right button opens the controls (backdrop, corner
radius, film, live backdrop). On a wide screen the phone sits in a frame with the controls beside it.
The web build runs, but browsers cannot read the live backdrop, so floating glass bends only the
backdrop image.

## 许可 / License

GNU Affero General Public License v3.0，见 [LICENSE](LICENSE)。
部分代码移植自 [qiaosi](https://github.com/TangfanOVO/qiaosi)(AGPL-3.0)和
[hyalite--liquid-glass](https://github.com/VII-Cae/hyalite--liquid-glass)(MIT)，见 [NOTICE](NOTICE)。

AGPL-3.0. Parts are ported from qiaosi (AGPL-3.0) and hyalite--liquid-glass (MIT); see NOTICE.
