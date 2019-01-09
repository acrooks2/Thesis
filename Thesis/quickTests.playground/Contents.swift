//: A Cocoa based Playground to present user interface

import AppKit
import PlaygroundSupport

let nibFile = NSNib.Name("MyView")
var topLevelObjects : NSArray?

Bundle.main.loadNibNamed(nibFile, owner:nil, topLevelObjects: &topLevelObjects)
let views = (topLevelObjects as! Array<Any>).filter { $0 is NSView }

// Present the view in Playground
PlaygroundPage.current.liveView = views[0] as! NSView


Float.random(in: 0..<1)
Float.random(in: 0..<1)
Float.random(in: 0..<0.5)

for _ in 0...10 {
    print(Float.random(in: 0..<0.5))
}

var list1: [Int] = []

var list2: [Int] = []

for _ in 1...100 {
    list1.append(Int.random(in: 1...100))
}

list1.shuffle()

for _ in 1...50 {
    list2.append(list1[Int.random(in: 0...99)])
}

let list2Sum = list2.reduce(0, +)
let list2Count = list2.count
let list2Mean = list2Sum / list2Count
