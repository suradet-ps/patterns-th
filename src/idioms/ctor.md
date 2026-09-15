# คอนสตรัคเตอร์

## คำอธิบาย

ภาษา Rust ไม่มีฟีเจอร์ Constructor เป็นคำสั่งเฉพาะของตัวภาษาเหมือนในภาษาเชิงวัตถุอื่นๆ แต่ธรรมเนียมปฏิบัติของชาว Rust คือการสร้าง [Associated Function][associated function] ที่มีชื่อว่า `new` เพื่อทำหน้าที่สร้างอินสแตนซ์ของออบเจกต์ขึ้นมา:

````rust
/// Time in seconds.
///
/// # Example
///
/// ```
/// let s = Second::new(42);
/// assert_eq!(42, s.value());
/// ```
pub struct Second {
    value: u64,
}

impl Second {
    // Constructs a new instance of [`Second`].
    // Note this is an associated function - no self.
    pub fn new(value: u64) -> Self {
        Self { value }
    }

    /// Returns the value in seconds.
    pub fn value(&self) -> u64 {
        self.value
    }
}
````

## คอนสตรัคเตอร์เริ่มต้น (Default Constructors)

Rust รองรับคอนสตรัคเตอร์เริ่มต้นผ่าน trait [`Default`][std-default]:

````rust
/// Time in seconds.
///
/// # Example
///
/// ```
/// let s = Second::default();
/// assert_eq!(0, s.value());
/// ```
pub struct Second {
    value: u64,
}

impl Second {
    /// Returns the value in seconds.
    pub fn value(&self) -> u64 {
        self.value
    }
}

impl Default for Second {
    fn default() -> Self {
        Self { value: 0 }
    }
}
````

`Default` ยังสามารถ derive ได้โดยอัตโนมัติหากทุกชนิดข้อมูลของทุกฟิลด์อิมพลีเมนต์ `Default` ไว้อยู่แล้ว เช่นเดียวกับกรณีของ `Second`:

````rust
/// Time in seconds.
///
/// # Example
///
/// ```
/// let s = Second::default();
/// assert_eq!(0, s.value());
/// ```
#[derive(Default)]
pub struct Second {
    value: u64,
}

impl Second {
    /// Returns the value in seconds.
    pub fn value(&self) -> u64 {
        self.value
    }
}
````

**ข้อสังเกต:** เป็นเรื่องปกติธรรมดาและถือเป็นสิ่งที่คาดหวังได้ ว่าชนิดข้อมูลควรจะอิมพลีเมนต์ทั้ง `Default` และคอนสตรัคเตอร์ `new` ที่ไม่รับพารามิเตอร์ควบคู่กัน เนื่องจาก `new` คือธรรมเนียมปฏิบัติมาตรฐานของการสร้างออบเจกต์ใน Rust และผู้ใช้คาดหวังว่าจะมีเมท็อดนี้ให้เรียกใช้เสมอ ดังนั้นหากมีความสมเหตุสมผลที่คอนสตรัคเตอร์พื้นฐานจะไม่รับอาร์กิวเมนต์ใดๆ ก็ควรเขียนเมท็อด `new()` เตรียมไว้ด้วย แม้ว่าการทำงานภายในจะเหมือนกับ `default()` ทุกประการก็ตาม

**คำแนะนำ:** ข้อดีของการอิมพลีเมนต์หรือ derive trait `Default` คือ ชนิดข้อมูลของคุณจะสามารถนำไปใช้งานร่วมกับฟังก์ชันหรือคอมโพเนนต์อื่นๆ ที่ต้องการ `Default` ได้ทันที ตัวอย่างที่เห็นได้ชัดเจนที่สุดคือ บรรดาฟังก์ชันตระกูล [`*or_default` ทั้งหลายในไลบรารีมาตรฐาน][std-or-default]

## ดูเพิ่มเติม

- [แนวปฏิบัติ Default (The Default Trait)](default.md) สำหรับคำอธิบายเชิงลึกเพิ่มเติมเกี่ยวกับ trait
  `Default`

- [แพตเทิร์นบิลเดอร์ (Builder Pattern)](../patterns/creational/builder.md) สำหรับการสร้างออบเจกต์
  ในกรณีที่มีหลายรูปแบบการตั้งค่า

- [API Guidelines/C-COMMON-TRAITS][API Guidelines/C-COMMON-TRAITS] สำหรับ
  การอิมพลีเมนต์ทั้ง `Default` และ `new`

[associated function]: https://doc.rust-lang.org/stable/book/ch05-03-method-syntax.html#associated-functions
[std-default]: https://doc.rust-lang.org/stable/std/default/trait.Default.html
[std-or-default]: https://doc.rust-lang.org/stable/std/?search=or_default
[API Guidelines/C-COMMON-TRAITS]: https://rust-lang.github.io/api-guidelines/interoperability.html#types-eagerly-implement-common-traits-c-common-traits
