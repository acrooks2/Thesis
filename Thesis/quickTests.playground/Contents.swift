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

(3 % 3)

-1.0 / 0.5 * log(0.5)

-log(Double.random(in: 0..<1)) / 0.5

-log(0.5) / 0.5

for _ in 1...10 {
    print(Int((Double.random(in: 0..<100)) * log(Double.random(in: 0..<1))))
}

func randExp(rate: Double) -> Double {
    return -1.0 / rate * log(Double.random(in: 0...1))
}

for _ in 1...10 {
    print(randExp(rate: 0.0175))
}

var x = ["key":1]
var y = x
y["key"]! -= 1
print(x["key"]!)
print(y["key"]!)


var dlist: [[String:Int]] = []
let order = ["ID": 1, "quantity": 20]
dlist.append(order)

var f = false

f == false
