# `#[non_exhaustive]` และฟิลด์ส่วนตัวเพื่อการขยายต่อ

## คำอธิบาย

มีสถานการณ์จำนวนหนึ่งที่ผู้เขียนไลบรารีอาจต้องการเพิ่มฟิลด์สาธารณะให้กับ struct สาธารณะ หรือเพิ่ม variant ใหม่ให้กับ enum โดยไม่ทำลายความเข้ากันได้ย้อนหลัง

Rust นำเสนอทางออกสองทางสำหรับปัญหานี้:

- ใช้ `#[non_exhaustive]` กับ `struct`, `enum` และ variant ของ `enum` สำหรับ
  เอกสารฉบับละเอียดเกี่ยวกับทุกที่ที่ใช้ `#[non_exhaustive]` ได้ ดู
  [เอกสารประกอบ](https://doc.rust-lang.org/reference/attributes/type_system.html#the-non_exhaustive-attribute)

- คุณเพิ่มฟิลด์ส่วนตัว (private field) ให้กับ struct เพื่อป้องกันไม่ให้สร้าง
  อินสแตนซ์โดยตรงหรือจับคู่แพตเทิร์นกับมันได้ (ดูทางเลือก)

## ตัวอย่าง

```rust
mod a {
    // Public struct.
    #[non_exhaustive]
    pub struct S {
        pub foo: i32,
    }

    #[non_exhaustive]
    pub enum AdmitMoreVariants {
        VariantA,
        VariantB,
        #[non_exhaustive]
        VariantC {
            a: String,
        },
    }
}

fn print_matched_variants(s: a::S) {
    // Because S is `#[non_exhaustive]`, it cannot be named here and
    // we must use `..` in the pattern.
    let a::S { foo: _, .. } = s;

    let some_enum = a::AdmitMoreVariants::VariantA;
    match some_enum {
        a::AdmitMoreVariants::VariantA => println!("it's an A"),
        a::AdmitMoreVariants::VariantB => println!("it's a b"),

        // .. required because this variant is non-exhaustive as well
        a::AdmitMoreVariants::VariantC { a, .. } => println!("it's a c"),

        // The wildcard match is required because more variants may be
        // added in the future
        _ => println!("it's a new variant"),
    }
}
```

## ทางเลือก: `Private fields` สำหรับ struct

`#[non_exhaustive]` ใช้ได้เฉพาะข้ามขอบเขตของครีตเท่านั้น ภายในครีตเดียวกันอาจใช้วิธีเพิ่มฟิลด์ส่วนตัวได้

การเพิ่มฟิลด์ให้กับ struct เป็นการเปลี่ยนแปลงที่เข้ากันได้ย้อนหลังเป็นส่วนใหญ่ อย่างไรก็ตาม หากไคลเอนต์ใช้แพตเทิร์นเพื่อแยกส่วนอินสแตนซ์ของ struct พวกเขาอาจระบุชื่อฟิลด์ทั้งหมดใน struct และการเพิ่มฟิลด์ใหม่จะทำลายแพตเทิร์นนั้น ไคลเอนต์อาจระบุชื่อเพียงบางฟิลด์แล้วใช้ `..` ในแพตเทิร์น ซึ่งในกรณีนั้นการเพิ่มฟิลด์อีกหนึ่งฟิลด์ยังคงเข้ากันได้ย้อนหลัง การทำให้ฟิลด์อย่างน้อยหนึ่งฟิลด์ของ struct เป็นส่วนตัวจะบังคับให้ไคลเอนต์ใช้แพตเทิร์นรูปแบบหลัง ซึ่งรับประกันว่า struct นั้นพร้อมรองรับอนาคต

ข้อเสียของแนวทางนี้คือคุณอาจต้องเพิ่มฟิลด์ที่ไม่จำเป็นอื่นๆ เข้าไปใน struct คุณใช้ชนิด `()` ได้เพื่อไม่ให้มีค่าใช้จ่ายตอนรันไทม์ และเติม `_` นำหน้าชื่อฟิลด์เพื่อหลีกเลี่ยงคำเตือนเรื่องฟิลด์ที่ไม่ได้ใช้

```rust
pub struct S {
    pub a: i32,
    // Because `b` is private, you cannot match on `S` without using `..` and `S`
    //  cannot be directly instantiated or matched against
    _b: (),
}
```

## การอภิปราย

สำหรับ `struct` แล้ว `#[non_exhaustive]` ช่วยให้เพิ่มฟิลด์เพิ่มเติมได้ในแบบที่เข้ากันได้ย้อนหลัง มันยังป้องกันไม่ให้ไคลเอนต์ใช้คอนสตรัคเตอร์ของ struct แม้ว่าทุกฟิลด์จะเป็นสาธารณะก็ตาม สิ่งนี้อาจมีประโยชน์ แต่น่าพิจารณาว่าคุณ*ต้องการ*ให้ฟิลด์เพิ่มเติมที่ไคลเอนต์ไม่รู้จักถูกตรวจพบเป็นข้อผิดพลาดจากคอมไพเลอร์ หรือปล่อยให้มันถูกมองข้ามไปอย่างเงียบๆ

`#[non_exhaustive]` ใช้กับ variant ของ enum ได้เช่นกัน variant ที่เป็น `#[non_exhaustive]` มีพฤติกรรมเหมือน struct ที่เป็น `#[non_exhaustive]`

จงใช้อย่างตั้งใจและระมัดระวัง: การเพิ่มเลขเวอร์ชันหลักเมื่อเพิ่มฟิลด์หรือ variant มักเป็นทางเลือกที่ดีกว่า `#[non_exhaustive]` อาจเหมาะสมในสถานการณ์ที่คุณกำลังจำลองทรัพยากรภายนอกซึ่งอาจเปลี่ยนแปลงไม่ตรงกับไลบรารีของคุณ แต่ไม่ใช่เครื่องมือเอนกประสงค์

### ข้อเสีย

`#[non_exhaustive]` อาจทำให้โค้ดของคุณใช้งานได้ไม่สะดวกสบายนัก โดยเฉพาะเมื่อถูกบังคับให้จัดการ variant ของ enum ที่ไม่รู้จัก ควรใช้เฉพาะเมื่อจำเป็นต้องรองรับวิวัฒนาการแบบนี้ **โดยไม่** เพิ่มเลขเวอร์ชันหลักเท่านั้น

เมื่อใช้ `#[non_exhaustive]` กับ `enum` มันจะบังคับให้ไคลเอนต์จัดการ variant แบบไวลด์การ์ด หากไม่มีแนวทางดำเนินการที่สมเหตุสมผลในกรณีนี้ อาจนำไปสู่โค้ดที่อึดอัดและเส้นทางโค้ดที่ถูกเรียกใช้เฉพาะในสถานการณ์ที่พบได้ยากมาก หากไคลเอนต์ตัดสินใจเรียก `panic!()` ในสถานการณ์นี้ อาจเป็นการดีกว่าถ้าให้ข้อผิดพลาดนี้ปรากฏตั้งแต่ตอนคอมไพล์ อันที่จริง `#[non_exhaustive]` บังคับให้ไคลเอนต์จัดการกรณี "อย่างอื่น" ซึ่งแทบไม่เคยมีแนวทางดำเนินการที่สมเหตุสมผลในสถานการณ์เช่นนั้นเลย

## ดูเพิ่มเติม

- [RFC ที่แนะนำแอตทริบิวต์ #[non_exhaustive] สำหรับ enum และ struct](https://github.com/rust-lang/rfcs/blob/master/text/2008-non-exhaustive.md)
