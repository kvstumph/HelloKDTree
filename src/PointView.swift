import MetalKit

class PointView: MTKView {

    var commandQueue: MTLCommandQueue!
    
    var renderPipelineState: MTLRenderPipelineState!
    var redRenderPipelineState: MTLRenderPipelineState!
    var linesRenderPipelineState: MTLRenderPipelineState!
    
    struct Point {
        var position: float3
        var momentum: float3
    }
 
    var redVertices: [Point] = [
        Point(position: float3(Float.randPosition(),Float.randPosition(),0), momentum: Float.randMomentum()),
        Point(position: float3(Float.randPosition(),Float.randPosition(),0), momentum: Float.randMomentum()),
        Point(position: float3(Float.randPosition(),Float.randPosition(),0), momentum: Float.randMomentum()),
        Point(position: float3(Float.randPosition(),Float.randPosition(),0), momentum: Float.randMomentum()),
        Point(position: float3(Float.randPosition(),Float.randPosition(),0), momentum: Float.randMomentum()),
        Point(position: float3(Float.randPosition(),Float.randPosition(),0), momentum: Float.randMomentum()),
        Point(position: float3(Float.randPosition(),Float.randPosition(),0), momentum: Float.randMomentum())
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
    
    let voronoiLines: [float3] = [
        float3(0,0,0),
        float3(0,0,0),
        
        float3(0,0,0),
        float3(0,0,0),
        
        float3(0,0,0),
        float3(0,0,0)
    ]
    
    var vertexBuffer: MTLBuffer!
    var redVertexBuffer: MTLBuffer!
    var voronoiBuffer: MTLBuffer!
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
        redVertexBuffer = device?.makeBuffer(bytes: redVertices, length: MemoryLayout<Point>.stride * redVertices.count, options: [])
        voronoiBuffer = device?.makeBuffer(bytes: voronoiLines, length: MemoryLayout<float3>.stride * voronoiLines.count, options: [])
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
        
        renderCommandEncoder?.pushDebugGroup("Red vertices")
        renderCommandEncoder?.setRenderPipelineState(redRenderPipelineState)
        renderCommandEncoder?.setVertexBuffer(redVertexBuffer, offset: 0, index: 1)
        renderCommandEncoder?.setVertexBuffer(voronoiBuffer, offset: 0, index: 4)
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
