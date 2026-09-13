# คอนสตรัคเตอร์

## คำอธิบาย

Rust ไม่มีคอนสตรัคเตอร์ในฐานะโครงสร้างของภาษา แต่ธรรมเนียมปฏิบัติคือการใช้ [ฟังก์ชันที่สัมพันธ์กับชนิด (associated function)][associated function] ชื่อ `new` เพื่อสร้างออบเจกต์:

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

`Default` ยังสามารถ derive ได้หากทุกชนิดของทุกฟิลด์อิมพลีเมนต์ `Default` อย่างเช่นกรณีของ `Second`:

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

**หมายเหตุ:** เป็นเรื่องปกติและคาดหวังได้ว่าชนิดข้อมูลจะอิมพลีเมนต์ทั้ง `Default` และคอนสตรัคเตอร์ `new` ที่ไม่รับอาร์กิวเมนต์ `new` เป็นธรรมเนียมของคอนสตรัคเตอร์ใน Rust และผู้ใช้คาดหวังว่ามันจะมีอยู่ ดังนั้นหากคอนสตรัคเตอร์พื้นฐานไม่รับอาร์กิวเมนต์ได้อย่างสมเหตุสมผล ก็ควรทำเช่นนั้น แม้จะทำงานเหมือนกับ default ทุกประการ

**คำแนะนำ:** ข้อดีของการอิมพลีเมนต์หรือ derive `Default` คือชนิดข้อมูลของคุณจะถูกใช้ในที่ที่ต้องการการอิมพลีเมนต์ `Default` ได้ โดยที่เด่นชัดที่สุดคือฟังก์ชัน [`*or_default` ใดๆ ในไลบรารีมาตรฐาน][std-or-default]

## ดูเพิ่มเติม

- [สำนวน default](default.md) สำหรับคำอธิบายเชิงลึกเพิ่มเติมเกี่ยวกับ trait
  `Default`

- [แพตเทิร์นบิลเดอร์](../patterns/creational/builder.md) สำหรับการสร้างออบเจกต์
  ในกรณีที่มีหลายรูปแบบการตั้งค่า

- [API Guidelines/C-COMMON-TRAITS][API Guidelines/C-COMMON-TRAITS] สำหรับ
  การอิมพลีเมนต์ทั้ง `Default` และ `new`

[associated function]: https://doc.rust-lang.org/stable/book/ch05-03-method-syntax.html#associated-functions
[std-default]: https://doc.rust-lang.org/stable/std/default/trait.Default.html
[std-or-default]: https://doc.rust-lang.org/stable/std/?search=or_default
[API Guidelines/C-COMMON-TRAITS]: https://rust-lang.github.io/api-guidelines/interoperability.html#types-eagerly-implement-common-traits-c-common-traits
