# การส่งสตริง

## คำอธิบาย

เมื่อต้องการส่งสตริงไปยังฟังก์ชัน FFI มีหลักการ 4 ประการที่ควรยึดถือ:

1. ควบคุมให้ช่วงชีวิต (lifetime) ของสตริงที่เป็นเจ้าของข้อมูลคงอยู่ยาวนานเพียงพอตลอดระยะเวลาที่ฟังก์ชันภายนอกเรียกใช้งาน
2. ลดการใช้โค้ด `unsafe` ระหว่างการแปลงชนิดข้อมูลให้เหลือน้อยที่สุด
3. หากโค้ดฝั่ง C มีความจำเป็นต้องแก้ไขข้อมูลในสตริง ให้ใช้ `Vec` แทนที่จะเป็น `CString`
4. หาก Foreign Function API ไม่ได้กำหนดไว้เป็นอย่างอื่นโดยเฉพาะ ความเป็นเจ้าของในสตริงนั้นไม่ควรถูกส่งมอบให้กับฟังก์ชันปลายทาง (callee)

## แรงจูงใจ

Rust รองรับการทำงานกับสตริงแบบ C ในตัวผ่านชนิดข้อมูล `CString` และ `CStr` อย่างไรก็ดี มีแนวทางหลากหลายรูปแบบให้เลือกใช้เมื่อต้องการส่งสตริงจากฟังก์ชันของ Rust ไปยังฟังก์ชันภาษาภายนอก

แนวทางปฏิบัติที่ดีที่สุดนั้นเรียบง่าย: ใช้ `CString` ในรูปแบบที่ลดการเขียนโค้ด `unsafe` ให้น้อยที่สุด อย่างไรก็ตาม มีข้อควรระวังสำคัญคือ *ตัวออบเจกต์ของสตริงต้องมีช่วงชีวิตยาวนานเพียงพอ* นอกจากนี้ ในเอกสารทางการของ Rust ยังระบุว่าการส่ง `CString` ข้ามไปให้แก้ไขแล้วแปลงกลับมาใช้ใหม่ (round-tripping) อาจก่อให้เกิด Undefined Behavior (UB) ได้ ดังนั้นหากต้องแก้ไขข้อมูล จึงจำเป็นต้องมีขั้นตอนเพิ่มเติม

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

ตัวอย่างข้างต้นได้รับการออกแบบเพื่อให้มั่นใจว่า:

1. บล็อกคำสั่ง `unsafe` มีขอบเขตเล็กที่สุดเท่าที่จะเป็นไปได้
2. ออบเจกต์ `CString` มีช่วงชีวิตคงอยู่ยาวนานเพียงพอตามที่ต้องการ
3. ข้อผิดพลาดจากการแปลงชนิดข้อมูล (typecast) จะถูกส่งต่อกลับออกมาเสมอเมื่อเป็นไปได้

ความผิดพลาดที่พบบ่อย (บ่อยจนถูกยกมาเตือนไว้ในเอกสารของ Rust เอง) คือการไม่เก็บตัวแปรสตริงไว้ในขอบเขตการทำงานก่อนเรียกใช้งานพอยน์เตอร์:

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

โค้ดข้างต้นจะทำให้เกิด dangling pointer (พอยน์เตอร์ชี้ไปยังหน่วยความจำที่ถูกคืนไปแล้ว) เนื่องจากช่วงชีวิตของค่าชั่วคราว `CString` จะสิ้นสุดลงทันทีเมื่อจบบรรทัด ไม่ได้ถูกยืดออกไปโดยการสร้าง raw pointer ซึ่งต่างจากการยืมแบบ reference ปกติ

อีกประเด็นหนึ่งที่มักถูกหยิบยกขึ้นมาคือ การสร้างเวกเตอร์ขนาด 1 KB ที่เต็มไปด้วยศูนย์เริ่มต้นนั้นอาจจะ "ช้า" ทว่าใน Rust เวอร์ชันปัจจุบัน คอมไพเลอร์ได้ปรับปรุง (optimize) มาโครดังกล่าวให้เป็นการเรียกใช้ `zmalloc` ซึ่งมีความเร็วเทียบเท่ากับขีดความสามารถของระบบปฏิบัติการในการจัดสรรหน่วยความจำที่เติมศูนย์ (ซึ่งรวดเร็วมาก)

## ข้อเสีย

แทบไม่มีข้อเสีย
