# เจเนอริกในฐานะคลาสชนิด

## คำอธิบาย

ระบบชนิดของ Rust ถูกออกแบบมาในแนวภาษาเชิงฟังก์ชัน (อย่าง Haskell) มากกว่าภาษาเชิงอิมเพอเรทีฟ (อย่าง Java และ C++) ผลก็คือ Rust สามารถเปลี่ยนปัญหาการเขียนโปรแกรมหลายชนิดให้กลายเป็นปัญหา "การกำหนดชนิดแบบสแตติก" ได้ นี่เป็นหนึ่งในข้อได้เปรียบที่ใหญ่ที่สุดของการเลือกภาษาเชิงฟังก์ชัน และเป็นสิ่งสำคัญยิ่งต่อการรับประกันตอนคอมไพล์หลายประการของ Rust

ส่วนสำคัญของแนวคิดนี้คือวิธีที่ชนิดเจเนอริกทำงาน ใน C++ และ Java ตัวอย่างเช่น ชนิดเจเนอริกเป็นโครงสร้างเมตาโปรแกรมมิงสำหรับคอมไพเลอร์ `vector<int>` และ `vector<char>` ใน C++ เป็นเพียงสำเนาสองชุดที่ต่างกันของโค้ด boilerplate เดียวกันสำหรับชนิด `vector` (ที่รู้จักในชื่อ `template`) โดยเติมชนิดที่ต่างกันลงไปสองชนิด

ใน Rust พารามิเตอร์ชนิดเจเนอริกสร้างสิ่งที่รู้จักในภาษาเชิงฟังก์ชันว่า "ข้อจำกัดคลาสชนิด (type class constraint)" และพารามิเตอร์แต่ละตัวที่ผู้ใช้ปลายทางเติมลงไป*เปลี่ยนชนิดจริงๆ* กล่าวอีกนัยหนึ่ง `Vec<isize>` กับ `Vec<char>` *เป็นสองชนิดที่ต่างกัน* ซึ่งทุกส่วนของระบบชนิดรับรู้ว่าแตกต่างกัน

สิ่งนี้เรียกว่า **monomorphization** โดยที่ชนิดต่างๆ ถูกสร้างจากโค้ด**พอลิมอร์ฟิก** พฤติกรรมพิเศษนี้ต้องให้บล็อก `impl` ระบุพารามิเตอร์เจเนอริก ค่าที่ต่างกันของชนิดเจเนอริกทำให้เกิดชนิดที่ต่างกัน และชนิดที่ต่างกันก็มีบล็อก `impl` ที่ต่างกันได้

ในภาษาเชิงวัตถุ คลาสสืบทอดพฤติกรรมจากคลาสแม่ได้ อย่างไรก็ตาม นั่นไม่ได้เปิดทางให้แนบพฤติกรรมเพิ่มเติมกับสมาชิกเฉพาะตัวของคลาสชนิดเพียงเท่านั้น แต่แนบพฤติกรรมพิเศษได้ด้วย

สิ่งที่ใกล้เคียงที่สุดคือพอลิมอร์ฟิซึมตอนรันไทม์ใน JavaScript และ Python ซึ่งสมาชิกใหม่สามารถถูกเพิ่มเข้าไปในออบเจกต์ได้ตามใจโดยคอนสตรัคเตอร์ใดก็ได้ อย่างไรก็ตาม ต่างจากภาษาเหล่านั้น เมท็อดเพิ่มเติมทั้งหมดของ Rust ถูกตรวจสอบชนิดได้เมื่อถูกใช้งาน เพราะเจเนอริกของมันถูกนิยามแบบสแตติก สิ่งนี้ทำให้ใช้งานได้สะดวกขึ้นขณะยังคงปลอดภัย

## ตัวอย่าง

สมมติว่าคุณกำลังออกแบบเซิร์ฟเวอร์จัดเก็บข้อมูลสำหรับเครื่องในห้องแล็บชุดหนึ่ง เนื่องจากซอฟต์แวร์ที่เกี่ยวข้อง มีโปรโตคอลสองแบบที่คุณต้องรองรับ: BOOTP (สำหรับการบูตผ่านเครือข่าย PXE) และ NFS (สำหรับพื้นที่จัดเก็บแบบเมานต์ระยะไกล)

เป้าหมายของคุณคือมีโปรแกรมหนึ่งที่เขียนด้วย Rust ซึ่งจัดการได้ทั้งสองแบบ โปรแกรมจะมีตัวจัดการโปรโตคอลและรอรับคำขอทั้งสองชนิด ตรรกะของแอปพลิเคชันหลักจะให้ผู้ดูแลแล็บตั้งค่าการจัดเก็บและมาตรการความปลอดภัยสำหรับไฟล์จริง

คำขอไฟล์จากเครื่องในแล็บมีข้อมูลพื้นฐานเหมือนกันไม่ว่าจะมาจากโปรโตคอลใด: วิธีการยืนยันตัวตน และชื่อไฟล์ที่ต้องการดึง การอิมพลีเมนต์แบบตรงไปตรงมาจะมีหน้าตาประมาณนี้:

```rust,ignore
enum AuthInfo {
    Nfs(crate::nfs::AuthInfo),
    Bootp(crate::bootp::AuthInfo),
}

struct FileDownloadRequest {
    file_name: PathBuf,
    authentication: AuthInfo,
}
```

การออกแบบนี้อาจใช้ได้ดีพอ แต่ทีนี้สมมติว่าคุณต้องรองรับการเพิ่มเมทาดาทาที่*จำเพาะต่อโปรโตคอล* ตัวอย่างเช่น กับ NFS คุณต้องการทราบว่าจุดเมานต์ของมันคืออะไร เพื่อบังคับใช้กฎความปลอดภัยเพิ่มเติม

วิธีที่ struct ปัจจุบันถูกออกแบบไว้ทำให้การตัดสินใจเรื่องโปรโตคอลถูกเลื่อนไปจนถึงตอนรันไทม์ นั่นหมายความว่าเมท็อดใดที่ใช้กับโปรโตคอลหนึ่งแต่ไม่ใช่อีกโปรโตคอลหนึ่ง ย่อมบังคับให้โปรแกรมเมอร์ต้องตรวจสอบตอนรันไทม์

นี่คือหน้าตาของการดึงจุดเมานต์ NFS:

```rust,ignore
struct FileDownloadRequest {
    file_name: PathBuf,
    authentication: AuthInfo,
    mount_point: Option<PathBuf>,
}

impl FileDownloadRequest {
    // ... other methods ...

    /// Gets an NFS mount point if this is an NFS request. Otherwise,
    /// return None.
    pub fn mount_point(&self) -> Option<&Path> {
        self.mount_point.as_ref()
    }
}
```

ผู้เรียก `mount_point()` ทุกคนต้องตรวจสอบค่า `None` และเขียนโค้ดจัดการมัน แม้พวกเขาจะรู้ว่าในเส้นทางโค้ดหนึ่งๆ มีเพียงคำขอ NFS เท่านั้นที่ถูกใช้ก็ตาม!

การทำให้เกิดข้อผิดพลาดตั้งแต่ตอนคอมไพล์เมื่อสับสนระหว่างชนิดคำขอที่ต่างกันจะเหมาะสมกว่ามาก ท้ายที่สุด เส้นทางทั้งหมดของโค้ดผู้ใช้ รวมถึงฟังก์ชันใดจากไลบรารีที่พวกเขาใช้ จะรู้ว่าคำขอนั้นเป็นคำขอ NFS หรือคำขอ BOOTP

ใน Rust เรื่องนี้ทำได้จริง! ทางออกคือ*เพิ่มชนิดเจเนอริก*เพื่อแยก API ออกเป็นส่วนๆ

นี่คือหน้าตาของมัน:

```rust
use std::path::{Path, PathBuf};

mod nfs {
    #[derive(Clone)]
    pub(crate) struct AuthInfo(String); // NFS session management omitted
}

mod bootp {
    pub(crate) struct AuthInfo(); // no authentication in bootp
}

// Keep the module private to prevent outside users from inventing their own protocols.
mod proto_trait {
    use super::{bootp, nfs};
    use std::path::{Path, PathBuf};

    pub(crate) trait ProtoKind {
        type AuthInfo;
        fn auth_info(&self) -> Self::AuthInfo;
    }

    pub struct Nfs {
        auth: nfs::AuthInfo,
        mount_point: PathBuf,
    }

    impl Nfs {
        pub(crate) fn mount_point(&self) -> &Path {
            &self.mount_point
        }
    }

    impl ProtoKind for Nfs {
        type AuthInfo = nfs::AuthInfo;
        fn auth_info(&self) -> Self::AuthInfo {
            self.auth.clone()
        }
    }

    pub struct Bootp(); // no additional metadata

    impl ProtoKind for Bootp {
        type AuthInfo = bootp::AuthInfo;
        fn auth_info(&self) -> Self::AuthInfo {
            bootp::AuthInfo()
        }
    }
}

use proto_trait::ProtoKind; // keep internal to prevent impls
pub use proto_trait::{Bootp, Nfs}; // re-export so callers can see them

struct FileDownloadRequest<P: ProtoKind> {
    file_name: PathBuf,
    protocol: P,
}

// all common API parts go into a generic impl block
impl<P: ProtoKind> FileDownloadRequest<P> {
    fn file_path(&self) -> &Path {
        &self.file_name
    }

    fn auth_info(&self) -> P::AuthInfo {
        self.protocol.auth_info()
    }
}

// all protocol-specific impls go into their own block
impl FileDownloadRequest<Nfs> {
    fn mount_point(&self) -> &Path {
        self.protocol.mount_point()
    }
}

fn main() {
    // your code here
}
```

ด้วยแนวทางนี้ หากผู้ใช้ทำผิดพลาดและใช้ชนิดผิด:

```rust,ignore
fn main() {
    let mut socket = crate::bootp::listen()?;
    while let Some(request) = socket.next_request()? {
        match request.mount_point().as_ref() {
            "/secure" => socket.send("Access denied"),
            _ => {} // continue on...
        }
        // Rest of the code here
    }
}
```

พวกเขาจะได้ syntax error ชนิด `FileDownloadRequest<Bootp>` ไม่อิมพลีเมนต์ `mount_point()` มีเพียงชนิด `FileDownloadRequest<Nfs>` เท่านั้นที่ทำได้ และแน่นอนว่ามันถูกสร้างโดยโมดูล NFS ไม่ใช่โมดูล BOOTP!

## ข้อดี

ประการแรก ช่วยให้ฟิลด์ที่ใช้ร่วมกันระหว่างหลายสถานะถูกลดความซ้ำซ้อนได้ ด้วยการทำให้ฟิลด์ที่ไม่ใช้ร่วมกันเป็นเจเนอริก มันจึงถูกอิมพลีเมนต์เพียงครั้งเดียว

ประการที่สอง ทำให้บล็อก `impl` อ่านง่ายขึ้น เพราะถูกแบ่งตามสถานะ เมท็อดที่ใช้ร่วมกันทุกสถานะถูกกำหนดชนิดครั้งเดียวในบล็อกเดียว และเมท็อดที่เฉพาะกับสถานะหนึ่งอยู่ในบล็อกแยก

ทั้งสองข้อนี้หมายความว่ามีโค้ดน้อยลงและจัดระเบียบได้ดีขึ้น

## ข้อเสีย

ปัจจุบันวิธีนี้เพิ่มขนาดไบนารี เนื่องจากวิธีที่ monomorphization ถูกอิมพลีเมนต์ในคอมไพเลอร์ หวังว่าการอิมพลีเมนต์จะพัฒนาได้ในอนาคต

## ทางเลือกอื่น

- หากชนิดข้อมูลดูเหมือนต้องการ "API แยกส่วน" เพราะการสร้างหรือการเริ่มต้น
  บางส่วน พิจารณาใช้[แพตเทิร์นบิลเดอร์](../patterns/creational/builder.md)แทน

- หาก API ระหว่างชนิดไม่เปลี่ยน -- เปลี่ยนเฉพาะพฤติกรรม -- ควรใช้
  [แพตเทิร์นกลยุทธ์](../patterns/behavioural/strategy.md)แทน

## ดูเพิ่มเติม

แพตเทิร์นนี้ถูกใช้ทั่วไลบรารีมาตรฐาน:

- `Vec<u8>` สามารถถูกแปลงมาจาก String ได้ ต่างจาก `Vec<T>` ชนิดอื่นๆ[^1]
- อิเทอเรเตอร์สามารถถูกแปลงเป็น binary heap ได้ แต่เฉพาะเมื่อมีชนิดที่
  อิมพลีเมนต์ trait `Ord`[^2]
- เมท็อด `to_string` ถูกทำให้เฉพาะทางสำหรับ `Cow` ของชนิด `str` เท่านั้น[^3]

มันยังถูกใช้โดยครีตยอดนิยมหลายตัวเพื่อเพิ่มความยืดหยุ่นของ API:

- ระบบนิเวศ `embedded-hal` ที่ใช้กับอุปกรณ์ฝังตัวใช้แพตเทิร์นนี้อย่างมาก
  ตัวอย่างเช่น ช่วยตรวจสอบการตั้งค่าของรีจิสเตอร์อุปกรณ์ที่ใช้ควบคุมพินแบบฝังตัว
  ได้ตั้งแต่ตอนคอมไพล์ เมื่อพินถูกใส่เข้าโหมดหนึ่ง มันจะคืน struct `Pin<MODE>`
  ซึ่งเจเนอริกของมันกำหนดฟังก์ชันที่ใช้ได้ในโหมดนั้น และฟังก์ชันเหล่านั้นไม่ได้อยู่บน
  `Pin` เอง [^4]

- ไลบรารีไคลเอนต์ HTTP `hyper` ใช้วิธีนี้เพื่อเปิดเผย API ที่สมบูรณ์สำหรับคำขอ
  แบบเสียบปลั๊กได้ต่างๆ ไคลเอนต์ที่มีตัวเชื่อมต่างกันมีเมท็อดต่างกันรวมถึงการ
  อิมพลีเมนต์ trait ที่ต่างกัน ขณะที่เมท็อดชุดแกนกลางใช้กับตัวเชื่อมใดก็ได้ [^5]

- แพตเทิร์น "type state" -- ที่ออบเจกต์ได้มาและสูญเสีย API ตามสถานะภายในหรือ
  invariant -- ถูกอิมพลีเมนต์ใน Rust ด้วยแนวคิดพื้นฐานเดียวกันและเทคนิคที่ต่าง
  ออกไปเล็กน้อย [^6]

[^1]: ดู:
    [impl From\<CString\> for Vec\<u8\>](https://doc.rust-lang.org/1.59.0/src/std/ffi/c_str.rs.html#803-811)

[^2]: ดู:
    [impl\<T: Ord\> FromIterator\<T\> for BinaryHeap\<T\>](https://web.archive.org/web/20201030132806/https://doc.rust-lang.org/stable/src/alloc/collections/binary_heap.rs.html#1330-1335)

[^3]: ดู:
    [impl\<'\_\> ToString for Cow\<'\_, str>](https://doc.rust-lang.org/stable/src/alloc/string.rs.html#2235-2240)

[^4]: ตัวอย่าง:
    [https://docs.rs/stm32f30x-hal/0.1.0/stm32f30x_hal/gpio/gpioa/struct.PA0.html](https://docs.rs/stm32f30x-hal/0.1.0/stm32f30x_hal/gpio/gpioa/struct.PA0.html)

[^5]: ดู:
    [https://docs.rs/hyper/0.14.5/hyper/client/struct.Client.html](https://docs.rs/hyper/0.14.5/hyper/client/struct.Client.html)

[^6]: ดู:
    [The Case for the Type State Pattern](https://web.archive.org/web/20210325065112/https://www.novatec-gmbh.de/en/blog/the-case-for-the-typestate-pattern-the-typestate-pattern-itself/)
    และ
    [Rusty Typestate Series (วิทยานิพนธ์ฉบับละเอียด)](https://web.archive.org/web/20210328164854/https://rustype.github.io/notes/notes/rust-typestate-series/rust-typestate-index)
