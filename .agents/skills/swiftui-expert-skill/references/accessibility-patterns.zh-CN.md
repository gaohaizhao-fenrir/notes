# SwiftUI 无障碍模式参考

## 目录

- [核心原则](#核心原则)
- [Dynamic Type 与 @ScaledMetric](#dynamic-type-与-scaledmetric)
- [无障碍特征（Accessibility Traits）](#无障碍特征accessibility-traits)
- [装饰性图片](#装饰性图片)
- [元素分组](#元素分组)
- [自定义控件](#自定义控件)
- [总结清单](#总结清单)

## 核心原则

对于可点击元素，优先使用 `Button` 而不是 `onTapGesture`。`Button` 天生就提供 VoiceOver 支持、焦点处理，以及正确的无障碍特征。

## Dynamic Type 与 @ScaledMetric

系统文本样式会随 Dynamic Type 自动缩放。只要适配你的 UI，就优先使用内置样式，如 `.largeTitle`、`.title`、`.title2`、`.title3`、`.headline`、`.subheadline`、`.body`、`.callout`、`.footnote`、`.caption` 和 `.caption2`：

```swift
VStack(alignment: .leading) {
    Text("Inbox")
        .font(.title2)
    Text("3 unread messages")
        .font(.body)
    Text("Updated just now")
        .font(.caption)
}
```

对于自定义字体，请使用支持 Dynamic Type 的字体初始化方式，这样文本仍会跟随用户偏好的内容大小：

```swift
VStack(alignment: .leading) {
    Text("Article")
        .font(.custom("SourceSerif4-Semibold", size: 28, relativeTo: .title2))
    Text("Body copy")
        .font(.custom("SourceSerif4-Regular", size: 17))
}
```

`Font.custom(_:size:relativeTo:)` 可让你对齐到指定文本样式。`Font.custom(_:size:)` 会相对 body 样式缩放。对于应响应 Dynamic Type 的主要内容，避免使用固定字号的自定义字体。

对于非文本数值（如 padding、spacing、图片尺寸），请使用 `@ScaledMetric`：

```swift
struct ProfileHeader: View {
    @ScaledMetric private var avatarSize = 60.0
    @ScaledMetric private var spacing = 12.0

    var body: some View {
        HStack(spacing: spacing) {
            Image("avatar")
                .resizable()
                .frame(width: avatarSize, height: avatarSize)
            Text("Username")
        }
    }
}
```

当某个值应跟随特定 Dynamic Type 样式时，请指定 `relativeTo`，这也适用于应与周边文本保持比例的图片或图标：

```swift
struct StatusRow: View {
    @ScaledMetric(relativeTo: .body) private var iconSize = 18.0

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: iconSize))
            Text("Synced")
                .font(.custom("AvenirNext-Regular", size: 17, relativeTo: .body))
        }
    }
}
```

## 无障碍特征（Accessibility Traits）

对于随状态变化的特征，请使用 `accessibilityAddTraits` 与 `accessibilityRemoveTraits`：

```swift
Text(item.title)
    .accessibilityAddTraits(item.isSelected ? [.isSelected, .isButton] : .isButton)
```

对不可交互元素使用 `.disabled(true)`，让 VoiceOver 读出 “Dimmed”（已置灰/不可用）。

## 装饰性图片

当资源图片纯粹用于视觉装饰，不应进入无障碍树时，使用 `Image(decorative:bundle:)`。

```swift
Image(decorative: "confetti")
```

这适用于背景、装饰元素，以及在邻近文本之外不额外传达含义的图标。

如果图片承载信息，应保持其可访问性并提供清晰标签：

```swift
Image("receipt")
    .accessibilityLabel("Receipt")
```

对于非资源图片（例如 SF Symbols），若仅为装饰，请改用 `accessibilityHidden(true)` 隐藏：

```swift
Image(systemName: "sparkles")
    .accessibilityHidden(true)
```

## 元素分组

### `.combine` -- 自动合并子元素标签

```swift
HStack {
    Image(systemName: "star.fill")
    Text("Favorites")
    Text("(\(count))")
}
.accessibilityElement(children: .combine)
```

VoiceOver 会把所有子元素标签作为一个元素读取，并用逗号分隔。

### `.ignore` -- 为容器手动指定标签

```swift
HStack {
    Text(item.name)
    Spacer()
    Text(item.price)
}
.accessibilityElement(children: .ignore)
.accessibilityLabel("\(item.name), \(item.price)")
```

### `.contain` -- 语义分组

```swift
HStack {
    ForEach(tabs) { tab in
        TabButton(tab: tab)
    }
}
.accessibilityElement(children: .contain)
.accessibilityLabel("Tab bar")
```

当焦点进入/离开容器时，VoiceOver 会播报容器名称。

## 自定义控件

### 可调节控件（递增/递减）

```swift
PageControl(selectedIndex: $selectedIndex, pageCount: pageCount)
    .accessibilityElement()
    .accessibilityValue("Page \(selectedIndex + 1) of \(pageCount)")
    .accessibilityAdjustableAction { direction in
        switch direction {
        case .increment:
            guard selectedIndex < pageCount - 1 else { break }
            selectedIndex += 1
        case .decrement:
            guard selectedIndex > 0 else { break }
            selectedIndex -= 1
        @unknown default:
            break
        }
    }
```

### 将自定义视图表示为原生控件

当某个自定义视图在无障碍上应表现得像原生控件时：

```swift
HStack {
    Text(label)
    Toggle("", isOn: $isOn)
}
.accessibilityRepresentation {
    Toggle(label, isOn: $isOn)
}
```

### 标签-内容配对

```swift
@Namespace private var ns

HStack {
    Text("Volume")
        .accessibilityLabeledPair(role: .label, id: "volume", in: ns)
    Slider(value: $volume)
        .accessibilityLabeledPair(role: .content, id: "volume", in: ns)
}
```

## 总结清单

- [ ] 对可点击元素使用 `Button`，而不是 `onTapGesture`
- [ ] 文本使用内置样式，或使用支持 Dynamic Type 的自定义字体
- [ ] 对应随 Dynamic Type 缩放的自定义数值使用 `@ScaledMetric`
- [ ] 将纯装饰图片标记为 decorative 或从无障碍中隐藏
- [ ] 使用 `accessibilityElement(children:)` 分组相关元素
- [ ] 默认标签不清晰时提供 `accessibilityLabel`
- [ ] 自定义控件使用 `accessibilityRepresentation`
- [ ] 递增/递减控件使用 `accessibilityAdjustableAction`
- [ ] 使用 VoiceOver 分组时确保导航流合理
