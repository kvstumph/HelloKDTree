import MetalKit
import Accelerate


import Metal
import QuartzCore
import Darwin

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

let k: Int = 10
let n: Int = 320
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
        
        Swift.print("===============================================")
        Swift.print("remove \(remVal)")
        Swift.print("root.val is: \(root!.val)")
        if contains(root, remVal) {
            
            Swift.print("val exists, remove it")
            
            root = remove(&root, remVal)
            nodeCount = nodeCount - 1
            
            Swift.print("===============================================")
        }
        
        Swift.print("val NOT exists, no need to remove")
        Swift.print("===============================================")
    }
    
    private func contains(_ node: AVLNode<T>?, _ val: T) -> Bool {
        if node == nil {
            Swift.print("CASE 1: return FALSE check: \(val)")
            return false
        }
        if node!.val == val {
            Swift.print("CASE 2: return TRUE check: \(val)")
            return true
        }
        if (node!.val < val && node?.left != nil) {
            Swift.print("CASE 4: recurse contains check: \(val) against \(node!.val)")
            return contains(node?.right, val)
        } else if (node!.val > val && node?.right != nil) {
            Swift.print("CASE 5: recurse contains check: \(val) against \(node!.val)")
            return contains(node?.left, val)
        }
        
        Swift.print("CASE 6: return FALSE check: \(val)")
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

//class AVLTree<T : Comparable & Equatable> {
//    var val: T?
//    // negative = left is longer
//    // equal = fully balanced
//    // positive = right is longer
//    var balance: Int
//    var parent: AVLTree<T>?
//    var left: AVLTree<T>?
//    var right: AVLTree<T>?
//
//    init(_ inParent: AVLTree<T>?) {
//        val = nil
//        parent = inParent
//        left = nil
//        right = nil
//        balance = 0
//    }
//
//    func getVal() -> T? {
//        return val
//    }
//
//    func setVal(_ inVal: T) {
//        val = inVal
//    }
//
//    func getBalance() -> Int {
//        return balance
//    }
//
//    func setBalance(_ inBalance: Int) {
//        balance = inBalance
//    }
//
//    func rebalanceParent(_ child: AVLTree<T>) {
//        if (child.getVal() == self.left?.getVal()) {
//            balance += 1
//        } else if (child.getVal() == self.right?.getVal()) {
//            balance -= 1
//        }
//        if (parent != nil) {
//            parent?.rebalanceParent(self)
//        }
//    }
//
//    func rebalance(_ grandchild: AVLTree<T>) {
//        if abs(balance) > 1 {
//            let child = grandchild.parent
//
//            // LEFT LEFT
//            if (child?.getVal() == left?.getVal() && left?.left?.getVal() == grandchild.getVal()) {
//                let parentCopy: AVLTree<T>? = self.parent
//
//                child?.parent = parentCopy
//
//                if (parentCopy != nil) {
//                    if (val == parentCopy?.left?.getVal()) {
//                        parentCopy?.left = child
//                    } else if (val == parentCopy?.right?.getVal()) {
//                        parentCopy?.right = child
//                    }
//                }
//
//                self.left = child?.right
//                child?.right?.parent = self
//
//                child?.right = self
//                self.parent = child
//
//                // Reset balance numbers
//                child!.setBalance(child!.getBalance() + 1)
//                balance += 2
//                parentCopy?.rebalanceParent(child!)
//
//            // LEFT RIGHT
//            } else if (child?.getVal() == left?.getVal() && left?.right?.getVal() == grandchild.getVal()) {
//                let parentCopy: AVLTree<T>? = self.parent
//
//                grandchild.parent = parentCopy
//
//                if (parentCopy != nil) {
//                    if (val == parentCopy?.left?.getVal()) {
//                        parentCopy?.left = grandchild
//                    } else if (val == parentCopy?.right?.getVal()) {
//                        parentCopy?.right = grandchild
//                    }
//                }
//
//                self.left = grandchild.right
//                grandchild.right?.parent = self
//
//                grandchild.right = self
//                self.parent = grandchild
//
//                child?.right = grandchild.left
//                grandchild.left?.parent = child
//
//                grandchild.left = child
//                child?.parent = grandchild
//
//                // Reset balance numbers
//                child!.setBalance(child!.getBalance() - 1)
//                grandchild.setBalance(balance + 2)
//                balance += 2 // Not certain on this one???  Could be a bug
//                parentCopy?.rebalanceParent(grandchild)
//
//            // RIGHT RIGHT
//            } else if (child?.getVal() == right?.getVal() && right?.right?.getVal() == grandchild.getVal()) {
//                let parentCopy: AVLTree<T>? = self.parent
//
//                child?.parent = parentCopy
//
//                if (parentCopy != nil) {
//                    if (val == parentCopy?.left?.getVal()) {
//                        parentCopy?.left = child
//                    } else if (val == parentCopy?.right?.getVal()) {
//                        parentCopy?.right = child
//                    }
//                }
//
//                self.right = child?.left
//                child?.left?.parent = self
//
//                child?.left = self
//                self.parent = child
//
//                // Reset balance numbers
//                child!.setBalance(child!.getBalance() - 1)
//                balance -= 2
//                parentCopy?.rebalanceParent(child!)
//
//            // RIGHT LEFT
//            } else if (child?.getVal() == right?.getVal() && right?.left?.getVal() == grandchild.getVal()) {
//                let parentCopy: AVLTree<T>? = self.parent
//
//                grandchild.parent = parentCopy
//
//                if (parentCopy != nil) {
//                    if (val == parentCopy?.left?.getVal()) {
//                        parentCopy?.left = grandchild
//                    } else if (val == parentCopy?.right?.getVal()) {
//                        parentCopy?.right = grandchild
//                    }
//                }
//
//                self.right = grandchild.left
//                grandchild.left?.parent = self
//
//                grandchild.left = self
//                self.parent = grandchild
//
//                child?.left = grandchild.right
//                grandchild.right?.parent = child
//
//                grandchild.right = child
//                child?.parent = grandchild
//
//                // Reset balance numbers
//                child!.setBalance(child!.getBalance() + 1)
//                grandchild.setBalance(balance - 2)
//                balance -= 2 // Not certain on this one???  Could be a bug
//                parentCopy?.rebalanceParent(grandchild)
//            }
//        } else if (parent != nil) {
//            parent?.rebalance(grandchild.parent!)
//        }
//    }
//
//    func insert(_ newVal: T) {
//        // Before calling insert make sure you are at the root.
//        if (parent == nil) {
//            _insert(newVal)
//        } else {
//            parent?.insert(newVal)
//        }
//    }
//
//    func _insert(_ newVal: T) {
//        if (val == nil) {
//            val = newVal
//            balance = 0
//            if let v = val {
//                Swift.print("insert val is: \(v)")
//            } else {
//                Swift.print("insert val is empty")
//            }
//        } else if (newVal > val!) {
//            balance += 1
//            if (right == nil) {
//                right = AVLTree(self)
//                right?.setVal(newVal)
//
//                if (newVal as! Int == 24) {
//                    Swift.print("=================INSERT: BEGIN RIGHT ============")
//                    print()
//                    Swift.print("=================INSERT: BEGIN RIGHT END ============")
//                }
//
//                parent?.rebalance(right!)
//
//                if (newVal as! Int == 24) {
//                    Swift.print("=================INSERT: AFTER RIGHT ============")
//                    print()
//                    Swift.print("=================INSERT: AFTER RIGHT END ============")
//                }
//            } else {
//                right?._insert(newVal)
//            }
//        } else {
//            balance -= 1
//            if (left == nil) {
//                left = AVLTree(self)
//                left?.setVal(newVal)
//
//                if (newVal as! Int == 24) {
//                    Swift.print("=================INSERT: BEGIN LEFT ============")
//                    print()
//                    Swift.print("=================INSERT: BEGIN LEFT END ============")
//                }
//
//                parent?.rebalance(left!)
//
//                if (newVal as! Int == 24) {
//                    Swift.print("=================INSERT: AFTER RIGHT ============")
//                    print()
//                    Swift.print("=================INSERT: AFTER RIGHT END ============")
//                }
//            } else {
//                left?._insert(newVal)
//            }
//        }
//    }
//
//    func print() {
//        // Before calling print make sure you are at the root.
//        if (parent == nil) {
//            _print()
//        } else {
//            parent?.print()
//        }
//    }
//
//    func _print() {
//        if left != nil {
//            left?._print()
//        }
//        if let v = val {
//            if (parent == nil) {
//                Swift.print("val is: \(v), with balance of: \(balance)  <===")
//            } else {
//                Swift.print("val is: \(v), with balance of: \(balance)")
//            }
//        } else {
//            Swift.print("val is empty")
//        }
//        if right != nil {
//            right?._print()
//        }
//    }
//}

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
            print("kdrange \(i + 1 - startIndex) is: \(inVals[i])")
        }
    }
    func printAll(_ inVals: inout [Int]) {
        for i in (0...inVals.count - 1) {
            print("kdrange \(i + 1) is: \(inVals[i])")
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

class PointView: MTKView {
    
    var commandQueue: MTLCommandQueue!
    
    var renderPipelineState: MTLRenderPipelineState!
    var beadRenderPipelineState: MTLRenderPipelineState!
    var boundaryRenderPipelineState: MTLRenderPipelineState!
    var yellowLinesRenderPipelineState: MTLRenderPipelineState!
    
    var kdTreeLines: [float3] = []
    var kdCells: [KDCell] = []
    var kdCellAVLTree: AVLTree<KDCell> = AVLTree()
    var cutLines: [Float] = []
    
//    beadPointer.storeBytes<Point>(of: Point(position: float3(Float.randPosition(),Float.randPosition(),0), momentum: Float.randMomentum()), as: Point.self)
    
    var beads: [Point] = []
    
//    var xvector:UnsafeMutablePointer = nil
//    var beads: UnsafeMutablePointer<Point>? = nil
//    var alignment:UInt = 0x4000
////    var xvectorByteSize:UInt = UInt(10)*UInt(sizeof(Float))
////    let uint8Pointer = UnsafeMutablePointer<Point>.allocate(capacity: 8)
////    // actual allocation with alignment
//    posix_memalign(&beads, alignment, xvectorByteSize)
//    uint8Pointer.initialize(from: &bytes, count: 8)
    
    let boundaryLines: [float3] = [
        // Top
        float3(-0.5,0.5,0),
        float3(0.5,0.5,0),
        
        // Left
        float3(-0.5,0.5,0),
        float3(-0.5,-0.5,0),
        
        // Right
        float3(0.5,0.5,0),
        float3(0.5,-0.5,0),

        // Bottom
        float3(-0.5,-0.5,0),
        float3(0.5,-0.5,0)
    ]
    
    let voronoiLines: [float3] = [
        float3(0,0,0),
        float3(0,0,0),
        
        float3(0,0,0),
        float3(0,0,0),
        
        float3(0,0,0),
        float3(0,0,0)
    ]
    
    var vertexBuffer: MTLBuffer!
    var beadVertexBuffer: MTLBuffer!
    var voronoiBuffer: MTLBuffer!
    var kdCellBuffer: MTLBuffer!
    var boundaryLinesBuffer: MTLBuffer!
    var kdTreeLinesBuffer: MTLBuffer!
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
        
        self.device = MTLCreateSystemDefaultDevice()
        
        self.clearColor = MTLClearColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
        
        self.colorPixelFormat = .bgra8Unorm
        
        self.commandQueue = device?.makeCommandQueue()
        
        createBeads()
        
        createRenderPipelineState()
        
        createBuffers()
        
        createKDTree()
        
//        createBinaryTree()
        
        createAVLTree()
        
        beadPointerTest()
    }
    
    let rawBeadPointer = UnsafeMutableRawPointer.allocate(
        byteCount: 3 * MemoryLayout<Point>.stride,
        alignment: 0x4000)
    
    func beadPointerTest() {
        let p1: Point = Point(position: float3(0.3,0.3,0), momentum: float3(0.3,0.3,0))
        let p2: Point = Point(position: float3(0.9,0.9,0), momentum: float3(0.9,0.9,0))
        let p3: Point = Point(position: float3(0.6,0.6,0), momentum: float3(0.6,0.6,0))
        
        rawBeadPointer.storeBytes(of: p1, toByteOffset: 0, as: Point.self)
        rawBeadPointer.storeBytes(of: p2, toByteOffset: MemoryLayout<Point>.stride, as: Point.self)
        rawBeadPointer.storeBytes(of: p3, toByteOffset: 2 * MemoryLayout<Point>.stride, as: Point.self)
        
        let typedPointer = rawBeadPointer.bindMemory(to: Point.self, capacity: 3)
        
        let beforeBufferPointer = UnsafeBufferPointer(start: typedPointer, count: 3)
        for (index, value) in beforeBufferPointer.enumerated() {
            print("BEFORE value \(index): \(value)")
        }
        
        // TODO: Create UnsafeKDRange
        
//        var pointArray: [Point] = Array(UnsafeMutableBufferPointer(start: typedPointer, count: 3))
//
//        let sorter:KDRange = KDRange(0, 2, "Y")
//        sorter.sort(&pointArray)
//
////        for (index, value) in pointArray.enumerated() {
////            print("AFTER value \(index): \(value)")
////        }
//
//        let afterBufferPointer = UnsafeBufferPointer(start: typedPointer, count: 3)
//        for (index, value) in afterBufferPointer.enumerated() {
//            print("AFTER value \(index): \(value)")
//        }
    }
    
    func createAVLTree() {
        let avl: AVLTree<KDCell> = AVLTree()
        avl.insert(KDCell(lowIndex: 1, highIndex: 101))
        avl.insert(KDCell(lowIndex: 2, highIndex: 99))
        avl.insert(KDCell(lowIndex: 4, highIndex: 102))
        avl.insert(KDCell(lowIndex: 8, highIndex: 98))
        avl.insert(KDCell(lowIndex: 16, highIndex: 103))
        avl.insert(KDCell(lowIndex: 32, highIndex: 97))
        avl.insert(KDCell(lowIndex: 24, highIndex: 104))
        avl.remove(KDCell(lowIndex: 8, highIndex: 98))
        avl.print()
        
//        let avl: AVLTree<Int> = AVLTree()
//        avl.insert(1)
//        avl.insert(2)
//        avl.insert(4)
//        avl.insert(8)
//        avl.insert(16)
//        avl.insert(32)
//        avl.insert(24)
//        avl.remove(8)
//        avl.print()
    }
    
//    func createBinaryTree() {
//        // RIGHT RIGHT test
////        let avl: AVLTree<Int> = AVLTree(nil)
////        avl.insert(1)
////        avl.insert(2)
////        avl.insert(4)
////        avl.insert(8)
////        avl.insert(16)
////        avl.insert(32)
////        avl.insert(24)
////        avl.print()
//
//        // LEFT LEFT test
//        let avl: AVLTree<Int> = AVLTree(nil)
//        avl.insert(32)
//        avl.insert(16)
//        avl.insert(8)
//        avl.insert(4)
//        avl.insert(3)
//        avl.insert(1)
//        avl.insert(2)
//        avl.print()
//    }
    
    func createBeads() {
        
//        for _ in (0...2) {
////            let n: Int = 320
//            let p: Point = Point(position: float3(Float.randPosition(),Float.randPosition(),0), momentum: Float.randMomentum())
//            beadPointer()
//        }
        
        for _ in (1...n) {
            beads.append(Point(position: float3(Float.randPosition(),Float.randPosition(),0), momentum: Float.randMomentum()))
        }
    }
    
    func createBuffers() {
        beadVertexBuffer = device?.makeBuffer(bytes: beads, length: MemoryLayout<Point>.stride * beads.count, options: [])
//        beadVertexBuffer = device?.makeBuffer(bytesNoCopy: beads, length: MemoryLayout<Point>.stride * beads.count, options: [], deallocator: nil)
//        beadVertexBuffer = device?.makeBuffer(bytesNoCopy: *beads, length: MemoryLayout<Point>.stride * beads.count, options: [], deallocator: nil)
        voronoiBuffer = device?.makeBuffer(bytes: voronoiLines, length: MemoryLayout<float3>.stride * voronoiLines.count, options: [])
        boundaryLinesBuffer = device?.makeBuffer(bytes: boundaryLines, length: MemoryLayout<float3>.stride * boundaryLines.count, options: [])
    }
    
    func kdTreeCut(_ m: KDRange, _ bounds: [Float], _ depth: Int) {
        print("===============================================")
        print("depth: \(depth), m.startIndex is \(m.getStartIndex())")
        print("depth: \(depth), m.endIndex is \(m.getEndIndex())")
        print("depth: \(depth), mid is \(m.getMid())")
        print("depth: \(depth), region contains \(m.getEndIndex() - m.getStartIndex() + 1)")
        print("===============================================")
        for (index, element) in beads.enumerated() {
            print("x,y \(index) is: \(element.position.x),\(element.position.y)")
        }
        
        let midIndex = m.getMid()
        
        kdCellAVLTree.remove(KDCell(lowIndex: m.getStartIndex(), highIndex: m.getEndIndex()))
        kdCellAVLTree.insert(KDCell(lowIndex: m.getStartIndex(), highIndex: m.getMid() - 1))
        kdCellAVLTree.insert(KDCell(lowIndex: m.getMid(), highIndex: m.getEndIndex()))
        
        let cut = m.getAxis() == "X" ?
            (beads[midIndex - 1].position.x + beads[midIndex].position.x) / 2 :
            (beads[midIndex - 1].position.y + beads[midIndex].position.y) / 2
        print("===============================================")
        print("\(m.getAxis()) cut is: \(cut)")
        
        cutLines.append(cut)
        
        if (m.getAxis() == "X") {
            kdTreeLines.append(float3(cut, bounds[0], 0))
            kdTreeLines.append(float3(cut, bounds[2], 0))
        } else {
            kdTreeLines.append(float3(bounds[1], cut, 0))
            kdTreeLines.append(float3(bounds[3], cut, 0))
        }
        
        // TODO: to make computation easier, do not cut one side, unless both sides can be cut.
        if (((m.getMid() - 1) - m.getStartIndex() > k) && (m.getEndIndex() - m.getMid() > k)) {
            if (m.getMid() - 1) - m.getStartIndex() > k {
                print("KVS: Checktpoint 1")
                let below:KDRange = KDRange(m.getStartIndex(), m.getMid() - 1, m.getNextAxis())
                below.sort(&beads)

                let cell: [Float]
                if (m.axis == "X") {
                    cell = [bounds[0], cut, bounds[2], bounds[3]]
                } else {
                    cell = [cut, bounds[1], bounds[2], bounds[3]]
                }

//                let kdCell: KDCell = KDCell(lowIndex: m.getStartIndex(), highIndex: m.getMid() - 1)
//                kdCells.append(kdCell)
//                kdCellAVLTree.insert(kdCell)
                
                print("===============================================")
                for (index, element) in beads.enumerated() {
                    if (index >= m.getStartIndex() && index <= (m.getMid() - 1)) {
                        print("BELOW SORT: x,y \(index) is: \(element.position.x),\(element.position.y)")
                    } else {
                        print("x,y \(index) is: \(element.position.x),\(element.position.y)")
                    }
                }

                kdTreeCut(below, cell, depth + 1)
            }
            if m.getEndIndex() - m.getMid() > k {
                print("KVS: Checktpoint 2")
                let above:KDRange = KDRange(m.getMid(), m.getEndIndex(), m.getNextAxis())
                // above.sort(&a)
                above.sort(&beads)

                let cell: [Float]
                if (m.axis == "X") {
                    cell = [bounds[0], bounds[1], bounds[2], cut]
                } else {
                    cell = [bounds[0], bounds[1], cut, bounds[3]]
                }
                
//                let kdCell: KDCell = KDCell(lowIndex: m.getMid(), highIndex: m.getEndIndex())
//                kdCells.append(kdCell)
//                kdCellAVLTree.insert(kdCell)
                
                print("===============================================")
                for (index, element) in beads.enumerated() {
                    if (index >= m.getMid() && index <= m.getEndIndex()) {
                        print("ABOVE SORT: x,y \(index) is: \(element.position.x),\(element.position.y)")
                    } else {
                        print("x,y \(index) is: \(element.position.x),\(element.position.y)")
                    }
                }

                kdTreeCut(above, cell, depth + 1)
            }
        }
    }
    
    func createKDTree() {
        let m:KDRange = KDRange(0, beads.count - 1, "X")
        m.sort(&beads)
        
        print("===============================================")
        for (i, point) in beads.enumerated() {
            print("a: \(i) is: \(point.position.x)")
        }
        
        kdTreeCut(m, [0.5, 0.5, -0.5, -0.5], 0)
        kdTreeLinesBuffer = device?.makeBuffer(bytes: kdTreeLines, length: MemoryLayout<float3>.stride * kdTreeLines.count, options: [])
        
         if (kdCells.count == 0) {
            print("KVS: kdcells.count is ZERO")
            kdCellAVLTree.print()
            
            //////////////////////////////////////////////////
            
            // 57 : k = 4
            //
            // 3,4 : 6
            // 3,4 : 13
            // 3,4 : 20
            // 3,4 : 27
            // 3,4 : 34
            // 3,4 : 41
            // 3,4 : 48
            // 4,4 : 56
            
            //////////////////////////////////////////////////
            
            // 58 : k = 4
            //
            // 3,4 : 6
            // 3,4 : 13
            // 3,4 : 20
            // 4,4: 28
            // 3,4: 35
            // 3,4: 42
            // 3,4: 49
            // 4,4: 57
            
            //////////////////////////////////////////////////
            
            // 59 : k = 4
            //
            // 3,4: 6
            // 3,4: 13
            // 3,4: 20
            // 4,4: 28
            // 3,4: 35
            // 4,4: 43
            // 3,4: 50
            // 4,4: 58
            
            //////////////////////////////////////////////////
            
            // 60 : k = 4
            //
            // 3,4: 6
            // 4,4: 14
            // 3,4: 14
            // 4,4: 29
            // 3,4: 36
            // 4,4: 44
            // 3,4: 51
            // 4,4: 59
            
            //////////////////////////////////////////////////
            
            // 64 : k = 4
            //
            // 4,4: 7
            // 4,4: 15
            // 4,4: 23
            // 4,4: 31
            // 4,4: 39
            // 4,4: 47
            // 4,4: 55
            // 4,4: 63
        }
        
//        kdCellBuffer = device?.makeBuffer(bytes: kdCells, length: MemoryLayout<KDCell>.stride * kdCells.count, options: [])
    }
    
    func createRenderPipelineState() {
        // Create renderPipelineState 1
        let library = device?.makeDefaultLibrary()
        let vertexFunction = library?.makeFunction(name: "basic_vertex_shader")
        let fragmentFunction = library?.makeFunction(name: "basic_fragment_shader")
        
        let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
        renderPipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        renderPipelineDescriptor.vertexFunction = vertexFunction
        renderPipelineDescriptor.fragmentFunction = fragmentFunction
        
        do {
            renderPipelineState = try device?.makeRenderPipelineState(descriptor: renderPipelineDescriptor)
        } catch let error as NSError {
            print(error)
        }
        
        // Create beadRenderPipelineState
        let beadVertexFunction = library?.makeFunction(name: "bead_vertex_shader")
        let beadFragmentFunction = library?.makeFunction(name: "bead_fragment_shader")
        
        let beadRenderPipelineDescriptor = MTLRenderPipelineDescriptor()
        beadRenderPipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        beadRenderPipelineDescriptor.vertexFunction = beadVertexFunction
        beadRenderPipelineDescriptor.fragmentFunction = beadFragmentFunction
        
        do {
            beadRenderPipelineState = try device?.makeRenderPipelineState(descriptor: beadRenderPipelineDescriptor)
        } catch let error as NSError {
            print(error)
        }
        
        // Create boundaryRenderPipelineState
        let linesVertexFunction = library?.makeFunction(name: "line_vertex_shader")
        let boundaryFragmentFunction = library?.makeFunction(name: "boundary_fragment_shader")
        
        let boundaryRenderPipelineDescriptor = MTLRenderPipelineDescriptor()
        boundaryRenderPipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        boundaryRenderPipelineDescriptor.vertexFunction = linesVertexFunction
        boundaryRenderPipelineDescriptor.fragmentFunction = boundaryFragmentFunction
        
        do {
            boundaryRenderPipelineState = try device?.makeRenderPipelineState(descriptor: boundaryRenderPipelineDescriptor)
        } catch let error as NSError {
            print(error)
        }
        
        // Create yelloLinesRenderPipelineState
        let yellowLinesVertexFunction = library?.makeFunction(name: "line_vertex_shader")
        let yellowFragmentFunction = library?.makeFunction(name: "yellow_fragment_shader")
        
        let yellowLinesRenderPipelineDescriptor = MTLRenderPipelineDescriptor()
        yellowLinesRenderPipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        yellowLinesRenderPipelineDescriptor.vertexFunction = yellowLinesVertexFunction
        yellowLinesRenderPipelineDescriptor.fragmentFunction = yellowFragmentFunction
        
        do {
            yellowLinesRenderPipelineState = try device?.makeRenderPipelineState(descriptor: yellowLinesRenderPipelineDescriptor)
        } catch let error as NSError {
            print(error)
        }
    }
    
    var time: Float = 0.0
    let deltaTime: Float = 1 / Float(60.0)
    var delta: Float = 0
    override func draw(_ dirtyRect: NSRect) {
        time += deltaTime
        delta = cos(time)
        
        guard let drawable = self.currentDrawable, let renderPassDescriptor = self.currentRenderPassDescriptor else { return }
        
        let commandBuffer = commandQueue.makeCommandBuffer()
        
        let renderCommandEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        
        renderCommandEncoder?.pushDebugGroup("Beads")
        renderCommandEncoder?.setRenderPipelineState(beadRenderPipelineState)
        renderCommandEncoder?.setVertexBuffer(beadVertexBuffer, offset: 0, index: 1)
        renderCommandEncoder?.setVertexBuffer(voronoiBuffer, offset: 0, index: 4)
        renderCommandEncoder?.drawPrimitives(type: .point, vertexStart: 0, vertexCount: beads.count, instanceCount: 1)
        renderCommandEncoder?.popDebugGroup()
        
        renderCommandEncoder?.pushDebugGroup("Boundary lines")
        renderCommandEncoder?.setRenderPipelineState(boundaryRenderPipelineState)
        renderCommandEncoder?.setVertexBuffer(boundaryLinesBuffer, offset: 0, index: 1)
        renderCommandEncoder?.drawPrimitives(type: .line, vertexStart: 0, vertexCount: boundaryLines.count, instanceCount: 1)
        renderCommandEncoder?.popDebugGroup()
        
        renderCommandEncoder?.pushDebugGroup("KDTree lines")
        renderCommandEncoder?.setRenderPipelineState(yellowLinesRenderPipelineState)
        renderCommandEncoder?.setVertexBuffer(kdTreeLinesBuffer, offset: 0, index: 1)
        renderCommandEncoder?.drawPrimitives(type: .line, vertexStart: 0, vertexCount: kdTreeLines.count, instanceCount: 1)
        renderCommandEncoder?.popDebugGroup()
        
        renderCommandEncoder?.endEncoding()
        commandBuffer?.present(drawable)
        commandBuffer?.commit()
    }
}
