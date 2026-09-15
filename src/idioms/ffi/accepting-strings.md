# การรับสตริง

## คำอธิบาย

เมื่อรับสตริงผ่าน FFI ด้วยพอยน์เตอร์ มีหลักการสำคัญสองข้อที่ควรยึดถือ:

1. คงสถานะของสตริงจากภาษาภายนอกให้อยู่ในรูปแบบ "การยืม" (`&CStr`) แทนที่จะคัดลอกข้อมูลโดยไม่จำเป็น
2. ลดความซับซ้อนและปริมาณโค้ด `unsafe` ที่เกี่ยวข้องกับการแปลงสตริงแบบภาษา C ไปเป็นสตริงของ Rust ให้เหลือน้อยที่สุด

## แรงจูงใจ

สตริงที่ใช้ในภาษา C มีพฤติกรรมและการจัดเก็บที่แตกต่างจากสตริงใน Rust ดังนี้:

- สตริงใน C สิ้นสุดด้วยไบต์ศูนย์ (null-terminated) ขณะที่สตริงใน Rust จัดเก็บขนาดความยาวไว้ในตัว
- สตริงใน C อาจประกอบด้วยไบต์ใดๆ ก็ได้ที่ไม่ใช่ศูนย์ ขณะที่สตริงใน Rust บังคับว่าต้องเข้ารหัสเป็น UTF-8 ที่ถูกต้องเสมอ
- สตริงใน C เข้าถึงและจัดการผ่านการดำเนินการกับ raw pointer แบบ `unsafe` ขณะที่การทำงานกับสตริงใน Rust กระทำผ่านเมท็อดที่ปลอดภัย (safe methods)

ไลบรารีมาตรฐานของ Rust มีชนิดข้อมูลคู่เทียบกับ `String` และ `&str` สำหรับภาษา C โดยเฉพาะ ได้แก่ `CString` และ `&CStr` ซึ่งช่วยให้เราหลีกเลี่ยงความซับซ้อนและลดการเขียนโค้ด `unsafe` ในการแปลงค่าระหว่างสตริงของทั้งสองภาษาลงได้อย่างมาก

ชนิดข้อมูล `&CStr` ยังช่วยให้เราทำงานกับข้อมูลที่ถูกยืมมาได้โดยตรง ส่งผลให้การส่งต่อสตริงระหว่าง Rust และ C แทบไม่มีต้นทุนทางประสิทธิภาพเพิ่มเติม (zero-cost)

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

ตัวอย่างข้างต้นได้รับการออกแบบเพื่อให้มั่นใจว่า:

1. บล็อกคำสั่ง `unsafe` มีขอบเขตเล็กที่สุดเท่าที่จะเป็นไปได้
2. พอยน์เตอร์ที่มีช่วงชีวิตที่คอมไพเลอร์ไม่สามารถติดตามได้ (untracked lifetime) จะถูกเปลี่ยนให้อยู่ในการอ้างอิงแบบแชร์ที่ผ่านการตรวจสอบอย่างปลอดภัย (tracked shared reference)

ลองพิจารณาอีกแนวทางหนึ่งที่มีการคัดลอกสตริงจริงๆ:

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

โค้ดนี้ด้อยกว่าแนวทางแรกในสองประเด็นหลัก:

1. มีโค้ด `unsafe` จำนวนมากเกินไป และที่สำคัญคือมีข้อกำหนดความถูกต้อง (invariants) ที่โปรแกรมเมอร์ต้องคอยระวังด้วยตนเองมากขึ้น
2. มีบั๊กซ่อนอยู่จากการคำนวณตำแหน่งพอยน์เตอร์ ซึ่งนำไปสู่พฤติกรรมที่ไม่พึงประสงค์หรือพฤติกรรมที่ไม่อาจคาดเดาได้ (Undefined Behavior: UB) ใน Rust

บั๊กในตัวอย่างนี้เกิดจากความผิดพลาดในการคำนวณขนาดพอยน์เตอร์: สตริงถูกคัดลอกมาครบจำนวน `msg_len` ไบต์ แต่ตัวปิดท้ายสตริง `NUL` ไม่ได้ถูกคัดลอกตามมาด้วย

จากนั้น เวกเตอร์ถูก *บังคับขนาด* (`set_len`) ให้เท่ากับความยาวของสตริงที่มีการจัดสรรพื้นที่ไว้ แทนที่จะใช้การ *ปรับขนาดจริง* (`resize`) ซึ่งจะช่วยเติมศูนย์ปิดท้ายให้ ผลลัพธ์คือไบต์สุดท้ายในเวกเตอร์กลายเป็นหน่วยความจำที่ยังไม่ได้กำหนดค่าเริ่มต้น (uninitialized memory) เมื่อมีการสร้าง `CString` ที่ท้ายบล็อก การอ่านข้อมูลจากเวกเตอร์นั้นจึงก่อให้เกิด UB ทันที!

เช่นเดียวกับบั๊กหน่วยความจำทั่วไป ปัญหานี้สืบค้นต้นตอได้ยากมาก บางครั้งโปรแกรมอาจ panic เพราะสตริงไม่ใช่ UTF-8 ที่ถูกต้อง บางครั้งอาจมีอักขระแปลกปลอมโผล่มาท้ายข้อความ หรือในบางกรณีอาจทำให้โปรแกรมหยุดทำงาน (crash) ไปเลยอย่างสิ้นเชิง

## ข้อเสีย

แทบไม่มีข้อเสีย
