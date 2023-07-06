import Foundation

enum Color {
    case red
    case black

    var symbol: String {
        switch self {
        case .black: return "■"
        case .red: return "□"
        }
    }
}

enum RedBlackTree<Element: Comparable> {
    case empty
    indirect case node(Color, Element, RedBlackTree<Element>, RedBlackTree<Element>)
}

// contain
extension RedBlackTree {
    func contains(_ value: Element) -> Bool {
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

// loop through
extension RedBlackTree {
    // l v r
    func forEach(handle: (_ element: Element) throws -> Void) rethrows {
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

// diagram display
extension RedBlackTree: CustomStringConvertible {
    var description: String {
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
    public mutating func inset(_ element: Element)->(inserted: Bool,memeberAfterInset:Element) {
        let (tree,old) = inserting(element)
        self = tree
        return (old == nil,old ?? element)
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

// insert
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

// balance
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

for i in (1..<20).shuffled() {
    set.inset(i)
}
print(set)
