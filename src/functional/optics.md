# ออปติกส์เชิงฟังก์ชัน (Functional Optics)

ออปติกส์ (Optics) เป็นรูปแบบหนึ่งของการออกแบบ API ที่พบได้ทั่วไปในภาษาเชิงฟังก์ชันบริสุทธิ์ แม้ว่าจะเป็นแนวคิดเชิงทฤษฎีที่ไม่ได้ถูกหยิบยกมาพูดถึงโดยตรงบ่อยนักในภาษา Rust

ถึงกระนั้น การทำความเข้าใจแนวคิดนี้จะช่วยให้เราเข้าใจเบื้องลึกของแพตเทิร์นสำคัญอื่นๆ ใน API ของ Rust ได้อย่างแจ่มแจ้งยิ่งขึ้น เช่น [แพตเทิร์นวิสิเตอร์ (Visitor)](../patterns/behavioural/visitor.md) อีกทั้งยังมีประโยชน์อย่างยิ่งในกรณีการใช้งานเฉพาะทางบางรูปแบบ

หัวข้อนี้มีขอบเขตกว้างขวางมาก และอาจต้องใช้หนังสือเกี่ยวกับการออกแบบภาษาทั้งเล่มเพื่ออธิบายศักยภาพทั้งหมดของมัน อย่างไรก็ดี เมื่อนำแนวคิดนี้มาประยุกต์ใช้ใน Rust โครงสร้างของมันจะมีความเรียบง่ายและเป็นรูปธรรมมากกว่ามาก

เพื่ออธิบายแนวคิดนี้ให้เห็นภาพชัดเจน เราจะใช้การออกแบบ API ของไลบรารี `Serde` มาเป็นกรณีศึกษา เนื่องจากเป็น API ยอดนิยมที่หลายคนมักรู้สึกว่าเข้าใจได้ยากหากอ่านเพียงแค่เอกสารอ้างอิงธรรมดา

ในบทนี้ เราจะครอบคลุมรูปแบบย่อยของออปติกส์ ได้แก่ *The Iso*, *The Poly Iso* และ *The Prism*

## ตัวอย่าง API: Serde

การพยายามทำความเข้าใจหลักการทำงานของ *Serde* ด้วยการอ่านโค้ดของ API เพียงอย่างเดียวถือเป็นเรื่องที่ท้าทายไม่น้อย โดยเฉพาะสำหรับผู้ที่เพิ่งเริ่มศึกษา ลองพิจารณา trait `Deserializer` ที่ไลบรารีตัวแปลงไฟล์ (Parser) ต้องอิมพลีเมนต์:

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

และนี่คือนิยามของ trait `Visitor` ที่ถูกส่งเข้ามาเป็นพารามิเตอร์แบบเจเนอริก:

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

สังเกตว่ามีการทำ Type Erasure และมี Associated Type ซ้อนกันอยู่หลายชั้นจนชวนให้สับสน

แต่ภาพใหญ่เบื้องหลังโครงสร้างนี้คืออะไรกันแน่? ทำไม `Visitor` ไม่คืนค่าส่วนประกอบที่ผู้เรียกต้องการออกมาตรงๆ ในลักษณะของ Streaming API ให้จบเรื่องไป? ทำไมต้องสร้างส่วนประกอบที่ดูซับซ้อนเหล่านี้ขึ้นมามากมาย?

คำตอบสามารถอธิบายได้ด้วยแนวคิดในโลกของการเขียนโปรแกรมเชิงฟังก์ชันที่เรียกว่า *Optics*

Optics คือแนวทางในการประกอบพฤติกรรมและคุณสมบัติต่างๆ เข้าด้วยกัน ซึ่งถูกออกแบบมาเพื่ออำนวยความสะดวกให้แก่แพตเทิร์นที่พบบ่อยใน Rust เช่น การจัดการข้อผิดพลาด (Failure Handling), การแปลงชนิดข้อมูล (Type Conversion) และอื่นๆ[^1]

แม้ว่าภาษา Rust จะไม่ได้มีฟีเจอร์รองรับเรื่องนี้ในระดับไวยากรณ์โดยตรง แต่แนวคิดของ Optics ก็แฝงอยู่เบื้องหลังการออกแบบสถาปัตยกรรมของภาษา และช่วยอธิบายเหตุผลในการออกแบบ API สำคัญๆ ของ Rust ได้เป็นอย่างดี

เป้าหมายสูงสุดที่ API เหล่านี้ต้องการบรรลุคือ: คุณสมบัติการประกอบเข้าด้วยกันได้อย่างไร้รอยต่อ (Composability)

## ออปติกส์พื้นฐาน

### The Iso

The Iso คือตัวแปลงค่ากลับไปมาระหว่างชนิดข้อมูลสองชนิด (Isomorphism) เป็นโครงสร้างพื้นฐานที่เรียบง่าย แต่ถือเป็นหน่วยสร้าง (Building Block) ที่สำคัญยิ่งในเชิงแนวคิด

ตัวอย่างเช่น สมมติว่าเรามีโครงสร้าง Hash Table ที่กำหนดขึ้นเองเพื่อใช้เป็นดัชนีคำค้น (Concordance) สำหรับเอกสาร[^2] โดยเก็บคำศัพท์เป็นคีย์ชนิด String และเก็บรายการตำแหน่งดัชนีเป็น Value (เช่น ตำแหน่งไบต์ในไฟล์)

ฟังก์ชันการทำงานที่จำเป็นประการหนึ่งคือความสามารถในการแปลงโครงสร้างข้อมูลนี้ให้อยู่ในรูปอนุกรม (Serialize) เพื่อบันทึกลงดิสก์ วิธีที่ "ง่ายและเร็วที่สุด" คือการเขียนโค้ดแปลงไปมาระหว่างข้อมูลนี้กับสตริงในรูปแบบ JSON (โดยขอละเว้นการจัดการ error ไว้ก่อนชั่วคราวเพื่อความเรียบง่าย)

หากเขียนในรูปแบบ Normal Form ตามที่ภาษาเชิงฟังก์ชันนิยมใช้:

```text
case class ConcordanceSerDe {
  serialize: Concordance -> String
  deserialize: String -> Concordance
}
```

The Iso จึงเป็นเพียงคู่ของฟังก์ชันสองตัวที่แปลงค่ากลับไปมาระหว่างสองชนิดข้อมูล: นั่นคือ `serialize` และ `deserialize`

การอิมพลีเมนต์แบบตรงไปตรงมาใน Rust จะมีลักษณะดังนี้:

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

โครงสร้างแบบนี้อาจดูผิวเผินไปหน่อย เพราะใน Rust การทำงานลักษณะนี้มักจะอิมพลีเมนต์ผ่าน trait เช่น `FromStr` และ `ToString` ที่มีอยู่ในไลบรารีมาตรฐานอยู่แล้ว

และนั่นก็นำพาเราไปสู่หัวข้อถัดไป: Poly Isos

### Poly Isos

ตัวอย่างก่อนหน้านี้เป็นการแปลงค่าระหว่างชนิดข้อมูลคู่เดิมที่ถูกกำหนดไว้ตายตัว แต่กลุ่มถัดไปจะยกระดับความสามารถขึ้นไปอีกขั้นด้วยการนำเจเนอริก (Generics) เข้ามาผสาน

Poly Isos ช่วยให้การแปลงข้อมูลทำงานแบบเจเนอริกกับชนิดข้อมูลใดๆ ก็ได้ โดยยังคงคืนค่าชนิดข้อมูลเป้าหมายออกมาได้อย่างถูกต้อง

สิ่งนี้นำเราเข้าใกล้การทำตัวแจงส่วน (Parser) มากขึ้น ลองพิจารณาว่า Parser พื้นฐานต้องทำอะไรบ้างหากเราตัดประเด็นเรื่อง Error ออกไปก่อน ในรูปแบบ Normal Form:

```text
case class Serde[T] {
    deserialize(String) -> T
    serialize(T) -> String
}
```

ณ จุดนี้ เรามีพารามิเตอร์เจเนอริกตัวแรกเกิดขึ้นแล้ว นั่นคือชนิดข้อมูล `T` ที่ต้องการแปลง

ใน Rust เราสามารถอิมพลีเมนต์สิ่งนี้ได้ผ่านคู่ของ trait ในไลบรารีมาตรฐาน: ได้แก่ `FromStr` และ `ToString` ซึ่งใน Rust นั้นจะมีการจัดการข้อผิดพลาดควบคู่ไปด้วยเสมอ:

```rust,ignore
pub trait FromStr: Sized {
    type Err;

    fn from_str(s: &str) -> Result<Self, Self::Err>;
}

pub trait ToString {
    fn to_string(&self) -> String;
}
```

สิ่งที่ทำให้ Poly Iso แตกต่างจาก Iso ธรรมดา คือการเปิดให้เรานำไปประยุกต์ใช้กับชนิดข้อมูลที่หลากหลาย และคืนผลลัพธ์กลับมาในรูปของเจเนอริก ซึ่งเป็นคุณสมบัติพื้นฐานที่ String Parser ต้องการ

เมื่อมองเผินๆ วิธีนี้ดูเหมือนจะเพียงพอสำหรับการเขียน Parser แล้ว ลองดูตัวอย่างการใช้งานจริง:

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

โค้ดนี้ดูสมเหตุสมผลดี แต่ในความเป็นจริงมีปัญหาสำคัญอยู่ 2 ประการ

ประการแรก เมท็อด `to_string` ไม่ได้บอกผู้ใช้เลยว่า "ผลลัพธ์นี้อยู่ในรูปแบบ JSON" ข้อมูลแต่ละประเภทอาจมีนิยามของสตริงที่แตกต่างกัน และหลายชนิดข้อมูลในไลบรารีมาตรฐานของ Rust ก็ไม่ได้คืนค่าออกมาในรูป JSON อยู่แล้ว การใช้วิธีนี้จึงอาจเกิดความสับสนได้ง่าย ซึ่งปัญหานี้แก้ได้ไม่ยากโดยการสร้าง trait ของเราเองขึ้นมา

แต่ปัญหาประการที่สองนั้นซับซ้อนและสำคัญกว่ามาก นั่นคือ: ปัญหาด้านความสามารถในการรองรับขนาดและการขยายระบบ (Scalability)

หากทุก struct ต้องมานั่งเขียนโค้ด `to_string` ด้วยมือทีละตัว โค้ดจะเริ่มกระจัดกระจายและซ้ำซ้อนอย่างมหาศาล ยิ่งถ้าแต่ละคนเลือกใช้ไลบรารี JSON ที่แตกต่างกัน ระบบทั้งหมดจะกลายเป็นความยุ่งเหยิงในทันที!

ทางออกสำหรับปัญหานี้คือนวัตกรรมชิ้นสำคัญของ Serde: นั่นคือการออกแบบ **Data Model ที่เป็นอิสระจากฟอร์แมตภายนอก** เพื่อทำหน้าที่เป็นตัวกลางในการจำลองโครงสร้างข้อมูลของ Rust และใช้ความสามารถของระบบโค้ดเจน (Code Generation / Macro) ในการสร้างชนิดข้อมูลตัวกลางสำหรับแปลงข้อมูล ซึ่งเรียกสิ่งนี้ว่า `Visitor`

ในรูปแบบ Normal Form (โดยละเว้นการจัดการข้อผิดพลาดเพื่อความกระชับ):

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

ส่งผลให้เราได้ Poly Iso หนึ่งตัว และได้ Iso ธรรมดาอีกหนึ่งตัว โดยทั้งคู่สามารถแปลงมาเป็น trait ใน Rust ได้ดังนี้:

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

ด้วยความที่กฎในการแปลงโครงสร้างข้อมูลของ Rust ไปสู่ Data Model ตัวกลางมีความสม่ำเสมอและคาดเดาได้ จึงเปิดทางให้ระบบ Code Generation สามารถสร้าง `Visitor` ที่สอดคล้องกับชนิดข้อมูล `T` แต่ละตัวขึ้นมาได้โดยอัตโนมัติ:

```rust,ignore
#[derive(Default, Serde)] // the "Serde" derive creates the trait impl block
struct TestStruct {
    a: usize,
    b: String,
}

// user writes this macro to generate an associated visitor type
generate_visitor!(TestStruct);
```

แต่เมื่อลองนำแนวทางนี้ไปใช้งานจริง:

```rust,ignore
fn main() {
    let a = TestStruct { a: 5, b: "hello".to_string() };
    let a_data = a.serialize().to_json();
    println!("Our Test Struct as JSON: {a_data}");
    let b = TestStruct::deserialize(
        generated_visitor_for!(TestStruct)::from_json(a_data));
}
```

เราจะพบว่าการแปลงข้อมูลไม่ได้มีความสมมาตรอย่างที่วาดหวังไว้! บนกระดาษอาจดูสมมาตรดี แต่ในการทำงานจริง ชื่อชนิดข้อมูลที่แท้จริงที่จำเป็นสำหรับการแปลงกลับมาจาก `String` จะถูกซ่อนไว้ ทำให้เราต้องสร้างมาโครอย่าง `generated_visitor_for!` เข้ามาช่วยดึงชื่อชนิดข้อมูลออกมา

วิธีนี้อาจพอถูไถไปได้... จนกระทั่งเรามาถึงปัญหาใหญ่ข้อสำคัญที่ไม่อาจมองข้ามได้ (The elephant in the room)

นั่นคือ ปัจจุบันวิธีนี้รองรับเพียงแค่ฟอร์แมต JSON เท่านั้น แล้วถ้าในอนาคตเราต้องการรองรับฟอร์แมตอื่นๆ เช่น YAML, Bincode หรือ TOML ล่ะ?

การออกแบบโครงสร้างเช่นนี้จะบีบให้เราต้องเขียนระบบโค้ดเจนใหม่ทั้งหมดสำหรับทุกฟอร์แมต และต้องสร้าง Serde trait ตัวใหม่อยู่ตลอดเวลา ซึ่งเป็นการออกแบบที่แย่มากและไม่สามารถขยายต่อได้อย่างยั่งยืน!

เพื่อแก้ปัญหานี้ เราจำเป็นต้องใช้แนวคิดที่ทรงพลังยิ่งกว่าเดิม

## Prism

หากต้องการให้ระบบรองรับฟอร์แมตข้อมูลได้อย่างยืดหยุ่น โครงสร้างในรูปแบบ Normal Form จะต้องเป็นดังนี้:

```text
case class Serde[T, F] {
    serialize: T, F -> String
    deserialize: String, F -> Result[T, Error]
}
```

โครงสร้างในลักษณะนี้เรียกว่า **Prism** ซึ่งมีระดับความเป็นเจเนอริกที่ "สูงขึ้นไปอีกขั้น" เมื่อเทียบกับ Poly Iso (โดยในที่นี้ ชนิดข้อมูลฟอร์แมต `F` คือกุญแจสำคัญ)

อย่างไรก็ดี เนื่องจาก `Visitor` จำเป็นต้องถูกกำหนดเป็น trait (เพราะชนิดข้อมูลแต่ละตัวจำเป็นต้องมีตรรกะเฉพาะในการแปลง) โครงสร้างนี้จึงต้องการระบบ Generic Type Boundary ที่ภาษา Rust ยังไม่รองรับในระดับภาษา

แต่โชคดีที่เรายังคงมีชนิดข้อมูล `Visitor` จากแนวทางก่อนหน้า แล้วหน้าที่แท้จริงของ `Visitor` คืออะไร? มันคือตัวแทนที่เปิดให้โครงสร้างข้อมูลแต่ละตัวสามารถกำหนดวิธีในการแจงส่วน (Parse) ตัวมันเองได้

แล้วจะเป็นอย่างไรถ้าเราเพิ่มอินเทอร์เฟซตัวกลางเข้ามาอีกชั้นหนึ่งสำหรับจัดการฟอร์แมตข้อมูลแบบเจเนอริก? เมื่อทำเช่นนั้น `Visitor` จะกลายเป็นเพียงรายละเอียดเบื้องหลังของการนำไปใช้งาน และทำหน้าที่เป็น "สะพานเชื่อม" ระหว่างสองฝั่งของ API

ในรูปแบบ Normal Form:

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

และผลลัพธ์ที่ได้คือ โครงสร้าง Poly Iso สองตัวที่อยู่ด้านล่าง ซึ่งสามารถนำมาอิมพลีเมนต์เป็น trait ใน Rust ได้อย่างลงตัว!

นี่จึงเป็นที่มาของสถาปัตยกรรม API ของ Serde:

1. ชนิดข้อมูลแต่ละตัวที่ต้องการ Serialize จะต้องอิมพลีเมนต์ trait `Deserialize` หรือ `Serialize` (เทียบเท่ากับคลาส `Serde`)
1. ชนิดข้อมูลเหล่านั้นจะมีชนิดตัวกลาง (2 ตัว สำหรับขาไปและขากลับ) ที่อิมพลีเมนต์ trait `Visitor` ซึ่งสร้างขึ้นโดยอัตโนมัติผ่าน Derive Macro โดยบรรจุตรรกะในการแปลงข้อมูลไปมาระหว่างโครงสร้างข้อมูลกับ Serde Data Model
1. ชนิดข้อมูลที่อิมพลีเมนต์ trait `Deserializer` จะรับผิดชอบรายละเอียดทั้งหมดที่เจาะจงเฉพาะฟอร์แมตนั้นๆ โดยจะถูก "ขับเคลื่อนการทำงาน" ผ่าน `Visitor`

การแบ่งส่วน API และการทำ Type Erasure ของ Rust ในลักษณะนี้ แท้จริงแล้วคือการจำลอง Prism ผ่านการอ้างอิงทางอ้อม (indirection)

คุณสามารถสังเกตสิ่งนี้ได้จากนิยามของ trait `Deserializer`:

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

และ trait ของ Visitor:

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

รวมถึง trait `Deserialize` ที่มาโครช่วยอิมพลีเมนต์ให้:

```rust,ignore
pub trait Deserialize<'de>: Sized {
    fn deserialize<D>(deserializer: D) -> Result<Self, D::Error>
    where
        D: Deserializer<'de>;
}
```

เพื่อไม่ให้เนื้อหาดูเป็นนามธรรมจนเกินไป ลองมาดูตัวอย่างการทำงานจริงที่เป็นรูปธรรมกัน

Serde มีขั้นตอนอย่างไรในการแปลง JSON กลับมาเป็น `struct Concordance` ดังตัวอย่างข้างต้น?

1. โค้ดของผู้ใช้จะเรียกฟังก์ชันของไลบรารีเพื่อแปลงข้อมูล ซึ่งจะสร้างอ็อบเจกต์ `Deserializer` ตามฟอร์แมต JSON ขึ้นมา
1. เมื่อพิจารณาจากฟิลด์ต่างๆ ภายใน struct ตัว `Visitor` จะถูกสร้างขึ้นมาเพื่อรับหน้าที่แปลงชนิดข้อมูลพื้นฐานใน Data Model: ได้แก่ `Vec` (List), `u64` และ `String`
1. Deserializer จะส่งต่อการทำงานไปยัง `Visitor` ในขณะที่กำลังแจงส่วนแต่ละฟิลด์
1. `Visitor` จะคอยตรวจสอบว่าข้อมูลที่พบตรงตามรูปแบบที่คาดหวังหรือไม่ หากไม่ตรง ก็จะแจ้ง error ออกมาเพื่อระบุว่าการ Deserialize ล้มเหลว

สำหรับโครงสร้างข้อมูลอย่างง่ายของเรา ลำดับขั้นตอนการทำงานจะเป็นดังนี้:

1. เริ่มประมวลผลข้อมูลแบบ Map (เทียบเท่ากับ `HashMap` ของ Serde หรือ Dictionary/Object ของ JSON)
1. ตรวจสอบคีย์ชนิด String ที่มีชื่อว่า "keys"
1. เริ่มประมวลผลค่า Value ของ Map
1. สำหรับแต่ละรายการ ให้ประมวลผลคีย์ String ตามด้วยค่าจำนวนเต็ม Integer
1. สิ้นสุดการประมวลผล Map
1. นำข้อมูล Map ที่ได้ไปกำหนดค่าลงในฟิลด์ `keys` ของ struct
1. ตรวจสอบคีย์ชนิด String ที่มีชื่อว่า "value_table"
1. เริ่มประมวลผลค่า Value ของ List
1. สำหรับแต่ละรายการ ให้ประมวลผลค่าจำนวนเต็ม Integer
1. สิ้นสุดการประมวลผล List
1. นำข้อมูล List ที่ได้ไปกำหนดค่าลงในฟิลด์ `value_table`
1. สิ้นสุดการประมวลผล Map ทั้งหมด

แต่อะไรคือตัวกำหนดว่าลำดับขั้นตอนใดที่ควรคาดหวัง?

ในภาษาเชิงฟังก์ชันบริสุทธิ์ จะสามารถใช้เทคนิค Currying เพื่อสร้าง Type Reflection ขึ้นมาจากตัวชนิดข้อมูลได้เอง แต่ภาษา Rust ไม่มีฟีเจอร์นี้ ดังนั้นชนิดข้อมูลทุกตัวจึงจำเป็นต้องมีโค้ดที่สร้างขึ้นเฉพาะตัวตามฟิลด์และคุณสมบัติของมัน

*Serde* แก้ไขปัญหาความสะดวกในการใช้งานนี้ด้วย Derive Macro:

```rust,ignore
use serde::Deserialize;

#[derive(Deserialize)]
struct IdRecord {
    name: String,
    customer_id: String,
}
```

มาโครดังกล่าวจะสร้างบล็อก `impl` ที่อิมพลีเมนต์ trait `Deserialize` ให้แก่ struct โดยอัตโนมัติ

นี่คือฟังก์ชันที่กำหนดกระบวนการสร้าง struct ขึ้นมา โดยโค้ดจะถูกสร้างขึ้นตามฟิลด์ของ struct นั้นๆ เมื่อไลบรารีตัวแปลงไฟล์ถูกเรียกใช้งาน -- ในตัวอย่างนี้คือตัวแปลง JSON -- มันจะสร้าง `Deserializer` ขึ้นมาแล้วเรียกใช้ `Type::deserialize` พร้อมส่งตัวมันเองเข้าไปเป็นพารามิเตอร์

จากนั้นโค้ดของ `deserialize` จะสร้าง `Visitor` ขึ้นมาเพื่อรับการเรียกทำงานจาก `Deserializer` และเมื่อกระบวนการทั้งหมดสำเร็จลุล่วง `Visitor` ก็จะประกอบและคืนค่าออบเจกต์ที่สอดคล้องกับชนิดข้อมูลที่กำลังแปลงกลับออกมา

สำหรับตัวอย่างฉบับสมบูรณ์ สามารถศึกษาเพิ่มเติมได้จาก
[เอกสารประกอบของ *Serde*](https://serde.rs/deserialize-struct.html)

ผลลัพธ์ที่ได้คือ โครงสร้างข้อมูลที่ต้องการ Deserialize จำเป็นต้องอิมพลีเมนต์เพียงแค่ "ส่วนบน" ของ API เท่านั้น ในขณะที่ฟอร์แมตของไฟล์ต่างๆ ก็อิมพลีเมนต์เพียงแค่ "ส่วนล่าง" ของ API ทำให้ทุกส่วนในระบบนิเวศสามารถ "ทำงานร่วมกันได้อย่างราบรื่นทันที" โดยมีระบบชนิดข้อมูลเจเนอริกทำหน้าที่เป็นสะพานเชื่อมระหว่างกัน

กล่าวโดยสรุป ระบบชนิดข้อมูลที่ได้แรงบันดาลใจมาจากแนวคิดเชิงฟังก์ชันของ Rust ช่วยให้ภาษาเข้าใกล้แนวคิดขั้นสูงเหล่านี้และดึงเอาศักยภาพของมันออกมาใช้ได้อย่างเต็มที่ แต่อาจต้องอาศัย Procedural Macro เข้ามาช่วยสร้างสะพานเชื่อมในการสร้างโค้ดเจเนอริก

หากคุณสนใจศึกษาเพิ่มเติมเกี่ยวกับหัวข้อนี้ สามารถอ่านรายละเอียดต่อได้ในส่วนถัดไป

## ดูเพิ่มเติม

- [crate lens-rs](https://crates.io/crates/lens-rs) สำหรับการอิมพลีเมนต์ Lenses สำเร็จรูป ที่มีอินเทอร์เฟซสะอาดตาและใช้งานง่าย
- [Serde](https://serde.rs) ไลบรารียอดนิยมที่นำแนวคิดเหล่านี้มาทำให้ผู้ใช้ปลายทางใช้งานได้อย่างสะดวกเป็นธรรมชาติ โดยไม่จำเป็นต้องเข้าใจทฤษฎีเชิงลึก
- [luminance](https://github.com/phaazon/luminance-rs) crate สำหรับการเรนเดอร์คอมพิวเตอร์กราฟิกที่ใช้การออกแบบ API ในลักษณะเดียวกันนี้ รวมถึงใช้ Procedural Macro เพื่อสร้าง Prism แบบเต็มรูปแบบสำหรับบัฟเฟอร์ของพิกเซลชนิดต่างๆ
- [บทความเกี่ยวกับ Lenses ในภาษา Scala](https://web.archive.org/web/20221128185849/https://medium.com/zyseme-technology/functional-references-lens-and-other-optics-in-scala-e5f7e2fdafe) ซึ่งเขียนอธิบายไว้อย่างเข้าใจง่ายแม้จะไม่มีพื้นฐานภาษา Scala มาก่อน
- [เอกสารวิจัย: Profunctor Optics: Modular Data Accessors](https://web.archive.org/web/20220701102832/https://arxiv.org/ftp/arxiv/papers/1703/1703.10857.pdf)
- [Musli](https://github.com/udoprog/musli) ไลบรารี Serialization ที่ใช้โครงสร้างคล้ายคลึงกันแต่ใช้แนวทางที่แตกต่าง เช่น การตัด visitor ออกไป

[^1]: [School of Haskell: A Little Lens Starter Tutorial](https://web.archive.org/web/20221128190041/https://www.schoolofhaskell.com/school/to-infinity-and-beyond/pick-of-the-week/a-little-lens-starter-tutorial)

[^2]: [Concordance บนวิกิพีเดีย](https://en.wikipedia.org/wiki/Concordance_(publishing))
