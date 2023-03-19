//! OGD is object generation data
//! 
//!     It is the metadata used to construct setpieces, script triggers, 
//! forces, emitters, lights, etcetera. The data must be small, very small. 
//! Exponentially larger worlds means exponentially more assets to fill in. The
//! size alloted to resources as it pertains to that worldspace is gravely 
//! important. OGD: assignment may need to skip header data, or be split in 
//! terms of data representation for override entries. The generation layout 
//! should be such that a 0'd value should spawn a debug cube (blessed be).
//! 
//!     OGD data needing to be represented is: 
//! Origin Chunk Index (static/initial derived)
//! Worldspace position (major derived) minor
//! Scale
//! Rotation
//! GenType
//!     Setpiece
//!     Actor
//!     Force
//!     Trigger
//!     Emitter
//!     Waterplane
//!     External...
//! 
//! 64 for euc and meta
//! 64 for gen type and data
//! 
//! #Meta and Positional#
//! 0b0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000
//!   ^^ <2> meta header ( 01 single 11 start 10 continues 00 ends)
//!     ^^_^^^^_^^ <8> xsubpos (* 0.5)
//!               ^^_^^^^_^^ <8> ysubpos (* 0.5)
//!                         ^^_^^^^_^^^^_^^^^_^^ <16> zpos (* 0.5 + height)
//!                                             ^^_^^^^ <6> xrot(* 5.625)
//!                                                    _^^^^_^^ <6> yrot(* 5.625)
//!                                                            ^^_^^^^ <6> zrot(* 5.625)
//!                                                                   _^^^^ <4> xscale(* 1.25)
//!                                                                        _^^^^ <4> yscale(* 1.25)
//!                                                                             _^^^^ <4> zscale(* 1.25)
//! 
//! #Generational#
//! 0b0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000   
//!   ^^ <2> enabled on generation
//!     ^^_^^ <4> gentype
//!          ^^_^^^^_^^^^_^^^^_^^^^_^^^^_^^^^_^^^^_^^ <32> gendata
//!                                                  ^^_^^^^_^^ <8>  
//!                                                            ^^_^^^^_^^^^_^^^^_^^^^ (18) UID   
//! 


const pnt = @import("../simpletypes/points.zig");
const euc = @import("../coaltypes/euclid.zig");
const GenType = enum(u3){ 
    Setpiece = 0, 
    Actor = 1, 
    Trigger = 2, 
    Force = 3, 
    Light = 4, 
    Emitter = 5, 
    Equipment = 6, 
    External = 7, 
    };

pub const OGD = struct {
    base : u128 = 0,
    index : pnt.Point3 = .{},
    euclid : euc.Euclid = .{},
    gentype : GenType = GenType.Setpiece,
    gendata : u64 = 0,
};