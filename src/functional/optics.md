# ออปติกส์ในภาษาเชิงฟังก์ชัน

ออปติกส์ (Optics) เป็นรูปแบบหนึ่งของการออกแบบ API ที่พบได้ทั่วไปในภาษาเชิงฟังก์ชัน เป็นแนวคิดเชิงฟังก์ชันล้วนๆ ที่ไม่ค่อยถูกใช้ใน Rust

ถึงกระนั้น การสำรวจแนวคิดนี้อาจช่วยให้เข้าใจแพตเทิร์นอื่นๆ ใน API ของ Rust เช่น [ผู้มาเยือน](../patterns/behavioural/visitor.md) อีกทั้งมันยังมีกรณีใช้งานเฉพาะทางด้วย

นี่เป็นหัวข้อที่ค่อนข้างใหญ่ และต้องใช้หนังสือเกี่ยวกับการออกแบบภาษาเต็มเล่มเพื่อเข้าถึงความสามารถของมันอย่างเต็มที่ อย่างไรก็ตาม การนำไปใช้ใน Rust นั้นเรียบง่ายกว่ามาก

เพื่ออธิบายส่วนที่เกี่ยวข้องของแนวคิดนี้ เราจะใช้ API ของ `Serde` เป็นตัวอย่าง เนื่องจากเป็น API ที่หลายคนเข้าใจได้ยากหากอ่านแค่เอกสารประกอบของ API

ในระหว่างนั้น จะมีการครอบคลุมแพตเทิร์นเฉพาะต่างๆ ที่เรียกว่าออปติกส์ ได้แก่ *The Iso*, *The Poly Iso* และ *The Prism*

## ตัวอย่าง API: Serde

การพยายามเข้าใจวิธีการทำงานของ *Serde* ด้วยการอ่านแค่ API เป็นเรื่องท้าทาย โดยเฉพาะครั้งแรก ลองพิจารณา trait `Deserializer` ที่ไลบรารีซึ่งแยกวิเคราะห์รูปแบบข้อมูลใหม่ใดๆ อิมพลีเมนต์:

```rust,ignore
pub trait Deserializer<'de>: Sized {
    type Error: Error;

    fn deserialize_any<V>(self, visitor: V) -> Result<V::Value, Self::Error>
    where
        V: Visitor<'de>;

    fn deserialize_bool<V>(self, visitor: V) -> Result<V::Value, Self::Error>
    where
        V: Visitor<'de>;

    // remainder omitted
}
```

และนี่คือนิยามของ trait `Visitor` ที่ถูกส่งเข้ามาแบบเจเนอริก:

```rust,ignore
pub trait Visitor<'de>: Sized {
    type Value;

    fn visit_bool<E>(self, v: bool) -> Result<Self::Value, E>
    where
        E: Error;

    fn visit_u64<E>(self, v: u64) -> Result<Self::Value, E>
    where
        E: Error;

    fn visit_str<E>(self, v: &str) -> Result<Self::Value, E>
    where
        E: Error;

    // remainder omitted
}
```

มี type erasure เกิดขึ้นมากมายตรงนี้ โดยมี associated type หลายระดับถูกส่งกลับไปกลับมา

แต่ภาพรวมคืออะไร? ทำไมไม่ให้ `Visitor` คืนส่วนประกอบที่ผู้เรียกต้องการใน API แบบสตรีมมิ่งแล้วจบเรื่องไป? ทำไมต้องมีชิ้นส่วนพิเศษทั้งหมด?

วิธีหนึ่งที่จะเข้าใจคือดูแนวคิดในภาษาเชิงฟังก์ชันที่เรียกว่า *optics*

นี่คือวิธีทำการประกอบพฤติกรรมและคุณสมบัติที่ออกแบบมาเพื่ออำนวยความสะดวกให้แพตเทิร์นที่พบบ่อยใน Rust: ความล้มเหลว การแปลงชนิด ฯลฯ[^1]

ภาษา Rust เองไม่มีการรองรับสิ่งเหล่านี้โดยตรงมากนัก อย่างไรก็ตาม สิ่งเหล่านี้ปรากฏอยู่ในการออกแบบของภาษาด้วย และแนวคิดของมันช่วยให้เข้าใจ API บางส่วนของ Rust ได้ ผลก็คือบทนี้พยายามอธิบายแนวคิดเหล่านั้นด้วยวิธีที่ Rust ทำ

การอธิบายนี้อาจช่วยให้เห็นกระจ่างว่า API เหล่านั้นบรรลุอะไร: คุณสมบัติเฉพาะของการประกอบกันได้ (composability)

## ออปติกส์พื้นฐาน

### The Iso

The Iso คือตัวแปลงค่าระหว่างสองชนิดข้อมูล มันเรียบง่ายมาก แต่เป็นหน่วยสร้าง (building block) ที่สำคัญเชิงแนวคิด

ตัวอย่างเช่น สมมติว่าเรามีโครงสร้างตารางแฮชที่กำหนดเองซึ่งใช้เป็น concordance สำหรับเอกสาร[^2] มันใช้สตริงเป็นคีย์ (คำ) และรายการดัชนีเป็นค่า (เช่น ตำแหน่งไบต์ในไฟล์)

คุณสมบัติสำคัญอย่างหนึ่งคือความสามารถในการทำให้รูปแบบนี้เป็นอนุกรมลงดิสก์ วิธี "เร็วและง่าย" คืออิมพลีเมนต์การแปลงไปกลับระหว่างสตริงในรูปแบบ JSON (ข้อผิดพลาดจะถูกละไว้ก่อน แล้วค่อยจัดการทีหลัง)

หากเขียนในรูปแบบปกติที่ผู้ใช้ภาษาเชิงฟังก์ชันคาดหวัง:

```text
case class ConcordanceSerDe {
  serialize: Concordance -> String
  deserialize: String -> Concordance
}
```

The Iso จึงเป็นฟังก์ชันคู่หนึ่งที่แปลงค่าระหว่างชนิดที่ต่างกัน: `serialize` และ `deserialize`

การอิมพลีเมนต์แบบตรงไปตรงมา:

```rust
use std::collections::HashMap;

struct Concordance {
    keys: HashMap<String, usize>,
    value_table: Vec<(usize, usize)>,
}

struct ConcordanceSerde {}

impl ConcordanceSerde {
    fn serialize(value: Concordance) -> String {
        todo!()
    }
    // invalid concordances are empty
    fn deserialize(value: String) -> Concordance {
        todo!()
    }
}
```

นี่อาจดูไร้สาระไปหน่อย ใน Rust พฤติกรรมแบบนี้มักทำด้วย traits ท้ายที่สุด ไลบรารีมาตรฐานก็มี `FromStr` และ `ToString` อยู่แล้ว

แต่นั่นคือจุดที่หัวข้อถัดไปของเราเข้ามา: Poly Isos

### Poly Isos

ตัวอย่างก่อนหน้าเป็นเพียงการแปลงระหว่างค่าของสองชนิดที่ตรึงไว้ กลุ่มถัดไปต่อยอดจากมันด้วยเจเนอริก และน่าสนใจกว่า

Poly Isos ช่วยให้การดำเนินการเป็นเจเนอริกบนชนิดใดก็ได้ ขณะเดียวกันก็คืนชนิดเดียว

สิ่งนี้นำเราเข้าใกล้การแยกวิเคราะห์มากขึ้น ลองพิจารณาว่า parser พื้นฐานจะทำอะไรหากไม่สนใจกรณีข้อผิดพลาด อีกครั้ง นี่คือรูปแบบปกติของมัน:

```text
case class Serde[T] {
    deserialize(String) -> T
    serialize(T) -> String
}
```

ตรงนี้เรามีเจเนอริกตัวแรก นั่นคือชนิด `T` ที่ถูกแปลง

ใน Rust สิ่งนี้สามารถอิมพลีเมนต์ได้ด้วย trait คู่หนึ่งในไลบรารีมาตรฐาน: `FromStr` และ `ToString` เวอร์ชัน Rust ยังจัดการข้อผิดพลาดได้ด้วย:

```rust,ignore
pub trait FromStr: Sized {
    type Err;

    fn from_str(s: &str) -> Result<Self, Self::Err>;
}

pub trait ToString {
    fn to_string(&self) -> String;
}
```

ต่างจาก Iso ตรงที่ Poly Iso ยอมให้ประยุกต์กับชนิดต่างๆ ได้หลายชนิด และคืนมันกลับมาแบบเจเนอริก นี่คือสิ่งที่คุณต้องการสำหรับ parser สตริงพื้นฐาน

เมื่อมองแวบแรก ดูเหมือนเป็นตัวเลือกที่ดีสำหรับการเขียน parser ลองดูการใช้งานจริง:

```rust,ignore
use anyhow;

use std::str::FromStr;

struct TestStruct {
    a: usize,
    b: String,
}

impl FromStr for TestStruct {
    type Err = anyhow::Error;
    fn from_str(s: &str) -> Result<TestStruct, Self::Err> {
        todo!()
    }
}

impl ToString for TestStruct {
    fn to_string(&self) -> String {
        todo!()
    }
}

fn main() {
    let a = TestStruct {
        a: 5,
        b: "hello".to_string(),
    };
    println!("Our Test Struct as JSON: {}", a.to_string());
}
```

ดูสมเหตุสมผลดีทีเดียว อย่างไรก็ตาม มีปัญหาสองข้อกับวิธีนี้

ประการแรก `to_string` ไม่ได้บอกผู้ใช้ API ว่า "นี่คือ JSON" ทุกชนิดข้อมูลจะต้องตกลงกันเรื่องตัวแทน JSON และชนิดข้อมูลหลายตัวในไลบรารีมาตรฐานของ Rust ก็ไม่ได้ตกลงกันอยู่แล้ว การใช้วิธีนี้จึงเข้ากันได้ไม่ดี ซึ่งแก้ได้ง่ายด้วย trait ของเราเอง

แต่มีปัญหาข้อที่สองที่ละเอียดอ่อนกว่า: การขยายขนาด

เมื่อทุกชนิดเขียน `to_string` ด้วยมือ วิธีนี้ก็ใช้ได้ แต่ถ้าทุกคนที่ต้องการให้ชนิดข้อมูลของตนทำให้เป็นอนุกรมได้ต้องเขียนโค้ดกองหนึ่ง -- และอาจใช้ไลบรารี JSON ที่ต่างกัน -- ด้วยตัวเอง มันจะกลายเป็นความยุ่งเหยิงอย่างรวดเร็ว!

คำตอบคือหนึ่งในสองนวัตกรรมสำคัญของ Serde: โมเดลข้อมูลอิสระสำหรับนำเสนอข้อมูล Rust ในโครงสร้างที่พบได้ทั่วไปในภาษาเพื่อการทำให้ข้อมูลเป็นอนุกรม ผลก็คือมันใช้ความสามารถในการสร้างโค้ดของ Rust เพื่อสร้างชนิดตัวกลางสำหรับการแปลงที่มันเรียกว่า `Visitor`

ซึ่งหมายความว่า ในรูปแบบปกติ (อีกครั้ง ข้ามการจัดการข้อผิดพลาดเพื่อความง่าย):

```text
case class Serde[T] {
    deserialize: Visitor[T] -> T
    serialize: T -> Visitor[T]
}

case class Visitor[T] {
    toJson: Visitor[T] -> String
    fromJson: String -> Visitor[T]
}
```

ผลลัพธ์คือ Poly Iso หนึ่งตัวและ Iso หนึ่งตัว (ตามลำดับ) ทั้งสองอย่างอิมพลีเมนต์ได้ด้วย traits:

```rust
trait Serde {
    type V;
    fn deserialize(visitor: Self::V) -> Self;
    fn serialize(self) -> Self::V;
}

trait Visitor {
    fn to_json(self) -> String;
    fn from_json(json: String) -> Self;
}
```

เนื่องจากมีชุดกฎที่สม่ำเสมอสำหรับแปลงโครงสร้าง Rust ไปเป็นรูปแบบอิสระ จึงเป็นไปได้ถึงขั้นให้การสร้างโค้ดสร้าง `Visitor` ที่สัมพันธ์กับชนิด `T` ได้:

```rust,ignore
#[derive(Default, Serde)] // the "Serde" derive creates the trait impl block
struct TestStruct {
    a: usize,
    b: String,
}

// user writes this macro to generate an associated visitor type
generate_visitor!(TestStruct);
```

แต่ลองใช้แนวทางนั้นจริงๆ กันดีกว่า

```rust,ignore
fn main() {
    let a = TestStruct { a: 5, b: "hello".to_string() };
    let a_data = a.serialize().to_json();
    println!("Our Test Struct as JSON: {a_data}");
    let b = TestStruct::deserialize(
        generated_visitor_for!(TestStruct)::from_json(a_data));
}
```

ปรากฏว่าการแปลงไม่สมมาตรกันอย่างที่คิด! บนกระดาษมันสมมาตร แต่กับโค้ดที่สร้างอัตโนมัติ ชื่อของชนิดจริงที่จำเป็นสำหรับแปลงกลับจาก `String` ถูกซ่อนไว้ เราจำเป็นต้องมีมาโคร `generated_visitor_for!` สักแบบเพื่อให้ได้ชื่อชนิดนั้นมา

มันพิลึก แต่ก็ใช้ได้... จนกระทั่งเราเจอปัญหาช้างในห้อง

รูปแบบเดียวที่รองรับในปัจจุบันคือ JSON แล้วเราจะรองรับรูปแบบอื่นๆ ได้อย่างไร?

การออกแบบปัจจุบันต้องเขียนการสร้างโค้ดใหม่ทั้งหมดและสร้าง Serde trait ตัวใหม่ ซึ่งแย่มากและไม่ขยายต่อได้เลย!

เพื่อแก้ปัญหานั้น เราจำเป็นต้องมีสิ่งที่ทรงพลังกว่านี้

## Prism

เพื่อคำนึงถึงรูปแบบข้อมูล เราต้องการอะไรบางอย่างในรูปแบบปกติเช่นนี้:

```text
case class Serde[T, F] {
    serialize: T, F -> String
    deserialize: String, F -> Result[T, Error]
}
```

โครงสร้างนี้เรียกว่า Prism มัน "อยู่สูงขึ้นหนึ่งระดับ" ในแง่เจเนอริกกว่า Poly Iso (ในกรณีนี้ ชนิด "ตัดกัน" F คือกุญแจสำคัญ)

น่าเสียดายที่เนื่องจาก `Visitor` เป็น trait (เพราะแต่ละ incarnation ต้องมีโค้ดเฉพาะของตัวเอง) สิ่งนี้จะต้องใช้ขอบเขตชนิดเจเนอริกแบบหนึ่งที่ Rust ไม่รองรับ

โชคดีที่เรายังมีชนิด `Visitor` จากก่อนหน้านี้ `Visitor` กำลังทำอะไร? มันพยายามให้แต่ละโครงสร้างข้อมูลนิยามวิธีที่ตัวมันเองถูกแยกวิเคราะห์

แล้วถ้าเราเพิ่มอินเทอร์เฟซอีกตัวสำหรับรูปแบบเจเนอริกล่ะ? จากนั้น `Visitor` ก็เป็นเพียงรายละเอียดการอิมพลีเมนต์ และมันจะ "เชื่อม" API ทั้งสองเข้าด้วยกัน

ในรูปแบบปกติ:

```text
case class Serde[T] {
    serialize: F -> String
    deserialize F, String -> Result[T, Error]
}

case class VisitorForT {
    build: F, String -> Result[T, Error]
    decompose: F, T -> String
}

case class SerdeFormat[T, V] {
    toString: T, V -> String
    fromString: V, String -> Result[T, Error]
}
```

และรู้ไหมว่า ที่ด้านล่างคือ Poly Iso คู่หนึ่งที่อิมพลีเมนต์เป็น traits ได้!

เราจึงได้ API ของ Serde:

1. แต่ละชนิดที่จะถูกทำให้เป็นอนุกรมอิมพลีเมนต์ `Deserialize` หรือ `Serialize`
   ซึ่งเทียบเท่ากับคลาส `Serde`
1. พวกมันได้ชนิดข้อมูลหนึ่งตัว (จริงๆ สองตัว ตัวละหนึ่งทิศทาง) ที่อิมพลีเมนต์
   trait `Visitor` ซึ่งโดยปกติ (แต่ไม่เสมอไป) ทำผ่านโค้ดที่สร้างโดย derive macro
   โดยบรรจุตรรกะสำหรับสร้างหรือแยกส่วนระหว่างชนิดข้อมูลกับรูปแบบของโมเดลข้อมูล
   Serde
1. ชนิดที่อิมพลีเมนต์ trait `Deserializer` จัดการรายละเอียดทั้งหมดที่จำเพาะต่อ
   รูปแบบ โดยถูก "ขับเคลื่อนโดย" `Visitor`

การแยกส่วนและ type erasure ของ Rust นี้จริงๆ แล้วเพื่อให้ได้ Prism ผ่านการอ้อมทาง

คุณเห็นได้จาก trait `Deserializer`

```rust,ignore
pub trait Deserializer<'de>: Sized {
    type Error: Error;

    fn deserialize_any<V>(self, visitor: V) -> Result<V::Value, Self::Error>
    where
        V: Visitor<'de>;

    fn deserialize_bool<V>(self, visitor: V) -> Result<V::Value, Self::Error>
    where
        V: Visitor<'de>;

    // remainder omitted
}
```

และตัว visitor:

```rust,ignore
pub trait Visitor<'de>: Sized {
    type Value;

    fn visit_bool<E>(self, v: bool) -> Result<Self::Value, E>
    where
        E: Error;

    fn visit_u64<E>(self, v: u64) -> Result<Self::Value, E>
    where
        E: Error;

    fn visit_str<E>(self, v: &str) -> Result<Self::Value, E>
    where
        E: Error;

    // remainder omitted
}
```

และ trait `Deserialize` ที่ถูกอิมพลีเมนต์โดยมาโคร:

```rust,ignore
pub trait Deserialize<'de>: Sized {
    fn deserialize<D>(deserializer: D) -> Result<Self, D::Error>
    where
        D: Deserializer<'de>;
}
```

ที่ผ่านมานามธรรมเกินไป ลองดูตัวอย่างที่เป็นรูปธรรมกัน

Serde จริงๆ แยกวิเคราะห์ JSON ส่วนเล็กๆ ให้เป็น `struct Concordance` จากก่อนหน้านี้ได้อย่างไร?

1. ผู้ใช้จะเรียกฟังก์ชันไลบรารีเพื่อแยกวิเคราะห์ข้อมูล ซึ่งจะสร้าง `Deserializer`
   ตามรูปแบบ JSON
1. จากฟิลด์ใน struct จะมี `Visitor` ถูกสร้างขึ้น (จะกล่าวถึงอีกครั้งสักครู่)
   ซึ่งรู้วิธีสร้างแต่ละชนิดในโมเดลข้อมูลเจเนอริกที่จำเป็นสำหรับนำเสนอข้อมูลนั้น:
   `Vec` (ลิสต์), `u64` และ `String`
1. ตัว deserializer จะเรียกใช้ `Visitor` ขณะที่มันแยกวิเคราะห์สมาชิกแต่ละตัว
1. `Visitor` จะบ่งชี้ว่าสมาชิกที่พบเป็นสิ่งที่คาดหวังหรือไม่ หากไม่ใช่ จะโยน
   ข้อผิดพลาดเพื่อบ่งชี้ว่าการแยกวิเคราะห์ล้มเหลว

สำหรับโครงสร้างง่ายๆ ข้างต้นของเรา แพตเทิร์นที่คาดหวังจะเป็น:

1. เริ่มเยี่ยมชมแมป (สิ่งที่ *Serde* เทียบเท่ากับ `HashMap` หรือดิกชันนารีของ JSON)
1. เยี่ยมชมคีย์สตริงชื่อ "keys"
1. เริ่มเยี่ยมชมค่าแมป
1. สำหรับแต่ละสมาชิก เยี่ยมชมคีย์สตริงแล้วตามด้วยค่าจำนวนเต็ม
1. เยี่ยมชมจุดสิ้นสุดของแมป
1. เก็บแมปลงในฟิลด์ `keys` ของโครงสร้างข้อมูล
1. เยี่ยมชมคีย์สตริงชื่อ "value_table"
1. เริ่มเยี่ยมชมค่าลิสต์
1. สำหรับแต่ละสมาชิก เยี่ยมชมจำนวนเต็ม
1. เยี่ยมชมจุดสิ้นสุดของลิสต์
1. เก็บลิสต์ลงในฟิลด์ `value_table`
1. เยี่ยมชมจุดสิ้นสุดของแมป

แต่อะไรเป็นตัวกำหนดว่าแพตเทิร์น "การสังเกต" ใดที่คาดหวัง?

ภาษาโปรแกรมเชิงฟังก์ชันจะใช้ currying เพื่อสร้างการสะท้อน (reflection) ของแต่ละชนิดจากตัวชนิดเองได้ Rust ไม่รองรับสิ่งนั้น ทุกชนิดข้อมูลจึงต้องมีโค้ดของตัวเองเขียนขึ้นจากฟิลด์และคุณสมบัติของมัน

*Serde* แก้ปัญหาการใช้งานนี้ด้วย derive macro:

```rust,ignore
use serde::Deserialize;

#[derive(Deserialize)]
struct IdRecord {
    name: String,
    customer_id: String,
}
```

มาโครนั้นเพียงสร้าง impl block ทำให้ struct อิมพลีเมนต์ trait ชื่อ `Deserialize`

นี่คือฟังก์ชันที่กำหนดวิธีสร้าง struct เอง โค้ดถูกสร้างจากฟิลด์ของ struct เมื่อไลบรารีการแยกวิเคราะห์ถูกเรียก -- ในตัวอย่างของเรา คือไลบรารีแยกวิเคราะห์ JSON -- มันจะสร้าง `Deserializer` แล้วเรียก `Type::deserialize` โดยส่งตัวเองเป็นพารามิเตอร์

จากนั้นโค้ด `deserialize` จะสร้าง `Visitor` ซึ่งการเรียกของมันจะถูก "หักเห" โดย `Deserializer` หากทุกอย่างเรียบร้อย ในที่สุด `Visitor` นั้นจะสร้างค่าที่สอดคล้องกับชนิดที่กำลังแยกวิเคราะห์และคืนมันกลับมา

สำหรับตัวอย่างที่สมบูรณ์ ดู
[เอกสารประกอบของ *Serde*](https://serde.rs/deserialize-struct.html)

ผลก็คือ ชนิดที่จะถูกแยกวิเคราะห์อิมพลีเมนต์เพียง "ชั้นบน" ของ API และรูปแบบไฟล์ต้องการอิมพลีเมนต์เพียง "ชั้นล่าง" จากนั้นแต่ละชิ้นส่วนก็ "ทำงานได้เลย" กับส่วนที่เหลือของระบบนิเวศ เพราะชนิดเจเนอริกจะเชื่อมมันเข้าด้วยกัน

โดยสรุป ระบบชนิดที่ได้แรงบันดาลใจจากเจเนอริกของ Rust สามารถนำมันเข้าใกล้แนวคิดเหล่านี้และใช้พลังของมันได้ ดังที่แสดงในการออกแบบ API นี้ แต่มันอาจต้องใช้โพรซีเจอรัลมาโครเพื่อสร้างสะพานเชื่อมให้เจเนอริกของมันด้วย

หากคุณสนใจเรียนรู้เพิ่มเติมเกี่ยวกับหัวข้อนี้ โปรดดูหัวข้อถัดไป

## ดูเพิ่มเติม

- [ครีต lens-rs](https://crates.io/crates/lens-rs) สำหรับการอิมพลีเมนต์เลนส์
  สำเร็จรูป ที่มีอินเทอร์เฟซสะอาดกว่าตัวอย่างเหล่านี้
- [Serde](https://serde.rs) เอง ซึ่งทำให้แนวคิดเหล่านี้เข้าใจง่ายสำหรับผู้ใช้
  ปลายทาง (คือการนิยาม struct) โดยไม่จำเป็นต้องเข้าใจรายละเอียด
- [luminance](https://github.com/phaazon/luminance-rs) เป็นครีตสำหรับวาดกราฟิก
  คอมพิวเตอร์ที่ใช้การออกแบบ API คล้ายกัน รวมถึงโพรซีเจอรัลมาโครสำหรับสร้าง
  prism เต็มรูปแบบให้กับบัฟเฟอร์ของชนิดพิกเซลต่างๆ ที่ยังคงเป็นเจเนอริก
- [บทความเกี่ยวกับเลนส์ในภาษา Scala](https://web.archive.org/web/20221128185849/https://medium.com/zyseme-technology/functional-references-lens-and-other-optics-in-scala-e5f7e2fdafe)
  ที่อ่านเข้าใจง่ายแม้ไม่มีความรู้เรื่อง Scala
- [Paper: Profunctor Optics: Modular Data
  Accessors](https://web.archive.org/web/20220701102832/https://arxiv.org/ftp/arxiv/papers/1703/1703.10857.pdf)
- [Musli](https://github.com/udoprog/musli) เป็นไลบรารีที่พยายามใช้โครงสร้าง
  คล้ายกันด้วยแนวทางที่ต่างออกไป เช่นการตัด visitor ออกไป

[^1]: [School of Haskell: A Little Lens Starter Tutorial](https://web.archive.org/web/20221128190041/https://www.schoolofhaskell.com/school/to-infinity-and-beyond/pick-of-the-week/a-little-lens-starter-tutorial)

[^2]: [Concordance บนวิกิพีเดีย](https://en.wikipedia.org/wiki/Concordance_(publishing))
