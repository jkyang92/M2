// use std::fs::File;
use std::ffi::c_char;
use std::ffi::CStr;
use std::io;
mod m2;

#[unsafe(no_mangle)]
pub extern "C" fn rust_startup() {
    unsafe {
        m2::interp_process();
    }
}
