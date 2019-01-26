import MetalKit

class PointView: MTKView {

    var commandQueue: MTLCommandQueue!
    
    var renderPipelineState: MTLRenderPipelineState!
    var pointsRenderPipelineState: MTLRenderPipelineState!
    var redRenderPipelineState: MTLRenderPipelineState!
    var linesRenderPipelineState: MTLRenderPipelineState!
    
    struct Point {
        var position: float3
        var momentum: float3
    }
    
    var points: [Point] = [
        Point(position: float3(0,0.5,0), momentum: float3(0.1,0,0)),
        Point(position: float3(0.5,-0.5,0), momentum: float3(0,0.1,0)),
        Point(position: float3(-0.5,-0.5,0), momentum: float3(0.1,0.1,0))
    ]
    
    let vertices: [float3] = [
        float3(-0.5,-0.5,0),
        float3(0.5,-0.5,0),
        float3(0,0.5,0)
    ]
    
    let redVertices: [float3] = [
        float3(0,-0.5,0),
        float3(0.5,0.5,0),
        float3(-0.5,0.5,0)
    ]
    
    let redLines: [float3] = [
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
    
    var vertexBuffer: MTLBuffer!
    var pointBuffer: MTLBuffer!
    var redVertexBuffer: MTLBuffer!
    var redLinesBuffer: MTLBuffer!
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
        
        self.device = MTLCreateSystemDefaultDevice()
        
        self.clearColor = MTLClearColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
        
        self.colorPixelFormat = .bgra8Unorm
        
        self.commandQueue = device?.makeCommandQueue()
        
        createRenderPipelineState()
        
        createBuffers()
    }
    
    func createBuffers() {
        vertexBuffer = device?.makeBuffer(bytes: vertices, length: MemoryLayout<float3>.stride * vertices.count, options: [])
        pointBuffer = device?.makeBuffer(bytes: points, length: MemoryLayout<Point>.stride * points.count, options: [])
        redVertexBuffer = device?.makeBuffer(bytes: redVertices, length: MemoryLayout<float3>.stride * redVertices.count, options: [])
        redLinesBuffer = device?.makeBuffer(bytes: redLines, length: MemoryLayout<float3>.stride * redLines.count, options: [])
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
        
        // Create renderPipelineState 2
        let redVertexFunction = library?.makeFunction(name: "red_vertex_shader")
        let redFragmentFunction = library?.makeFunction(name: "red_fragment_shader")
        
        let redRenderPipelineDescriptor = MTLRenderPipelineDescriptor()
        redRenderPipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        redRenderPipelineDescriptor.vertexFunction = redVertexFunction
        redRenderPipelineDescriptor.fragmentFunction = redFragmentFunction
        
        do {
            redRenderPipelineState = try device?.makeRenderPipelineState(descriptor: redRenderPipelineDescriptor)
        } catch let error as NSError {
            print(error)
        }
        
        // Create linesRenderPipelineState
        let linesVertexFunction = library?.makeFunction(name: "line_vertex_shader")
        
        let linesRenderPipelineDescriptor = MTLRenderPipelineDescriptor()
        linesRenderPipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        linesRenderPipelineDescriptor.vertexFunction = linesVertexFunction
        linesRenderPipelineDescriptor.fragmentFunction = redFragmentFunction
        
        do {
            linesRenderPipelineState = try device?.makeRenderPipelineState(descriptor: linesRenderPipelineDescriptor)
        } catch let error as NSError {
            print(error)
        }
        
        // Create pointsRenderPipelineState
        let pointsVertexFunction = library?.makeFunction(name: "point_vertex_shader")
        let pointsFragmentFunction = library?.makeFunction(name: "point_fragment_shader")
        
        let pointsRenderPipelineDescriptor = MTLRenderPipelineDescriptor()
        pointsRenderPipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        pointsRenderPipelineDescriptor.vertexFunction = pointsVertexFunction
        pointsRenderPipelineDescriptor.fragmentFunction = pointsFragmentFunction
        
        do {
            pointsRenderPipelineState = try device?.makeRenderPipelineState(descriptor: pointsRenderPipelineDescriptor)
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
        
//        renderCommandEncoder?.pushDebugGroup("White vertices")
//        renderCommandEncoder?.setRenderPipelineState(renderPipelineState)
//        renderCommandEncoder?.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
//        renderCommandEncoder?.drawPrimitives(type: .point, vertexStart: 0, vertexCount: vertices.count, instanceCount: 1)
//        renderCommandEncoder?.popDebugGroup()
        
        for i in 0..<points.count {
            points[i].position.x = points[i].position.x + time * points[i].momentum.x
            points[i].position.y = points[i].momentum.y + time * points[i].momentum.y
            
            if (i == 1) {
                print("point0.x: \(points[i].position.x)")
                print("point0.y: \(points[i].position.y)")
            }
        }
        
        renderCommandEncoder?.pushDebugGroup("Blue points")
        renderCommandEncoder?.setRenderPipelineState(pointsRenderPipelineState)
        renderCommandEncoder?.setVertexBytes(&delta, length: MemoryLayout<Float>.stride, index: 3)
        renderCommandEncoder?.setVertexBuffer(pointBuffer, offset: 0, index: 2)
        renderCommandEncoder?.drawPrimitives(type: .point, vertexStart: 0, vertexCount: points.count, instanceCount: 1)
        renderCommandEncoder?.popDebugGroup()
        
        renderCommandEncoder?.pushDebugGroup("Red vertices")
        renderCommandEncoder?.setRenderPipelineState(redRenderPipelineState)
        renderCommandEncoder?.setVertexBuffer(redVertexBuffer, offset: 0, index: 1)
        renderCommandEncoder?.drawPrimitives(type: .point, vertexStart: 0, vertexCount: redVertices.count, instanceCount: 1)
        renderCommandEncoder?.popDebugGroup()
        
        renderCommandEncoder?.pushDebugGroup("Red lines")
        renderCommandEncoder?.setRenderPipelineState(linesRenderPipelineState)
        renderCommandEncoder?.setVertexBuffer(redLinesBuffer, offset: 0, index: 1)
        renderCommandEncoder?.drawPrimitives(type: .line, vertexStart: 0, vertexCount: redLines.count, instanceCount: 1)
        renderCommandEncoder?.popDebugGroup()
        
        renderCommandEncoder?.endEncoding()
        commandBuffer?.present(drawable)
        commandBuffer?.commit()
    }
}
