# trait `Default`

## คำอธิบาย

ชนิดข้อมูลจำนวนมากใน Rust มี[คอนสตรัคเตอร์][constructor] อย่างไรก็ตาม คอนสตรัคเตอร์นั้น*เฉพาะ*กับชนิดข้อมูล Rust ไม่สามารถวางนามธรรมครอบ "ทุกสิ่งที่มีเมท็อด `new()`" ได้ เพื่อให้ทำได้ จึงเกิด trait [`Default`] ขึ้น ซึ่งใช้ได้กับคอนเทนเนอร์และชนิดเจเนอริกอื่นๆ (ตัวอย่างเช่น ดู [`Option::unwrap_or_default()`]) ที่น่าสนใจคือคอนเทนเนอร์บางตัวอิมพลีเมนต์ trait นี้อยู่แล้วในกรณีที่เหมาะสม

ไม่เพียงแต่คอนเทนเนอร์ที่มีสมาชิกเดียวอย่าง `Cow`, `Box` หรือ `Arc` จะอิมพลีเมนต์ `Default` ให้กับชนิด `Default` ที่บรรจุอยู่เท่านั้น เรายังสามารถ `#[derive(Default)]` ให้กับ struct ที่ทุกฟิลด์อิมพลีเมนต์มันได้โดยอัตโนมัติ ดังนั้นยิ่งมีชนิดข้อมูลอิมพลีเมนต์ `Default` มากเท่าไร มันก็ยิ่งมีประโยชน์มากขึ้นเท่านั้น

ในทางกลับกัน คอนสตรัคเตอร์รับอาร์กิวเมนต์หลายตัวได้ ขณะที่เมท็อด `default()` ทำไม่ได้ ซ้ำยังมีคอนสตรัคเตอร์หลายตัวที่ตั้งชื่อต่างกันได้อีกด้วย แต่การอิมพลีเมนต์ `Default` มีได้เพียงหนึ่งเดียวต่อชนิดข้อมูลเท่านั้น

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

- [สำนวนคอนสตรัคเตอร์][constructor] เป็นอีกวิธีหนึ่งในการสร้างอินสแตนซ์ซึ่งอาจเป็นหรือไม่เป็นค่า "default" ก็ได้
- เอกสารประกอบของ [`Default`] (เลื่อนลงไปดูรายการชนิดที่อิมพลีเมนต์)
- [`Option::unwrap_or_default()`]
- [`derive(new)`]

[constructor]: ctor.md
[`Default`]: https://doc.rust-lang.org/stable/std/default/trait.Default.html
[`Option::unwrap_or_default()`]: https://doc.rust-lang.org/stable/std/option/enum.Option.html#method.unwrap_or_default
[`derive(new)`]: https://crates.io/crates/derive-new/
