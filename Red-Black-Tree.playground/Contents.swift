import Foundation

public enum Color {
    case red
    case black

    var symbol: String {
        switch self {
        case .black: return "■"
        case .red: return "□"
        }
    }
}

public enum RedBlackTree<Element: Comparable> {
    case empty
    indirect case node(Color, Element, RedBlackTree<Element>, RedBlackTree<Element>)
}

/// contain
extension RedBlackTree {
    public func contains(_ value: Element) -> Bool {
        switch self {
        case .empty:
            return false
        case .node(_, value, _, _):
            return true
        case let .node(_, element, leftNode, _) where element > value:
            return leftNode.contains(value)
        case let .node(_, _, _, rightNode):
            return rightNode.contains(value)
        }
    }
}

/// loop through
extension RedBlackTree {
    // l v r
    public func forEach(handle: (_ element: Element) throws -> Void) rethrows {
        switch self {
        case .empty:
            break
        case let .node(_, value, leftNode, rightNode):
            try leftNode.forEach(handle: handle)
            try handle(value)
            try rightNode.forEach(handle: handle)
        }
    }
}

/// diagram display
extension RedBlackTree: CustomStringConvertible {
    public var description: String {
        return diagram("", "", "")
    }

    // 能大概看懂
    func diagram(_ top: String,
                 _ root: String,
                 _ bottom: String) -> String {
        switch self { case .empty:
            return root + "•\n"
        case let .node(color, value, .empty, .empty):
            return root + "\(color.symbol) \(value)\n"
        case let .node(color, value, left, right):
            return right.diagram(top + "    ", top + "┌───", top + "│   ")
                + root + "\(color.symbol) \(value)\n"
                + left.diagram(bottom + "│   ", bottom + "└───", bottom + "    ")
        }
    }
}

extension RedBlackTree {
    @discardableResult
    public mutating func inset(_ element: Element) -> (inserted: Bool, memeberAfterInset: Element) {
        let (tree, old) = inserting(element)
        self = tree
        return (old == nil, old ?? element)
    }
}

extension RedBlackTree {
    public func inserting(_ element: Element) -> (tree: RedBlackTree, existingMember: Element?) {
        let (tree, old) = _inserting(element)
        switch tree {
        case let .node(.red, value, left, right):
            return (.node(.black, value, left, right), old) // 将头节点染黑
        default:
            return (tree, old)
        }
    }
}

/// insert
extension RedBlackTree {
    func _inserting(_ element: Element) -> (tree: RedBlackTree, old: Element?) {
        switch self {
        case .empty:
            return (.node(.red, element, .empty, .empty), nil) // 违反第一条-在上层函数中fix
        case let .node(_, value, _, _) where value == element:
            return (self, element) // 如存在则返回自身
        case let .node(color, value, left, right) where value > element:
            let (l, old) = left._inserting(element)
            if let old = old {
                return (self, old)
            }
            // handle balance
            return (balanced(color, value: value, left: l, right: right), nil)
        case let .node(color, value, left, right):
            let (r, old) = right._inserting(element)
            if let old = old {
                return (self, old)
            }
            // handle balance
            return (balanced(color, value: value, left: left, right: r), nil)
        }
    }
}

/// balance
extension RedBlackTree {
    func balanced(_ color: Color, value: Element, left: RedBlackTree, right: RedBlackTree) -> RedBlackTree {
        switch (color, value, left, right) {
        case let (.black, z, .node(.red, y, .node(.red, x, a, b), c), d),
             let (.black, z, .node(.red, x, a, .node(.red, y, b, c)), d),
             let (.black, x, a, .node(.red, z, .node(.red, y, b, c), d)),
             let (.black, x, a, .node(.red, y, b, .node(.red, z, c, d))):
            return .node(.red, y, .node(.black, x, a, b), .node(.black, z, c, d))
        default:
            return .node(color, value, left, right)
        }
    }
}

// test
var set = RedBlackTree<Int>.empty

for i in (1 ..< 20).shuffled() {
    set.inset(i)
}

print(set)

/// Index
extension RedBlackTree {
    public struct Index {
        fileprivate var value: Element? // filePrivate
    }
}
/// Comparable
extension RedBlackTree.Index: Comparable {
    public static func < (lhs: RedBlackTree<Element>.Index, rhs: RedBlackTree<Element>.Index) -> Bool {
        if let l = lhs.value,
           let r = rhs.value {
            return l < r
        }
        // left nil / right nil / both nil
        /// 保证结束索引最大
        return lhs.value != nil
    }
    
    public static func == (lhs: RedBlackTree<Element>.Index,
                           rhs: RedBlackTree<Element>.Index) -> Bool { // equal
        return lhs.value == rhs.value
    }
}
/// min max
extension RedBlackTree {
    // log N collection 协议要求在常数事件内完成 -- 缓存
    public func min()->Element? {
        switch self {
        case .empty:
            return nil
        case let .node(_, value, left, _):
            return left.min() ?? value // 够优雅
        }
    /*
     case .node(_, let value, .empty, _):
         return value
     case .node(_, _, let left, _):
         return left.min()
     }
     */
    }
    
    public func max()->Element? {
        var dummy = self
        var max: Element?
        while case let .node(_,value,_,right) = dummy {
            max = value
            dummy = right
        }
        return max
    }
    
}
/// Collection
extension RedBlackTree: Collection {

    
    public var startIndex: Index {Index.init(value: min())}
    public var endIndex: Index {Index.init(value: nil)}
    
    public subscript(i: Index) ->Element {
        return i.value! //
    }
    
    public func index(after i: Index) -> Index {
        let v = self.value(following: i.value!)
        precondition(v.found)
        return Index(value: v.next)
    }
    
}

// before & after
extension RedBlackTree {
    func value(following element: Element)->(found: Bool,next: Element?) {
        switch self {
        case .empty:
            return (false,nil) // non match
        case .node(_, element, _,let right): // value match
            return (true,right.min())
        case let .node(_, value, left, _) where value > element:
            let v = left.value(following: element)
            return (v.found,v.next ?? value)
        case let .node(_, _, _, right):
            return right.value(following: element)
        }
    }
    
    func value(preceding element: Element)->(found: Bool,next: Element?) {
        var node = self
        var previous: Element? = nil
        while case let .node(_,value,left,right) = node {
            if value > element {
                node = left
            } else if value < element {
                previous = value
                node = right
            } else {
                return (true,left.max() ?? previous)
            }
        }
        return (false,previous)
    }
}

//它的默认实现将会计算 startIndex 和 endIndex 之间的步数， 这样 O(n log n) 比起我们的 O(n) 会慢得多。但是我们的实现也并没有什么值得宣扬的:它仍 然需要访问树中每一个节点。
extension RedBlackTree {
    public init() {
        self = .empty
    }
    
    //O(n) 默认实现会从startIndex 到 endIndex 是O(nlogn)
    public var count: Int {
        switch self {
        case .empty:
            return 0
        case .node(_, _, let left, let right ):
            return (left.count + 1 + right.count)
        }
    }
}


// 目前没有删除操作---与删除后平衡树的操作
