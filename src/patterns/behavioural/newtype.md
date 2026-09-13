# นิวไทป์

จะเป็นอย่างไรหากในบางกรณีเราต้องการให้ชนิดข้อมูลหนึ่งมีพฤติกรรมคล้ายกับอีกชนิดหนึ่ง หรือบังคับพฤติกรรมบางอย่างตั้งแต่ตอนคอมไพล์ ในเมื่อการใช้เพียง type alias ไม่เพียงพอ?

ตัวอย่างเช่น หากเราต้องการสร้างการอิมพลีเมนต์ `Display` แบบกำหนดเองให้กับ `String` ด้วยเหตุผลด้านความปลอดภัย (เช่น รหัสผ่าน)

ในกรณีเช่นนี้ เราสามารถใช้แพตเทิร์น `Newtype` เพื่อมอบ**ความปลอดภัยของชนิด** (type safety) และ**การห่อหุ้ม** (encapsulation) ได้

## คำอธิบาย

ใช้ tuple struct ที่มีหนึ่งฟิลด์เพื่อสร้างตัวห่อทึบแสงให้กับชนิดข้อมูล วิธีนี้สร้างชนิดข้อมูลใหม่ขึ้นมา แทนที่จะเป็นชื่อเรียกแทนชนิดเดิม (`type` items)

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

แรงจูงใจหลักของนิวไทป์คือนามธรรม (abstraction) มันช่วยให้คุณแบ่งปันรายละเอียดการอิมพลีเมนต์ระหว่างชนิดข้อมูลต่างๆ ขณะเดียวกันก็ควบคุมอินเทอร์เฟซได้อย่างแม่นยำ การใช้นิวไทป์แทนการเปิดเผยชนิดที่อิมพลีเมนต์เป็นส่วนหนึ่งของ API ช่วยให้คุณเปลี่ยนการอิมพลีเมนต์ได้โดยยังเข้ากันได้ย้อนหลัง

นิวไทป์ใช้จำแนกหน่วยวัดได้ เช่น ห่อ `f64` เพื่อให้ได้ `Miles` และ `Kilometres` ที่แยกออกจากกันได้

## ข้อดี

ชนิดที่ถูกห่อและชนิดที่ห่อไม่เข้ากันทางชนิดข้อมูล (ต่างจากการใช้ `type`) ผู้ใช้นิวไทป์จึงไม่มีทาง "สับสน" ระหว่างชนิดที่ถูกห่อกับชนิดที่ห่อได้เลย

นิวไทป์เป็นนามธรรมที่ไม่มีค่าใช้จ่าย (zero-cost abstraction) - ไม่มี overhead ตอนรันไทม์

ระบบความเป็นส่วนตัวรับประกันว่าผู้ใช้ไม่สามารถเข้าถึงชนิดที่ถูกห่อได้ (หากฟิลด์เป็นส่วนตัว ซึ่งเป็นค่าเริ่มต้นอยู่แล้ว)

## ข้อเสีย

ข้อเสียของนิวไทป์ (โดยเฉพาะเมื่อเทียบกับ type alias) คือไม่มีการรองรับระดับภาษาเป็นพิเศษ หมายความว่าอาจมีโค้ด boilerplate *จำนวนมาก* คุณต้องมีเมท็อด "ส่งผ่าน" สำหรับทุกเมท็อดที่ต้องการเปิดเผยบนชนิดที่ถูกห่อ และต้องมี impl สำหรับทุก trait ที่ต้องการให้อิมพลีเมนต์บนชนิดที่ห่อด้วย

## การอภิปราย

นิวไทป์พบได้ทั่วไปมากในโค้ด Rust การวางนามธรรมหรือการแทนหน่วยวัดเป็นกรณีใช้ที่พบบ่อยที่สุด แต่ยังใช้ด้วยเหตุผลอื่นได้อีก:

- จำกัดฟังก์ชันการทำงาน (ลดฟังก์ชันที่เปิดเผยหรือ trait ที่อิมพลีเมนต์)
- ทำให้ชนิดที่มีความหมายเชิงคัดลอก (copy semantics) มีความหมายเชิงย้าย (move
  semantics)
- สร้างนามธรรมโดยนำเสนอชนิดที่ชัดเจนขึ้นและซ่อนชนิดภายใน เช่น

```rust,ignore
pub struct Foo(Bar<T1, T2>);
```

ในที่นี้ `Bar` อาจเป็นชนิดสาธารณะแบบเจเนอริก และ `T1` กับ `T2` เป็นชนิดภายใน ผู้ใช้โมดูลของเราไม่ควรรู้ว่าเราอิมพลีเมนต์ `Foo` โดยใช้ `Bar` แต่สิ่งที่เราซ่อนจริงๆ ในที่นี้คือชนิด `T1` และ `T2` กับวิธีที่มันถูกใช้ร่วมกับ `Bar`

## ดูเพิ่มเติม

- [Advanced Types ในหนังสือ The Rust Book](https://doc.rust-lang.org/book/ch19-04-advanced-types.html?highlight=newtype#using-the-newtype-pattern-for-type-safety-and-abstraction)
- [Newtypes ใน Haskell](https://wiki.haskell.org/Newtype)
- [Type aliases](https://doc.rust-lang.org/stable/book/ch19-04-advanced-types.html#creating-type-synonyms-with-type-aliases)
- [derive_more](https://crates.io/crates/derive_more) ครีตสำหรับ derive trait
  ในตัวหลายตัวบนนิวไทป์
- [The Newtype Pattern In Rust](https://web.archive.org/web/20230519162111/https://www.worthe-it.co.za/blog/2020-10-31-newtype-pattern-in-rust.html)
