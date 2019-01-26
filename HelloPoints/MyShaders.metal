#include <metal_stdlib>
using namespace metal;

struct InPoint
{
    float3 position [[ attribute(0) ]];
    float3 momentum [[ attribute(1) ]];
};

struct OutPoint
{
    float4 position [[ position ]];
    float size [[ point_size ]];
};

vertex OutPoint basic_vertex_shader(device float3 *vertices [[ buffer(0) ]],
                                  uint vid [[ vertex_id ]]) {
    OutPoint point;
    point.position = float4(vertices[vid], 1);
    point.size = 6.0;
    return point;
}

fragment half4 basic_fragment_shader(OutPoint point [[ stage_in ]]) {
    return half4(1, 1, 1, 1);
}

vertex OutPoint red_vertex_shader(device float3 *vertices [[ buffer(1) ]],
                                 uint vid [[ vertex_id ]]) {
    OutPoint point;
    if (vid == 0) {
        vertices[vid].x += 0.0005;
        vertices[vid].y += 0.002;
    }
    point.position = float4(vertices[vid], 1);
    point.size = 8.0;
    return point;
}

vertex OutPoint line_vertex_shader(device float3 *vertices [[ buffer(1) ]],
                                  uint vid [[ vertex_id ]]) {
    OutPoint point;
    point.position = float4(vertices[vid], 1);
    point.size = 8.0;
    return point;
}

fragment half4 red_fragment_shader(OutPoint point [[ stage_in ]]) {
    return half4(1, 0, 0, 1);
}

vertex OutPoint point_vertex_shader(device InPoint *points [[ buffer(2) ]],
                                    constant float &delta [[ buffer(3) ]],
                                    uint vid [[ vertex_id ]]) {
    OutPoint point;
    float x1 = points[vid].position.x;
    float y1 = points[vid].position.y;
    float z1 = points[vid].position.z;

    if (vid == 0) {
        float x2;
        float y2;
        float xDiff;
        float yDiff;
        if ( delta < 0.0) {
            x2 = points[1].position.x;
            y2 = points[1].position.y;
            xDiff = -(x2 - x1);
            yDiff = -(y2 - y1);
        } else {
            x2 = points[2].position.x;
            y2 = points[2].position.y;
            xDiff = x2 - x1;
            yDiff = y2 - y1;
        }
        
        float magnitude = sqrt(pow(xDiff, 2) + pow(yDiff, 2));
        float3 unitVector = float3(xDiff / magnitude, yDiff / magnitude, 0);
        
        point.position = float4(x1 + delta * unitVector.x, y1 + delta * unitVector.y, z1, 1);
    } else {
        point.position = float4(x1, y1, z1, 1);
    }
    point.size = 8.0;
    return point;
}

fragment half4 point_fragment_shader(OutPoint point [[ stage_in ]]) {
    return half4(0, 0, 1, 1);
}
