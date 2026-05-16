// use std::fs::File;
use std::ffi::c_char;
use std::ffi::CStr;
use std::io;

unsafe extern "C" {
    fn interp_process();
}

#[unsafe(no_mangle)]
pub extern "C" fn rust_startup() {
    unsafe {
        interp_process();
    }
}
