# การจัดการข้อผิดพลาดใน FFI

## คำอธิบาย

ในภาษาต่างภาษาอย่าง C ข้อผิดพลาดจะถูกแสดงด้วยรหัสส่งคืน (return code) อย่างไรก็ตาม ระบบชนิดของ Rust ช่วยให้เก็บและส่งต่อข้อมูลข้อผิดพลาดที่สมบูรณ์ยิ่งขึ้นได้ผ่านชนิดข้อมูลเต็มรูปแบบ

แนวปฏิบัติที่ดีที่สุดนี้อธิบายรหัสข้อผิดพลาดชนิดต่างๆ และวิธีเปิดเผยมันอย่างใช้งานได้จริง:

1. Enum แบบแบน (Flat Enums) ควรถูกแปลงเป็นจำนวนเต็มและคืนเป็นรหัส
2. Enum แบบมีโครงสร้าง (Structured Enums) ควรถูกแปลงเป็นรหัสจำนวนเต็มพร้อมข้อความข้อผิดพลาดแบบสตริงสำหรับรายละเอียด
3. ชนิดข้อผิดพลาดที่กำหนดเอง (Custom Error Types) ควรกลายเป็น "โปร่งใส" ด้วยตัวแทนแบบ C

## ตัวอย่างโค้ด

### Enum แบบแบน

```rust,ignore
enum DatabaseError {
    IsReadOnly = 1,    // user attempted a write operation
    IOError = 2,       // user should read the C errno() for what it was
    FileCorrupted = 3, // user should run a repair tool to recover it
}

impl From<DatabaseError> for libc::c_int {
    fn from(e: DatabaseError) -> libc::c_int {
        (e as i8).into()
    }
}
```

### Enum แบบมีโครงสร้าง

```rust,ignore
pub mod errors {
    enum DatabaseError {
        IsReadOnly,
        IOError(std::io::Error),
        FileCorrupted(String), // message describing the issue
    }

    impl From<DatabaseError> for libc::c_int {
        fn from(e: DatabaseError) -> libc::c_int {
            match e {
                DatabaseError::IsReadOnly => 1,
                DatabaseError::IOError(_) => 2,
                DatabaseError::FileCorrupted(_) => 3,
            }
        }
    }
}

pub mod c_api {
    use super::errors::DatabaseError;
    use core::ptr;

    #[no_mangle]
    pub extern "C" fn db_error_description(
        e: Option<ptr::NonNull<DatabaseError>>,
    ) -> Option<ptr::NonNull<libc::c_char>> {
        // SAFETY: we assume that the lifetime of `e` is greater than
        // the current stack frame.
        let error = unsafe { e?.as_ref() };

        let error_str: String = match error {
            DatabaseError::IsReadOnly => {
                format!("cannot write to read-only database")
            }
            DatabaseError::IOError(e) => {
                format!("I/O Error: {e}")
            }
            DatabaseError::FileCorrupted(s) => {
                format!("File corrupted, run repair: {}", &s)
            }
        };

        let error_bytes = error_str.as_bytes();

        let c_error = unsafe {
            // SAFETY: copying error_bytes to an allocated buffer with a '\0'
            // byte at the end.
            let buffer = ptr::NonNull::<u8>::new(libc::malloc(error_bytes.len() + 1).cast())?;

            buffer
                .as_ptr()
                .copy_from_nonoverlapping(error_bytes.as_ptr(), error_bytes.len());
            buffer.as_ptr().add(error_bytes.len()).write(0_u8);
            buffer
        };

        Some(c_error.cast())
    }
}
```

### ชนิดข้อผิดพลาดที่กำหนดเอง

```rust,ignore
struct ParseError {
    expected: char,
    line: u32,
    ch: u16,
}

impl ParseError {
    /* ... */
}

/* Create a second version which is exposed as a C structure */
#[repr(C)]
pub struct parse_error {
    pub expected: libc::c_char,
    pub line: u32,
    pub ch: u16,
}

impl From<ParseError> for parse_error {
    fn from(e: ParseError) -> parse_error {
        let ParseError { expected, line, ch } = e;
        parse_error { expected, line, ch }
    }
}
```

## ข้อดี

วิธีนี้รับประกันว่าภาษาต่างภาษาจะเข้าถึงข้อมูลข้อผิดพลาดได้อย่างชัดเจน โดยไม่ทำให้ API ของโค้ด Rust เสียหายเลย

## ข้อเสีย

ต้องพิมพ์เยอะ และบางชนิดข้อมูลอาจแปลงเป็น C ได้ไม่ง่ายนัก
