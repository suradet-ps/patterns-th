# การจัดการข้อผิดพลาดใน FFI

## คำอธิบาย

ในภาษาภายนอก เช่น ภาษา C ข้อผิดพลาดมักแสดงด้วยรหัสสถานะที่ส่งกลับคืนมา (return codes) อย่างไรก็ตาม ระบบชนิดข้อมูล (type system) ของ Rust ช่วยให้เราสามารถรวบรวมและส่งต่อข้อมูลข้อผิดพลาดที่ละเอียดและสมบูรณ์กว่ามากผ่านชนิดข้อมูลที่สร้างขึ้นอย่างเต็มรูปแบบ

แนวทางปฏิบัติที่ดีที่สุดนี้นำเสนอรูปแบบรหัสข้อผิดพลาดชนิดต่างๆ และวิธีเปิดเผยข้อมูลเหล่านั้นออกไปให้ภาษาภายนอกใช้งานได้อย่างสะดวก:

1. Flat Enum (enum ค่าเดี่ยวแบบเรียบ) ควรแปลงเป็นเลขจำนวนเต็มเพื่อส่งคืนเป็นรหัสข้อผิดพลาด
2. Structured Enum (enum ที่มีฟิลด์ข้อมูลโครงสร้างซ้อนอยู่) ควรแปลงเป็นรหัสจำนวนเต็ม ควบคู่กับเมท็อดส่งคืนข้อความสตริงเพื่ออธิบายรายละเอียด
3. ชนิดข้อมูลข้อผิดพลาดแบบกำหนดเอง (Custom Error Types) ควรทำให้มีโครงสร้างที่ "โปร่งใส" โดยกำหนดการจัดเรียงในหน่วยความจำให้เข้ากันได้กับ C (`#[repr(C)]`)

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

แนวทางนี้ช่วยให้ภาษาภายนอกสามารถเข้าถึงรายละเอียดของข้อผิดพลาดได้อย่างชัดเจน โดยไม่สูญเสียความกระชับและความถูกต้องของ API ฝั่ง Rust แม้แต่น้อย

## ข้อเสีย

ต้องเขียนโค้ดแปลงข้อมูล (boilerplate) เพิ่มขึ้นพอสมควร และชนิดข้อมูลบางชนิดอาจไม่สามารถแปลงไปเป็นโครงสร้างแบบภาษา C ได้อย่างตรงไปตรงมา
