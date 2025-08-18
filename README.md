AKNumericFormatter-Swift
==================
Just for fun reimplemetation of [AKNumericFormatter](https://github.com/blackm00n/AKNumericFormatter) to replace objc code from some product application.

Code rewriten in Swift.
Library available via SPM.

Usage
-----

You can look at Sample project or exlore [tests](https://github.com/kifio/AKNumericFormatter-Swift/blob/master/Tests/AKNumericFormatter_SwiftTests/AKNumericFormatter_SwiftTests.swift) to see `AKNumericFormatter-Swift` in action.

Formatter usage:
```swift
let out = AKNumericFormatter.format(string: "12345678901", mask: "+*(***)***-**-**", placeholder: Character("*"))
```
Of course you will get `"+1(234)567-89-01"`

To format `UITextField`'s input on-the-fly while the text is being entered:
```swift
// Somewhere, let's say in viewDidLoad
textField.numericFormatter = AKNumericFormatter.formatter(mask: "+1(999)*-**-**-x-**", placeholder: "*", mode: mode)
```
Yep, it's easy and no subclassing.

Compability
------------

Minimum supported iOS version is iOS 15 now. Maybe it can be less, but i have no devices to test.
Public API may be a bit different with original library. Not drastically. I suppose it would take 5-7 minutes to completely replace the library in your code.

Installation
------------
In Xcode add the dependency to your project via File > Add Packages > Search or Enter Package URL and use the following url:
https://github.com/kifio/AKNumericFormatter-Swift.git

Once added, import the package in your code:
import AKNumericFormatter_Swift


