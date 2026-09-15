# นิวไทป์ (Newtype)

จะเป็นอย่างไรหากในบางสถานการณ์ เราต้องการให้ชนิดข้อมูลหนึ่งมีพฤติกรรมคล้ายคลึงกับอีกชนิดหนึ่ง หรือต้องการบังคับใช้กฎเกณฑ์บางอย่างตั้งแต่ขั้นตอนการคอมไพล์ โดยที่การประกาศเพียงนามแฝงของชนิดข้อมูล (type alias) นั้นไม่เพียงพอ?

ตัวอย่างเช่น เราอาจต้องการปรับแต่งการแสดงผลของ `Display` สำหรับ `String` เพื่อจุดประสงค์ด้านความปลอดภัย (เช่น การซ่อนรหัสผ่าน)

ในกรณีเช่นนี้ เราสามารถเลือกใช้แพตเทิร์น `Newtype` เพื่อสร้าง**ความปลอดภัยของชนิดข้อมูล** (type safety) ควบคู่ไปกับ**การห่อหุ้มข้อมูล** (encapsulation) ได้อย่างสมบูรณ์แบบ

## คำอธิบาย

ใช้ tuple struct ที่มีเพียงฟิลด์เดียวเพื่อสร้างตัวห่อหุ้มที่ซ่อนรายละเอียดภายใน (opaque wrapper) ให้กับชนิดข้อมูลเดิม ซึ่งจะทำให้เกิดชนิดข้อมูลตัวใหม่ขึ้นมาจริงๆ ไม่ใช่เพียงแค่ชื่อเรียกแทนหรือนามแฝงเหมือนกับการใช้ `type`

## ตัวอย่าง

```rust
use std::fmt::Display;

// Create Newtype Password to override the Display trait for String
struct Password(String);

impl Display for Password {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "****************")
    }
}

fn main() {
    let unsecured_password: String = "ThisIsMyPassword".to_string();
    let secured_password: Password = Password(unsecured_password.clone());
    println!("unsecured_password: {unsecured_password}");
    println!("secured_password: {secured_password}");
}
```

```shell
unsecured_password: ThisIsMyPassword
secured_password: ****************
```

## แรงจูงใจ

แรงจูงใจสำคัญประการแรกของการใช้ Newtype คือการสร้างการถอดรหัสนามธรรม (abstraction) ซึ่งช่วยให้เราสามารถแชร์รายละเอียดการทำงานร่วมกันระหว่างชนิดข้อมูลต่างๆ ได้ ในขณะที่ยังสามารถควบคุมอินเทอร์เฟซภายนอกได้อย่างรัดกุม การเลือกใช้ Newtype แทนที่จะเปิดเผยชนิดข้อมูลภายในออกไปเป็นส่วนหนึ่งของ API ช่วยให้เราสามารถปรับปรุงแก้ไขการทำงานภายในได้โดยไม่ส่งผลกระทบต่อความเข้ากันได้ย้อนหลัง (backward compatibility)

นอกจากนี้ Newtype ยังนิยมนำมาใช้แยกแยะหน่วยวัดทางกายภาพ เช่น การนำ `f64` มาห่อหุ้มเพื่อแยกชนิดข้อมูลระหว่าง `Miles` (ไมล์) กับ `Kilometres` (กิโลเมตร) ออกจากกันอย่างเด็ดขาด

## ข้อดี

ชนิดข้อมูลภายในที่ถูกห่อหุ้มกับชนิดข้อมูล Newtype ภายนอกจะถือเป็นคนละชนิดข้อมูลกันโดยสิ้นเชิงและไม่สามารถใช้สลับแทนกันได้โดยตรง (ต่างจากการใช้ `type alias`) ผู้ใช้งาน Newtype จึงไม่มีโอกาสเกิดความสับสนหรือส่งข้อมูลผิดชนิดอย่างแน่นอน

Newtype ถือเป็น zero-cost abstraction โดยสมบูรณ์ — ไม่ก่อให้เกิด overhead หรือภาระประสิทธิภาพเพิ่มเติมขณะรันไทม์เลย

ระบบควบคุมการเข้าถึง (privacy system) ของ Rust ช่วยรับประกันได้ว่าผู้ใช้งานจะไม่สามารถแอบเข้าถึงชนิดข้อมูลภายในที่ถูกห่อไว้ได้ (หากกำหนดให้ฟิลด์นั้นเป็น private ซึ่งเป็นค่าเริ่มต้นอยู่แล้ว)

## ข้อเสีย

ข้อจำกัดสำคัญของ Newtype (โดยเฉพาะเมื่อเทียบกับ type alias) คือภาษา Rust ไม่ได้มีไวยากรณ์พิเศษมาช่วยส่งต่อเมท็อดให้อัตโนมัติ ซึ่งหมายความว่าเราอาจต้องเขียนโค้ด boilerplate *ค่อนข้างมาก* โดยเราต้องเขียนเมท็อดส่งต่อการทำงาน (pass-through method) สำหรับทุกฟังก์ชันที่ต้องการเปิดเผยออกมาจากชนิดข้อมูลภายใน และต้องเขียนบล็อก `impl` สำหรับทุก trait ที่ต้องการให้ Newtype ภายนอกใช้งานได้ด้วย

## การอภิปราย

Newtype เป็นแพตเทิร์นที่พบเห็นได้ทั่วไปอย่างยิ่งในโค้ดภาษา Rust การสร้าง abstraction และการจำแนกหน่วยวัดถือเป็นกรณีการใช้งานหลัก แต่นอกจากนี้ยังสามารถนำไปประยุกต์ใช้ในลักษณะอื่นได้อีก:

- การจำกัดฟังก์ชันการทำงาน (ลดจำนวนฟังก์ชันที่เปิดเผย หรือลด trait ที่นำไปใช้งาน)
- การเปลี่ยนให้ชนิดข้อมูลที่มี copy semantics มีพฤติกรรมกลายเป็น move semantics แทน
- การสร้าง abstraction เพื่อนำเสนอชนิดข้อมูลที่ชัดเจนยิ่งขึ้น และซ่อนชนิดข้อมูลภายในที่ซับซ้อน เช่น:

```rust,ignore
pub struct Foo(Bar<T1, T2>);
```

ในกรณีนี้ `Bar` อาจเป็นชนิดข้อมูล generic สาธารณะ ขณะที่ `T1` และ `T2` เป็นชนิดข้อมูลภายใน ผู้ใช้งานโมดูลไม่จำเป็นต้องทราบว่าเราอิมพลีเมนต์ `Foo` โดยอิงกับ `Bar` และสิ่งที่เราซ่อนไว้จากภายนอกอย่างแท้จริงก็คือชนิดข้อมูล `T1`, `T2` ตลอดจนรูปแบบการประกอบเข้ากับ `Bar`

## ดูเพิ่มเติม

- [Advanced Types ในหนังสือ The Rust Book](https://doc.rust-lang.org/book/ch19-04-advanced-types.html?highlight=newtype#using-the-newtype-pattern-for-type-safety-and-abstraction)
- [Newtypes ใน Haskell](https://wiki.haskell.org/Newtype)
- [Type aliases](https://doc.rust-lang.org/stable/book/ch19-04-advanced-types.html#creating-type-synonyms-with-type-aliases)
- [derive_more](https://crates.io/crates/derive_more) crate สำหรับ derive trait พื้นฐานจำนวนมากให้กับนิวไทป์โดยอัตโนมัติ
- [The Newtype Pattern In Rust](https://web.archive.org/web/20230519162111/https://www.worthe-it.co.za/blog/2020-10-31-newtype-pattern-in-rust.html)
