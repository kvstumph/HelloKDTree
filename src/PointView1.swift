import MetalKit
import Accelerate
import Metal
import QuartzCore
import Darwin


class PointView1: MTKView {
    
    // --------------------------------------------
    // CONFIG:
    //     TODO: this should come from file
    // --------------------------------------------
    let k: Int = 4
    let n: Int = 8
    let ADD_MOTION: Bool = true
    let SHOW_KDTREE_LINES: Bool = true
    let COMPUTE_VORONOI: Bool = false

    let TOTAL_SLICES: Int = 128
    var CURRENT_SLICE: Int = 1
    var CURRENT_SLICE_COUNT: Int = 0
    var SLICE_EXPAND: Bool = true
    
    // --------------------------------------------
    
    struct Vertex {
        var position: SIMD3<Float>
        var color: SIMD4<Float>
    }
    
    var commandQueue: MTLCommandQueue!
    
    var renderPipelineState: MTLRenderPipelineState!
    var beadRenderPipelineState: MTLRenderPipelineState!
    var boundaryRenderPipelineState: MTLRenderPipelineState!
    var detectorRenderPipelineState: MTLRenderPipelineState!
    var trianglesRenderPipelineState: MTLRenderPipelineState!
    var voronoiRenderPipelineState: MTLRenderPipelineState!
    var yellowLinesRenderPipelineState: MTLRenderPipelineState!
    
    var kdTreeLines: [SIMD3<Float>] = []
//    var kdCells: [KDCell] = []
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
    
    let boundaryLines: [SIMD3<Float>] = [
        //------------------------------
        // Front Face
        //------------------------------
        // Top
        SIMD3<Float>(-0.5,0.5,0),
        SIMD3<Float>(0.5,0.5,0),
        
        // Left
        SIMD3<Float>(-0.5,0.5,0),
        SIMD3<Float>(-0.5,-0.5,0),
        
        // Right
        SIMD3<Float>(0.5,0.5,0),
        SIMD3<Float>(0.5,-0.5,0),

        // Bottom
        SIMD3<Float>(-0.5,-0.5,0),
        SIMD3<Float>(0.5,-0.5,0),
        
        //------------------------------
        // Back Face  -- not showing...
        //------------------------------
        // Top
        SIMD3<Float>(-0.5,0.5,-0.5),
        SIMD3<Float>(0.5,0.5,-0.5),
        
        // Left
        SIMD3<Float>(-0.5,0.5,-0.5),
        SIMD3<Float>(-0.5,-0.5,-0.5),
        
        // Right
        SIMD3<Float>(0.5,0.5,-0.5),
        SIMD3<Float>(0.5,-0.5,-0.5),
        
        // Bottom
        SIMD3<Float>(-0.5,-0.5,-0.5),
        SIMD3<Float>(0.5,-0.5,-0.5)
    ]
    
    var detectorLines: [SIMD3<Float>] = []
    var triangles: [Vertex] = []
    var voronoiLines: [SIMD3<Float>] = []
    
    var vertexBuffer: MTLBuffer!
    var beadVertexBuffer: MTLBuffer!
    var voronoiBuffer: MTLBuffer!
    var kdCellBuffer: MTLBuffer!
    var boundaryLinesBuffer: MTLBuffer!
    var detectorLinesBuffer: MTLBuffer!
    var trianglesBuffer: MTLBuffer!
    var kdTreeLinesBuffer: MTLBuffer!
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
        
        self.device = MTLCreateSystemDefaultDevice()
        
        self.clearColor = MTLClearColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
        
        self.colorPixelFormat = .bgra8Unorm
        
        self.commandQueue = device?.makeCommandQueue()

        updateTriangles()
        
        initDetectorLines()
        
        createBeads()
        
        createRenderPipelineState()
        
        createBuffers()
    }
    
    let rawBeadPointer = UnsafeMutableRawPointer.allocate(
        byteCount: 3 * MemoryLayout<Point>.stride,
        alignment: 0x4000)
    
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
    
    func appendDetectorLines(xSign: Float, ySign: Float) {
        detectorLines.append(SIMD3<Float>(xSign * 0.5 * Float(sin(Double(0) * Double.pi/Double(TOTAL_SLICES * 2))),ySign * 0.5 * Float(cos(Double(0) * Double.pi / Double(TOTAL_SLICES * 2))),0))
        for i in 1...(TOTAL_SLICES) {
            detectorLines.append(SIMD3<Float>(xSign * 0.5 * Float(sin(Double(i) * Double.pi/Double(TOTAL_SLICES * 2))),ySign * 0.5 * Float(cos(Double(i) * Double.pi / Double(TOTAL_SLICES * 2))),0))
            // Duplicate the line if not the last iteration.
            if (i < TOTAL_SLICES) {
                detectorLines.append(SIMD3<Float>(xSign * 0.5 * Float(sin(Double(i) * Double.pi/Double(TOTAL_SLICES * 2))),ySign * 0.5 * Float(cos(Double(i) * Double.pi / Double(TOTAL_SLICES * 2))),0))
            }
        }
    }
    
    func initDetectorLines() {
        // Quadrant 1
        appendDetectorLines(xSign: 1.0, ySign: 1.0)
        
        // Quadrant 2
        appendDetectorLines(xSign: -1.0, ySign: 1.0)
        
        // Quadrant 3
        appendDetectorLines(xSign: 1.0, ySign: -1.0)
        
        // Quadrant 4
        appendDetectorLines(xSign: -1.0, ySign: -1.0)
    }
    
    func appendTriangles(xSign: Float, ySign: Float) {
        for i in 1...(self.CURRENT_SLICE) {
            triangles.append(
                Vertex(
                    position: SIMD3<Float>(0.0, 0.0 ,0.0),
                    color: SIMD4<Float>(1,0,0,1)
                )
            )
            triangles.append(
                Vertex(
                    position: SIMD3<Float>(xSign * 0.5 * Float(sin(Double(i) * Double.pi/Double(self.TOTAL_SLICES * 2))), ySign * 0.5 * Float(cos(Double(i) * Double.pi / Double(self.TOTAL_SLICES * 2))),0),
                    color: SIMD4<Float>(0,1,0,1)
                )
            )
            triangles.append(
                Vertex(
                    position: SIMD3<Float>(xSign * 0.5 * Float(sin(Double(i-1) * Double.pi/Double(self.TOTAL_SLICES * 2))), ySign * 0.5 * Float(cos(Double(i-1) * Double.pi / Double(self.TOTAL_SLICES * 2))),0),
                    color: SIMD4<Float>(0,0,1,1)
                )
            )
        }
    }
    
    func updateTriangles() {
        triangles.removeAll()
        
        // Quadrant 1
        appendTriangles(xSign: 1.0, ySign: 1.0)
        
        // Quadrant 2
        appendTriangles(xSign: -1.0, ySign: 1.0)
        
        // Quadrant 3
        appendTriangles(xSign: 1.0, ySign: -1.0)
        
        // Quadrant 4
        appendTriangles(xSign: -1.0, ySign: -1.0)
        
        trianglesBuffer = device?.makeBuffer(bytes: triangles, length: MemoryLayout<Vertex>.stride * triangles.count, options: [])
    }
    
    func createBeads() {
        
//        for _ in (0...2) {
////            let n: Int = 320
//            let p: Point = Point(position: float3(Float.randPosition(),Float.randPosition(),0), momentum: Float.randMomentum())
//            beadPointer()
//        }
        
        for _ in (1...n) {
            beads.append(Point(position: SIMD3<Float>(Float.randPosition(),Float.randPosition(),0), momentum: Float.randMomentum()))
        }
    }
    
    func updateBeads() {
        beads.indices.forEach {            
            let newX:Float = beads[$0].position.x + beads[$0].momentum.x;
            let newY:Float = beads[$0].position.y + beads[$0].momentum.y;
            var newMomentumX:Float = beads[$0].momentum.x
            var newMomentumY:Float = beads[$0].momentum.y
            if (newX > 0.5 || newX < -0.5) {
                newMomentumX = -beads[$0].momentum.x
            }
            if (newY > 0.5 || newY < -0.5) {
                newMomentumY = -beads[$0].momentum.y
            }
            
            beads[$0] = Point(position: SIMD3<Float>(newX, newY, 0), momentum: SIMD3<Float>(newMomentumX, newMomentumY, 0))
        }
        beadVertexBuffer = device?.makeBuffer(bytes: beads, length: MemoryLayout<Point>.stride * beads.count, options: [])
    }
    
    func createBuffers() {
        beadVertexBuffer = device?.makeBuffer(bytes: beads, length: MemoryLayout<Point>.stride * beads.count, options: [])
        boundaryLinesBuffer = device?.makeBuffer(bytes: boundaryLines, length: MemoryLayout<SIMD3<Float>>.stride * boundaryLines.count, options: [])
        detectorLinesBuffer = device?.makeBuffer(bytes: detectorLines, length: MemoryLayout<SIMD3<Float>>.stride * detectorLines.count, options: [])
        trianglesBuffer = device?.makeBuffer(bytes: triangles, length: MemoryLayout<Vertex>.stride * triangles.count, options: [])
    }
    
    func kdTreeCut(_ m: KDRange, _ bounds: [Float], _ depth: Int) {
//        print("===============================================")
//        print("depth: \(depth), m.startIndex is \(m.getStartIndex())")
//        print("depth: \(depth), m.endIndex is \(m.getEndIndex())")
//        print("depth: \(depth), mid is \(m.getMid())")
//        print("depth: \(depth), region contains \(m.getEndIndex() - m.getStartIndex() + 1)")
//        print("===============================================")
//        for (index, element) in beads.enumerated() {
//            print("x,y \(index) is: \(element.position.x),\(element.position.y)")
//        }
        
        let midIndex = m.getMid()
        
        kdCellAVLTree.remove(KDCell(lowIndex: m.getStartIndex(), highIndex: m.getEndIndex()))
        kdCellAVLTree.insert(KDCell(lowIndex: m.getStartIndex(), highIndex: m.getMid() - 1))
        kdCellAVLTree.insert(KDCell(lowIndex: m.getMid(), highIndex: m.getEndIndex()))
        
        let cut = m.getAxis() == "X" ?
            (beads[midIndex - 1].position.x + beads[midIndex].position.x) / 2 :
            (beads[midIndex - 1].position.y + beads[midIndex].position.y) / 2
//        print("===============================================")
//        print("\(m.getAxis()) cut is: \(cut)")
        
        cutLines.append(cut)
        
        if (m.getAxis() == "X") {
            kdTreeLines.append(SIMD3<Float>(cut, bounds[0], 0))
            kdTreeLines.append(SIMD3<Float>(cut, bounds[2], 0))
        } else {
            kdTreeLines.append(SIMD3<Float>(bounds[1], cut, 0))
            kdTreeLines.append(SIMD3<Float>(bounds[3], cut, 0))
        }
        
        // TODO: to make computation easier, do not cut one side, unless both sides can be cut.
        if (((m.getMid() - 1) - m.getStartIndex() > k) && (m.getEndIndex() - m.getMid() > k)) {
            if (m.getMid() - 1) - m.getStartIndex() > k {
//                print("KVS: Checktpoint 1")
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
                
//                print("===============================================")
//                for (index, element) in beads.enumerated() {
//                    if (index >= m.getStartIndex() && index <= (m.getMid() - 1)) {
//                        print("BELOW SORT: x,y \(index) is: \(element.position.x),\(element.position.y)")
//                    } else {
//                        print("x,y \(index) is: \(element.position.x),\(element.position.y)")
//                    }
//                }

                kdTreeCut(below, cell, depth + 1)
            }
            if m.getEndIndex() - m.getMid() > k {
//                print("KVS: Checktpoint 2")
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
                
//                print("===============================================")
//                for (index, element) in beads.enumerated() {
//                    if (index >= m.getMid() && index <= m.getEndIndex()) {
//                        print("ABOVE SORT: x,y \(index) is: \(element.position.x),\(element.position.y)")
//                    } else {
//                        print("x,y \(index) is: \(element.position.x),\(element.position.y)")
//                    }
//                }

                kdTreeCut(above, cell, depth + 1)
            }
        }
    }
    
    func updateSlice() {
        var sliceCountThreshold:Int
        
        self.CURRENT_SLICE_COUNT += 1
        let double = cos(Double(self.CURRENT_SLICE) * Double.pi / Double(TOTAL_SLICES * 2))
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        guard let number =  numberFormatter.string(from: NSNumber(value: double)) else { fatalError("Can not get number") }
        
        if number == "0" {
            sliceCountThreshold = 0
        } else if number == "1" {
            sliceCountThreshold = 1000
        } else {
            sliceCountThreshold = Int(number.split(separator: ".")[1]) ?? 0
        }
        if (Float(self.CURRENT_SLICE_COUNT) > Float(sliceCountThreshold / 150)) {
            self.CURRENT_SLICE_COUNT = 0
            if (self.SLICE_EXPAND) {
                self.CURRENT_SLICE += 1
            } else {
                self.CURRENT_SLICE -= 1
            }
            
            if (self.CURRENT_SLICE == TOTAL_SLICES) {
                self.SLICE_EXPAND = false
            } else if (self.CURRENT_SLICE == 1) {
                self.SLICE_EXPAND = true
            }
        }
    }
    
    func updateKDTree() {
        kdTreeLines = []
        createKDTree()
    }
    
    func updateVoronoiDiagram() {
        voronoiLines = []
        createVoronoiDiagram()
    }
    
    func createKDTree() {
        let m:KDRange = KDRange(0, beads.count - 1, "X")
        m.sort(&beads)
        
//        print("===============================================")
//        for (i, point) in beads.enumerated() {
//            print("a: \(i) is: \(point.position.x)")
//        }
        
        kdTreeCut(m, [0.5, 0.5, -0.5, -0.5], 0)
        kdTreeLinesBuffer = device?.makeBuffer(bytes: kdTreeLines, length: MemoryLayout<SIMD3<Float>>.stride * kdTreeLines.count, options: [])
        
//         if (kdCells.count == 0) {
////            print("KVS: kdcells.count is ZERO")
//            kdCellAVLTree.print()
//
//            //////////////////////////////////////////////////
//
//            // 57 : k = 4
//            //
//            // 3,4 : 6
//            // 3,4 : 13
//            // 3,4 : 20
//            // 3,4 : 27
//            // 3,4 : 34
//            // 3,4 : 41
//            // 3,4 : 48
//            // 4,4 : 56
//
//            //////////////////////////////////////////////////
//
//            // 58 : k = 4
//            //
//            // 3,4 : 6
//            // 3,4 : 13
//            // 3,4 : 20
//            // 4,4: 28
//            // 3,4: 35
//            // 3,4: 42
//            // 3,4: 49
//            // 4,4: 57
//
//            //////////////////////////////////////////////////
//
//            // 59 : k = 4
//            //
//            // 3,4: 6
//            // 3,4: 13
//            // 3,4: 20
//            // 4,4: 28
//            // 3,4: 35
//            // 4,4: 43
//            // 3,4: 50
//            // 4,4: 58
//
//            //////////////////////////////////////////////////
//
//            // 60 : k = 4
//            //
//            // 3,4: 6
//            // 4,4: 14
//            // 3,4: 14
//            // 4,4: 29
//            // 3,4: 36
//            // 4,4: 44
//            // 3,4: 51
//            // 4,4: 59
//
//            //////////////////////////////////////////////////
//
//            // 64 : k = 4
//            //
//            // 4,4: 7
//            // 4,4: 15
//            // 4,4: 23
//            // 4,4: 31
//            // 4,4: 39
//            // 4,4: 47
//            // 4,4: 55
//            // 4,4: 63
//        }
        
//        kdCellBuffer = device?.makeBuffer(bytes: kdCells, length: MemoryLayout<KDCell>.stride * kdCells.count, options: [])
    }
    
    func createVoronoiDiagram() {
//        var left: AVLNode<KDCell>? = kdCellAVLTree.root?.left
        
        let beadOne: SIMD3<Float> = beads[0].position
        let beadTwo: SIMD3<Float> = beads[1].position
        let beadThree: SIMD3<Float> = beads[2].position
//        let beadFour: SIMD3<Float> = beads[3].position
        
        // First triangle
        voronoiLines.append(beadOne)
        voronoiLines.append(beadTwo)
        
        voronoiLines.append(beadOne)
        voronoiLines.append(beadThree)
        
//        voronoiLines.append(beadTwo)
//        voronoiLines.append(beadThree)
//
//        // Second triangle
//        voronoiLines.append(beadTwo)
//        voronoiLines.append(beadThree)
//
//        voronoiLines.append(beadTwo)
//        voronoiLines.append(beadFour)
//
//        voronoiLines.append(beadThree)
//        voronoiLines.append(beadFour)
        
        voronoiBuffer = device?.makeBuffer(bytes: voronoiLines, length: MemoryLayout<SIMD3<Float>>.stride * voronoiLines.count, options: [])
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
        
        // Create detectorRenderPipelineState
        let detectorLinesVertexFunction = library?.makeFunction(name: "line_vertex_shader")
        let detectorFragmentFunction = library?.makeFunction(name: "boundary_fragment_shader")
        
        let detectorRenderPipelineDescriptor = MTLRenderPipelineDescriptor()
        detectorRenderPipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        detectorRenderPipelineDescriptor.vertexFunction = detectorLinesVertexFunction
        detectorRenderPipelineDescriptor.fragmentFunction = detectorFragmentFunction
        
        do {
            detectorRenderPipelineState = try device?.makeRenderPipelineState(descriptor: detectorRenderPipelineDescriptor)
        } catch let error as NSError {
            print(error)
        }
        
        // Create triangleRenderPipelineState
        let trianglesVertexFunction = library?.makeFunction(name: "triangle_vertex_shader")
        let trianglesFragmentFunction = library?.makeFunction(name: "triangle_fragment_shader")
        
        let trianglesRenderPipelineDescriptor = MTLRenderPipelineDescriptor()
        trianglesRenderPipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        trianglesRenderPipelineDescriptor.vertexFunction = trianglesVertexFunction
        trianglesRenderPipelineDescriptor.fragmentFunction = trianglesFragmentFunction
        
        do {
            trianglesRenderPipelineState = try device?.makeRenderPipelineState(descriptor: trianglesRenderPipelineDescriptor)
        } catch let error as NSError {
            print(error)
        }
        
        // Create voronoiRenderPipelineState
        let voronoiLinesVertexFunction = library?.makeFunction(name: "line_vertex_shader")
        let voronoiFragmentFunction = library?.makeFunction(name: "boundary_fragment_shader")
        
        let voronoiRenderPipelineDescriptor = MTLRenderPipelineDescriptor()
        voronoiRenderPipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        voronoiRenderPipelineDescriptor.vertexFunction = voronoiLinesVertexFunction
        voronoiRenderPipelineDescriptor.fragmentFunction = voronoiFragmentFunction
        
        do {
            voronoiRenderPipelineState = try device?.makeRenderPipelineState(descriptor: voronoiRenderPipelineDescriptor)
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
        
        if (ADD_MOTION) {
            updateBeads()
        }

        updateSlice()
        updateTriangles()
        updateKDTree()
        
        if (COMPUTE_VORONOI) {
            updateVoronoiDiagram()
        }
        
        time += deltaTime
        delta = cos(time)
        
        guard let drawable = self.currentDrawable, let renderPassDescriptor = self.currentRenderPassDescriptor else { return }
        
        let commandBuffer = commandQueue.makeCommandBuffer()
        
        let renderCommandEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        
        renderCommandEncoder?.pushDebugGroup("Beads")
        renderCommandEncoder?.setRenderPipelineState(beadRenderPipelineState)
        renderCommandEncoder?.setVertexBuffer(beadVertexBuffer, offset: 0, index: 1)
        renderCommandEncoder?.drawPrimitives(type: .point, vertexStart: 0, vertexCount: beads.count, instanceCount: 1)
        renderCommandEncoder?.popDebugGroup()
        
        renderCommandEncoder?.pushDebugGroup("Boundary lines")
        renderCommandEncoder?.setRenderPipelineState(boundaryRenderPipelineState)
        renderCommandEncoder?.setVertexBuffer(boundaryLinesBuffer, offset: 0, index: 1)
        renderCommandEncoder?.drawPrimitives(type: .line, vertexStart: 0, vertexCount: boundaryLines.count, instanceCount: 1)
        renderCommandEncoder?.popDebugGroup()
        
        renderCommandEncoder?.pushDebugGroup("Detector lines")
        renderCommandEncoder?.setRenderPipelineState(detectorRenderPipelineState)
        renderCommandEncoder?.setVertexBuffer(detectorLinesBuffer, offset: 0, index: 1)
        renderCommandEncoder?.drawPrimitives(type: .line, vertexStart: 0, vertexCount: detectorLines.count, instanceCount: 1)
        renderCommandEncoder?.popDebugGroup()
        
        renderCommandEncoder?.pushDebugGroup("Triangles")
        renderCommandEncoder?.setRenderPipelineState(trianglesRenderPipelineState)
        renderCommandEncoder?.setVertexBuffer(trianglesBuffer, offset: 0, index: 0)
        renderCommandEncoder?.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: triangles.count)
        renderCommandEncoder?.popDebugGroup()
        
        if (COMPUTE_VORONOI) {
            renderCommandEncoder?.pushDebugGroup("Voronoi Lines")
            renderCommandEncoder?.setRenderPipelineState(voronoiRenderPipelineState)
            renderCommandEncoder?.setVertexBuffer(voronoiBuffer, offset: 0, index: 1)
            renderCommandEncoder?.drawPrimitives(type: .line, vertexStart: 0, vertexCount: voronoiLines.count, instanceCount: 1)
            renderCommandEncoder?.popDebugGroup()
        }
        
        if (SHOW_KDTREE_LINES) {
            renderCommandEncoder?.pushDebugGroup("KDTree lines")
            renderCommandEncoder?.setRenderPipelineState(yellowLinesRenderPipelineState)
            renderCommandEncoder?.setVertexBuffer(kdTreeLinesBuffer, offset: 0, index: 1)
            renderCommandEncoder?.drawPrimitives(type: .line, vertexStart: 0, vertexCount: kdTreeLines.count, instanceCount: 1)
            renderCommandEncoder?.popDebugGroup()
        }
        
        renderCommandEncoder?.endEncoding()
        commandBuffer?.present(drawable)
        commandBuffer?.commit()
    }
}
