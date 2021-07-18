import MetalKit


struct Point {
    var position: float3
    var momentum: float3
}

struct KDCell {
    var lowIndex: Int
    var highIndex: Int
}

extension KDCell: Equatable {
    static func == (lhs: KDCell, rhs: KDCell) -> Bool {
        return lhs.lowIndex == rhs.lowIndex &&
            lhs.highIndex == rhs.highIndex
    }
}

extension KDCell: Comparable {
    static func < (lhs: KDCell, rhs: KDCell) -> Bool {
        return lhs.lowIndex < rhs.lowIndex
    }
}

let SMALLEST_POINT:Point = Point(position: float3(-Float.greatestFiniteMagnitude,-Float.greatestFiniteMagnitude,0), momentum: float3(0,0,0))

class AVLNode<T: Comparable & Equatable> {
    var parent: AVLNode<T>?
    var left: AVLNode<T>?
    var right: AVLNode<T>?
    var balance: Int
    var height: Int
    var val: T

    init(_ inParent: AVLNode<T>?, _ inVal: T) {
        parent = inParent
        val = inVal
        left = nil
        right = nil
        balance = 0
        height = 0
    }

    func clear() {
        parent = nil
        left = nil
        right = nil
        balance = 0
        height = 0
    }

    func print() {
        if left != nil {
            left?.print()
        }

        Swift.print("val is \(val), and height is: \(height)")

        if right != nil {
            right?.print()
        }
    }
}

class AVLTree<T: Comparable & Equatable> {
    var root: AVLNode<T>?
    var nodeCount: Int

    init() {
        root = nil
        nodeCount = 0
    }

    func insert(_ newVal: T) {
        if !contains(root, newVal) {
            root = insert(root, newVal)
            nodeCount = nodeCount + 1
        }
    }

    func remove(_ remVal: T) {
        if root == nil {
            return
        }

//        Swift.print("===============================================")
//        Swift.print("remove \(remVal)")
//        Swift.print("root.val is: \(root!.val)")
        if contains(root, remVal) {

//            Swift.print("val exists, remove it")

            root = remove(&root, remVal)
            nodeCount = nodeCount - 1

//            Swift.print("===============================================")
        }

//        Swift.print("val NOT exists, no need to remove")
//        Swift.print("===============================================")
    }

    private func contains(_ node: AVLNode<T>?, _ val: T) -> Bool {
        if node == nil {
//            Swift.print("CASE 1: return FALSE check: \(val)")
            return false
        }
        if node!.val == val {
//            Swift.print("CASE 2: return TRUE check: \(val)")
            return true
        }
        if (node!.val < val && node?.left != nil) {
//            Swift.print("CASE 4: recurse contains check: \(val) against \(node!.val)")
            return contains(node?.right, val)
        } else if (node!.val > val && node?.right != nil) {
//            Swift.print("CASE 5: recurse contains check: \(val) against \(node!.val)")
            return contains(node?.left, val)
        }

//        Swift.print("CASE 6: return FALSE check: \(val)")
        return false
    }

    func update(_ node: AVLNode<T>?) {
        var leftHeight = -1
        var rightHeight = -1
        if node?.left != nil {
            leftHeight = node!.left!.height
        }
        if node?.right != nil {
            rightHeight = node!.right!.height
        }
        node?.height = 1 + max(leftHeight, rightHeight)
        node?.balance = rightHeight - leftHeight
    }

    private func leftRotate(_ node: AVLNode<T>?) -> AVLNode<T>? {
        let newRoot = node!.right
        node!.right = newRoot!.left
        newRoot!.left = node
        update(node)
        update(newRoot)
        return newRoot
    }

    private func rightRotate(_ node: AVLNode<T>?) -> AVLNode<T>? {
        let newRoot = node!.left
        node!.left = newRoot!.right
        newRoot!.right = node
        update(node)
        update(newRoot)
        return newRoot
    }

    private func leftLeftRebalance(_ node: AVLNode<T>?) -> AVLNode<T>? {
        return rightRotate(node)
    }

    private func leftRightRebalance(_ node: AVLNode<T>?) -> AVLNode<T>? {
        node!.left = leftRotate(node!.left)
        return leftLeftRebalance(node)
    }

    private func rightRightRebalance(_ node: AVLNode<T>?) -> AVLNode<T>? {
        return leftRotate(node)
    }

    private func rightLeftRebalance(_ node: AVLNode<T>?) -> AVLNode<T>? {
        node!.right = rightRotate(node!.right)
        return rightRightRebalance(node)
    }

    private func balance(_ node: AVLNode<T>?) -> AVLNode<T>? {
        if node?.balance == -2 {
            if node!.left!.balance <= 0 {
                return leftLeftRebalance(node)
            } else {
                return leftRightRebalance(node)
            }
        } else if node?.balance == 2 {
            if node!.right!.balance >= 0 {
                return rightRightRebalance(node)
            } else {
                return rightLeftRebalance(node)
            }
        }

        return node
    }

    private func insert(_ node: AVLNode<T>?, _ newVal: T) -> AVLNode<T>? {
        if node == nil {
            return AVLNode(node, newVal)
        } else if node!.val < newVal {
            node?.right = insert(node?.right, newVal)
        } else {
            node?.left = insert(node?.left, newVal)
        }

        update(node)

        return balance(node)
    }

    private func minVal(_ node: AVLNode<T>?) -> T {
        var min: AVLNode<T>? = node
        while(min?.left != nil) {
            min = min!.left
        }
        return min!.val;
    }

    private func maxVal(_ node: AVLNode<T>?) -> T {
        var max: AVLNode<T>? = node
        while(max?.right != nil) {
            max = max!.right
        }
        return max!.val;
    }

    private func remove(_ node: inout AVLNode<T>?, _ remVal: T) -> AVLNode<T>? {
        if node == nil {
            return nil
        } else if node!.val < remVal {
            node?.right = remove(&node!.right, remVal)
        } else if node!.val > remVal {
            node?.left = remove(&node!.left, remVal)
        } else {
            // Got it!  So now, let's remove it
            if node!.left == nil {
                let rightChild: AVLNode<T>? = node!.right
                node!.clear()
                node = nil
                return rightChild
            } else if node!.right == nil {
                let leftChild: AVLNode<T>? = node!.left
                node!.clear()
                node = nil
                return leftChild
            } else {
                if node!.left!.height > node!.right!.height {
                    let successorVal: T = maxVal(node!.left)
                    node!.val = successorVal
                    node!.left = remove(&node!.left, successorVal);
                } else {
                    let successorVal: T = minVal(node!.right)
                    node!.val = successorVal
                    node!.right = remove(&node!.right, successorVal);
                }
            }
        }

        update(node)

        return balance(node)
    }

    func print() {
        _print(root)
    }

    private func _print(_ node: AVLNode<T>?) {
        Swift.print("===============================================")
        Swift.print("print AVLTree")
        Swift.print("===============================================")
        node?.print()
        Swift.print("===============================================")
    }
}

class KDRange {
    var startIndex: Int
    var endIndex: Int
    var axis: String
    init(_ inStartIndex: Int, _ inEndIndex: Int, _ inAxis: String) {
        startIndex = inStartIndex
        endIndex = inEndIndex
        axis = inAxis
    }
    func printVals(_ inVals: inout [Int]) {
        for i in (startIndex...endIndex) {
//            print("kdrange \(i + 1 - startIndex) is: \(inVals[i])")
        }
    }
    func printAll(_ inVals: inout [Int]) {
        for i in (0...inVals.count - 1) {
//            print("kdrange \(i + 1) is: \(inVals[i])")
        }
    }
    func get(_ inVals: inout [Point], _ i: Int) -> Point {
        if (startIndex + i > endIndex) {
            return SMALLEST_POINT
        }
        return inVals[startIndex + i]
    }
    func set(_ inVals: inout [Point], _ i: Int, _ newVal: Point) {
        inVals[startIndex + i] = newVal
    }
    func setAxis(_ newAxis: String) {
        axis = newAxis
    }
    func setEndIndex(_ newEndIndex: Int) {
        endIndex = newEndIndex
    }
    func setStartIndex(_ newStartIndex: Int) {
        startIndex = newStartIndex
    }
    func getAxis() -> String {
        return axis
    }
    func getNextAxis() -> String {
        return axis == "X" ? "Y" : "X"
    }
    func getSize() -> Int {
        return endIndex - startIndex + 1
    }
    func getEndIndex() -> Int {
        return endIndex
    }
    func getStartIndex() -> Int {
        return startIndex
    }
    func getMid() -> Int {
        return startIndex + (endIndex - startIndex + 1) / 2
    }
    func getLeft(_ index: Int) -> Int {
        let i = index + 1
        return 2 * i - 1
    }
    func getRight(_ i: Int) -> Int {
        return getLeft(i) + 1
    }
    func getAbsoluteIndex(_ i: Int) -> Int {
        return i + startIndex
    }
    func greaterThan(_ inVals: inout [Point], _ lhs: Int, _ rhs: Int) -> Bool {
        let left = get(&inVals, lhs)
        let right = get(&inVals, rhs)
        if (axis == "X") {
            return left.position.x > right.position.x
        }
        return left.position.y > right.position.y
    }
    func heapify(_ inVals: inout [Point], _ index: Int) {
        let heapSize = getSize()
        let cur = index
        let left = getLeft(index)
        let right = getRight(index)

        var largest = cur

        if (left < heapSize && greaterThan(&inVals, left, cur)) {
            largest = left
        }
        if (left < heapSize && greaterThan(&inVals, right, largest)) {
            largest = right
        }

        if (largest != cur) {
            // swap
            let copy = get(&inVals, largest)
            set(&inVals, largest, get(&inVals, cur))
            set(&inVals, cur, copy)

            heapify(&inVals, largest)
        }
    }
    func createHeap(_ inVals: inout [Point]) {
        let mid = getMid()
        for i in (1...mid).reversed() {
            heapify(&inVals, i - 1)
        }
    }
    func sort(_ inVals: inout [Point]) {
        createHeap(&inVals)

        let m:KDRange = KDRange(startIndex, endIndex, axis)

        for i in (1...getSize() - 1).reversed() {
            let copy = get(&inVals, i)
            set(&inVals, i, get(&inVals, 0))
            set(&inVals, 0, copy)
            m.setEndIndex(m.endIndex - 1)
            m.heapify(&inVals, 0)
        }
    }
}
