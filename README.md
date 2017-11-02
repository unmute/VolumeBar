![VolumeBar](https://github.com/gizmosachin/VolumeBar/raw/master/VolumeBar.gif)

## VolumeBar

`VolumeBar` is a [Swift](https://developer.apple.com/swift/) volume indicator that doesn't obstruct content on screen. A basic implementation is just one line of code, but it can be heavily customized via several appearance and presentation properties.

### Features
- [x] Customizable appearance
- [x] Orientation change support
- [x] Hides system volume HUD automatically
- [x] Simple API

[![Build Status](https://travis-ci.org/gizmosachin/VolumeBar.svg?branch=master)](https://travis-ci.org/gizmosachin/VolumeBar) [![Pod Version](https://img.shields.io/cocoapods/v/VolumeBar.svg?style=flat)](http://cocoadocs.org/docsets/VolumeBar/)

## Version Compatibility

Current Swift compatibility breakdown:

| Swift Version | Framework Version |
| ------------- | ----------------- |
| 3.0	        | master          	|
| 2.3	        | 1.1          		|
| 2.2           | 1.1          		|

## Usage

A basic implementation of `VolumeBar` is just one line of code.

```swift
VolumeBar.sharedInstance.start()
```

By default, adding `VolumeBar` to your app will cause background audio to pause when your app is opened. To prevent this, add the following line of code wherever you call the `start` method:

```swift
try! AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryAmbient)
```

Calling the `start` method begins observing changes in the system volume. After calling `start`, `VolumeBar` will show automatically whenever your app is active and the volume changes. This is appropriate for most use cases. To stop observing changes and use the system volume HUD again, call `stop`:

```swift
VolumeBar.sharedInstance.stop()
```

[Please see the documentation](http://gizmosachin.github.io/VolumeBar/docs) and check out the sample app (VolumeBarSample) for more details.

****

##### Appearance

Customize tint color, bar tint color, and track tint color:

```swift
VolumeBar.sharedInstance.tintColor = UIColor.white
VolumeBar.sharedInstance.backgroundColor = UIColor.black.withAlphaComponent(0.5)
VolumeBar.sharedInstance.trackTintColor = UIColor.clear
```

Customize layout properties:

```swift
VolumeBar.sharedInstance.barHeight = 5
VolumeBar.sharedInstance.segmentCount = 8
VolumeBar.sharedInstance.interitemSpacing = 5
```

****

##### Presentation

If `start` has been called, `VolumeBar` will automatically show when the system volume changes. You can also manually show and hide `VolumeBar`.

```swift
VolumeBar.sharedInstance.show()
VolumeBar.sharedInstance.hide()
```

Change the animation style:

```swift
VolumeBar.sharedInstance.animationStyle = .fade // default is .slide
VolumeBar.sharedInstance.animationDuration = 0.5
VolumeBar.sharedInstance.minimumVisibleDuration = 2.0
```

****

##### Status Bar

`VolumeBar` needs to know when the status bar is hidden or changes style. These properties should be updated in the  `viewWillAppear` method of each view controller.

```swift
VolumeBar.sharedInstance.statusBarHidden = false
VolumeBar.sharedInstance.statusBarStyle = .lightContent
```

## Installation

### CocoaPods

`VolumeBar` is available using the Cocoa dependency manager [CocoaPods](http://cocoapods.org/).

To integrate, add the following to your `Podfile`:

```ruby
source 'https://github.com/CocoaPods/Specs.git'
use_frameworks!

pod 'VolumeBar', '~> 2.0.6'
```

### Carthage

Installation is also available using the dependency manager [Carthage](https://github.com/Carthage/Carthage). To integrate, add the following line to your `Cartfile`:

```ogdl
github "gizmosachin/VolumeBar" "master"
```

### Swift Package Manager

Installation is also available using the [Swift Package Manager](https://swift.org/package-manager/). To integrate, add the following to your `Package.swift`:

```swift
import PackageDescription

let package = Package(
    name: "MyProject",
    dependencies: [
        .Package(url: "https://github.com/gizmosachin/VolumeBar.git", majorVersion: 0),
    ]
)
```

### Manual

You can also simply copy `VolumeBar.swift` into your Xcode project.

## Documentation

API documentation is [available here](http://gizmosachin.github.io/VolumeBar/docs).

## Community

- Need help? Use [Stack Overflow](http://stackoverflow.com/questions/tagged/volumebar-swift) with the tag 'volumebar-swift'.
- Questions? Use [Stack Overflow](http://stackoverflow.com/questions/tagged/volumebar-swift) with the tag 'volumebar-swift'.
- Found a bug? Open an [issue](https://github.com/gizmosachin/VolumeBar/issues).
- Feature idea? Open an [issue](https://github.com/gizmosachin/VolumeBar/issues).
- Want to contribute? Submit a [pull request](https://github.com/gizmosachin/VolumeBar/pulls).

## License

VolumeBar is available under the MIT license, see the [LICENSE](https://github.com/gizmosachin/VolumeBar/blob/master/LICENSE) file for more information.
