
/// A bitmaskable flag series for report classification
pub const ReportType = enum(u16)
{
    // Information
    lvl_info = 0b0000_0000_0000_0001,
    // Something that should not, did not, or should otherwise have happened
    lvl_warn = 0b0000_0000_0000_0010,
    // Something that should never happen, happened
    lvl_erro = 0b0000_0000_0000_0100,
    // Something bad is going to negatively affect everything in a cascade
    lvl_term = 0b0000_0000_0000_1000,
    //base system related or catch all
    coal_sys = 0b0000_0000_0001_0000,
    //file input or output related 
    file__io = 0b0000_0000_0010_0000,
    //sdl system related
    sdl__sys = 0b0000_0000_0100_0000,
    //engine window-specific related
    windwsys = 0b0000_0000_1000_0000,
    //egnine renderer related
    renderer = 0b0000_0001_0000_0000,
    //focus/focalpoint related
    focalpnt = 0b0000_0010_0000_0000,
    //external script related
    scriptng = 0b0000_0100_0000_0000,
    //system memory related
    memalloc = 0b0000_1000_0000_0000,
    //asset management or handling related
    assetsys = 0b0001_0000_0000_0000,
    //chunk or chunk management related
    chunksys = 0b0010_0000_0000_0000,
    //audio related
    audiosys = 0b0100_0000_0000_0000,
    //physics-related
    physcsys = 0b1000_0000_0000_0000,
};


/// Report struct, used to log engine events 
pub const Report = struct
{
    report_type : u16 = 0,
    report_mssg : u32 = 0,
    report_data : [4]i32 = [_]i32{0} ** 4,
    report_etic : usize = 0
};