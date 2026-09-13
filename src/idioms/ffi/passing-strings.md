# การส่งสตริง

## คำอธิบาย

เมื่อส่งสตริงไปยังฟังก์ชัน FFI มีหลักการสี่ข้อที่ควรปฏิบัติตาม:

1. ทำให้อายุการใช้งานของสตริงที่เป็นเจ้าของยาวนานที่สุดเท่าที่จะเป็นไปได้
2. ลดโค้ด `unsafe` ระหว่างการแปลงให้เหลือน้อยที่สุด
3. หากโค้ด C สามารถแก้ไขข้อมูลสตริงได้ ให้ใช้ `Vec` แทน `CString`
4. เว้นแต่ Foreign Function API กำหนดไว้เป็นอย่างอื่น ความเป็นเจ้าของสตริงไม่ควร
   ถ่ายโอนไปยังผู้ถูกเรียก (callee)

## แรงจูงใจ

Rust มีการรองรับสตริงแบบ C ในตัวผ่านชนิด `CString` และ `CStr` อย่างไรก็ตาม มีแนวทางที่แตกต่างกันซึ่งใช้ได้กับสตริงที่ถูกส่งไปยังการเรียกฟังก์ชันต่างภาษาจากฟังก์ชัน Rust

แนวปฏิบัติที่ดีที่สุดนั้นเรียบง่าย: ใช้ `CString` ในลักษณะที่ลดโค้ด `unsafe` ให้น้อยที่สุด อย่างไรก็ตาม มีข้อควรระวังรองลงมาคือ *ออบเจกต์ต้องมีอายุยาวนานพอ* หมายความว่าควรทำให้อายุการใช้งานยาวนานที่สุด นอกจากนี้ เอกสารประกอบยังอธิบายว่าการ "นำ `CString` ไปแก้ไขแล้วส่งกลับมาใช้อีกครั้ง (round-tripping)" ถือเป็น UB ดังนั้นในกรณีนั้นจึงต้องทำงานเพิ่มเติม

## ตัวอย่างโค้ด

```rust,ignore
pub mod unsafe_module {

    // other module content

    extern "C" {
        fn seterr(message: *const libc::c_char);
        fn geterr(buffer: *mut libc::c_char, size: libc::c_int) -> libc::c_int;
    }

    fn report_error_to_ffi<S: Into<String>>(err: S) -> Result<(), std::ffi::NulError> {
        let c_err = std::ffi::CString::new(err.into())?;

        unsafe {
            // SAFETY: calling an FFI whose documentation says the pointer is
            // const, so no modification should occur
            seterr(c_err.as_ptr());
        }

        Ok(())
        // The lifetime of c_err continues until here
    }

    fn get_error_from_ffi() -> Result<String, std::ffi::IntoStringError> {
        let mut buffer = vec![0u8; 1024];
        unsafe {
            // SAFETY: calling an FFI whose documentation implies
            // that the input need only live as long as the call
            let written: usize = geterr(buffer.as_mut_ptr(), 1023).into();

            buffer.truncate(written + 1);
        }

        std::ffi::CString::new(buffer).unwrap().into_string()
    }
}
```

## ข้อดี

ตัวอย่างนี้เขียนขึ้นในแบบที่รับประกันว่า:

1. บล็อก `unsafe` มีขนาดเล็กที่สุดเท่าที่จะเป็นไปได้
2. `CString` มีอายุยาวนานพอ
3. ข้อผิดพลาดจากการแปลงชนิด (typecast) ถูกส่งต่อเสมอเมื่อเป็นไปได้

ความผิดพลาดที่พบบ่อย (บ่อยจนปรากฏอยู่ในเอกสารประกอบด้วยซ้ำ) คือการไม่นำตัวแปรมาใช้ในบล็อกแรก:

```rust,ignore
pub mod unsafe_module {

    // other module content

    fn report_error<S: Into<String>>(err: S) -> Result<(), std::ffi::NulError> {
        unsafe {
            // SAFETY: whoops, this contains a dangling pointer!
            seterr(std::ffi::CString::new(err.into())?.as_ptr());
        }
        Ok(())
    }
}
```

โค้ดนี้จะทำให้เกิด dangling pointer เพราะอายุของ `CString` ไม่ได้ถูกยืดออกโดยการสร้างพอยน์เตอร์ ต่างจากการสร้างเรฟเฟอเรนซ์

ประเด็นอื่นที่ถูกยกขึ้นบ่อยคือการเริ่มต้นเวกเตอร์ขนาด 1k ที่เต็มไปด้วยศูนย์นั้น "ช้า" อย่างไรก็ตาม Rust เวอร์ชันใหม่ๆ ได้ optimize มาโครนั้นให้เป็นการเรียก `zmalloc` ซึ่งหมายความว่ามันเร็วเท่ากับความสามารถของระบบปฏิบัติการในการคืนหน่วยความจำที่ตั้งเป็นศูนย์ (ซึ่งเร็วทีเดียว)

## ข้อเสีย

ไม่มี?
