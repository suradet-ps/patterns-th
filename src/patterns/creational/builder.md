# บิลเดอร์

## คำอธิบาย

สร้างออบเจกต์ผ่านการเรียกตัวช่วยบิลเดอร์

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

มีประโยชน์เมื่อคุณต้องมีคอนสตรัคเตอร์หลายตัว หรือเมื่อการสร้างออบเจกต์มีผลข้างเคียง (side effect)

## ข้อดี

แยกเมท็อดสำหรับการสร้างออกจากเมท็อดอื่นๆ

ป้องกันการเพิ่มจำนวนคอนสตรัคเตอร์อย่างพร่ำเพรื่อ

ใช้ได้ทั้งกับการเริ่มต้นแบบบรรทัดเดียวและแบบที่ซับซ้อนกว่า

เมื่อคุณเพิ่มฟิลด์ใหม่ให้ struct เป้าหมาย คุณปรับบิลเดอร์ได้เพื่อให้โค้ดของไคลเอนต์ยังเข้ากันได้ย้อนหลัง

## ข้อเสีย

ซับซ้อนกว่าการสร้างออบเจกต์ struct ตรงๆ หรือใช้ฟังก์ชันคอนสตรัคเตอร์ง่ายๆ

## การอภิปราย

แพตเทิร์นนี้พบได้บ่อยใน Rust (และกับออบเจกต์ที่ง่ายกว่า) มากกว่าในภาษาอื่นหลายภาษา เพราะ Rust ขาดการโอเวอร์โหลดและค่าเริ่มต้นของพารามิเตอร์ฟังก์ชัน เนื่องจากเรามีเมท็อดชื่อหนึ่งได้เพียงตัวเดียว การมีคอนสตรัคเตอร์หลายตัวจึงไม่สะดวกใน Rust เท่ากับใน C++ หรือ Java หรือภาษาอื่นๆ

แพตเทิร์นนี้มักถูกใช้ในกรณีที่ออบเจกต์บิลเดอร์มีประโยชน์ในตัวมันเอง ไม่ได้เป็นแค่บิลเดอร์ ตัวอย่างเช่น ดู
[`std::process::Command`](https://doc.rust-lang.org/std/process/struct.Command.html)
ซึ่งเป็นบิลเดอร์สำหรับ
[`Child`](https://doc.rust-lang.org/std/process/struct.Child.html) (โปรเซส) ในกรณีเหล่านี้จะไม่ใช้รูปแบบการตั้งชื่อ `T` และ `TBuilder`

ตัวอย่างนี้รับและคืนบิลเดอร์ด้วยค่า (by value) ซึ่งบ่อยครั้งสะดวกกว่า (และมีประสิทธิภาพกว่า) ที่จะรับและคืนบิลเดอร์เป็นการอ้างอิงที่แก้ไขได้ borrow checker ทำให้วิธีนี้ทำงานได้อย่างเป็นธรรมชาติ แนวทางนี้มีข้อดีตรงที่เราสามารถเขียนโค้ดแบบนี้ได้

```rust,ignore
let mut fb = FooBuilder::new();
fb.a();
fb.b();
let f = fb.build();
```

รวมถึงสไตล์ `FooBuilder::new().a().b().build()` ด้วย

## ดูเพิ่มเติม

- [คำอธิบายใน style guide](https://web.archive.org/web/20210104103100/https://doc.rust-lang.org/1.12.0/style/ownership/builders.html)
- [derive_builder](https://crates.io/crates/derive_builder) ครีตสำหรับอิมพลีเมนต์
  แพตเทิร์นนี้อัตโนมัติโดยหลีกเลี่ยงโค้ด boilerplate
- [แพตเทิร์นคอนสตรัคเตอร์](../../idioms/ctor.md) สำหรับกรณีที่การสร้างเรียบง่ายกว่า
- [Builder pattern (วิกิพีเดีย)](https://en.wikipedia.org/wiki/Builder_pattern)
- [Construction of complex values](https://web.archive.org/web/20210104103000/https://rust-lang.github.io/api-guidelines/type-safety.html#c-builder)
