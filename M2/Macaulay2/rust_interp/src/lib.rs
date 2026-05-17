// use std::fs::File;
use std::ffi::*;
use std::ptr;
use std::ffi::CStr;
use std::io;
mod m2;
mod parse_tree;
//use parse_tree;

#[unsafe(no_mangle)]
pub extern "C" fn rust_startup() {
    unsafe {
        m2::interp_process();
    }
}

#[unsafe(no_mangle)]
pub extern "C" fn rust_parse(str: * const c_char) -> *const c_char {
    unsafe {
        let rust_str = CStr::from_ptr(str).to_str().expect("Invalid String").to_owned();
        parse_string(rust_str);
        return ptr::null();
    }
}


fn parse_string(str: String) -> parse_tree::ParseNode {
    return parse_tree::ParseNode::Identifier{name : str,pos : parse_tree::EMPTY_POSITION};
}
