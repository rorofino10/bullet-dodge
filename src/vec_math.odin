package main

import "core:math"
import "core:math/linalg"

Vec2 :: [2]f32
Vec2i :: [2]i32

vec2_to_vec2i :: proc(vec2: Vec2) -> Vec2i {
	return Vec2i{i32(vec2.x), i32(vec2.y)}
}
vec2i_to_vec2 :: proc(vec2i: Vec2i) -> Vec2 {
	return Vec2{f32(vec2i.x), f32(vec2i.y)}
}

vec2_normalize :: proc(vec2: Vec2) -> Vec2 {
	return linalg.normalize0(vec2)
}
vec2i_normalize :: proc(vec2: Vec2i) -> Vec2 {
	return linalg.normalize0(vec2i_to_vec2(vec2))
}

vec_normalize :: proc {
	vec2_normalize,
	vec2i_normalize,
}

wall_normal :: proc(vec1, vec2: Vec2) -> Vec2 {
	dir := vec2_normalize(vec1 - vec2)
	return Vec2{dir.y, -dir.x}
}
