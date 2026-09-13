# กลยุทธ์ (หรือ Policy)

## คำอธิบาย

[แพตเทิร์นการออกแบบกลยุทธ์](https://en.wikipedia.org/wiki/Strategy_pattern) เป็นเทคนิคที่ช่วยแยกความรับผิดชอบ (separation of concerns) มันยังช่วยลดการผูกมัดระหว่างโมดูลซอฟต์แวร์ผ่าน
[การผกผันการพึ่งพา (Dependency Inversion)](https://en.wikipedia.org/wiki/Dependency_inversion_principle)

แนวคิดพื้นฐานเบื้องหลังแพตเทิร์นกลยุทธ์คือ เมื่อมีอัลกอริทึมที่แก้ปัญหาหนึ่งๆ เรานิยามเพียงโครงร่างของอัลกอริทึมในระดับนามธรรม และแยกการอิมพลีเมนต์อัลกอริทึมเฉพาะทางออกเป็นส่วนต่างๆ

ด้วยวิธีนี้ ไคลเอนต์ที่ใช้อัลกอริทึมสามารถเลือกการอิมพลีเมนต์เฉพาะได้ ขณะที่ขั้นตอนการทำงานโดยรวมของอัลกอริทึมยังคงเดิม กล่าวอีกนัยหนึ่ง ข้อกำหนดเชิงนามธรรมของคลาสไม่ขึ้นกับการอิมพลีเมนต์เฉพาะของคลาสที่สืบทอด แต่การอิมพลีเมนต์เฉพาะต้องยึดตามข้อกำหนดเชิงนามธรรม นี่คือเหตุผลที่เราเรียกมันว่า "การผกผันการพึ่งพา"

## แรงจูงใจ

ลองจินตนาการว่าเรากำลังทำงานบนโปรเจกต์ที่สร้างรายงานทุกเดือน เราต้องการให้รายงานถูกสร้างในรูปแบบ (กลยุทธ์) ต่างๆ เช่น รูปแบบ `JSON` หรือ `Plain Text` แต่สิ่งต่างๆ เปลี่ยนไปตามกาลเวลา และเราไม่รู้ว่าในอนาคตจะได้ข้อกำหนดแบบไหน ตัวอย่างเช่น เราอาจต้องสร้างรายงานในรูปแบบใหม่ทั้งหมด หรือเพียงแก้รูปแบบที่มีอยู่แล้วแบบใดแบบหนึ่ง

## ตัวอย่าง

ในตัวอย่างนี้ invariant (หรือนามธรรม) ของเราคือ `Formatter` และ `Report` ขณะที่ `Text` และ `Json` เป็น struct กลยุทธ์ของเรา กลยุทธ์เหล่านี้ต้องอิมพลีเมนต์ trait `Formatter`

```rust
use std::collections::HashMap;

type Data = HashMap<String, u32>;

trait Formatter {
    fn format(&self, data: &Data, buf: &mut String);
}

struct Report;

impl Report {
    // Write should be used but we kept it as String to ignore error handling
    fn generate<T: Formatter>(g: T, s: &mut String) {
        // backend operations...
        let mut data = HashMap::new();
        data.insert("one".to_string(), 1);
        data.insert("two".to_string(), 2);
        // generate report
        g.format(&data, s);
    }
}

struct Text;
impl Formatter for Text {
    fn format(&self, data: &Data, buf: &mut String) {
        for (k, v) in data {
            let entry = format!("{k} {v}\n");
            buf.push_str(&entry);
        }
    }
}

struct Json;
impl Formatter for Json {
    fn format(&self, data: &Data, buf: &mut String) {
        buf.push('[');
        for (k, v) in data.into_iter() {
            let entry = format!(r#"{{"{}":"{}"}}"#, k, v);
            buf.push_str(&entry);
            buf.push(',');
        }
        if !data.is_empty() {
            buf.pop(); // remove extra , at the end
        }
        buf.push(']');
    }
}

fn main() {
    let mut s = String::from("");
    Report::generate(Text, &mut s);
    assert!(s.contains("one 1"));
    assert!(s.contains("two 2"));

    s.clear(); // reuse the same buffer
    Report::generate(Json, &mut s);
    assert!(s.contains(r#"{"one":"1"}"#));
    assert!(s.contains(r#"{"two":"2"}"#));
}
```

## ข้อดี

ข้อดีหลักคือการแยกความรับผิดชอบ ตัวอย่างเช่น ในกรณีนี้ `Report` ไม่รู้อะไรเกี่ยวกับการอิมพลีเมนต์เฉพาะของ `Json` และ `Text` เลย ขณะที่การอิมพลีเมนต์เอาต์พุตก็ไม่สนใจว่าข้อมูลถูกประมวลผลล่วงหน้า จัดเก็บ และดึงมาอย่างไร สิ่งเดียวที่ทั้งสองต้องรู้คือ trait เฉพาะที่ต้องอิมพลีเมนต์และเมท็อดของมันที่นิยามการอิมพลีเมนต์อัลกอริทึมอย่างเป็นรูปธรรมซึ่งประมวลผลผลลัพธ์ นั่นคือ `Formatter` และ `format(...)`

## ข้อเสีย

สำหรับแต่ละกลยุทธ์ ต้องมีโมดูลอย่างน้อยหนึ่งโมดูลที่อิมพลีเมนต์มัน จำนวนโมดูลจึงเพิ่มขึ้นตามจำนวนกลยุทธ์ หากมีกลยุทธ์ให้เลือกมาก ผู้ใช้จำเป็นต้องรู้ว่ากลยุทธ์ต่างๆ ต่างกันอย่างไร

## การอภิปราย

ในตัวอย่างก่อนหน้านี้ กลยุทธ์ทั้งหมดถูกอิมพลีเมนต์ในไฟล์เดียว วิธีจัดเตรียมกลยุทธ์ต่างๆ ได้แก่:

- ทั้งหมดในไฟล์เดียว (ดังตัวอย่างนี้ คล้ายกับการแยกเป็นโมดูล)
- แยกเป็นโมดูล เช่น โมดูล `formatter::json` โมดูล `formatter::text`
- ใช้แฟล็กฟีเจอร์ของคอมไพเลอร์ เช่น ฟีเจอร์ `json`, ฟีเจอร์ `text`
- แยกเป็นครีต เช่น ครีต `json`, ครีต `text`

ครีต Serde เป็นตัวอย่างที่ดีของแพตเทิร์น `Strategy` ที่ลงมือใช้จริง Serde ช่วยให้
[ปรับแต่งพฤติกรรมการทำให้เป็นอนุกรม (serialization)](https://serde.rs/custom-serialization.html) ได้อย่างเต็มที่ โดยการอิมพลีเมนต์ trait `Serialize` และ `Deserialize` ให้กับชนิดข้อมูลของเราด้วยตนเอง ตัวอย่างเช่น เราสลับ `serde_json` กับ `serde_cbor` ได้ง่ายมากเพราะทั้งคู่เปิดเผยเมท็อดที่คล้ายกัน การมีสิ่งนี้ทำให้ครีตตัวช่วยอย่าง `serde_transcode` มีประโยชน์และใช้งานสะดวกขึ้นมาก

อย่างไรก็ตาม เราไม่จำเป็นต้องใช้ trait เพื่อออกแบบแพตเทิร์นนี้ใน Rust

ตัวอย่างของเล่นต่อไปนี้สาธิตแนวคิดของแพตเทิร์นกลยุทธ์โดยใช้ `closures` ของ Rust:

```rust
struct Adder;
impl Adder {
    pub fn add<F>(x: u8, y: u8, f: F) -> u8
    where
        F: Fn(u8, u8) -> u8,
    {
        f(x, y)
    }
}

fn main() {
    let arith_adder = |x, y| x + y;
    let bool_adder = |x, y| {
        if x == 1 || y == 1 {
            1
        } else {
            0
        }
    };
    let custom_adder = |x, y| 2 * x + y;

    assert_eq!(9, Adder::add(4, 5, arith_adder));
    assert_eq!(0, Adder::add(0, 0, bool_adder));
    assert_eq!(5, Adder::add(1, 3, custom_adder));
}
```

อันที่จริง Rust ใช้แนวคิดนี้อยู่แล้วในเมท็อด `map` ของ `Option`:

```rust
fn main() {
    let val = Some("Rust");

    let len_strategy = |s: &str| s.len();
    assert_eq!(4, val.map(len_strategy).unwrap());

    let first_byte_strategy = |s: &str| s.bytes().next().unwrap();
    assert_eq!(82, val.map(first_byte_strategy).unwrap());
}
```

## ดูเพิ่มเติม

- [แพตเทิร์นกลยุทธ์](https://en.wikipedia.org/wiki/Strategy_pattern)
- [การฉีดพึ่งพา (Dependency Injection)](https://en.wikipedia.org/wiki/Dependency_injection)
- [Policy Based Design](https://en.wikipedia.org/wiki/Modern_C++_Design#Policy-based_design)
- [Implementing a TCP server for Space Applications in Rust using the Strategy Pattern](https://web.archive.org/web/20231003171500/https://robamu.github.io/posts/rust-strategy-pattern/)
