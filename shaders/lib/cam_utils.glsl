#ifndef LIB_CAM_UTILS
#define LIB_CAM_UTILS

uniform vec3 cameraPositionFract;
uniform ivec3 cameraPositionInt;

uniform vec3 previousCameraPositionFract;
uniform ivec3 previousCameraPositionInt;

vec3 get_camera_delta() {
    return vec3(cameraPositionInt - previousCameraPositionInt) + cameraPositionFract - previousCameraPositionFract;
}

#endif