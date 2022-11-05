/// Two-part Vector, not to be confused with the SIMD @Vector
pub const Vector2 = struct
{
    x : f32 = 0.0,
    y : f32 = 0.0,
    /// Inline Initializer
    pub inline fn init(x : f32, y : f32) Vector2
    {
        return .{.x = x, .y = y};
    }
    /// Inline SIMD converter
    pub inline fn simd() @Vector(2, f32)
    {
        return @Vector(2, f32){.x, .y};
    }
};

/// Three-part Vector, not to be confused with the SIMD @Vector
pub const Vector3 = struct
{
    x : f32 = 0.0,
    y : f32 = 0.0,
    z : f32 = 0.0,
    /// Inline Initializer
    pub inline fn init(x : f32, y : f32, z : f32) Vector3
    {
        return .{.x = x, .y = y, .z = z};
    }
    /// Inline SIMD converter
    pub inline fn simd() @Vector(3, f32)
    {
        return @Vector(3, f32){.x, .y, .z};
    }
    /// An entirely wrong cross product calculation
    pub inline fn badCross(lhd : Vector3, rhd : Vector3) Vector3
	{
		return Vector3{
			.x = lhd.y * rhd.z - lhd.z * rhd.y,
			.y = lhd.z * rhd.x - lhd.x * rhd.z,
			.z = lhd.y * rhd.x - lhd.x * rhd.y
		};
	}
    /// Dot product of two vectors
    pub inline fn vectorDot(a : Vector3, b : Vector3) f32
	{
		return a.x * b.x + a.y * b.y + a.z * b.z;
	}
};

/// Four-part Vector, not to be confused with the SIMD @Vector
pub const Vector4 = struct
{
    w : f32 = 0.0,
    x : f32 = 0.0,
    y : f32 = 0.0,
    z : f32 = 0.0,
    /// Inline Initializer
    pub inline fn init(w : f32, x : f32, y : f32, z : f32) Vector4
    {
        return .{.w = w, .x = x, .y = y, .z = z};
    }
    /// Inline SIMD converter
    pub inline fn simd() @Vector(4, f32)
    {
        return @Vector(4, f32){.w, .x, .y, .z};
    }
};