# การรับสตริง

## คำอธิบาย

เมื่อรับสตริงผ่าน FFI ทางพอยน์เตอร์ มีหลักการสองข้อที่ควรปฏิบัติตาม:

1. ให้สตริงจากภาษาต่างภาษา "ถูกยืม" ไว้ แทนที่จะคัดลอกมาตรงๆ
2. ลดความซับซ้อนและปริมาณโค้ด `unsafe` ที่เกี่ยวข้องกับการแปลงจากสตริงแบบ C
   เป็นสตริง Rust พื้นเมืองให้เหลือน้อยที่สุด

## แรงจูงใจ

สตริงที่ใช้ใน C มีพฤติกรรมต่างจากสตริงที่ใช้ใน Rust กล่าวคือ:

- สตริง C ลงท้ายด้วย null (null-terminated) ขณะที่สตริง Rust เก็บความยาวของตัวเอง
- สตริง C บรรจุไบต์ใดๆ ที่ไม่ใช่ศูนย์ก็ได้ ขณะที่สตริง Rust ต้องเป็น UTF-8
- สตริง C เข้าถึงและจัดการผ่านการดำเนินการกับพอยน์เตอร์แบบ `unsafe` ขณะที่การ
  ปฏิสัมพันธ์กับสตริง Rust ผ่านเมท็อดที่ปลอดภัย

ไลบรารีมาตรฐานของ Rust มีชนิดที่เทียบเท่ากับ `String` และ `&str` ของ Rust ในโลก C ชื่อ `CString` และ `&CStr` ซึ่งช่วยให้เราหลีกเลี่ยงความซับซ้อนและโค้ด `unsafe` จำนวนมากที่เกี่ยวข้องกับการแปลงระหว่างสตริง C กับสตริง Rust ได้

ชนิด `&CStr` ยังช่วยให้เราทำงานกับข้อมูลแบบยืมได้ด้วย หมายความว่าการส่งสตริงระหว่าง Rust กับ C เป็นการดำเนินการที่ไม่มีค่าใช้จ่ายเพิ่ม (zero-cost)

## ตัวอย่างโค้ด

```rust,ignore
pub mod unsafe_module {

    // other module content

    /// Log a message at the specified level.
    ///
    /// # Safety
    ///
    /// It is the caller's guarantee to ensure `msg`:
    ///
    /// - is not a null pointer
    /// - points to valid, initialized data
    /// - points to memory ending in a null byte
    /// - won't be mutated for the duration of this function call
    #[no_mangle]
    pub unsafe extern "C" fn mylib_log(msg: *const libc::c_char, level: libc::c_int) {
        let level: crate::LogLevel = match level { /* ... */ };

        // SAFETY: The caller has already guaranteed this is okay (see the
        // `# Safety` section of the doc-comment).
        let msg_str: &str = match std::ffi::CStr::from_ptr(msg).to_str() {
            Ok(s) => s,
            Err(e) => {
                crate::log_error("FFI string conversion failed");
                return;
            }
        };

        crate::log(msg_str, level);
    }
}
```

## ข้อดี

ตัวอย่างนี้เขียนขึ้นเพื่อรับประกันว่า:

1. บล็อก `unsafe` มีขนาดเล็กที่สุดเท่าที่จะเป็นไปได้
2. พอยน์เตอร์ที่มีไลฟ์ไทม์แบบ "ไม่ถูกติดตาม" กลายเป็นการอ้างอิงร่วมแบบ "ถูกติดตาม"

ลองพิจารณาทางเลือกที่คัดลอกสตริงจริงๆ:

```rust,ignore
pub mod unsafe_module {

    // other module content

    pub extern "C" fn mylib_log(msg: *const libc::c_char, level: libc::c_int) {
        // DO NOT USE THIS CODE.
        // IT IS UGLY, VERBOSE, AND CONTAINS A SUBTLE BUG.

        let level: crate::LogLevel = match level { /* ... */ };

        let msg_len = unsafe { /* SAFETY: strlen is what it is, I guess? */
            libc::strlen(msg)
        };

        let mut msg_data = Vec::with_capacity(msg_len + 1);

        let msg_cstr: std::ffi::CString = unsafe {
            // SAFETY: copying from a foreign pointer expected to live
            // for the entire stack frame into owned memory
            std::ptr::copy_nonoverlapping(msg, msg_data.as_mut(), msg_len);

            msg_data.set_len(msg_len + 1);

            std::ffi::CString::from_vec_with_nul(msg_data).unwrap()
        }

        let msg_str: String = unsafe {
            match msg_cstr.into_string() {
                Ok(s) => s,
                Err(e) => {
                    crate::log_error("FFI string conversion failed");
                    return;
                }
            }
        };

        crate::log(&msg_str, level);
    }
}
```

โค้ดนี้ดอยกว่าตัวต้นฉบับในสองแง่:

1. มีโค้ด `unsafe` มากกว่ามาก และที่สำคัญกว่านั้นคือมี invariant ที่ต้องรักษามากขึ้น
2. เนื่องจากการคำนวณจำนวนมากที่ต้องทำ มีบั๊กอยู่ในเวอร์ชันนี้ที่ทำให้เกิด `undefined behaviour` ใน Rust

บั๊กในที่นี้เป็นความผิดพลาดง่ายๆ ในการคำนวณพอยน์เตอร์: สตริงถูกคัดลอกมาทั้งหมด `msg_len` ไบต์ แต่ตัวปิดท้าย `NUL` ที่อยู่ตอนท้ายกลับไม่ถูกคัดลอกมาด้วย

จากนั้นเวกเตอร์ก็ถูก*กำหนด*ขนาดเป็นความยาวของ*สตริงที่เติมศูนย์* แทนที่จะถูก*ปรับขนาด*ให้เป็นค่านั้น ซึ่งถ้าทำอย่างนั้นก็จะเติมศูนย์ที่ตอนท้ายให้ได้ ผลก็คือไบต์สุดท้ายในเวกเตอร์เป็นหน่วยความจำที่ยังไม่ถูกเริ่มต้น เมื่อ `CString` ถูกสร้างขึ้นที่ด้านล่างของบล็อก การอ่านเวกเตอร์ของมันจะทำให้เกิด `undefined behaviour`!

เช่นเดียวกับปัญหาทำนองนี้หลายอย่าง นี่เป็นเรื่องยากที่จะตามหาต้นตอ บางครั้งมันจะ panic เพราะสตริงไม่ใช่ `UTF-8` บางครั้งมันจะใส่อักขระแปลกๆ ไว้ท้ายสตริง บางครั้งมันก็แครชไปเลย

## ข้อเสีย

ไม่มี?
