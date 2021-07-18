import MetalKit

public extension Float {
    public static func rand() -> Float {
        return (Float(arc4random()) / 0xFFFFFFFF)
    }
    public static func randPosition() -> Float {
        return (Float(arc4random()) / 0xFFFFFFFF) - 0.5
    }
    public static func randMomentum() -> float3 {
        let MAX_MOMENTUM = Float(0.014)
//        let rand = Float.rand() * MAX_MOMENTUM
        let randX = ((Float(arc4random()) / 0xFFFFFFFF) - 0.5) * MAX_MOMENTUM
        let randY = ((Float(arc4random()) / 0xFFFFFFFF) - 0.5) * MAX_MOMENTUM
//        return float3(rand, MAX_MOMENTUM - rand, 0)
        return float3(randX, randY, 0)
    }
}
