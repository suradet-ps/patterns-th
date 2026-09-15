# Builder pattern (แพตเทิร์นผู้สร้าง หรือ บิลเดอร์)

## คำอธิบาย

สร้างออบเจกต์ผ่านการเรียกใช้งานออบเจกต์ตัวช่วยประเภท Builder

## ตัวอย่าง

```rust
#[derive(Debug, PartialEq)]
pub struct Foo {
    // Lots of complicated fields.
    bar: String,
}

impl Foo {
    // This method will help users to discover the builder
    pub fn builder() -> FooBuilder {
        FooBuilder::default()
    }
}

#[derive(Default)]
pub struct FooBuilder {
    // Probably lots of optional fields.
    bar: String,
}

impl FooBuilder {
    pub fn new(/* ... */) -> FooBuilder {
        // Set the minimally required fields of Foo.
        FooBuilder {
            bar: String::from("X"),
        }
    }

    pub fn name(mut self, bar: String) -> FooBuilder {
        // Set the name on the builder itself, and return the builder by value.
        self.bar = bar;
        self
    }

    // If we can get away with not consuming the Builder here, that is an
    // advantage. It means we can use the FooBuilder as a template for constructing
    // many Foos.
    pub fn build(self) -> Foo {
        // Create a Foo from the FooBuilder, applying all settings in FooBuilder
        // to Foo.
        Foo { bar: self.bar }
    }
}

#[test]
fn builder_test() {
    let foo = Foo {
        bar: String::from("Y"),
    };
    let foo_from_builder: Foo = FooBuilder::new().name(String::from("Y")).build();
    assert_eq!(foo, foo_from_builder);
}
```

## แรงจูงใจ

มีประโยชน์อย่างยิ่งในกรณีที่คุณจำเป็นต้องมีคอนสตรัคเตอร์หลากหลายรูปแบบเพื่อรองรับพารามิเตอร์ที่แตกต่างกัน หรือในกรณีที่กระบวนการสร้างออบเจกต์ก่อให้เกิดผลข้างเคียง (side effects)

## ข้อดี

แยกเมท็อดสำหรับการประกอบสร้างออบเจกต์ออกจากเมท็อดการทำงานทั่วไปอย่างชัดเจน

ป้องกันปัญหาการงอกของคอนสตรัคเตอร์จำนวนมากเกินความจำเป็น (constructor proliferation)

รองรับทั้งการสร้างและกำหนดค่าแบบบรรทัดเดียวจบ (one-liner initialization) ตลอดจนการประกอบสร้างที่มีขั้นตอนซับซ้อน

เมื่อมีการเพิ่มฟิลด์ใหม่เข้าไปใน struct ปลายทาง คุณสามารถอัปเดตตัว builder เพื่อให้โค้ดส่วนอื่นที่เรียกใช้อยู่เดิมยังคงเข้ากันได้ย้อนหลัง (backwards compatible) เสมอ

## ข้อเสีย

มีความซับซ้อนมากกว่าการสร้าง struct โดยตรง หรือการเรียกฟังก์ชันคอนสตรัคเตอร์แบบธรรมดา

## การอภิปราย

แพตเทิร์นนี้พบเห็นได้บ่อยครั้งในภาษา Rust (แม้กระทั่งกับออบเจกต์ที่มีโครงสร้างไม่ซับซ้อนมาก) เมื่อเทียบกับภาษาอื่นๆ เนื่องจากภาษา Rust ไม่มีฟีเจอร์ method overloading และไม่มีค่าเริ่มต้น (default arguments) สำหรับพารามิเตอร์ของฟังก์ชัน และเนื่องจากเราสามารถตั้งชื่อเมท็อดได้เพียงชื่อเดียว การสร้างคอนสตรัคเตอร์หลายๆ ตัวที่มีชื่อซ้ำกันจึงไม่สามารถทำได้เหมือนในภาษา C++, Java หรือภาษาอื่นๆ

นอกจากนี้ Builder pattern มักถูกนำมาประยุกต์ใช้ในกรณีที่ตัวออบเจกต์ Builder เองมีฟังก์ชันและประโยชน์ในการใช้งานเฉพาะด้าน ไม่ได้ทำหน้าที่เพียงแค่สร้างออบเจกต์เท่านั้น ตัวอย่างเช่น
[`std::process::Command`](https://doc.rust-lang.org/std/process/struct.Command.html)
ซึ่งทำหน้าที่เป็น builder ในการตั้งค่าและสร้าง
[`Child`](https://doc.rust-lang.org/std/process/struct.Child.html) (กระบวนการหรือโปรเซสภายนอก) ซึ่งในกรณีเหล่านี้ จะไม่นิยมใช้รูปแบบการตั้งชื่อแบบ `T` และ `TBuilder`

ในตัวอย่างข้างต้น ตัว builder มีการรับและส่งคืนค่าด้วยการส่งผ่านค่า (by value / consuming self) ทว่าในความเป็นจริง บ่อยครั้งที่การรับและส่งคืน builder ในรูปของการอ้างอิงที่เปลี่ยนแปลงค่าได้ (`&mut self`) จะให้ความสะดวกสบาย (และมีประสิทธิภาพ) มากกว่า ซึ่ง borrow checker ของ Rust รองรับแนวทางนี้ได้อย่างเป็นธรรมชาติ โดยแนวทางดังกล่าวมีข้อดีคือทำให้เราสามารถเขียนโค้ดได้ทั้งแบบ:

```rust,ignore
let mut fb = FooBuilder::new();
fb.a();
fb.b();
let f = fb.build();
```

ควบคู่ไปกับสไตล์แบบ method chaining เช่น `FooBuilder::new().a().b().build()` ได้เช่นเดียวกัน

## ดูเพิ่มเติม

- [คำอธิบายในคู่มือ Style Guide](https://web.archive.org/web/20210104103100/https://doc.rust-lang.org/1.12.0/style/ownership/builders.html)
- [derive_builder](https://crates.io/crates/derive_builder) crate สำหรับช่วยอิมพลีเมนต์แพตเทิร์นนี้โดยอัตโนมัติเพื่อลดการเขียนโค้ด boilerplate
- [Constructor pattern (แพตเทิร์นคอนสตรัคเตอร์)](../../idioms/ctor.md) สำหรับกรณีที่การสร้างออบเจกต์มีความเรียบง่าย
- [Builder pattern (วิกิพีเดีย)](https://en.wikipedia.org/wiki/Builder_pattern)
- [การประกอบสร้างค่าที่มีความซับซ้อน (Construction of complex values)](https://web.archive.org/web/20210104103000/https://rust-lang.github.io/api-guidelines/type-safety.html#c-builder)
