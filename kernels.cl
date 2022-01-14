float sdSphere(float3 p, float r)
{
    return length(p) - r; // p is the test point and r is the radius of the sphere
}

float scene_dist(float3 pos) {
    float3 z = pos;
    float dr = 1.0;
    float r = 0.0;

    for (int i = 0; i < 50; i++) {
        r = length(z);
        if (r>2) break;

        // convert to polar coordinates
        float theta = acos(z.z/r);
        float phi = atan2(z.y,z.x);
        dr =  pow( r, 8.f-1.0f)*8*dr + 1.0;

        // scale and rotate the point
        float zr = pow( r,8.f);
        theta = theta*8;
        phi = phi*8;

        // convert back to cartesian coordinates
        z = zr*(float3)(sin(theta)*cos(phi), sin(phi)*sin(theta), cos(theta));
        z+=pos;
    }

    return 0.5*log(r)*r/dr;
}

float3 estimate_normal(float3 point) {
    float3 small_step = (float3)(0.001, 0.0, 0.0);

    float m_x = scene_dist(point + small_step.xyy) - scene_dist(point - small_step.xyy);
    float m_y = scene_dist(point + small_step.yxy) - scene_dist(point - small_step.yxy);
    float m_z = scene_dist(point + small_step.yyx) - scene_dist(point - small_step.yyx);

    float3 normal = (float3)(m_x, m_y, m_z);

    return normalize(normal);
}

float3 ray_march(float3 origin, float3 direction, int* i) {
    float depth = 0.f;

    for (*i = 0; *i < 800; (*i)++) {
        // current ray position
        float3 point = origin + depth * direction;

        // get current distance from scene
        float distance = scene_dist(point);

        depth += distance;

        if (distance < 0.001f) {
            float3 norm = estimate_normal(point - direction * 0.001f);

            float occlusion_mult = clamp((scene_dist(point + norm * 0.02f) - distance) / 0.02f, 0.f, 1.f);

            float len = length(point);

            float3 col = mix((float3)(0, 255, 255), (float3)(255, 0, 255), len * len);

            float3 light = col * occlusion_mult + 0.2f;

            return light;
        }

        if (depth > 1000.f) {
            break;
        }
    }

    return (float3)(0, 0, 0);
}

void kernel process(__write_only image2d_t out) {
    float x = (float)get_global_id(0);
    float y = (float)get_global_id(1);
    float w = (float)get_global_size(0);
    float h = (float)get_global_size(1);

    float2 norm = (float2)((x / w - .5f) *  (w / h), y / h - .5f);

    float3 origin = (float3)(0, 0, 4);
    float3 direction = normalize((float3)(norm.x, norm.y, -1.5));

    int iterations = 0;
    float3 result = ray_march(origin, direction, &iterations);

    int2 pos = (int2)(x, y);

    if (length(result) != 0.f) {
        write_imageui(out, pos, (uint4)(result.x, result.y, result.z, 255));
    }

    else {
        write_imageui(out, pos, (uint4)(iterations * .8, iterations * .2, iterations, 255));
    }
}