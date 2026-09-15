# trait `Default`

## คำอธิบาย

ชนิดข้อมูลจำนวนมากใน Rust มี[คอนสตรัคเตอร์][constructor] เป็นของตนเอง อย่างไรก็ตาม คอนสตรัคเตอร์นั้นถือเป็นเมท็อดที่*เฉพาะเจาะจง*สำหรับแต่ละชนิดข้อมูล ทำให้ Rust ไม่สามารถสร้างแอบสแตรกชันครอบคลุม "ทุกสิ่งที่มีเมท็อด `new()`" ได้โดยตรง เพื่อทลายข้อจำกัดนี้ trait [`Default`] จึงถูกคิดค้นขึ้นมา เพื่อเปิดให้ชนิดข้อมูลต่างๆ สามารถใช้งานร่วมกับ Container และชนิดข้อมูลแบบเจเนอริกอื่นๆ ได้ (เช่น เมท็อด [`Option::unwrap_or_default()`]) ซึ่งที่น่าสังเกตคือ Container พื้นฐานหลายตัวในไลบรารีมาตรฐานต่างก็ได้อิมพลีเมนต์ trait นี้ไว้ล่วงหน้าแล้ว

นอกจาก Container ที่บรรจุข้อมูลเดี่ยวอย่าง `Cow`, `Box` หรือ `Arc` จะอิมพลีเมนต์ `Default` ให้กับชนิดข้อมูลภายในที่รองรับ `Default` แล้ว เรายังสามารถสั่ง `#[derive(Default)]` อัตโนมัติให้กับ struct ใดๆ ที่ทุกฟิลด์ภายในอิมพลีเมนต์ `Default` ไว้อยู่แล้วได้อีกด้วย ดังนั้น ยิ่งมีชนิดข้อมูลที่รองรับ `Default` มากขึ้นเท่าใด ประโยชน์และความยืดหยุ่นในการใช้งานร่วมกันในระบบนิเวศก็จะยิ่งทวีคูณขึ้นเท่านั้น

ในทางกลับกัน ฟังก์ชันคอนสตรัคเตอร์สามารถรับพารามิเตอร์ได้หลายตัว ในขณะที่เมท็อด `default()` ไม่รับพารามิเตอร์ใดๆ เลย และเรายังสามารถสร้างคอนสตรัคเตอร์ได้หลายตัวโดยตั้งชื่อฟังก์ชันให้แตกต่างกันได้ แต่สำหรับการอิมพลีเมนต์ `Default` นั้น ชนิดข้อมูลหนึ่งจะสามารถมีได้เพียงแบบเดียวเท่านั้น

## ตัวอย่าง

```rust
use std::{path::PathBuf, time::Duration};

// note that we can simply auto-derive Default here.
#[derive(Default, Debug, PartialEq)]
struct MyConfiguration {
    // Option defaults to None
    output: Option<PathBuf>,
    // Vecs default to empty vector
    search_path: Vec<PathBuf>,
    // Duration defaults to zero time
    timeout: Duration,
    // bool defaults to false
    check: bool,
}

impl MyConfiguration {
    // add setters here
}

fn main() {
    // construct a new instance with default values
    let mut conf = MyConfiguration::default();
    // do something with conf here
    conf.check = true;
    println!("conf = {conf:#?}");

    // partial initialization with default values, creates the same instance
    let conf1 = MyConfiguration {
        check: true,
        ..Default::default()
    };
    assert_eq!(conf, conf1);
}
```

## ดูเพิ่มเติม

- [แนวปฏิบัติคอนสตรัคเตอร์ (Constructors)][constructor] อีกหนึ่งแนวทางในการสร้างอินสแตนซ์ที่ไม่จำเป็นต้องจำกัดอยู่เฉพาะค่าเริ่มต้น (default)
- เอกสารประกอบของ [`Default`] (สามารถเลื่อนลงไปดูรายการชนิดข้อมูลทั้งหมดที่อิมพลีเมนต์ trait นี้ได้)
- [`Option::unwrap_or_default()`]
- [`derive(new)`]

[constructor]: ctor.md
[`Default`]: https://doc.rust-lang.org/stable/std/default/trait.Default.html
[`Option::unwrap_or_default()`]: https://doc.rust-lang.org/stable/std/option/enum.Option.html#method.unwrap_or_default
[`derive(new)`]: https://crates.io/crates/derive-new/
