# พจนานุกรมศัพท์ (Glossary) — Rust Design Patterns ฉบับภาษาไทย

ตารางนี้เป็นคำศัพท์ที่ใช้อย่างสม่ำเสมอตลอดทั้งเล่ม เพื่อให้การแปลทุกบทใช้คำเดียวกัน

| ศัพท์ต้นฉบับ | คำแปลไทย | หมายเหตุ |
|---|---|---|
| design pattern | ดีไซน์แพตเทิร์น | กล่าวถึงครั้งแรกด้วย "รูปแบบการออกแบบ (design pattern)" |
| anti-pattern | แอนติแพตเทิร์น | กล่าวถึงครั้งแรกด้วย "รูปแบบต่อต้าน (anti-pattern)" |
| idiom | สำนวน (idiom) | ชื่อหมวด Idioms ใช้ "สำนวน" |
| pattern | แพตเทิร์น | |
| trait | trait (คงชื่อเดิม) | คำสงวนของภาษา Rust จึงคงรูปเดิมทั้งเล่ม |
| struct | struct (คงชื่อเดิม) | คำสงวนของภาษา Rust |
| enum | enum (คงชื่อเดิม) | คำสงวนของภาษา Rust |
| impl | impl (คงชื่อเดิม) | คำสงวนของภาษา Rust |
| derive | derive (คงชื่อเดิม) | คำสั่งของภาษา Rust |
| unsafe | unsafe (คงชื่อเดิม) | คีย์เวิร์ดของภาษา Rust |
| ownership | ความเป็นเจ้าของ | ระบบความเป็นเจ้าของของ Rust |
| borrowing | การยืม | |
| borrow checker | borrow checker | ตัวตรวจสอบการยืมของคอมไพเลอร์ |
| lifetime | ไลฟ์ไทม์ | |
| generic(s) | เจเนอริก | |
| closure | โคลเชอร์ | |
| iterator | อิเทอเรเตอร์ | |
| crate | ครีต | |
| module | โมดูล | |
| macro | มาโคร | |
| smart pointer | สมาร์ตพอยน์เตอร์ | |
| newtype | นิวไทป์ | แพตเทิร์นหนึ่งในเล่ม |
| builder | บิลเดอร์ | แพตเทิร์นหนึ่งในเล่ม |
| wrapper | ตัวห่อ (wrapper) | |
| compiler | คอมไพเลอร์ | |
| compile | คอมไพล์ | |
| runtime | รันไทม์ | |
| refactoring | การรีแฟกเตอร์ | |
| abstraction | นามธรรม (abstraction) | |
| polymorphism | พอลิมอร์ฟิซึม | |
| instantiate | สร้างอินสแตนซ์ | |
| mutable / immutable | ที่แก้ไขได้ / แก้ไขไม่ได้ | |
| allocation | การจัดสรรหน่วยความจำ | |
| stack | สแตก | |
| heap | ฮีป | |
| expression | นิพจน์ | |
| statement | คำสั่ง (statement) | |
| pattern matching | การจับคู่แพตเทิร์น | |
| error handling | การจัดการข้อผิดพลาด | |
| API | API | คงชื่อเดิม |
| FFI | FFI | Foreign Function Interface |
| UB | พฤติกรรมที่ไม่ได้นิยาม (UB) | Undefined Behavior |
| RFC | RFC | คงชื่อเดิม |

## หลักการทั่วไป

- ชื่อเครื่องมือ คำสั่ง CLI ตัวเลือก (flag) ชื่อแพ็กเกจ และ URL **ไม่แปล** เช่น `cargo`, `rustc`, `#[derive(Debug)]`, `Option<T>`
- โค้ดทุกบล็อก (``` ... ```) เก็บไว้ตามต้นฉบับทุกตัวอักษร รวมถึงคอมเมนต์ภายในโค้ด
- ลิงก์ (ทั้ง inline และ reference-style) คง path เดิม เพื่อให้ mdbook ยัง build ได้
- ชื่อ trait, struct, enum, ฟังก์ชัน และเมท็อดในโค้ด ไม่แปล
- หัวข้อ (heading) แปลเป็นไทย แต่ anchor ของลิงก์ภายในเล่มอ่านจาก HTML ที่ build แล้วเสมอ (mdbook ตัดวรรณยุกต์ไทยออกจาก slug) จึงไม่เดา anchor เอง
