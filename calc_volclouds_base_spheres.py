import math
import random

class Vec3:
    x: float
    y: float
    z: float

    @property
    def magnitude(self) -> float:
        return math.sqrt(self.x**2 + self.y**2 + self.z**2)

    def __init__(self, x: float, y: float, z: float) -> None:
        self.x = x
        self.y = y
        self.z = z
    
    def __add__(self, other):
        return Vec3(self.x + other.x, self.y + other.y, self.z + other.z)
    
    def __sub__(self, other):
        return Vec3(self.x - other.x, self.y - other.y, self.z - other.z)
    
    def __mul__(self, other):
        if type(other) == Vec3:
            return Vec3(self.x*other.x, self.y*other.y, self.z*other.z)
        elif type(other) == float or type(other) == int:
            return Vec3(self.x*other, self.y*other, self.z*other)
    
    def __div__(self, other: float | int):
        return Vec3(self.x/other, self.y/other, self.z/other)
    
    def __repr__(self) -> str:
        return f"vec3({self.x},{self.y},{self.z})"

def gen_point(min_coords: Vec3, max_coords: Vec3) -> Vec3:
    return Vec3(
        random.uniform(min_coords.x, max_coords.x),
        random.uniform(min_coords.y, max_coords.y),
        random.uniform(min_coords.z, max_coords.z)
    )

def clamp_vec3(vec: Vec3, min_coords: Vec3, max_coords: Vec3) -> Vec3:
    def clamp(v: float, minv: float, maxv: float) -> float:
        return min(max(v, minv), maxv)
    
    return Vec3(
        clamp(vec.x, min_coords.x, max_coords.x),
        clamp(vec.y, min_coords.y, max_coords.y),
        clamp(vec.z, min_coords.z, max_coords.z)
    )

def gen_point_near(reference: Vec3, max_dist: float) -> Vec3:
    offset = gen_point(Vec3(-max_dist, -max_dist, -max_dist), Vec3(max_dist, max_dist, max_dist))
    while offset.magnitude > max_dist:
        offset = gen_point(Vec3(-max_dist, -max_dist, -max_dist), Vec3(max_dist, max_dist, max_dist))
    
    return reference + offset

class Sphere:
    center: Vec3
    radius: float
    smoothing_apply: float

    def __init__(self, c, r, s):
        self.center = c
        self.radius = r
        self.smoothing_apply = s
    
    def __repr__(self) -> str:
        return f"Sphere({self.center}, {self.radius}, {self.smoothing_apply})"

def gen_cloud() -> list[Sphere]:
    min_coords = Vec3(0.0, 0.0, 0.0)
    max_coords = Vec3(256.0, 48.0, 256.0)
    
    retlist = []

    base_radius = random.uniform(8.0, 16.0)
    base_pos = gen_point(min_coords + Vec3(base_radius, base_radius, base_radius), max_coords - Vec3(base_radius, base_radius, base_radius))
    base_smoothing = 0.5

    retlist.append(Sphere(base_pos, base_radius, base_smoothing))

    for _ in range(6):
        new_radius = base_radius + random.uniform(-6.0, 1.0)
        new_pos = clamp_vec3(
            gen_point_near(base_pos, base_radius*random.uniform(0.75, 1.5)),
            min_coords + Vec3(new_radius, new_radius, new_radius),
            max_coords - Vec3(new_radius, new_radius, new_radius)
        )
        new_smoothing = base_smoothing + random.uniform(-0.4, 0.2)
        retlist.append(Sphere(new_pos, new_radius, new_smoothing))
    
    for _ in range(8):
        new_radius = max(base_radius + random.uniform(-12.0, -2.0), 1.0)
        new_pos = clamp_vec3(
            gen_point_near(base_pos, base_radius*random.uniform(1.0, 1.75)),
            min_coords + Vec3(new_radius, new_radius, new_radius),
            max_coords - Vec3(new_radius, new_radius, new_radius)
        )
        new_smoothing = base_smoothing + random.uniform(-0.4, 0.1)
        retlist.append(Sphere(new_pos, new_radius, new_smoothing))

    return retlist

def gen_clouds(count) -> str:
    sphere_list: list[Sphere] = []
    for _ in range(count):
        sphere_list.extend(gen_cloud())
    
    for s in sphere_list:
        s.center += Vec3(0.0, 180.0, 0.0)
    
    return ",\n".join(map(lambda s: s.__repr__(), sphere_list))

print(gen_clouds(10))