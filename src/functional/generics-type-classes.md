# เจเนอริกในฐานะ Type Classes

## คำอธิบาย

ระบบชนิดข้อมูล (Type System) ของ Rust ได้รับการออกแบบให้มีความใกล้เคียงกับภาษาเชิงฟังก์ชัน (อย่างเช่น Haskell) มากกว่าภาษาเชิงอิมเพอเรทีฟ (อย่าง Java หรือ C++) ผลลัพธ์คือ Rust สามารถเปลี่ยนโจทย์ปัญหาการเขียนโปรแกรมหลายประเภทให้กลายเป็นปัญหาการตรวจสอบชนิดข้อมูลแบบคงที่ (Static Typing) ได้ตั้งแต่ตอนคอมไพล์ ซึ่งนี่คือหนึ่งในข้อได้เปรียบที่ทรงพลังที่สุดของการเลือกใช้แนวคิดเชิงฟังก์ชัน และเป็นหัวใจสำคัญของการรับประกันความถูกต้องในขั้นตอนคอมไพล์ (Compile-time Guarantees) ของ Rust

หัวใจสำคัญของแนวคิดนี้คือวิธีการทำงานของชนิดข้อมูลเจเนอริก (Generics) ในภาษาอย่าง C++ และ Java ชนิดข้อมูลเจเนอริกจะทำหน้าที่เสมือนโครงสร้าง Metaprogramming สำหรับคอมไพเลอร์ เช่น `vector<int>` และ `vector<char>` ใน C++ เป็นเพียงสำเนาโค้ด boilerplate สองชุดของคลาส `vector` เดียวกัน (หรือที่รู้จักกันในชื่อ `template`) โดยแค่แทนที่ชนิดข้อมูลที่แตกต่างกันลงไป

แต่ใน Rust พารามิเตอร์ของเจเนอริกจะสร้างสิ่งที่ในภาษาเชิงฟังก์ชันเรียกว่า "ข้อกำหนดขอบเขตของ Type Class (Type Class Constraint)" และพารามิเตอร์แต่ละตัวที่ผู้ใช้นำมากำหนด จะส่งผลให้*เกิดชนิดข้อมูลใหม่ขึ้นมาจริงๆ* กล่าวคือ `Vec<isize>` กับ `Vec<char>` *ถือเป็นคนละชนิดข้อมูลกันโดยสิ้นเชิง* ซึ่งทุกส่วนของระบบ Type System จะมองเห็นว่าเป็นสองชนิดที่แยกขาดจากกัน

กระบวนการนี้เรียกว่า **Monomorphization** ซึ่งเป็นการสร้างชนิดข้อมูลที่เป็นรูปธรรมขึ้นมาจากโค้ดแบบ**พอลิมอร์ฟิก (Polymorphic Code)** พฤติกรรมพิเศษนี้กำหนดให้บล็อก `impl` ต้องระบุพารามิเตอร์เจเนอริกให้ชัดเจน ค่าของชนิดข้อมูลเจเนอริกที่ต่างกันจะทำให้ได้ชนิดข้อมูลที่ต่างกัน และชนิดข้อมูลที่ต่างกันก็สามารถมีบล็อก `impl` แยกเป็นของตัวเองได้

ในภาษาเชิงวัตถุ คลาสสามารถสืบทอดพฤติกรรมจากคลาสแม่ได้ แต่กลไกของ Rust นี้ไม่เพียงแต่อนุญาตให้เราเพิ่มพฤติกรรมเฉพาะให้กับสมาชิกบางตัวของ Type Class ได้เท่านั้น แต่ยังสามารถแนบพฤติกรรมพิเศษอื่นๆ เพิ่มเติมเข้าไปได้อีกด้วย

สิ่งที่ใกล้เคียงที่สุดคือ Runtime Polymorphism ใน JavaScript หรือ Python ที่คอนสตรัคเตอร์ใดๆ ก็สามารถเพิ่มสมาชิกหรือเมท็อดใหม่ๆ เข้าไปในออบเจกต์ได้อย่างอิสระตามใจชอบ อย่างไรก็ตาม สิ่งที่ทำให้ Rust เหนือกว่าภาษาเหล่านั้นคือ ทุกเมท็อดที่เพิ่มเข้ามาจะถูกตรวจสอบความถูกต้องของชนิดข้อมูล (Type Check) ได้อย่างแม่นยำตั้งแต่ตอนคอมไพล์ เพราะเจเนอริกทั้งหมดถูกนิยามไว้อย่างคงที่ (Static) ทำให้มีความสะดวกสบายในการใช้งานควบคู่ไปกับความปลอดภัยสูงสุด

## ตัวอย่าง

สมมติว่าคุณกำลังออกแบบเซิร์ฟเวอร์จัดเก็บข้อมูลสำหรับเครื่องคอมพิวเตอร์ในห้องทดลอง เนื่องจากข้อกำหนดของระบบ คุณจึงจำเป็นต้องรองรับโปรโตคอลสองรูปแบบที่แตกต่างกัน: ได้แก่ BOOTP (สำหรับการบูตเครื่องผ่านเครือข่าย PXE) และ NFS (สำหรับพื้นที่จัดเก็บข้อมูลแบบ Remote Mount)

เป้าหมายของคุณคือการสร้างโปรแกรมตัวเดียวด้วย Rust ที่สามารถรองรับและจัดการทั้งสองโปรโตคอลได้อย่างมีประสิทธิภาพ ตัวโปรแกรมจะมีตัวจัดการโปรโตคอล (Protocol Handler) คอยรับฟังคำขอทั้งสองรูปแบบ และมีตรรกะหลักของแอปพลิเคชันที่เปิดให้ผู้ดูแลระบบสามารถกำหนดค่าพื้นที่จัดเก็บและสิทธิ์ความปลอดภัยสำหรับไฟล์จริงได้

คำขอไฟล์จากเครื่องในห้องทดลองจะมีข้อมูลพื้นฐานที่เหมือนกัน ไม่ว่าจะส่งมาจากโปรโตคอลใดก็ตาม นั่นคือ: วิธีการยืนยันตัวตน (Authentication Method) และชื่อไฟล์ที่ต้องการดึง การเขียนโค้ดแบบตรงไปตรงมาอาจมีหน้าตาประมาณนี้:

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

การออกแบบลักษณะนี้อาจทำงานได้ดีในระดับหนึ่ง แต่สมมติว่าในเวลาต่อมา คุณจำเป็นต้องรองรับการเก็บ metadata ที่*เจาะจงเฉพาะโปรโตคอลนั้นๆ* ตัวอย่างเช่น ในกรณีของ NFS คุณต้องการทราบจุดเมานต์ (Mount Point) เพื่อบังคับใช้กฎความปลอดภัยเพิ่มเติม

วิธีที่ struct ข้างต้นถูกออกแบบไว้ จะเลื่อนการตัดสินใจเลือกโปรโตคอลไปจนถึงช่วงรันไทม์ นั่นหมายความว่า หากมีเมท็อดใดที่ใช้ได้เฉพาะกับโปรโตคอลหนึ่งแต่ใช้ไม่ได้กับอีกโปรโตคอลหนึ่ง โปรแกรมเมอร์จะต้องเขียนโค้ดตรวจสอบเงื่อนไขตอนรันไทม์เสมอ

นี่คือตัวอย่างโค้ดเมื่อต้องการดึงจุดเมานต์ของ NFS:

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

ส่งผลให้โค้ดทุกจุดที่เรียกใช้ `mount_point()` จะต้องคอยเช็กค่า `None` และเขียนโค้ดดักไว้เสมอ แม้ว่าผู้เขียนโค้ดจะทราบดีอยู่แล้วว่าในเส้นทางการทำงานตรงนั้นจะมีเพียงคำขอแบบ NFS เท่านั้นก็ตาม!

จะดีกว่ามากหากเราสามารถทำให้คอมไพเลอร์แจ้งเตือนข้อผิดพลาดตั้งแต่ตอนคอมไพล์ (Compile-time Error) หากมีการเรียกใช้เมท็อดผิดประเภท เพราะตามความเป็นจริง โค้ดของผู้ใช้ย่อมทราบแน่ชัดอยู่แล้วว่าคำขอที่กำลังจัดการอยู่นั้นเป็น NFS หรือ BOOTP

ในภาษา Rust เราสามารถทำเช่นนั้นได้จริง! โดยทางออกคือการ*นำชนิดข้อมูลเจเนอริกเข้ามาใช้* เพื่อแยก API ออกจากกันตามชนิดข้อมูล

โครงสร้างโค้ดจะมีลักษณะดังนี้:

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

ด้วยแนวทางนี้ หากผู้ใช้เผลอทำผิดพลาดโดยส่งชนิดข้อมูลผิดประเภท:

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

คอมไพเลอร์จะฟ้อง compile error ทันที เนื่องจากชนิดข้อมูล `FileDownloadRequest<Bootp>` ไม่ได้มีการอิมพลีเมนต์เมท็อด `mount_point()` ไว้ มีเพียงชนิดข้อมูล `FileDownloadRequest<Nfs>` เท่านั้นที่มีเมท็อดนี้ และออบเจกต์ดังกล่าวก็ถูกสร้างขึ้นมาจากโมดูล NFS เท่านั้น ไม่ใช่โมดูล BOOTP!

## ข้อดี

ประการแรก ช่วยลดความซ้ำซ้อนของฟิลด์ที่ใช้งานร่วมกันในหลายสถานะ โดยการนำฟิลด์ส่วนที่ไม่เหมือนกันมาแยกเป็นเจเนอริก ทำให้ฟิลด์ส่วนกลางถูกเขียนขึ้นเพียงครั้งเดียว

ประการที่สอง ช่วยให้บล็อก `impl` อ่านและทำความเข้าใจได้ง่ายขึ้น เพราะโค้ดถูกแบ่งแยกตามสถานะอย่างชัดเจน เมท็อดที่ใช้ร่วมกันทุกสถานะจะรวมอยู่ในบล็อกเดียว ส่วนเมท็อดที่จำเพาะสำหรับแต่ละสถานะก็จะแยกไปอยู่ในบล็อกของตัวเอง

ทั้งสองประการนี้ช่วยลดจำนวนบรรทัดของโค้ดลง และทำให้โครงสร้างโปรแกรมเป็นระเบียบเรียบร้อยยิ่งขึ้น

## ข้อเสีย

ในปัจจุบัน แนวทางนี้จะทำให้ขนาดของไฟล์ไบนารีเพิ่มขึ้นเล็กน้อย เนื่องจากกลไก Monomorphization ของคอมไพเลอร์ ซึ่งหวังว่าจะได้รับการปรับปรุงให้ดียิ่งขึ้นในอนาคต

## ทางเลือกอื่น

- หากชนิดข้อมูลต้องการ "API แยกส่วน" อันเนื่องมาจากขั้นตอนการสร้างออบเจกต์หรือการกำหนดค่าเริ่มต้นเพียงบางส่วน ควรพิจารณาใช้[แพตเทิร์นบิลเดอร์](../patterns/creational/builder.md)แทน

- หาก API ระหว่างแต่ละชนิดข้อมูลเหมือนกันทุกประการและเปลี่ยนแปลงเฉพาะพฤติกรรมการทำงาน ควรพิจารณาใช้[แพตเทิร์นกลยุทธ์](../patterns/behavioural/strategy.md)แทน

## ดูเพิ่มเติม

แพตเทิร์นนี้ถูกนำมาใช้อย่างแพร่หลายในไลบรารีมาตรฐานของ Rust:

- `Vec<u8>` สามารถแปลงมาจาก String ได้ ซึ่งไม่เหมือนกับ `Vec<T>` ชนิดอื่นๆ[^1]
- อิเทอเรเตอร์สามารถแปลงเป็น binary heap ได้ แต่เฉพาะเมื่อสมาชิกภายในเป็นชนิดที่อิมพลีเมนต์ trait `Ord` เท่านั้น[^2]
- เมท็อด `to_string` ถูกกำหนดไว้เฉพาะสำหรับ `Cow` ที่มีชนิดข้อมูลเป็น `str` เท่านั้น[^3]

นอกจากนี้ ยังมี crate ยอดนิยมหลายตัวที่นำแพตเทิร์นนี้มาใช้เพื่อเพิ่มความยืดหยุ่นให้แก่ API:

- ระบบนิเวศ `embedded-hal` สำหรับอุปกรณ์สมองกลฝังตัว นำแพตเทิร์นนี้มาใช้อย่างเข้มข้น ตัวอย่างเช่น ใช้ตรวจสอบการกำหนดค่าของรีจิสเตอร์ที่ควบคุมขาพินฮาร์ดแวร์ได้ตั้งแต่ตอนคอมไพล์ เมื่อพินถูกกำหนดเข้าสู่โหมดหนึ่ง จะคืนค่า struct `Pin<MODE>` ออกมา ซึ่งเจเนอริกจะคอยระบุว่าฟังก์ชันใดบ้างที่เรียกใช้งานได้ในโหมดนั้นๆ โดยที่ฟังก์ชันเหล่านั้นไม่ได้อยู่บนตัว `Pin` เปล่าๆ [^4]

- ไลบรารี HTTP client `hyper` ใช้แนวทางนี้เพื่อเปิดเผย API ที่หลากหลายตามรูปแบบคำขอ โดย client ที่มีคอนเนกเตอร์ต่างกันจะมีเมท็อดและการอิมพลีเมนต์ trait ที่แตกต่างกันออกไป ในขณะที่เมท็อดแกนหลักยังคงใช้ร่วมกันได้กับทุกคอนเนกเตอร์ [^5]

- แพตเทิร์น "Typestate" -- ที่ออบเจกต์จะได้รับหรือสูญเสียความสามารถของ API ตามสถานะภายในตัวมัน (Invariant) -- ก็ถูกนำมาอิมพลีเมนต์ใน Rust โดยใช้แนวคิดพื้นฐานเดียวกันนี้ แต่มีเทคนิคปลีกย่อยที่แตกต่างกันเล็กน้อย [^6]

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
