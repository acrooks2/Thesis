//: A Cocoa based Playground to present user interface

import AppKit
import PlaygroundSupport


let nibFile = NSNib.Name("MyView")
var topLevelObjects : NSArray?

Bundle.main.loadNibNamed(nibFile, owner:nil, topLevelObjects: &topLevelObjects)
let views = (topLevelObjects as! Array<Any>).filter { $0 is NSView }

// Present the view in Playground
PlaygroundPage.current.liveView = views[0] as! NSView

import Foundation // Needed for ComparisonResult (used privately)

/// An array that keeps its elements sorted at all times.
public struct SortedArray<Element> {
    /// The backing store
    fileprivate var _elements: [Element]
    
    public typealias Comparator<A> = (A, A) -> Bool
    
    /// The predicate that determines the array's sort order.
    fileprivate let areInIncreasingOrder: Comparator<Element>
    
    /// Initializes an empty array.
    ///
    /// - Parameter areInIncreasingOrder: The comparison predicate the array should use to sort its elements.
    public init(areInIncreasingOrder: @escaping Comparator<Element>) {
        self._elements = []
        self.areInIncreasingOrder = areInIncreasingOrder
    }
    
    /// Initializes the array with a sequence of unsorted elements and a comparison predicate.
    public init<S: Sequence>(unsorted: S, areInIncreasingOrder: @escaping Comparator<Element>) where S.Element == Element {
        let sorted = unsorted.sorted(by: areInIncreasingOrder)
        self._elements = sorted
        self.areInIncreasingOrder = areInIncreasingOrder
    }
    
    /// Initializes the array with a sequence that is already sorted according to the given comparison predicate.
    ///
    /// This is faster than `init(unsorted:areInIncreasingOrder:)` because the elements don't have to sorted again.
    ///
    /// - Precondition: `sorted` is sorted according to the given comparison predicate. If you violate this condition, the behavior is undefined.
    public init<S: Sequence>(sorted: S, areInIncreasingOrder: @escaping Comparator<Element>) where S.Element == Element {
        self._elements = Array(sorted)
        self.areInIncreasingOrder = areInIncreasingOrder
    }
    
    /// Inserts a new element into the array, preserving the sort order.
    ///
    /// - Returns: the index where the new element was inserted.
    /// - Complexity: O(_n_) where _n_ is the size of the array. O(_log n_) if the new
    /// element can be appended, i.e. if it is ordered last in the resulting array.
    @discardableResult
    public mutating func insert(_ newElement: Element) -> Index {
        let index = insertionIndex(for: newElement)
        // This should be O(1) if the element is to be inserted at the end,
        // O(_n) in the worst case (inserted at the front).
        _elements.insert(newElement, at: index)
        return index
    }
    
    /// Inserts all elements from `elements` into `self`, preserving the sort order.
    ///
    /// This can be faster than inserting the individual elements one after another because
    /// we only need to re-sort once.
    ///
    /// - Complexity: O(_n * log(n)_) where _n_ is the size of the resulting array.
    public mutating func insert<S: Sequence>(contentsOf newElements: S) where S.Element == Element {
        _elements.append(contentsOf: newElements)
        _elements.sort(by: areInIncreasingOrder)
    }
}

extension SortedArray where Element: Comparable {
    /// Initializes an empty sorted array. Uses `<` as the comparison predicate.
    public init() {
        self.init(areInIncreasingOrder: <)
    }
    
    /// Initializes the array with a sequence of unsorted elements. Uses `<` as the comparison predicate.
    public init<S: Sequence>(unsorted: S) where S.Element == Element {
        self.init(unsorted: unsorted, areInIncreasingOrder: <)
    }
    
    /// Initializes the array with a sequence that is already sorted according to the `<` comparison predicate. Uses `<` as the comparison predicate.
    ///
    /// This is faster than `init(unsorted:)` because the elements don't have to sorted again.
    ///
    /// - Precondition: `sorted` is sorted according to the `<` predicate. If you violate this condition, the behavior is undefined.
    public init<S: Sequence>(sorted: S) where S.Element == Element {
        self.init(sorted: sorted, areInIncreasingOrder: <)
    }
}

extension SortedArray: RandomAccessCollection {
    public typealias Index = Int
    
    public var startIndex: Index { return _elements.startIndex }
    public var endIndex: Index { return _elements.endIndex }
    
    public func index(after i: Index) -> Index {
        return _elements.index(after: i)
    }
    
    public func index(before i: Index) -> Index {
        return _elements.index(before: i)
    }
    
    public subscript(position: Index) -> Element {
        return _elements[position]
    }
}

extension SortedArray {
    /// Like `Sequence.filter(_:)`, but returns a `SortedArray` instead of an `Array`.
    /// We can do this efficiently because filtering doesn't change the sort order.
    public func filter(_ isIncluded: (Element) throws -> Bool) rethrows -> SortedArray<Element> {
        let newElements = try _elements.filter(isIncluded)
        return SortedArray(sorted: newElements, areInIncreasingOrder: areInIncreasingOrder)
    }
}

extension SortedArray: CustomStringConvertible, CustomDebugStringConvertible {
    public var description: String {
        return "\(String(describing: _elements)) (sorted)"
    }
    
    public var debugDescription: String {
        return "<SortedArray> \(String(reflecting: _elements))"
    }
}

// MARK: - Removing elements. This is mostly a reimplementation of part `RangeReplaceableCollection`'s interface. `SortedArray` can't conform to `RangeReplaceableCollection` because some of that protocol's semantics (e.g. `append(_:)` don't fit `SortedArray`'s semantics.
extension SortedArray {
    /// Removes and returns the element at the specified position.
    ///
    /// - Parameter index: The position of the element to remove. `index` must be a valid index of the array.
    /// - Returns: The element at the specified index.
    /// - Complexity: O(_n_), where _n_ is the length of the array.
    @discardableResult
    public mutating func remove(at index: Int) -> Element {
        return _elements.remove(at: index)
    }
    
    /// Removes the elements in the specified subrange from the array.
    ///
    /// - Parameter bounds: The range of the array to be removed. The
    ///   bounds of the range must be valid indices of the array.
    ///
    /// - Complexity: O(_n_), where _n_ is the length of the array.
    public mutating func removeSubrange(_ bounds: Range<Int>) {
        _elements.removeSubrange(bounds)
    }
    
    /// Removes the elements in the specified subrange from the array.
    ///
    /// - Parameter bounds: The range of the array to be removed. The
    ///   bounds of the range must be valid indices of the array.
    ///
    /// - Complexity: O(_n_), where _n_ is the length of the array.
    public mutating func removeSubrange(_ bounds: ClosedRange<Int>) {
        _elements.removeSubrange(bounds)
    }
    
    // Starting with Swift 4.2, CountableRange and CountableClosedRange are typealiases for
    // Range and ClosedRange, so these methods trigger "Invalid redeclaration" errors.
    // Compile them only for older compiler versions.
    // swift(3.1): Latest version of Swift 3 under the Swift 3 compiler.
    // swift(3.2): Swift 4 compiler under Swift 3 mode.
    // swift(3.3): Swift 4.1 compiler under Swift 3 mode.
    // swift(3.4): Swift 4.2 compiler under Swift 3 mode.
    // swift(4.0): Swift 4 compiler
    // swift(4.1): Swift 4.1 compiler
    // swift(4.1.50): Swift 4.2 compiler in Swift 4 mode
    // swift(4.2): Swift 4.2 compiler
    #if !swift(>=4.1.50)
    /// Removes the elements in the specified subrange from the array.
    ///
    /// - Parameter bounds: The range of the array to be removed. The
    ///   bounds of the range must be valid indices of the array.
    ///
    /// - Complexity: O(_n_), where _n_ is the length of the array.
    public mutating func removeSubrange(_ bounds: CountableRange<Int>) {
    _elements.removeSubrange(bounds)
    }
    
    /// Removes the elements in the specified subrange from the array.
    ///
    /// - Parameter bounds: The range of the array to be removed. The
    ///   bounds of the range must be valid indices of the array.
    ///
    /// - Complexity: O(_n_), where _n_ is the length of the array.
    public mutating func removeSubrange(_ bounds: CountableClosedRange<Int>) {
    _elements.removeSubrange(bounds)
    }
    #endif
    
    /// Removes the specified number of elements from the beginning of the
    /// array.
    ///
    /// - Parameter n: The number of elements to remove from the array.
    ///   `n` must be greater than or equal to zero and must not exceed the
    ///   number of elements in the array.
    ///
    /// - Complexity: O(_n_), where _n_ is the length of the array.
    public mutating func removeFirst(_ n: Int) {
        _elements.removeFirst(n)
    }
    
    /// Removes and returns the first element of the array.
    ///
    /// - Precondition: The array must not be empty.
    /// - Returns: The removed element.
    /// - Complexity: O(_n_), where _n_ is the length of the collection.
    @discardableResult
    public mutating func removeFirst() -> Element {
        return _elements.removeFirst()
    }
    
    /// Removes and returns the last element of the array.
    ///
    /// - Precondition: The collection must not be empty.
    /// - Returns: The last element of the collection.
    /// - Complexity: O(1)
    @discardableResult
    public mutating func removeLast() -> Element {
        return _elements.removeLast()
    }
    
    /// Removes the given number of elements from the end of the array.
    ///
    /// - Parameter n: The number of elements to remove. `n` must be greater
    ///   than or equal to zero, and must be less than or equal to the number of
    ///   elements in the array.
    /// - Complexity: O(1).
    public mutating func removeLast(_ n: Int) {
        _elements.removeLast(n)
    }
    
    /// Removes all elements from the array.
    ///
    /// - Parameter keepCapacity: Pass `true` to keep the existing capacity of
    ///   the array after removing its elements. The default value is `false`.
    ///
    /// - Complexity: O(_n_), where _n_ is the length of the array.
    public mutating func removeAll(keepingCapacity keepCapacity: Bool = true) {
        _elements.removeAll(keepingCapacity: keepCapacity)
    }
    
    /// Removes an element from the array. If the array contains multiple
    /// instances of `element`, this method only removes the first one.
    ///
    /// - Complexity: O(_n_), where _n_ is the size of the array.
    public mutating func remove(_ element: Element) {
        guard let index = index(of: element) else { return }
        _elements.remove(at: index)
    }
}

// MARK: - More efficient variants of default implementations or implementations that need fewer constraints than the default implementations.
extension SortedArray {
    /// Returns the first index where the specified value appears in the collection.
    ///
    /// - Complexity: O(_log(n)_), where _n_ is the size of the array.
    public func firstIndex(of element: Element) -> Index? {
        var range: Range<Index> = startIndex ..< endIndex
        var match: Index? = nil
        while case let .found(m) = search(for: element, in: range) {
            // We found a matching element
            // Check if its predecessor also matches
            if let predecessor = index(m, offsetBy: -1, limitedBy: range.lowerBound),
                compare(self[predecessor], element) == .orderedSame
            {
                // Predecessor matches => continue searching using binary search
                match = predecessor
                range = range.lowerBound ..< predecessor
            }
            else {
                // We're done
                match = m
                break
            }
        }
        return match
    }
    
    /// Returns the first index where the specified value appears in the collection.
    /// Old name for `firstIndex(of:)`.
    /// - Seealso: `firstIndex(of:)`
    public func index(of element: Element) -> Index? {
        return firstIndex(of: element)
    }
    
    /// Returns a Boolean value indicating whether the sequence contains the given element.
    ///
    /// - Complexity: O(_log(n)_), where _n_ is the size of the array.
    public func contains(_ element: Element) -> Bool {
        return anyIndex(of: element) != nil
    }
    
    /// Returns the minimum element in the sequence.
    ///
    /// - Complexity: O(1).
    @warn_unqualified_access
    public func min() -> Element? {
        return first
    }
    
    /// Returns the maximum element in the sequence.
    ///
    /// - Complexity: O(1).
    @warn_unqualified_access
    public func max() -> Element? {
        return last
    }
}

// MARK: - APIs that go beyond what's in the stdlib
extension SortedArray {
    /// Returns an arbitrary index where the specified value appears in the collection.
    /// Like `index(of:)`, but without the guarantee to return the *first* index
    /// if the array contains duplicates of the searched element.
    ///
    /// Can be slightly faster than `index(of:)`.
    public func anyIndex(of element: Element) -> Index? {
        switch search(for: element) {
        case let .found(at: index): return index
        case .notFound(insertAt: _): return nil
        }
    }
    
    /// Returns the last index where the specified value appears in the collection.
    ///
    /// - Complexity: O(_log(n)_), where _n_ is the size of the array.
    public func lastIndex(of element: Element) -> Index? {
        var range: Range<Index> = startIndex ..< endIndex
        var match: Index? = nil
        while case let .found(m) = search(for: element, in: range) {
            // We found a matching element
            // Check if its successor also matches
            let lastValidIndex = index(before: range.upperBound)
            if let successor = index(m, offsetBy: 1, limitedBy: lastValidIndex),
                compare(self[successor], element) == .orderedSame
            {
                // Successor matches => continue searching using binary search
                match = successor
                guard let afterSuccessor = index(successor, offsetBy: 1, limitedBy: lastValidIndex) else {
                    break
                }
                range =  afterSuccessor ..< range.upperBound
            }
            else {
                // We're done
                match = m
                break
            }
        }
        return match
    }
}

// MARK: - Converting between a stdlib comparator function and Foundation.ComparisonResult
extension SortedArray {
    fileprivate func compare(_ lhs: Element, _ rhs: Element) -> Foundation.ComparisonResult {
        if areInIncreasingOrder(lhs, rhs) {
            return .orderedAscending
        } else if areInIncreasingOrder(rhs, lhs) {
            return .orderedDescending
        } else {
            // If neither element comes before the other, they _must_ be
            // equal, per the strict ordering requirement of `areInIncreasingOrder`.
            return .orderedSame
        }
    }
}

// MARK: - Binary search
extension SortedArray {
    /// The index where `newElement` should be inserted to preserve the array's sort order.
    fileprivate func insertionIndex(for newElement: Element) -> Index {
        switch search(for: newElement) {
        case let .found(at: index): return index
        case let .notFound(insertAt: index): return index
        }
    }
}

fileprivate enum Match<Index: Comparable> {
    case found(at: Index)
    case notFound(insertAt: Index)
}

extension Range where Bound == Int {
    var middle: Int? {
        guard !isEmpty else { return nil }
        return lowerBound + count / 2
    }
}

extension SortedArray {
    /// Searches the array for `element` using binary search.
    ///
    /// - Returns: If `element` is in the array, returns `.found(at: index)`
    ///   where `index` is the index of the element in the array.
    ///   If `element` is not in the array, returns `.notFound(insertAt: index)`
    ///   where `index` is the index where the element should be inserted to
    ///   preserve the sort order.
    ///   If the array contains multiple elements that are equal to `element`,
    ///   there is no guarantee which of these is found.
    ///
    /// - Complexity: O(_log(n)_), where _n_ is the size of the array.
    fileprivate func search(for element: Element) -> Match<Index> {
        return search(for: element, in: startIndex ..< endIndex)
    }
    
    fileprivate func search(for element: Element, in range: Range<Index>) -> Match<Index> {
        guard let middle = range.middle else { return .notFound(insertAt: range.upperBound) }
        switch compare(element, self[middle]) {
        case .orderedDescending:
            return search(for: element, in: index(after: middle)..<range.upperBound)
        case .orderedAscending:
            return search(for: element, in: range.lowerBound..<middle)
        case .orderedSame:
            return .found(at: middle)
        }
    }
}

#if swift(>=4.1)
extension SortedArray: Equatable where Element: Equatable {
    public static func == (lhs: SortedArray<Element>, rhs: SortedArray<Element>) -> Bool {
        // Ignore the comparator function for Equatable
        return lhs._elements == rhs._elements
    }
}
#else
public func ==<Element: Equatable> (lhs: SortedArray<Element>, rhs: SortedArray<Element>) -> Bool {
return lhs._elements == rhs._elements
}

public func !=<Element: Equatable> (lhs: SortedArray<Element>, rhs: SortedArray<Element>) -> Bool {
return lhs._elements != rhs._elements
}
#endif

#if swift(>=4.1.50)
extension SortedArray: Hashable where Element: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(_elements)
    }
}
#endif


var array = SortedArray<Int>()

array.insert(3)
array.insert(4)
array.insert(1)
array.insert(9)
array.insert(7)
array.insert(2)

print(array)

import Foundation


struct Order {
    var orderID: Int
    var traderID: Int
    var timeStamp: Int
    var type: Int
    var quantity: Int
    var side: Int
    var price: Int
}

struct Trade {
    var restingTraderID: Int
    var restingOrderID: Int
    var restingTimeStamp: Int
    var incomingTraderID: Int
    var incomingOrderID: Int
    var incomingTimeStamp: Int
    var tradePrice: Int
    var tradeQuantity: Int
    var side: Int
}

struct BidBook {
    //always sorted array of bid prices
    var prices: SortedArray<Int>
    //orders is a dictionary with exIDs as keys and the associated order as values
    var orders: [Int:Order]
    //the number of orders at each price
    var numOrders: [Int:Int]
    //the quantity at each price
    var priceSize: [Int:Int]
    // dictionary with prices as keys and lists of order ids as values
    var orderIDs: [Int:[Int]]
    
}

struct AskBook {
    //always sorted array of ask prices
    var prices: SortedArray<Int>
    //orders is a dictionary with exIDs as keys and the associated order as values
    var orders: [Int:Order]
    //the number of orders at each price
    var numOrders: [Int:Int]
    //the quantity at each price
    var priceSize: [Int:Int]
    // dictionary with prices as keys and lists of order ids as values
    var orderIDs: [Int:[Int]]
}

struct TradeBook {
    // A dictionary to store all trades with trade ID as key and trades as values
    var trades: [Int:Trade]
}

class OrderBook {
    var orderHistory: [Int:Order]
    var bidBook: BidBook
    var askBook: AskBook
    var orderIndex: Int
    var exIndex: Int
    var traded: Bool
    var confirmTradeCollector: [Order]
    var confirmTradeCollectorTimeStamps: [Int]
    var tradeBook: TradeBook
    var tradeIndex: Int
    var lookUp: [Int:[Int:Order]]
    
    init(bidbook: BidBook, askbook: AskBook, tradebook: TradeBook) {
        self.orderHistory = [:]
        self.bidBook = bidbook
        self.askBook = askbook
        // Order index is simply to identify orders in sequence in order history
        self.orderIndex = 0
        // ex index is for identifying limit orders will hit in process order
        self.exIndex = 0
        self.traded = false
        self.confirmTradeCollector = []
        self.confirmTradeCollectorTimeStamps = []
        self.tradeBook = tradebook
        self.tradeIndex = 0
        self.lookUp = [:]
    }
    
    func addOrderToHistory(order: Order) {
        orderIndex += 1
        orderHistory[orderIndex] = order
    }
    
    func addOrderToLookUp(order: Order) {
        if lookUp.keys.contains(order.traderID) {
            lookUp[order.traderID]![order.orderID]! = order
        }
        else {
            lookUp[order.traderID]! = [order.orderID:order]
        }
    }
    
    func addOrderToBook(order: Order) {
        exIndex += 1
        // Add an order to the buy side
        if order.side == 1 {
            if bidBook.prices.contains(order.price) {
                bidBook.numOrders[order.price]! += 1
                bidBook.priceSize[order.price]! += order.quantity
                bidBook.orderIDs[order.price]!.append(exIndex)
                bidBook.orders[exIndex] = order
            }
            else {
                bidBook.prices.insert(order.price)
                bidBook.numOrders[order.price] = 1
                bidBook.priceSize[order.price] = order.quantity
                bidBook.orderIDs[order.price]!.append(exIndex)
                bidBook.orders[exIndex] = order
                
            }
        }
            // Add an order to the sell side
        else {
            if askBook.prices.contains(order.price) {
                askBook.numOrders[order.price]! += 1
                askBook.priceSize[order.price]! += order.quantity
                askBook.orderIDs[order.price]?.append(exIndex)
                askBook.orders[exIndex] = order
            }
            else {
                askBook.prices.insert(order.price)
                askBook.numOrders[order.price] = 1
                askBook.priceSize[order.price] = order.quantity
                askBook.orderIDs[order.price]?.append(exIndex)
                askBook.orders[exIndex] = order
            }
        }
        addOrderToLookUp(order: order)
    }
    
    func confirmTrade(bookOrder: Order, order: Order) {
        confirmTradeCollector.append(bookOrder)
        confirmTradeCollectorTimeStamps.append(order.timeStamp)
    }
    
    func addTradeToBook(trade: Trade) {
        tradeBook.trades[tradeIndex] = trade
    }
    
    func removeOrder(order: Order) {
        if order.side == 1 {
            bidBook.numOrders[order.price]! -= 1
            bidBook.priceSize[order.price]! -= order.quantity
            bidBook.orderIDs[order.price]!.removeLast()
            if bidBook.numOrders[order.price]! == 0 {
                bidBook.prices.remove(order.price)
            }
        }
        else {
            askBook.numOrders[order.price]! -= 1
            askBook.priceSize[order.price]! -= order.quantity
            askBook.orderIDs[order.price]!.removeLast()
            if askBook.numOrders[order.price]! == 0 {
                askBook.prices.remove(order.price)
            }
        }
        lookUp[order.traderID]!.removeValue(forKey: order.orderID)
    }
    
    func modifyOrder(order: Order, less: Int) {
        if order.side == 1 {
            if less < bidBook.orders[order.orderID]!.quantity {
                bidBook.priceSize[order.price]! -= less
                bidBook.orders[order.orderID]!.quantity -= less
            }
            else {
                removeOrder(order: order)
            }
        }
        else {
            if less < askBook.orders[order.orderID]!.quantity {
                askBook.priceSize[order.price]! -= less
                askBook.orders[order.orderID]!.quantity -= less
            }
            else {
                removeOrder(order: order)
            }
        }
    }
    
    func matchTrade(order: Order) {
        traded = true
        confirmTradeCollector.removeAll()
        confirmTradeCollectorTimeStamps.removeAll()
        // If order side is "buy"
        var remainder = order.quantity
        if order.side == 1 {
            while remainder > 0 {
                var price = askBook.prices[0]
                if order.price >= price {
                    var orderID = askBook.orderIDs[order.price]![0]
                    var bookOrder = askBook.orders[orderID]
                    if remainder >= bookOrder!.quantity {
                        confirmTrade(bookOrder: bookOrder!, order: order)
                        var trade = Trade(restingTraderID: (bookOrder?.traderID)!, restingOrderID: (bookOrder?.orderID)!, restingTimeStamp: (bookOrder?.timeStamp)!, incomingTraderID: order.traderID, incomingOrderID: order.orderID, incomingTimeStamp: order.timeStamp, tradePrice: (bookOrder?.price)!, tradeQuantity: (bookOrder?.quantity)!, side: order.side)
                        addTradeToBook(trade: trade)
                        removeOrder(order: bookOrder!)
                        remainder -= bookOrder!.quantity
                    }
                        // Remainder less than book order
                    else {
                        confirmTrade(bookOrder: bookOrder!, order: order)
                        var trade = Trade(restingTraderID: (bookOrder?.traderID)!, restingOrderID: (bookOrder?.orderID)!, restingTimeStamp: (bookOrder?.timeStamp)!, incomingTraderID: order.traderID, incomingOrderID: order.orderID, incomingTimeStamp: order.timeStamp, tradePrice: (bookOrder?.price)!, tradeQuantity: (bookOrder?.quantity)!, side: order.side)
                        addTradeToBook(trade: trade)
                        modifyOrder(order: bookOrder!, less: remainder)
                        break
                    }
                }
                else {
                    // have to make order a var or else it errors because it is "let constant"
                    var newBookOrder = order
                    newBookOrder.quantity = remainder
                    addOrderToBook(order: newBookOrder)
                    break
                }
            }
        }
            // order is "sell"
        else {
            while remainder > 0 {
                var price = bidBook.prices[-1]
                if order.price <= price {
                    var orderID = bidBook.orderIDs[order.price]![0]
                    var bookOrder = bidBook.orders[orderID]
                    if remainder >= bookOrder!.quantity {
                        confirmTrade(bookOrder: bookOrder!, order: order)
                        var trade = Trade(restingTraderID: (bookOrder?.traderID)!, restingOrderID: (bookOrder?.orderID)!, restingTimeStamp: (bookOrder?.timeStamp)!, incomingTraderID: order.traderID, incomingOrderID: order.orderID, incomingTimeStamp: order.timeStamp, tradePrice: (bookOrder?.price)!, tradeQuantity: (bookOrder?.quantity)!, side: order.side)
                        addTradeToBook(trade: trade)
                        removeOrder(order: bookOrder!)
                        remainder -= bookOrder!.quantity
                    }
                        // Remainder less than book order
                    else {
                        confirmTrade(bookOrder: bookOrder!, order: order)
                        var trade = Trade(restingTraderID: (bookOrder?.traderID)!, restingOrderID: (bookOrder?.orderID)!, restingTimeStamp: (bookOrder?.timeStamp)!, incomingTraderID: order.traderID, incomingOrderID: order.orderID, incomingTimeStamp: order.timeStamp, tradePrice: (bookOrder?.price)!, tradeQuantity: (bookOrder?.quantity)!, side: order.side)
                        addTradeToBook(trade: trade)
                        modifyOrder(order: bookOrder!, less: remainder)
                        break
                    }
                }
                else {
                    // have to make order a var or else it errors because it is "let constant"
                    var newBookOrder = order
                    newBookOrder.quantity = remainder
                    addOrderToBook(order: newBookOrder)
                    break
                }
            }
        }
    }
    
    func processOrder(order: Order) {
        traded = false
        addOrderToHistory(order: order)
        // If order type is "add"
        if order.type == 1 {
            // If order side is "buy"
            if order.side == 1 {
                // If price is greater than or equal to lowest ask book price (i.e. is marketable)
                if order.price >= askBook.prices[0] {
                    matchTrade(order: order)
                }
                else {
                    addOrderToBook(order: order)
                }
            }
                // Order is "sell"
            else {
                if order.price <= bidBook.prices[-1] {
                    matchTrade(order: order)
                }
                else {
                    addOrderToBook(order: order)
                }
            }
        }
            // order is not "cancel" or "modify"
        else {
            // order is "cancel"
            if order.type == 2 {
                let orderToCancel = lookUp[order.traderID]![order.orderID]
                removeOrder(order: orderToCancel!)
            }
                // order is "modify"
            else {
                let orderToModify = lookUp[order.traderID]![order.orderID]
                modifyOrder(order: orderToModify!, less: order.quantity)
            }
        }
    }
}

var bb = BidBook(prices: SortedArray<Int>(), orders: [:], numOrders: [:], priceSize: [:], orderIDs: [:])
var ab = AskBook(prices: SortedArray<Int>(), orders: [:], numOrders: [:], priceSize: [:], orderIDs: [:])
var tb = TradeBook(trades: [:])
var ob = OrderBook(bidbook: bb, askbook: ab, tradebook: tb)

var newOrder = Order(orderID: 1, traderID: 1000, timeStamp: 1, type: 1, quantity: 100, side: 1, price: 500)
ob.addOrderToBook(order: newOrder)

