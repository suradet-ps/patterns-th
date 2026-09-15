# Strategy pattern (แพตเทิร์นกลยุทธ์ หรือ Policy)

## คำอธิบาย

[Strategy pattern](https://en.wikipedia.org/wiki/Strategy_pattern) เป็นเทคนิคการออกแบบที่ช่วยในการแยกส่วนความรับผิดชอบ (Separation of Concerns: SoC) และช่วยลดการผูกมัดระหว่างโมดูลต่างๆ ในซอฟต์แวร์ด้วย
[หลักการผกผันการพึ่งพา (Dependency Inversion Principle: DIP)](https://en.wikipedia.org/wiki/Dependency_inversion_principle)

แนวคิดพื้นฐานเบื้องหลัง Strategy pattern คือ เมื่อมีอัลกอริทึมสำหรับแก้ปัญหาใดปัญหาหนึ่ง เราจะกำหนดเพียงแค่โครงร่างหลักของอัลกอริทึมในระดับนามธรรม (abstract level) แล้วแยกตรรกะการทำงานเฉพาะเจาะจงของแต่ละอัลกอริทึมออกเป็นส่วนประกอบย่อยๆ ต่างหาก

ด้วยวิธีนี้ ฝั่งผู้เรียกใช้งาน (client) จะสามารถเลือกเปลี่ยนการอิมพลีเมนต์ที่ต้องการได้ตามสถานการณ์ ขณะที่ลำดับขั้นตอนการทำงานโดยรวมของอัลกอริทึมยังคงเดิม กล่าวอีกนัยหนึ่งคือ ข้อกำหนดเชิงนามธรรมจะไม่ขึ้นอยู่กับรายละเอียดการทำงานเฉพาะด้าน แต่การทำงานเฉพาะด้านเหล่านั้นจะต้องปฏิบัติตามข้อกำหนดเชิงนามธรรม นี่คือเหตุผลที่เราเรียกหลักการนี้ว่า "การผกผันการพึ่งพา (Dependency Inversion)"

## แรงจูงใจ

ลองจินตนาการว่าเรากำลังพัฒนาโปรเจกต์ที่ต้องสร้างรายงานสรุปในทุกๆ สิ้นเดือน โดยมีความต้องการสร้างรายงานในหลากหลายรูปแบบ (ต่าง strategy กัน) เช่น รูปแบบ `JSON` หรือ `Plain Text` แต่เมื่อเวลาผ่านไป ความต้องการทางธุรกิจย่อมเปลี่ยนแปลง และเราไม่อาจทราบล่วงหน้าได้ว่าจะมีรูปแบบรายงานชนิดใดเพิ่มเข้ามาในอนาคต เช่น อาจต้องรองรับฟอร์แมตใหม่ทั้งหมด หรือต้องการปรับแต่งตรรกะของฟอร์แมตเดิมที่มีอยู่แล้ว

## ตัวอย่าง

ในตัวอย่างนี้ สิ่งที่เป็นข้อกำหนดเชิงนามธรรม (abstractions) ของเราคือ `Formatter` และ `Report` ในขณะที่ `Text` และ `Json` คือ struct ที่ทำหน้าที่เป็น strategy โดยแต่ละ strategy จะต้องนำ trait `Formatter` ไปอิมพลีเมนต์

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

ข้อดีหลักคือการแยกส่วนความรับผิดชอบอย่างชัดเจน ตัวอย่างเช่น `Report` ไม่จำเป็นต้องทราบรายละเอียดการทำงานภายในของ `Json` หรือ `Text` เลย ขณะที่ฝั่งฟอร์แมตเอาต์พุตก็ไม่จำเป็นต้องสนใจว่าข้อมูลถูกเตรียม จัดเก็บ หรือดึงมาจากแหล่งใด สิ่งเดียวที่ทั้งสองฝ่ายต้องรับรู้ร่วมกันคือ trait ที่ใช้เชื่อมโยงและเมท็อดที่กำหนดขั้นตอนการแปลงผลลัพธ์ ซึ่งก็คือ `Formatter` และเมท็อด `format(...)`

## ข้อเสีย

สำหรับแต่ละ strategy จะต้องมีโมดูลหรือชนิดข้อมูลมารองรับอย่างน้อยหนึ่งตัว ทำให้จำนวนโมดูลเพิ่มขึ้นตามจำนวนของ strategy และหากมี strategy ให้เลือกใช้เป็นจำนวนมาก ผู้ใช้งานจำเป็นต้องศึกษาความแตกต่างของแต่ละ strategy ด้วยตนเอง

## การอภิปราย

ในตัวอย่างข้างต้น strategy ทั้งหมดถูกเขียนรวมไว้ในไฟล์เดียว ทว่าในทางปฏิบัติ มีหลากหลายวิธีในการจัดระเบียบ strategy ต่างๆ:

- รวมไว้ในไฟล์เดียว (ดังที่แสดงในตัวอย่าง คล้ายกับการแยกเป็นโมดูลย่อยภายในไฟล์)
- แยกออกเป็นโมดูล เช่น โมดูล `formatter::json`, `formatter::text`
- ใช้ Feature Flags ของคอมไพเลอร์ เช่น ฟีเจอร์ `json`, ฟีเจอร์ `text`
- แยกออกเป็น crate ต่างหาก เช่น crate `json`, `crate text`

Crate ยอดนิยมอย่าง Serde ถือเป็นตัวอย่างอันยอดเยี่ยมของการประยุกต์ใช้ `Strategy` pattern ในชีวิตจริง โดย Serde เปิดให้เราสามารถ
[ปรับแต่งพฤติกรรมการแปลงข้อมูล (custom serialization)](https://serde.rs/custom-serialization.html) ได้อย่างอิสระด้วยการเขียน implementation ของ `Serialize` และ `Deserialize` สำหรับชนิดข้อมูลของเราเอง ตัวอย่างเช่น เราสามารถสลับเปลี่ยนระหว่าง `serde_json` กับ `serde_cbor` ได้อย่างง่ายดายเพราะทั้งคู่เปิดเผยเมท็อดที่สอดคล้องกัน ซึ่งทำให้ crate ตัวช่วยอย่าง `serde_transcode` ยิ่งทรงพลังและใช้งานได้สะดวกสบายมากขึ้น

อย่างไรก็ดี ในภาษา Rust เราไม่จำเป็นต้องพึ่งพา trait เสมอไปในการสร้างแพตเทิร์นนี้

ตัวอย่างจำลองแบบเข้าใจง่าย (toy example) ต่อไปนี้แสดงการนำ Strategy pattern มาประยุกต์ใช้ผ่าน `closure` ใน Rust:

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

และในความเป็นจริง ภาษา Rust ได้นำแนวคิดนี้มาใช้งานอยู่แล้วในเมท็อด `map` ของ `Option`:

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

- [Strategy Pattern](https://en.wikipedia.org/wiki/Strategy_pattern)
- [Dependency Injection](https://en.wikipedia.org/wiki/Dependency_injection)
- [Policy Based Design](https://en.wikipedia.org/wiki/Modern_C++_Design#Policy-based_design)
- [Implementing a TCP server for Space Applications in Rust using the Strategy Pattern](https://web.archive.org/web/20231003171500/https://robamu.github.io/posts/rust-strategy-pattern/)
